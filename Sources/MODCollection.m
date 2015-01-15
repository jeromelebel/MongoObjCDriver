//
//  MODCollection.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 03/09/2011.
//

#import "MongoObjCDriver-private.h"

@interface MODCollection ()
@property (nonatomic, strong, readwrite) MODDatabase *database;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *absoluteName;
@property (nonatomic, assign, readwrite) BOOL dropped;

- (bool)_commandSimpleWithCommand:(MODSortedDictionary *)command readPreferences:(MODReadPreferences *)readPreferences reply:(MODSortedDictionary **)reply error:(NSError **)error;

@end

static mongoc_query_flags_t mongocQueryFlagsFromMODQueryFlags(MODQueryFlags flags)
{
    switch(flags) {
        case MODQueryFlagsNone:
            return MONGOC_QUERY_NONE;
        case MODQueryFlagsTailableCursor:
            return MONGOC_QUERY_TAILABLE_CURSOR;
        case MODQueryFlagsSlaveOk:
            return MONGOC_QUERY_SLAVE_OK;
        case MODQueryFlagsOplogReplay:
            return MONGOC_QUERY_OPLOG_REPLAY;
        case MODQueryFlagsNoCursorTimeout:
            return MONGOC_QUERY_NO_CURSOR_TIMEOUT;
        case MODQueryFlagsAwaitData:
            return MONGOC_QUERY_AWAIT_DATA;
        case MODQueryFlagsExhaust:
            return MONGOC_QUERY_EXHAUST;
        case MODQueryFlagsPartial:
            return MONGOC_QUERY_PARTIAL;
        default:
            NSLog(@"unknow value %d", flags);
            assert(NO);
            return MONGOC_QUERY_NONE;
    }
}

@implementation MODCollection

@synthesize absoluteName = _absoluteName;
@synthesize mongocCollection = _mongocCollection;
@synthesize readPreferences = _readPreferences;
@synthesize dropped = _dropped;

- (instancetype)initWithName:(NSString *)name database:(MODDatabase *)database
{
    if (self = [self init]) {
        self.database = database;
        self.name = name;
        self.mongocCollection = mongoc_database_get_collection(self.database.mongocDatabase, name.UTF8String);
    }
    return self;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self name:nil object:nil];
    if (self.mongocCollection) {
        mongoc_collection_destroy(self.mongocCollection);
        self.mongocCollection = nil;
    }
    self.absoluteName = nil;
    self.readPreferences = nil;
    MOD_RELEASE(_database);
    MOD_RELEASE(_name);
    MOD_SUPER_DEALLOC();
}

- (void)updateAbsoluteName
{
    self.absoluteName = [NSString stringWithFormat:@"%@.%@", self.database.name, self.name];
}

- (void)setDatabase:(MODDatabase *)database
{
    if (database != _database) {
        [self willChangeValueForKey:@"database"];
        MOD_RELEASE(_database);
        _database = MOD_RETAIN(database);
        [self updateAbsoluteName];
        [self didChangeValueForKey:@"database"];
    }
}

- (MODDatabase *)database
{
    return _database;
}

- (void)setDropped:(BOOL)dropped
{
    if (_dropped != dropped) {
        [self willChangeValueForKey:@"dropped"];
        _dropped = dropped;
        [self didChangeValueForKey:@"dropped"];
    }
}

- (BOOL)dropped
{
    return _dropped || self.database.dropped;
}

- (void)setName:(NSString *)name
{
    if (name != _name) {
        [self willChangeValueForKey:@"name"];
        MOD_RELEASE(_name);
        _name = MOD_RETAIN(name);
        [self updateAbsoluteName];
        [self didChangeValueForKey:@"name"];
    }
}

