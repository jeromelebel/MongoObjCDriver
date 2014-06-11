//
//  MODDatabase.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@interface MODDatabase ()
@property (nonatomic, readwrite, strong) MODClient *client;
@property (nonatomic, readwrite, copy) NSString *name;

@end

@implementation MODDatabase

@synthesize client = _client, name = _name, mongocDatabase = _mongocDatabase;

- (id)initWithClient:(MODClient *)client name:(NSString *)name
{
    if (self = [self init]) {
        self.client = client;
        self.name = name;
        self.mongocDatabase = mongoc_client_get_database(client.mongocClient, self.name.UTF8String);
        
    }
    return self;
}

- (void)dealloc
{
    self.client = nil;
    if (self.mongocDatabase) {
        mongoc_database_destroy(self.mongocDatabase);
        self.mongocDatabase = nil;
    }
    [_systemIndexesCollection release];
    [super dealloc];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock
{
    [mongoQuery.mutableParameters setObject:self forKey:@"mongodatabase"];
    [self.client mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:callbackBlock];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock
{
    [mongoQuery.mutableParameters setObject:self forKey:@"mongodatabase"];
    [self.client mongoQueryDidFinish:mongoQuery withError:error callbackBlock:callbackBlock];
}

- (MODQuery *)statsWithCallback:(void (^)(MODSortedMutableDictionary *databaseStats, MODQuery *mongoQuery))callback;
{
    MODQuery *query;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery){
        MODSortedMutableDictionary *stats = nil;
        bson_error_t error = BSON_NO_ERROR;
        
        if (!mongoQuery.canceled) {
            bson_t cmd = BSON_INITIALIZER;
            bson_t output;
            
            bson_init (&cmd);
            BSON_APPEND_INT32(&cmd, "dbstats", 1);
            if (mongoc_database_command_simple(self.mongocDatabase, &cmd, self.mongocReadPreferences, &output, &error)) {
                stats = [[self.client class] objectFromBson:&output];
                [mongoQuery.mutableParameters setObject:stats forKey:@"databasestats"];
            }
            bson_destroy(&cmd);
            bson_destroy(&output);
        }
        [self mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (callback) {
                callback(stats, mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"fetchdatabasestats" forKey:@"command"];
    return query;
}

- (MODQuery *)fetchCollectionListWithCallback:(void (^)(NSArray *collectionList, MODQuery *mongoQuery))callback;
{
    MODQuery *query;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery){
        NSMutableArray *collections = nil;
        bson_error_t error = BSON_NO_ERROR;
        
        if (!mongoQuery.canceled) {
            char **cStringCollections;
            
            cStringCollections = mongoc_database_get_collection_names(self.mongocDatabase, &error);
            if (cStringCollections) {
                char **cursor = cStringCollections;
                
                collections = [[NSMutableArray alloc] init];
                while (*cursor != NULL) {
                    [collections addObject:[NSString stringWithUTF8String:*cursor]];
                    bson_free(*cursor);
                    cursor++;
                }
                bson_free(cStringCollections);
            }
        }
        [self mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (callback) {
                callback(collections, mongoQuery);
            }
        }];
        [collections release];
    }];
    [query.mutableParameters setObject:@"fetchcollectionlist" forKey:@"command"];
    return query;
}

- (MODCollection *)collectionForName:(NSString *)name
{
    return [[[MODCollection alloc] initWithName:name database:self] autorelease];
}

- (MODQuery *)createCollectionWithName:(NSString *)collectionName callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery){
        bson_error_t error = BSON_NO_ERROR;
        
        if (!mongoQuery.canceled) {
            mongoc_database_create_collection(self.mongocDatabase, collectionName.UTF8String, NULL, &error);
        }
        [self mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (callback) {
                callback(mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"createcollection" forKey:@"command"];
    [query.mutableParameters setObject:collectionName forKey:@"collectionname"];
    return query;
}

//- (MODQuery *)createCappedCollectionWithName:(NSString *)collectionName capSize:(int64_t)capSize callback:(void (^)(MODQuery *mongoQuery))callback
//{
//    MODQuery *query;
//    
//    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery){
//        if (!self.client.isMaster) {
//            mongoQuery.error = [MODClient errorWithErrorDomain:MODMongoErrorDomain code:MONGO_CONN_NOT_MASTER descriptionDetails:@"Collection add forbidden on a slave"];
//        } else if (!mongoQuery.canceled && [self.client authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
//            mongo_cmd_create_capped_collection(self.client.mongo, [_databaseName UTF8String], [collectionName UTF8String], capSize);
//        }
//        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
//            if (callback) {
//                callback(mongoQuery);
//            }
//        }];
//    }];
//    [query.mutableParameters setObject:@"createcappedcollection" forKey:@"command"];
//    [query.mutableParameters setObject:collectionName forKey:@"collectionname"];
//    [query.mutableParameters setObject:[NSNumber numberWithLongLong:capSize] forKey:@"capsize"];
//    return query;
//}

- (MODQuery *)dropWithCallback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        bson_error_t error = BSON_NO_ERROR;
        
        if (!mongoQuery.canceled) {
            mongoc_database_drop(self.mongocDatabase, &error);
        }
        [self mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (callback) {
                callback(mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"dropdatabase" forKey:@"command"];
    return query;
}

- (mongoc_client_t *)mongocClient
{
    return self.client.mongocClient;
}

- (MODCollection *)systemIndexesCollection
{
    if (!_systemIndexesCollection) {
        _systemIndexesCollection = [[self collectionForName:@"system.indexes"] retain];
    }
    return _systemIndexesCollection;
}

- (mongoc_read_prefs_t *)mongocReadPreferences
{
    return self.client.mongocReadPreferences;
}

@end
