//
//  MODDatabase.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 03/09/2011.
//

#import "MongoObjCDriver-private.h"

@interface MODDatabase ()
@property (nonatomic, strong, readwrite) MODClient *client;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) BOOL dropped;

@end

@implementation MODDatabase

@synthesize client = _client;
@synthesize name = _name;
@synthesize mongocDatabase = _mongocDatabase;
@synthesize readPreferences = _readPreferences;
@synthesize dropped = _dropped;

- (instancetype)initWithClient:(MODClient *)client name:(NSString *)name
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
    self.name = nil;
    self.readPreferences = nil;
    if (self.mongocDatabase) {
        mongoc_database_destroy(self.mongocDatabase);
        self.mongocDatabase = nil;
    }
    MOD_RELEASE(_systemIndexesCollection);
    MOD_SUPER_DEALLOC();
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock
{
    [self.client mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:callbackBlock];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock
{
    [self.client mongoQueryDidFinish:mongoQuery withError:error callbackBlock:callbackBlock];
}

- (MODQuery *)statsWithReadPreferences:(MODReadPreferences *)readPreferences callback:(void (^)(MODSortedDictionary *databaseStats, MODQuery *mongoQuery))callback;
{
    MODQuery *query;
    MODDatabase *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery){
        MODSortedDictionary *stats = nil;
        bson_error_t error = BSON_NO_ERROR;
        
        if (!mongoQuery.isCanceled) {
            bson_t cmd = BSON_INITIALIZER;
            bson_t output;
            
            bson_init (&cmd);
            BSON_APPEND_INT32(&cmd, "dbstats", 1);
            if (mongoc_database_command_simple(currentSelf.mongocDatabase, &cmd, readPreferences?readPreferences.mongocReadPreferences:NULL, &output, &error)) {
                stats = [[currentSelf.client class] objectFromBson:&output];
            }
            bson_destroy(&cmd);
            bson_destroy(&output);
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(stats, mongoQuery);
            }
        }];
    } owner:self name:@"databasestats" parameters:nil];
    return query;
}

- (MODQuery *)collectionNamesWithCallback:(void (^)(NSArray *collectionList, MODQuery *mongoQuery))callback;
{
    MODQuery *query;
    MODDatabase *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery){
        NSMutableArray *collections = nil;
        bson_error_t error = BSON_NO_ERROR;
        
        if (!mongoQuery.isCanceled) {
            char **cStringCollections;
            
            cStringCollections = mongoc_database_get_collection_names(currentSelf.mongocDatabase, &error);
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
        [currentSelf mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(collections, mongoQuery);
            }
        }];
        MOD_RELEASE(collections);
    } owner:self name:@"collectionnames" parameters:nil];
    return query;
}

- (MODCollection *)collectionForName:(NSString *)name
{
    MODCollection *result;
    
    result = MOD_AUTORELEASE([[MODCollection alloc] initWithName:name database:self]);
    result.readPreferences = self.readPreferences;
    return result;
}

- (MODQuery *)createCollectionWithName:(NSString *)collectionName callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    MODDatabase *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery){
        bson_error_t error = BSON_NO_ERROR;
        
        if (!mongoQuery.isCanceled) {
            mongoc_database_create_collection(currentSelf.mongocDatabase, collectionName.UTF8String, NULL, &error);
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(mongoQuery);
            }
        }];
    } owner:self name:@"createcollection" parameters:@{ @"name": collectionName }];
    return query;
}

//- (MODQuery *)createCappedCollectionWithName:(NSString *)collectionName capSize:(int64_t)capSize callback:(void (^)(MODQuery *mongoQuery))callback
//{
//    MODQuery *query;
//    
//    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery){
//        if (!self.client.isMaster) {
//            mongoQuery.error = [MODClient errorWithErrorDomain:MODMongoErrorDomain code:MONGO_CONN_NOT_MASTER descriptionDetails:@"Collection add forbidden on a slave"];
//        } else if (!mongoQuery.isCanceled && [self.client authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
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
    MODDatabase *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        bson_error_t error = BSON_NO_ERROR;
        BOOL droppedCalled = NO;
        
        if (!mongoQuery.isCanceled) {
            mongoc_database_drop(currentSelf.mongocDatabase, &error);
            droppedCalled = YES;
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (droppedCalled) {
                if (callback) {
                    callback(mongoQuery);
                }
                if (!mongoQuery.error) {
                    currentSelf.dropped = YES;
                    [NSNotificationCenter.defaultCenter postNotificationName:MODDatabase_Dropped_Notification object:currentSelf];
                }
            }
        }];
    } owner:self name:@"dropdatabase" parameters:@{ @"name": self.name }];
    return query;
}

- (mongoc_client_t *)mongocClient
{
    return self.client.mongocClient;
}

- (MODCollection *)systemIndexesCollection
{
    if (!_systemIndexesCollection) {
        _systemIndexesCollection = MOD_RETAIN([self collectionForName:@"system.indexes"]);
    }
    return _systemIndexesCollection;
}

- (mongoc_read_prefs_t *)mongocReadPreferences
{
    return self.readPreferences.mongocReadPreferences;
}

- (void)setReadPreferences:(MODReadPreferences *)readPreferences
{
    MOD_RELEASE(_readPreferences);
    _readPreferences = MOD_RETAIN(readPreferences);
    if (self.mongocDatabase) {
        mongoc_database_set_read_prefs(self.mongocDatabase, self.mongocReadPreferences);
    }
    
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: name %@, %p>", self.className, self.name, self];
}

@end