- (NSString *)name
{
    return _name;
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock
{
    [self.database mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:callbackBlock];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock
{
    [self.database mongoQueryDidFinish:mongoQuery withError:error callbackBlock:callbackBlock];
}

- (MODQuery *)renameWithNewDatabase:(MODDatabase *)newDatabase newCollectionName:(NSString *)newCollectionName dropTargetBeforeRenaming:(BOOL)dropTargetBeforeRenaming callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    MODCollection *currentSelf = self;
    
    NSParameterAssert(newCollectionName);
    if (newDatabase == self.database) {
        newDatabase = nil;
    }
    if (newDatabase) {
        parameters[@"newdatabase"] = newDatabase.name;
        NSParameterAssert(newDatabase.client == self.client);
    }
    parameters[@"newcollectionname"] = newCollectionName;
    parameters[@"droptargetbeforerenaming"] = @(dropTargetBeforeRenaming);
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        bson_error_t error = BSON_NO_ERROR;
        BOOL renameCalled = NO;
        
        if (!mongoQuery.isCanceled) {
            mongoc_collection_rename(currentSelf.mongocCollection, newDatabase.name.UTF8String, newCollectionName.UTF8String, dropTargetBeforeRenaming, &error);
            renameCalled = YES;
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^{
            if (renameCalled) {
                if (!mongoQuery.error) {
                    currentSelf.name = newCollectionName;
                    if (newDatabase) {
                        currentSelf.database = newDatabase;
                    }
                    currentSelf.absoluteName = [NSString stringWithFormat:@"%@.%@", currentSelf.database.name, currentSelf.name];
                }
                if (callback) {
                    callback(mongoQuery);
                }
            }
        }];
    } owner:self name:@"rename" parameters:parameters];
    return query;
}

- (MODQuery *)statsWithCallback:(void (^)(MODSortedDictionary *stats, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    MODCollection *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        MODSortedDictionary *stats = nil;
        bson_error_t error = BSON_NO_ERROR;
        
        if (!mongoQuery.isCanceled) {
            bson_t output = BSON_INITIALIZER;
            
            if (mongoc_collection_stats(currentSelf.mongocCollection, NULL, &output, &error)) {
                stats = [[currentSelf.client class] objectFromBson:&output];
            }
            bson_destroy(&output);
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(stats, mongoQuery);
            }
        }];
    } owner:self name:@"collectionstats" parameters:nil];
    return query;
}

- (MODQuery *)findWithCriteria:(MODSortedDictionary *)criteria
                        fields:(MODSortedDictionary *)fields
                          skip:(int32_t)skip
                         limit:(int32_t)limit
                          sort:(MODSortedDictionary *)sort
                      callback:(void (^)(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    MODCollection *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        NSMutableArray *documents = nil;
        NSMutableArray *allBsonData = nil;
        
        if (!mongoQuery.isCanceled) {
            NSData *bsonData;
            MODCursor *cursor;
            MODSortedDictionary *document;
            
            documents = [[NSMutableArray alloc] initWithCapacity:limit];
            allBsonData = [[NSMutableArray alloc] initWithCapacity:limit];
            cursor = [currentSelf cursorWithCriteria:criteria fields:fields skip:skip limit:limit sort:sort];
            while ((document = [cursor nextDocumentWithBsonData:&bsonData error:&error]) != nil) {
                [documents addObject:document];
                [allBsonData addObject:bsonData];
            }
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(documents, allBsonData, mongoQuery);
            }
        }];
        MOD_RELEASE(documents);
        MOD_RELEASE(allBsonData);
    } owner:self name:@"find" parameters:@{ @"criteria": criteria?criteria:[NSNull null], @"fields": fields?fields:[NSNull null], @"skip": [NSNumber numberWithUnsignedInteger:skip], @"limit": [NSNumber numberWithUnsignedInteger:limit], @"sort": sort?sort:[NSNull null] }];
    return query;
}

- (MODCursor *)cursorWithCriteria:(MODSortedDictionary *)query
                           fields:(MODSortedDictionary *)fields
                             skip:(int32_t)skip
                            limit:(int32_t)limit
                             sort:(MODSortedDictionary *)sort
{
    return MOD_AUTORELEASE([[MODCursor alloc] initWithCollection:self
                                                           query:query
                                                          fields:fields
                                                            skip:skip
                                                           limit:limit
                                                            sort:sort]);
}

