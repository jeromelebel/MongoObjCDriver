//
//  MODCollection.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@interface MODCollection ()
@property (nonatomic, readwrite, retain) MODDatabase *mongoDatabase;
@property (nonatomic, readwrite, retain) NSString *name;
@property (nonatomic, readwrite, retain) NSString *absoluteName;

@end

@implementation MODCollection

@synthesize mongoDatabase = _mongoDatabase, name = _name, absoluteName = _absoluteName, mongocCollection = _mongocCollection;

- (id)initWithName:(NSString *)name mongoDatabase:(MODDatabase *)mongoDatabase
{
    if (self = [self init]) {
        self.mongoDatabase = mongoDatabase;
        self.name = [name retain];
        self.absoluteName = [[[NSString alloc] initWithFormat:@"%@.%@", self.mongoDatabase.name, self.name] autorelease];
        self.mongocCollection = mongoc_database_get_collection(self.mongoDatabase.mongocDatabase, name.UTF8String);
    }
    return self;
}

- (void)dealloc
{
    self.mongoDatabase = nil;
    self.name = nil;
    self.absoluteName = nil;
    [super dealloc];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock
{
    [mongoQuery.mutableParameters setObject:self forKey:@"collection"];
    [self.mongoDatabase mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:callbackBlock];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock
{
    [mongoQuery.mutableParameters setObject:self forKey:@"collection"];
    [self.mongoDatabase mongoQueryDidFinish:mongoQuery withError:error callbackBlock:callbackBlock];
}

- (MODQuery *)fetchCollectionStatsWithCallback:(void (^)(MODSortedMutableDictionary *stats, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        MODSortedMutableDictionary *stats = nil;
        bson_error_t error;
        
        if (!mongoQuery.canceled) {
            bson_t output = BSON_INITIALIZER;
            bson_t cmd = BSON_INITIALIZER;
            
            BSON_APPEND_INT32 (&cmd, "collstats", 1);
            if (mongoc_client_command_simple(self.mongocClient, self.absoluteName.UTF8String, &cmd, NULL, &output, &error)) {
                stats = [[self.mongoServer class] objectFromBson:&output];
                [mongoQuery.mutableParameters setObject:stats forKey:@"collectionstats"];
            }
            bson_destroy(&output);
            bson_destroy(&cmd);
        }
        [self mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (callback) {
                callback(stats, mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"databasestats" forKey:@"command"];
    return query;
}
//
//- (MODQuery *)indexListWithCallback:(void (^)(NSArray *documents, MODQuery *mongoQuery))callback
//{
//    MODQuery *query = nil;
//    
//    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        if (!mongoQuery.canceled) {
//            NSMutableArray *documents;
//            MODCursor *cursor;
//            MODSortedMutableDictionary *document;
//            NSError *error = nil;
//            
//            documents = [[NSMutableArray alloc] init];
//            cursor = [[MODCursor alloc] initWithMongoCollection:self];
//            cursor.cursor = mongo_index_list(self.mongocClient, self.absoluteName.UTF8String, 0, 0);
//            while ((document = [cursor nextDocumentWithBsonData:nil error:&error]) != nil) {
//                [documents addObject:document];
//            }
//            if (error) {
//                mongoQuery.error = error;
//            }
//            [mongoQuery.mutableParameters setObject:documents forKey:@"documents"];
//            [documents release];
//            [cursor release];
//        }
//        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
//            callback([mongoQuery.mutableParameters objectForKey:@"documents"], mongoQuery);
//        }];
//    }];
//    [query.mutableParameters setObject:@"indexlist" forKey:@"command"];
//    return query;
//}

- (MODQuery *)findWithCriteria:(NSString *)jsonCriteria fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(NSString *)sort callback:(void (^)(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            NSMutableArray *documents;
            NSMutableArray *allBsonData;
            NSData *bsonData;
            MODCursor *cursor;
            MODSortedMutableDictionary *document;
            
            documents = [[NSMutableArray alloc] initWithCapacity:limit];
            allBsonData = [[NSMutableArray alloc] initWithCapacity:limit];
            cursor = [self cursorWithCriteria:jsonCriteria fields:fields skip:skip limit:limit sort:sort];
            while ((document = [cursor nextDocumentWithBsonData:&bsonData error:&error]) != nil) {
                [documents addObject:document];
                [allBsonData addObject:bsonData];
            }
            [mongoQuery.mutableParameters setObject:documents forKey:@"documents"];
            [mongoQuery.mutableParameters setObject:allBsonData forKey:@"dataDocuments"];
            [documents release];
            [allBsonData release];
        }
        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (callback) {
                callback([mongoQuery.mutableParameters objectForKey:@"documents"], [mongoQuery.mutableParameters objectForKey:@"dataDocuments"], mongoQuery);
            }
        }];
    }];
    if (jsonCriteria) {
        [query.mutableParameters setObject:jsonCriteria forKey:@"criteria"];
    }
    if (fields) {
        [query.mutableParameters setObject:fields forKey:@"fields"];
    }
    [query.mutableParameters setObject:@"finddocuments" forKey:@"command"];
    [query.mutableParameters setObject:[NSNumber numberWithUnsignedInteger:skip] forKey:@"skip"];
    [query.mutableParameters setObject:[NSNumber numberWithUnsignedInteger:limit] forKey:@"limit"];
    if (sort) {
        [query.mutableParameters setObject:sort forKey:@"sort"];
    }
    return query;
}

- (MODCursor *)cursorWithCriteria:(NSString *)query fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(NSString *)sort
{
    return [[[MODCursor alloc] initWithMongoCollection:self query:query fields:fields skip:skip limit:limit sort:sort] autorelease];
}

- (MODQuery *)countWithCriteria:(NSString *)jsonCriteria callback:(void (^)(int64_t count, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        int64_t count = 0;
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            bson_t *bsonQuery = NULL;
            
            bsonQuery = bson_new();
            bson_init(bsonQuery);
            if (jsonCriteria && [jsonCriteria length] > 0) {
                [MODRagelJsonParser bsonFromJson:bsonQuery json:jsonCriteria error:&error];
            }
            
            if (error) {
                mongoQuery.error = error;
            } else {
                NSNumber *response;
                bson_error_t bsonError;
                
                count = mongoc_collection_count(self.mongocCollection, 0, bsonQuery, 0, 0, NULL, &bsonError);
                if (count == -1) {
                    error = [self.mongoServer.class errorFromBsonError:bsonError];
                } else {
                    response = [[NSNumber alloc] initWithUnsignedLongLong:count];
                    [mongoQuery.mutableParameters setObject:response forKey:@"count"];
                    [response release];
                }
            }
            bson_destroy(bsonQuery);
        }
        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (callback) {
                callback(count, mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"countdocuments" forKey:@"command"];
    if (jsonCriteria) {
        [query.mutableParameters setObject:jsonCriteria forKey:@"criteria"];
    }
    return query;
}

- (MODQuery *)insertWithDocuments:(NSArray *)documents callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            NSInteger ii = 0;
            mongoc_bulk_operation_t *bulk;
            
            bulk = mongoc_collection_create_bulk_operation(self.mongocCollection, false, NULL);
            for (id document in documents) {
                bson_t bson = BSON_INITIALIZER;
                
                if ([document isKindOfClass:[NSString class]]) {
                    [MODRagelJsonParser bsonFromJson:&bson json:document error:&error];
                    if (error) {
                        NSMutableDictionary *userInfo;
                        
                        userInfo = error.userInfo.mutableCopy;
                        [userInfo setObject:[NSNumber numberWithInteger:ii] forKey:@"documentIndex"];
                        error = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
                        [userInfo release];
                    }
                } else if ([document isKindOfClass:[MODSortedMutableDictionary class]]) {
                    [[self.mongoServer class] appendObject:document toBson:&bson];
                }
                if (error) {
                    break;
                }
                mongoc_bulk_operation_insert(bulk, &bson);
                ii++;
                if (ii >= 50) {
                    bson_error_t bsonError;
                    
                    mongoc_bulk_operation_execute(bulk, NULL, &bsonError);
                    error = [self.mongoServer.class errorFromBsonError:bsonError];
                    if (error) {
                        break;
                    }
                    mongoc_bulk_operation_destroy(bulk);
                    bulk = mongoc_collection_create_bulk_operation(self.mongocCollection, false, NULL);
                }
            }
            if (!error) {
                bson_error_t bsonError;
                
                mongoc_bulk_operation_execute(bulk, NULL, &bsonError);
                error = [self.mongoServer.class errorFromBsonError:bsonError];
            }
            mongoc_bulk_operation_destroy(bulk);
            mongoQuery.error = error;
        }
        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (callback) {
                callback(mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"insertdocuments" forKey:@"command"];
    [query.mutableParameters setObject:documents forKey:@"documents"];
    return query;
}

- (MODQuery *)updateWithCriteria:(NSString *)jsonCriteria update:(NSString *)update upsert:(BOOL)upsert multiUpdate:(BOOL)multiUpdate callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            bson_t bsonCriteria = BSON_INITIALIZER;
            bson_t bsonUpdate = BSON_INITIALIZER;
            
            bson_init(&bsonCriteria);
            if (jsonCriteria && [jsonCriteria length] > 0) {
                [MODRagelJsonParser bsonFromJson:&bsonCriteria json:jsonCriteria error:&error];
            } else {
                error = [self.mongoServer.class errorWithErrorDomain:MODJsonParserErrorDomain code:JSON_PARSER_ERROR_EXPECTED_END descriptionDetails:nil];
            }
            bson_init(&bsonUpdate);
            if (error == nil && update && [update length] > 0) {
                [MODRagelJsonParser bsonFromJson:&bsonUpdate json:update error:&error];
            } else if (error == nil && (!update || [update length] > 0)) {
                error = [self.mongoServer.class errorWithErrorDomain:MODJsonParserErrorDomain code:JSON_PARSER_ERROR_EXPECTED_END descriptionDetails:nil];
            }
            if (error == nil) {
                bson_error_t bsonError = BSON_NO_ERROR;
                
                if (!mongoc_collection_update(self.mongocCollection, (upsert?MONGOC_UPDATE_UPSERT:0) | (multiUpdate?MONGOC_UPDATE_MULTI_UPDATE:0), &bsonCriteria, &bsonUpdate, NULL, &bsonError)) {
                    error = [self.mongoServer.class errorFromBsonError:bsonError];
                    mongoQuery.error = error;
                }
            } else {
                mongoQuery.error = error;
            }
            bson_destroy(&bsonCriteria);
            bson_destroy(&bsonUpdate);
        }
        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            callback(mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"updatedocuments" forKey:@"command"];
    if (jsonCriteria) {
        [query.mutableParameters setObject:jsonCriteria forKey:@"criteria"];
    }
    [query.mutableParameters setObject:update forKey:@"update"];
    [query.mutableParameters setObject:[NSNumber numberWithBool:upsert] forKey:@"upsert"];
    [query.mutableParameters setObject:[NSNumber numberWithBool:multiUpdate] forKey:@"multiUpdate"];
    return query;
}

