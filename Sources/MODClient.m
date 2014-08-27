//
//  MODClient.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 02/09/2011.
//

#import "MongoObjCDriver-private.h"
#import "bson.h"
#import "mongoc.h"
#import "mongoc-client-private.h"

@interface MODBlockOperation : NSBlockOperation
{
    MODQuery *_mongoQuery;
}
@property (nonatomic, readwrite, strong) MODQuery *mongoQuery;

@end

@implementation MODBlockOperation

@synthesize mongoQuery = _mongoQuery;

@end

@interface MODClient ()
@property (nonatomic, readwrite, retain) NSOperationQueue *operationQueue;

@end

@implementation MODClient

@synthesize connected = _connected;
@synthesize mongocClient = _mongocClient;
@synthesize operationQueue = _operationQueue;

+ (instancetype)clientWihtURLString:(NSString *)urlString
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

- (instancetype)init
{
    if ((self = [super init]) != nil) {
        self.operationQueue = [[[NSOperationQueue alloc] init] autorelease];
        [self.operationQueue setMaxConcurrentOperationCount:1];
    }
    return self;
}

- (instancetype)initWithURIString:(NSString *)urlString
{
    return [self initWithURICString:urlString.UTF8String];
}

- (instancetype)initWithURICString:(const char *)urlCString
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

- (instancetype)initWithMongoURI:(const mongoc_uri_t *)uri
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
    self.sslOptions = nil;
    self.writeConcern = nil;
    self.readPreferences = nil;
    self.operationQueue = nil;
    mongoc_client_destroy(self.mongocClient);
    [super dealloc];
}

- (instancetype)copy
{
    MODClient *result;
    
    result = [[self.class alloc] initWithMongoURI:mongoc_client_get_uri(self.mongocClient)];
    result.sslOptions = self.sslOptions;
    result.readPreferences = self.readPreferences;
    result.writeConcern = self.writeConcern;
    return result;
}

- (MODQuery *)addQueryInQueue:(void (^)(MODQuery *currentMongoQuery))block owner:(id<NSObject>)owner name:(NSString *)name parameters:(NSDictionary *)parameters
{
    MODQuery *mongoQuery;
    MODBlockOperation *blockOperation;
    
    mongoQuery = [[MODQuery alloc] initWithOwner:owner name:name parameters:parameters];
    blockOperation = [[MODBlockOperation alloc] init];
    blockOperation.mongoQuery = mongoQuery;
    [blockOperation addExecutionBlock:^{
        [mongoQuery starts];
        block(mongoQuery);
    }];
    mongoQuery.blockOperation = blockOperation;
    [self.operationQueue addOperation:blockOperation];
    [blockOperation release];
    return [mongoQuery autorelease];
}

- (void)cancelAllOperations
{
    for (MODBlockOperation *blockOperation in self.operationQueue.operations) {
        [blockOperation.mongoQuery cancel];
    }
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error
{
    [mongoQuery endsWithError:error];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock
{
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

- (MODQuery *)serverStatusWithReadPreferences:(MODReadPreferences *)readPreferences callback:(void (^)(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery){
        bson_t output = BSON_INITIALIZER;
        bson_error_t error = BSON_NO_ERROR;
        MODSortedMutableDictionary *outputObjects = nil;
        
        if (!mongoQuery.isCanceled) {
            mongoc_client_get_server_status(self.mongocClient, readPreferences?readPreferences.mongocReadPreferences:NULL, &output, &error);
            outputObjects = [self.class objectFromBson:&output];
        }
        [self mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(outputObjects, mongoQuery);
            }
        }];
        bson_destroy(&output);
    } owner:self name:@"serverstatus" parameters:nil];
    return query;
}

- (MODQuery *)databaseNamesWithCallback:(void (^)(NSArray *list, MODQuery *mongoQuery))callback;
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery) {
        bson_t output = BSON_INITIALIZER;
        NSMutableArray *list = nil;
        bson_error_t error = BSON_NO_ERROR;
        
        if (!mongoQuery.isCanceled) {
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
            if (!mongoQuery.isCanceled && callback) {
                callback(list, mongoQuery);
            }
        }];
        bson_destroy(&output);
        [list release];
    } owner:self name:@"databasenames" parameters:nil];
    return query;
}

- (MODDatabase *)databaseForName:(NSString *)databaseName
{
    MODDatabase *result;
    
    result = [[[MODDatabase alloc] initWithClient:self name:databaseName] autorelease];
    result.readPreferences = self.readPreferences;
    return result;
}

- (mongoc_read_prefs_t *)mongocReadPreferences
{
    return self.readPreferences.mongocReadPreferences;
}

- (MODReadPreferences *)readPreferences
{
    return [MODReadPreferences readPreferencesWithMongocReadPreferences:mongoc_client_get_read_prefs(self.mongocClient)];
}

- (void)setReadPreferences:(MODReadPreferences *)readPreferences
{
    mongoc_client_set_read_prefs(self.mongocClient, self.mongocReadPreferences);
}

- (MODSSLOptions *)sslOptions
{
    return [MODSSLOptions sslOptionsWithMongocSSLOpt:&self.mongocClient->ssl_opts];
}

- (void)setSslOptions:(MODSSLOptions *)sslOptions
{
    mongoc_ssl_opt_t mongocSSLOptions = { NULL, NULL, NULL, NULL, NULL, false };
    
    [sslOptions getMongocSSLOpt:&mongocSSLOptions];
    [_sslOptions release];
    _sslOptions = [sslOptions retain];
    mongoc_client_set_ssl_opts(self.mongocClient, &mongocSSLOptions);
}

- (MODWriteConcern *)writeConcern
{
    return [MODWriteConcern writeConcernWithMongocWriteConcern:mongoc_client_get_write_concern(self.mongocClient)];
}

- (void)setWriteConcern:(MODWriteConcern *)writeConcern
{
    mongoc_client_set_write_concern(self.mongocClient, writeConcern.mongocWriteConcern);
}

@end