- (MODQuery *)countWithCriteria:(MODSortedDictionary *)criteria readPreferences:(MODReadPreferences *)readPreferences callback:(void (^)(int64_t count, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    MODCollection *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        int64_t count = 0;
        NSError *error = nil;
        
        if (!mongoQuery.isCanceled) {
            bson_t bsonQuery = BSON_INITIALIZER;
            
            if (criteria && criteria.count > 0) {
                [currentSelf.client.class appendObject:criteria toBson:&bsonQuery];
            }
            
            if (error) {
                mongoQuery.error = error;
            } else {
                bson_error_t bsonError;
                
                count = mongoc_collection_count(currentSelf.mongocCollection, 0, &bsonQuery, 0, 0, readPreferences?readPreferences.mongocReadPreferences:NULL, &bsonError);
                if (count == -1) {
                    error = [currentSelf.client.class errorFromBsonError:bsonError];
                }
            }
            bson_destroy(&bsonQuery);
        }
        mongoQuery.result = [[NSNumber alloc] initWithUnsignedLongLong:count];
        [currentSelf mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(count, mongoQuery);
            }
        }];
    } owner:self name:@"count" parameters:@{ @"criteria": criteria?criteria:[NSNull null] }];
    return query;
}

- (MODQuery *)insertWithDocuments:(NSArray *)documents
                     writeConcern:(MODWriteConcern *)writeConcern
                         callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    MODCollection *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.isCanceled) {
            NSInteger ii = 0;
            mongoc_bulk_operation_t *bulk;
            
            bulk = mongoc_collection_create_bulk_operation(currentSelf.mongocCollection, false, NULL);
            for (id document in documents) {
                bson_t bson = BSON_INITIALIZER;
                
                if ([document isKindOfClass:[NSString class]]) {
                    [MODRagelJsonParser bsonFromJson:&bson json:document error:&error];
                    if (error) {
                        NSMutableDictionary *userInfo;
                        
                        userInfo = error.userInfo.mutableCopy;
                        [userInfo setObject:[NSNumber numberWithInteger:ii] forKey:@"documentIndex"];
                        error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
                        MOD_RELEASE(userInfo);
                    }
                } else if ([document isKindOfClass:[MODSortedDictionary class]]) {
                    [[currentSelf.client class] appendObject:document toBson:&bson];
                }
                if (error) {
                    break;
                }
                mongoc_bulk_operation_insert(bulk, &bson);
                ii++;
                if (ii >= 50) {
                    bson_error_t bsonError;
                    
                    ii = 0;
                    mongoc_bulk_operation_execute(bulk, NULL, &bsonError);
                    error = [currentSelf.client.class errorFromBsonError:bsonError];
                    if (error) {
                        break;
                    }
                    mongoc_bulk_operation_destroy(bulk);
                    bulk = mongoc_collection_create_bulk_operation(currentSelf.mongocCollection, false, writeConcern.mongocWriteConcern);
                }
            }
            if (!error && ii > 0) {
                bson_error_t bsonError = BSON_NO_ERROR;
                
                mongoc_bulk_operation_execute(bulk, NULL, &bsonError);
                error = [currentSelf.client.class errorFromBsonError:bsonError];
            }
            mongoc_bulk_operation_destroy(bulk);
            mongoQuery.error = error;
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(mongoQuery);
            }
        }];
    } owner:self name:@"insert" parameters:@{ @"documents": documents }];
    return query;
}

- (MODQuery *)updateWithCriteria:(MODSortedDictionary *)criteria
                          update:(MODSortedDictionary *)update
                          upsert:(BOOL)upsert
                     multiUpdate:(BOOL)multiUpdate
                    writeConcern:(MODWriteConcern *)writeConcern
                        callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    MODCollection *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.isCanceled) {
            bson_t bsonCriteria = BSON_INITIALIZER;
            bson_t bsonUpdate = BSON_INITIALIZER;
            
            if (criteria && criteria.count > 0) {
                [currentSelf.client.class appendObject:criteria toBson:&bsonCriteria];
            }
            if (update && update.count > 0) {
                [currentSelf.client.class appendObject:update toBson:&bsonUpdate];
            }
            if (error == nil) {
                bson_error_t bsonError = BSON_NO_ERROR;
                
                if (!mongoc_collection_update(currentSelf.mongocCollection, (upsert?MONGOC_UPDATE_UPSERT:0) | (multiUpdate?MONGOC_UPDATE_MULTI_UPDATE:0), &bsonCriteria, &bsonUpdate, writeConcern.mongocWriteConcern, &bsonError)) {
                    error = [currentSelf.client.class errorFromBsonError:bsonError];
                    mongoQuery.error = error;
                }
            } else {
                mongoQuery.error = error;
            }
            bson_destroy(&bsonCriteria);
            bson_destroy(&bsonUpdate);
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(mongoQuery);
            }
        }];
    } owner:self name:@"update" parameters:@{ @"criteria": criteria?criteria:[NSNull null], @"update": update?update:[NSNull null], @"upsert":[NSNumber numberWithBool:upsert], @"multiupdate": [NSNumber numberWithBool:multiUpdate] }];
    return query;
}