- (MODQuery *)saveWithDocument:(NSString *)document callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            bson_t bsonDocument = BSON_INITIALIZER;
            
            bson_init(&bsonDocument);
            [MODRagelJsonParser bsonFromJson:&bsonDocument json:document error:&error];
            if (error == nil) {
                bson_error_t bsonError = BSON_NO_ERROR;
                
                if (!mongoc_collection_save(self.mongocCollection, &bsonDocument, NULL, &bsonError)) {
                    error = [self.mongoServer.class errorFromBsonError:bsonError];
                    mongoQuery.error = error;
                }
            } else {
                mongoQuery.error = error;
            }
            bson_destroy(&bsonDocument);
        }
        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            callback(mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"savedocuments" forKey:@"command"];
    [query.mutableParameters setObject:document forKey:@"document"];
    return query;
}

- (MODQuery *)removeWithCriteria:(id)criteria callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            bson_t bsonCriteria = BSON_INITIALIZER;
            
            bson_init(&bsonCriteria);
            if (criteria && [criteria isKindOfClass:[NSString class]]) {
                if ([criteria length] > 0) {
                    [MODRagelJsonParser bsonFromJson:&bsonCriteria json:criteria error:&error];
                }
            } else if (criteria && [criteria isKindOfClass:[MODSortedMutableDictionary class]]) {
                [[self.mongoServer class] appendObject:criteria toBson:&bsonCriteria];
            } else {
                error = [self.mongoServer.class errorWithErrorDomain:MODJsonParserErrorDomain code:JSON_PARSER_ERROR_EXPECTED_END descriptionDetails:nil];
            }
            if (error == nil) {
                bson_error_t bsonError = BSON_NO_ERROR;
                
                if (!mongoc_collection_delete(self.mongocCollection, MONGOC_DELETE_NONE, &bsonCriteria, NULL, &bsonError)) {
                    error = [self.mongoServer.class errorFromBsonError:bsonError];
                    mongoQuery.error = error;
                }
            } else {
                mongoQuery.error = error;
            }
            bson_destroy(&bsonCriteria);
        }
        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            callback(mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"removedocuments" forKey:@"command"];
    if (criteria) {
        [query.mutableParameters setObject:criteria forKey:@"criteria"];
    }
    return query;
}

