//
//  MODClient.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"
#import "bson.h"
#import "mongoc.h"

@interface MODClient ()
@property (nonatomic, readwrite, retain) NSOperationQueue *operationQueue;

@end

@implementation MODClient

@synthesize connected = _connected, mongocClient = _mongocClient, operationQueue = _operationQueue;

+ (MODClient *)clientWihtURLString:(NSString *)urlString
{
    MODClient *result;
    
    mongoc_init();
    result = [[MODClient alloc] initWithURIString:urlString];
    return [result autorelease];
}

+ (uint16_t)defaultPort
{
    return MONGOC_DEFAULT_PORT;
}

- (id)init
{
    if ((self = [super init]) != nil) {
        self.operationQueue = [[[NSOperationQueue alloc] init] autorelease];
        [_operationQueue setMaxConcurrentOperationCount:1];
    }
    return self;
}

- (id)initWithURIString:(NSString *)urlString
{
    return [self initWithURICString:urlString.UTF8String];
}

- (id)initWithURICString:(const char *)urlCString
{
    if ((self = [self init]) != nil) {
        self.mongocClient = mongoc_client_new(urlCString);
        if (self.mongocClient == NULL) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (id)initWithMongoURI:(const mongoc_uri_t *)uri
{
    if ((self = [self init]) != nil) {
        _mongocClient = mongoc_client_new_from_uri(uri);
        if (_mongocClient == NULL) {
            [self release];
            self = nil;
        }
    }
    return self;
}

- (void)dealloc
{
    if (self.mongocClient) {
        mongoc_client_destroy(self.mongocClient);
        self.mongocClient = NULL;
    }
    self.operationQueue = nil;
    [super dealloc];
}

- (id)copy
{
    return [[MODClient alloc] initWithMongoURI:mongoc_client_get_uri(self.mongocClient)];
}

- (MODQuery *)addQueryInQueue:(void (^)(MODQuery *currentMongoQuery))block
{
    MODQuery *mongoQuery;
    NSBlockOperation *blockOperation;
    
    mongoQuery = [[MODQuery alloc] init];
    blockOperation = [[NSBlockOperation alloc] init];
    [blockOperation addExecutionBlock:^{
        [mongoQuery starts];
        block(mongoQuery);
    }];
    mongoQuery.blockOperation = blockOperation;
    [_operationQueue addOperation:blockOperation];
    [blockOperation release];
    return [mongoQuery autorelease];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error
{
    [mongoQuery.mutableParameters setObject:self forKey:@"mongoserver"];
    [mongoQuery ends];
    mongoQuery.error = error;
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock
{
    if (![mongoQuery.parameters objectForKey:@"command"]) {
        NSLog(@"done with %@", [mongoQuery.parameters objectForKey:@"command"]);
    }
    [self mongoQueryDidFinish:mongoQuery withError:error];
    if (callbackBlock) {
        dispatch_async(dispatch_get_main_queue(), callbackBlock);
    }
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)bsonError callbackBlock:(void (^)(void))callbackBlock
{
    NSError *error = nil;
    
    if (bsonError.code != 0) {
        error = [self.class errorFromBsonError:bsonError];
    }
    [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:callbackBlock];
}

- (MODQuery *)fetchServerStatusWithCallback:(void (^)(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery){
        bson_t output;
        bson_error_t error = BSON_NO_ERROR;
        MODSortedMutableDictionary *outputObjects = nil;
        
        if (!mongoQuery.canceled) {
            mongoc_client_get_server_status(self.mongocClient, NULL, &output, &error);
            outputObjects = [self.class objectFromBson:&output];
        }
        [self mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            callback(outputObjects, mongoQuery);
        }];
        bson_destroy(&output);
    }];
    [query.mutableParameters setObject:@"fetchserverstatus" forKey:@"command"];
    return query;
}

- (MODQuery *)fetchDatabaseListWithCallback:(void (^)(NSArray *list, MODQuery *mongoQuery))callback;
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery) {
        bson_t output = BSON_INITIALIZER;
        NSMutableArray *list = nil;
        bson_error_t error = BSON_NO_ERROR;
        
        if (!mongoQuery.canceled) {
            char **cStringName;
            
            cStringName = mongoc_client_get_database_names(self.mongocClient, &error);
            if (cStringName) {
                char **cursor = cStringName;
                
                list = [[NSMutableArray alloc] init];
                while (*cursor != NULL) {
                    [list addObject:[NSString stringWithUTF8String:*cursor]];
                    bson_free(*cursor);
                    cursor++;
                }
                bson_free(cStringName);
            }

        }
        [self mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            callback(list, mongoQuery);
        }];
        bson_destroy(&output);
        [list release];
    }];
    [query.mutableParameters setObject:@"fetchdatabaselist" forKey:@"command"];
    return query;
}

- (MODDatabase *)databaseForName:(NSString *)databaseName
{
    return [[[MODDatabase alloc] initWithClient:self name:databaseName] autorelease];
}

@end