- (MODQuery *)saveWithDocument:(MODSortedDictionary *)document callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    MODCollection *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.isCanceled) {
            bson_t bsonDocument = BSON_INITIALIZER;
            bson_error_t bsonError = BSON_NO_ERROR;
            
            [currentSelf.client.class appendObject:document toBson:&bsonDocument];
            if (!mongoc_collection_save(currentSelf.mongocCollection, &bsonDocument, NULL, &bsonError)) {
                error = [currentSelf.client.class errorFromBsonError:bsonError];
                mongoQuery.error = error;
            }
            bson_destroy(&bsonDocument);
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(mongoQuery);
            }
        }];
    } owner:self name:@"savedocument" parameters:@{ @"document": document }];
    return query;
}

- (MODQuery *)removeWithCriteria:(id)criteria callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    MODCollection *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.isCanceled) {
            bson_t bsonCriteria = BSON_INITIALIZER;
            
            if (criteria == nil) {
                // nothing to do
            } else if ([criteria isKindOfClass:[NSString class]]) {
                if ([criteria length] > 0) {
                    [MODRagelJsonParser bsonFromJson:&bsonCriteria json:criteria error:&error];
                }
            } else if ([criteria isKindOfClass:[MODSortedDictionary class]]) {
                [[currentSelf.client class] appendObject:criteria toBson:&bsonCriteria];
            } else {
                error = [currentSelf.client.class errorWithErrorDomain:MODJsonParserErrorDomain code:JSON_PARSER_ERROR_EXPECTED_END descriptionDetails:nil];
            }
            if (error == nil) {
                bson_error_t bsonError = BSON_NO_ERROR;
                
                if (!mongoc_collection_remove(currentSelf.mongocCollection, MONGOC_DELETE_NONE, &bsonCriteria, NULL, &bsonError)) {
                    error = [currentSelf.client.class errorFromBsonError:bsonError];
                    mongoQuery.error = error;
                }
            } else {
                mongoQuery.error = error;
            }
            bson_destroy(&bsonCriteria);
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(mongoQuery);
            }
        }];
    } owner:self name:@"remove" parameters:@{ @"criteria": criteria?criteria:[NSNull null] }];
    return query;
}

- (MODQuery *)indexListWithCallback:(void (^)(NSArray *documents, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    MODSortedDictionary *dictionary;
    
    dictionary = [[MODSortedDictionary alloc] initWithObjectsAndKeys:self.absoluteName, @"ns", nil];
    query = [self.database.systemIndexesCollection findWithCriteria:dictionary
                                                             fields:nil
                                                               skip:0
                                                              limit:0
                                                               sort:nil
                                                           callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        callback(documents, mongoQuery);
    }];
    MOD_RELEASE(dictionary);
    return query;
}

- (MODQuery *)createIndexWithKeys:(id)keys indexOptions:(MODIndexOpt *)indexOptions callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    // Just in case the index options are changed before we add the index
    // we need to make a copy of it
    MODIndexOpt *indexOptionsCopy = [indexOptions copy];
    MODCollection *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.isCanceled) {
            bson_t index = BSON_INITIALIZER;
            bson_error_t bsonError = BSON_NO_ERROR;
            
            if ([keys isKindOfClass:[NSString class]]) {
                [MODRagelJsonParser bsonFromJson:&index json:keys error:&error];
            } else {
                [[currentSelf.client class] appendObject:keys toBson:&index];
            }
            if (!error) {
                mongoc_collection_create_index(currentSelf.mongocCollection, &index, indexOptionsCopy.mongocIndexOpt, &bsonError);
                error = [currentSelf.client.class errorFromBsonError:bsonError];
            }
            bson_destroy(&index);
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(mongoQuery);
            }
        }];
    } owner:self name:@"createindex" parameters:@{ @"keys": keys, @"options": indexOptionsCopy }];
    return query;
}