//static enum mongo_index_opts convertIndexOptions(enum MOD_INDEX_OPTIONS option)
//{
//    return (enum mongo_index_opts)option;
//}
//
//- (MODQuery *)createIndex:(id)indexDocument name:(NSString *)name options:(enum MOD_INDEX_OPTIONS)options callback:(void (^)(MODQuery *mongoQuery))callback
//{
//    MODQuery *query = nil;
//    NSMutableString *defaultName = nil;
//    
//    if (!name) {
//        NSDictionary *objects;
//        
//        if ([indexDocument isKindOfClass:[NSString class]]) {
//            objects = [MODRagelJsonParser objectsFromJson:indexDocument withError:NULL];
//        } else {
//            objects = indexDocument;
//        }
//        defaultName = [[NSMutableString alloc] init];
//        for (NSString *key in [objects allKeys]) {
//            [defaultName appendString:key];
//            [defaultName appendString:@"_"];
//        }
//        name = defaultName;
//    }
//    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        if (!self.mongoServer.isMaster) {
//            mongoQuery.error = [self.mongoServer.class errorWithErrorDomain:MODMongoErrorDomain code:MONGO_CONN_NOT_MASTER descriptionDetails:@"Index create is forbidden on a slave"];
//        } else if (!mongoQuery.canceled) {
//            bson_t index = BSON_INITIALIZER;
//            bson_t output = BSON_INITIALIZER;
//            NSError *error = nil;
//            
//            bson_init(&index);
//            if ([indexDocument isKindOfClass:[NSString class]]) {
//                [MODRagelJsonParser bsonFromJson:&index json:indexDocument error:&error];
//            } else {
//                [[self.mongoServer class] appendObject:indexDocument toBson:&index];
//            }
//            mongo_create_index(self.mongocClient, self.absoluteName.UTF8String, &index, name.UTF8String, convertIndexOptions(options), -1, &output);
//            bson_destroy(&index);
//            bson_destroy(&output);
//        }
//        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
//            callback(mongoQuery);
//        }];
//    }];
//    [query.mutableParameters setObject:@"createindex" forKey:@"command"];
//    [query.mutableParameters setObject:indexDocument forKey:@"index"];
//    [query.mutableParameters setObject:[NSNumber numberWithInt:options] forKey:@"options"];
//    [query.mutableParameters setObject:name forKey:@"name"];
//    [defaultName release];
//    return query;
//}
//
//- (MODQuery *)dropIndex:(id)indexDocument callback:(void (^)(MODQuery *mongoQuery))callback
//{
//    MODQuery *query = nil;
//    
//    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        if (!self.mongoServer.isMaster) {
//            mongoQuery.error = [self.mongoServer.class errorWithErrorDomain:MODMongoErrorDomain code:MONGO_CONN_NOT_MASTER descriptionDetails:@"Index drop is forbidden on a slave"];
//        } else if (!mongoQuery.canceled) {
//            bson_t index = BSON_INITIALIZER;
//            NSError *error = nil;
//            
//            bson_init(&index);
//            if ([indexDocument isKindOfClass:[NSString class]]) {
//                [MODRagelJsonParser bsonFromJson:&index json:indexDocument error:&error];
//            } else {
//                [[self.mongoServer class] appendObject:indexDocument toBson:&index];
//            }
//            if (error == nil) {
//                mongo_drop_indexes(self.mongocClient, self.absoluteName.UTF8String, &index);
//            } else {
//                mongoQuery.error = error;
//            }
//            bson_destroy(&index);
//        }
//        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
//            callback(mongoQuery);
//        }];
//    }];
//    [query.mutableParameters setObject:@"dropindex" forKey:@"command"];
//    [query.mutableParameters setObject:indexDocument forKey:@"index"];
//    return query;
//}
//
//- (MODQuery *)reIndexWithCallback:(void (^)(MODQuery *mongoQuery))callback
//{
//    MODQuery *query = nil;
//    
//    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        if (!mongoQuery.canceled) {
//            mongo_reindex(self.mongocClient, self.absoluteName.UTF8String);
//        }
//        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
//            callback(mongoQuery);
//        }];
//    }];
//    [query.mutableParameters setObject:@"reindex" forKey:@"command"];
//    return query;
//}
//
//- (MODQuery *)mapReduceWithMapFunction:(NSString *)mapFunction reduceFunction:(NSString *)reduceFunction query:(id)mapReduceQuery sort:(id)sort limit:(int64_t)limit output:(id)output keepTemp:(BOOL)keepTemp finalizeFunction:(NSString *)finalizeFunction scope:(id)scope jsmode:(BOOL)jsmode verbose:(BOOL)verbose callback:(void (^)(MODQuery *mongoQuery))callback
//{
//    MODQuery *query = nil;
//    
//    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        if (!self.mongoServer.isMaster) {
//            mongoQuery.error = [self.mongoServer.class errorWithErrorDomain:MODMongoErrorDomain code:MONGO_CONN_NOT_MASTER descriptionDetails:@"Map reduce is forbidden on a slave"];
//        } else if (!mongoQuery.canceled) {
//            bson_t bsonQuery = BSON_INITIALIZER;
//            bson_t bsonSort = BSON_INITIALIZER;
//            bson_t bsonOutput = BSON_INITIALIZER;
//            bson_t bsonScope = BSON_INITIALIZER;
//            bson_t bsonResult = BSON_INITIALIZER;
//            NSError *error = nil;
//            
//            bson_init(&bsonQuery);
//            if (mapReduceQuery && [mapReduceQuery length] > 0) {
//                [MODRagelJsonParser bsonFromJson:&bsonQuery json:mapReduceQuery error:&error];
//            }
//            if (!error) {
//                bson_init(&bsonSort);
//                if (sort) {
//                    [MODRagelJsonParser bsonFromJson:&bsonSort json:sort error:&error];
//                }
//            }
//            if (!error) {
//                bson_init(&bsonOutput);
//                if (output) {
//                    [MODRagelJsonParser bsonFromJson:&bsonOutput json:output error:&error];
//                }
//            }
//            if (!error) {
//                bson_init(&bsonScope);
//                if (scope) {
//                    [MODRagelJsonParser bsonFromJson:&bsonScope json:scope error:&error];
//                }
//            }
//            if (!error) {
//                mongo_map_reduce(self.mongocClient, self.absoluteName.UTF8String, mapFunction.UTF8String, reduceFunction.UTF8String, &bsonQuery, &bsonSort, limit, &bsonOutput, keepTemp?1:0, finalizeFunction.UTF8String, &bsonScope, jsmode?1:0, verbose?1:0, &bsonResult);
//                NSLog(@"%@", [self.mongoServer.class objectFromBson:&bsonResult]);
//            } else {
//                mongoQuery.error = error;
//            }
//            bson_destroy(&bsonResult);
//        }
//        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
//            callback(mongoQuery);
//        }];
//    }];
//    [query.mutableParameters setObject:@"reindex" forKey:@"command"];
//    return query;
//}

- (MODQuery *)dropWithCallback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        bson_error_t error = BSON_NO_ERROR;
        
        if (!mongoQuery.canceled) {
            mongoc_collection_drop(self.mongocCollection, &error);
        }
        [self mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:^(void) {
            if (callback) {
                callback(mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"dropcollection" forKey:@"command"];
    return query;
}

- (mongoc_client_t *)mongocClient
{
    return self.mongoDatabase.mongocClient;
}

- (MODServer *)mongoServer
{
    return self.mongoDatabase.mongoServer;
}

- (NSString *)databaseName
{
    return self.mongoDatabase.name;
}

@end