- (MODQuery *)dropIndexName:(NSString *)name callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    MODCollection *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;

        if (!mongoQuery.isCanceled) {
            bson_error_t bsonError = BSON_NO_ERROR;
            
            mongoc_collection_drop_index(currentSelf.mongocCollection, name.UTF8String, &bsonError);
            error = [currentSelf.client.class errorFromBsonError:bsonError];
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(mongoQuery);
            }
        }];
    } owner:self name:@"dropindex" parameters:@{ @"index": name }];
    return query;
}

- (MODQuery *)aggregateWithFlags:(MODQueryFlags)flags
                        pipeline:(NSArray *)pipeline
                         options:(MODSortedDictionary *)options
                 readPreferences:(MODReadPreferences *)readPreferences
                        callback:(void (^)(MODQuery *mongoQuery, MODCursor *cursor))callback
{
    MODQuery *query = nil;
    MODCollection *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        MODCursor *cursor = nil;
        bson_error_t bsonError = BSON_NO_ERROR;

        if (!mongoQuery.isCanceled) {
            bson_t bsonPipeline = BSON_INITIALIZER;
            bson_t bsonOptions = BSON_INITIALIZER;
            mongoc_cursor_t *mongocCursor = nil;
            
            if (pipeline) [currentSelf.client.class appendArray:pipeline toBson:&bsonPipeline];
            if (options) [currentSelf.client.class appendObject:options toBson:&bsonOptions];
            mongocCursor = mongoc_collection_aggregate(currentSelf.mongocCollection, mongocQueryFlagsFromMODQueryFlags(flags), &bsonPipeline, &bsonOptions, readPreferences?readPreferences.mongocReadPreferences:NULL);
            cursor = MOD_AUTORELEASE([[MODCursor alloc] initWithCollection:currentSelf mongocCursor:mongocCursor]);
            bson_destroy(&bsonPipeline);
            bson_destroy(&bsonOptions);
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withBsonError:bsonError callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(mongoQuery, cursor);
            }
        }];
    } owner:self name:@"aggregate" parameters:@{ @"flags": @(flags), @"pipeline": pipeline?pipeline:[NSNull null], @"options": options?options:[NSNull null], @"readPreferences": readPreferences?readPreferences:[NSNull null] }];
    return query;
}

- (bool)_commandSimpleWithCommand:(MODSortedDictionary *)command readPreferences:(MODReadPreferences *)readPreferences reply:(MODSortedDictionary **)reply error:(NSError **)error
{
    bson_t bsonCommand = BSON_INITIALIZER;
    bson_t bsonReply = BSON_INITIALIZER;
    bson_error_t bsonError = BSON_NO_ERROR;
    bool result;
    
    [self.client.class appendObject:command toBson:&bsonCommand];
    result = mongoc_collection_command_simple(self.mongocCollection, &bsonCommand, readPreferences?readPreferences.mongocReadPreferences:NULL, &bsonReply, &bsonError);
    if (reply) *reply = [self.client.class objectFromBson:&bsonReply];
    if (error) *error = [self.client.class errorFromBsonError:bsonError];
    return result;
}

- (MODQuery *)commandSimpleWithCommand:(MODSortedDictionary *)command readPreferences:(MODReadPreferences *)readPreferences callback:(void (^)(MODQuery *query, MODSortedDictionary *reply))callback
{
    MODQuery *mongoQuery = nil;
    MODCollection *currentSelf = self;
    
    mongoQuery = [self.client addQueryInQueue:^(MODQuery *currentMongoQuery) {
        MODSortedDictionary *reply = nil;
        NSError *error = nil;
        
        if (!currentMongoQuery.isCanceled) {
            [currentSelf _commandSimpleWithCommand:command readPreferences:readPreferences reply:&reply error:&error];
        }
        [currentSelf mongoQueryDidFinish:currentMongoQuery withError:error callbackBlock:^(void) {
            if (!currentMongoQuery.isCanceled && callback) {
                callback(currentMongoQuery, reply);
            }
        }];
    } owner:self name:@"simplecommand" parameters:@{ @"command": command }];
    return mongoQuery;
}

- (MODQuery *)mapReduceWithMapFunction:(NSString *)mapFunction
                        reduceFunction:(NSString *)reduceFunction
                                 query:(MODSortedDictionary *)query
                                  sort:(MODSortedDictionary *)sort
                                 limit:(int64_t)limit
                                output:(MODSortedDictionary *)output
                              keepTemp:(BOOL)keepTemp
                      finalizeFunction:(NSString *)finalizeFunction
                                 scope:(MODSortedDictionary *)scope
                                jsmode:(BOOL)jsmode
                               verbose:(BOOL)verbose
                       readPreferences:(MODReadPreferences *)readPreferences
                              callback:(void (^)(MODQuery *mongoQuery, MODSortedDictionary *documents))callback
{
    MODQuery *mongoQuery = nil;
    MODCollection *currentSelf = self;
    
    mongoQuery = [self.client addQueryInQueue:^(MODQuery *currentMongoQuery) {
        NSError *error = nil;
        MODSortedDictionary *reply = nil;
        
        if (!currentMongoQuery.isCanceled) {
            MODSortedMutableDictionary *command;
            
            command = [MODSortedMutableDictionary sortedDictionary];
            [command setObject:currentSelf.name forKey:@"mapreduce"];
            [command setObject:mapFunction forKey:@"map"];
            [command setObject:reduceFunction forKey:@"reduce"];
            if (query && query.count > 0) [command setObject:query forKey:@"query"];
            if (sort && sort.count > 0) [command setObject:sort forKey:@"sort"];
            if (limit > 0) [command setObject:[NSNumber numberWithLongLong:limit] forKey:@"limit"];
            if (output && output.count > 0) [command setObject:output forKey:@"out"];
            if (finalizeFunction && finalizeFunction.length > 0) [command setObject:finalizeFunction forKey:@"finalize"];
            if (scope && scope.count > 0) [command setObject:scope forKey:@"scope"];

            [command setObject:[NSNumber numberWithBool:keepTemp] forKey:@"keeptemp"];
            [command setObject:[NSNumber numberWithBool:jsmode] forKey:@"jsmode"];
            [command setObject:[NSNumber numberWithBool:verbose] forKey:@"verbose"];

            [currentSelf _commandSimpleWithCommand:command readPreferences:readPreferences reply:&reply error:&error];
        }
        [currentSelf mongoQueryDidFinish:currentMongoQuery withError:error callbackBlock:^(void) {
            if (!currentMongoQuery.isCanceled && callback) {
                callback(currentMongoQuery, reply);
            }
        }];
    } owner:self name:@"mapreduce" parameters:nil];
    return mongoQuery;
}

- (MODQuery *)dropWithCallback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query;
    MODCollection *currentSelf = self;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        bson_error_t error = BSON_NO_ERROR;
        BOOL droppedCalled = NO;
        
        if (!mongoQuery.isCanceled) {
            mongoc_collection_drop(currentSelf.mongocCollection, &error);
            droppedCalled = YES;
        }
        [currentSelf mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (droppedCalled) {
                if (callback) {
                    callback(mongoQuery);
                }
                if (!mongoQuery.error) {
                    currentSelf.dropped = YES;
                    [NSNotificationCenter.defaultCenter postNotificationName:MODCollection_Dropped_Notification object:currentSelf];
                }
            }
        }];
    } owner:self name:@"dropcollection" parameters:@{ @"name": self.absoluteName }];
    return query;
}

- (mongoc_client_t *)mongocClient
{
    return self.database.mongocClient;
}

- (MODClient *)client
{
    return self.database.client;
}

- (NSString *)databaseName
{
    return self.database.name;
}

- (mongoc_read_prefs_t *)mongocReadPreferences
{
    return self.readPreferences.mongocReadPreferences;
}

- (void)setReadPreferences:(MODReadPreferences *)readPreferences
{
    MOD_RELEASE(_readPreferences);
    _readPreferences = MOD_RETAIN(readPreferences);
    if (self.mongocCollection) {
        mongoc_collection_set_read_prefs(self.mongocCollection, self.mongocReadPreferences);
    }
    
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: name %@, %p>", self.className, self.absoluteName, self];
}

@end
