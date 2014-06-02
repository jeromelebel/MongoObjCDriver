//
//  MODCollection.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@interface MODCollection ()
@property (nonatomic, readwrite, retain) MODDatabase *database;
@property (nonatomic, readwrite, retain) NSString *name;
@property (nonatomic, readwrite, retain) NSString *absoluteName;

@end

@implementation MODCollection

@synthesize database = _database, name = _name, absoluteName = _absoluteName, mongocCollection = _mongocCollection;

- (id)initWithName:(NSString *)name database:(MODDatabase *)database
{
    if (self = [self init]) {
        self.database = database;
        self.name = [name retain];
        self.absoluteName = [[[NSString alloc] initWithFormat:@"%@.%@", self.database.name, self.name] autorelease];
        self.mongocCollection = mongoc_database_get_collection(self.database.mongocDatabase, name.UTF8String);
    }
    return self;
}

- (void)dealloc
{
    self.database = nil;
    self.name = nil;
    self.absoluteName = nil;
    [super dealloc];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock
{
    [mongoQuery.mutableParameters setObject:self forKey:@"collection"];
    [self.database mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:callbackBlock];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock
{
    [mongoQuery.mutableParameters setObject:self forKey:@"collection"];
    [self.database mongoQueryDidFinish:mongoQuery withError:error callbackBlock:callbackBlock];
}

- (MODQuery *)fetchCollectionStatsWithCallback:(void (^)(MODSortedMutableDictionary *stats, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        MODSortedMutableDictionary *stats = nil;
        bson_error_t error;
        
        if (!mongoQuery.canceled) {
            bson_t output = BSON_INITIALIZER;
            bson_t cmd = BSON_INITIALIZER;
            
            BSON_APPEND_INT32 (&cmd, "collstats", 1);
            if (mongoc_client_command_simple(self.mongocClient, self.absoluteName.UTF8String, &cmd, NULL, &output, &error)) {
                stats = [[self.client class] objectFromBson:&output];
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

- (MODQuery *)findWithCriteria:(NSString *)jsonCriteria fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(NSString *)sort callback:(void (^)(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
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
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
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
                    error = [self.client.class errorFromBsonError:bsonError];
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
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
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
                    [[self.client class] appendObject:document toBson:&bson];
                }
                if (error) {
                    break;
                }
                mongoc_bulk_operation_insert(bulk, &bson);
                ii++;
                if (ii >= 50) {
                    bson_error_t bsonError;
                    
                    mongoc_bulk_operation_execute(bulk, NULL, &bsonError);
                    error = [self.client.class errorFromBsonError:bsonError];
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
                error = [self.client.class errorFromBsonError:bsonError];
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
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            bson_t bsonCriteria = BSON_INITIALIZER;
            bson_t bsonUpdate = BSON_INITIALIZER;
            
            bson_init(&bsonCriteria);
            if (jsonCriteria && [jsonCriteria length] > 0) {
                [MODRagelJsonParser bsonFromJson:&bsonCriteria json:jsonCriteria error:&error];
            } else {
                error = [self.client.class errorWithErrorDomain:MODJsonParserErrorDomain code:JSON_PARSER_ERROR_EXPECTED_END descriptionDetails:nil];
            }
            bson_init(&bsonUpdate);
            if (error == nil && update && [update length] > 0) {
                [MODRagelJsonParser bsonFromJson:&bsonUpdate json:update error:&error];
            } else if (error == nil && (!update || [update length] > 0)) {
                error = [self.client.class errorWithErrorDomain:MODJsonParserErrorDomain code:JSON_PARSER_ERROR_EXPECTED_END descriptionDetails:nil];
            }
            if (error == nil) {
                bson_error_t bsonError = BSON_NO_ERROR;
                
                if (!mongoc_collection_update(self.mongocCollection, (upsert?MONGOC_UPDATE_UPSERT:0) | (multiUpdate?MONGOC_UPDATE_MULTI_UPDATE:0), &bsonCriteria, &bsonUpdate, NULL, &bsonError)) {
                    error = [self.client.class errorFromBsonError:bsonError];
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
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            bson_t bsonDocument = BSON_INITIALIZER;
            
            bson_init(&bsonDocument);
            [MODRagelJsonParser bsonFromJson:&bsonDocument json:document error:&error];
            if (error == nil) {
                bson_error_t bsonError = BSON_NO_ERROR;
                
                if (!mongoc_collection_save(self.mongocCollection, &bsonDocument, NULL, &bsonError)) {
                    error = [self.client.class errorFromBsonError:bsonError];
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
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            bson_t bsonCriteria = BSON_INITIALIZER;
            
            bson_init(&bsonCriteria);
            if (criteria && [criteria isKindOfClass:[NSString class]]) {
                if ([criteria length] > 0) {
                    [MODRagelJsonParser bsonFromJson:&bsonCriteria json:criteria error:&error];
                }
            } else if (criteria && [criteria isKindOfClass:[MODSortedMutableDictionary class]]) {
                [[self.client class] appendObject:criteria toBson:&bsonCriteria];
            } else {
                error = [self.client.class errorWithErrorDomain:MODJsonParserErrorDomain code:JSON_PARSER_ERROR_EXPECTED_END descriptionDetails:nil];
            }
            if (error == nil) {
                bson_error_t bsonError = BSON_NO_ERROR;
                
                if (!mongoc_collection_remove(self.mongocCollection, MONGOC_DELETE_NONE, &bsonCriteria, NULL, &bsonError)) {
                    error = [self.client.class errorFromBsonError:bsonError];
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

- (MODQuery *)indexListWithCallback:(void (^)(NSArray *documents, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self findWithCriteria:[NSString stringWithFormat:@"{ns: \"%@\"", self.absoluteName] fields:nil skip:0 limit:0 sort:nil callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        callback(documents, mongoQuery);
    }];
    [query.mutableParameters setObject:@"indexlist" forKey:@"command"];
    return query;
}

- (MODQuery *)createIndex:(id)indexDocument name:(NSString *)name options:(enum MOD_INDEX_OPTIONS)options callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    NSMutableString *defaultName = nil;
    
    if (!name) {
        NSDictionary *objects;
        
        if ([indexDocument isKindOfClass:[NSString class]]) {
            objects = [MODRagelJsonParser objectsFromJson:indexDocument withError:NULL];
        } else {
            objects = indexDocument;
        }
        defaultName = [[NSMutableString alloc] init];
        for (NSString *key in [objects allKeys]) {
            [defaultName appendString:key];
            [defaultName appendString:@"_"];
        }
        name = defaultName;
    }
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            bson_t index = BSON_INITIALIZER;
            bson_error_t bsonError = BSON_NO_ERROR;
            mongoc_index_opt_t indexOptions;
            
            memcpy(&indexOptions, mongoc_index_opt_get_default(), sizeof(indexOptions));
            indexOptions.background = (options & MOD_INDEX_OPTIONS_BACKGROUND) == MOD_INDEX_OPTIONS_BACKGROUND;
            indexOptions.unique = (options & MOD_INDEX_OPTIONS_UNIQUE) == MOD_INDEX_OPTIONS_UNIQUE;
            indexOptions.sparse = (options & MOD_INDEX_OPTIONS_SPARSE) == MOD_INDEX_OPTIONS_SPARSE;
            indexOptions.drop_dups = (options & MOD_INDEX_OPTIONS_DROP_DUPS) == MOD_INDEX_OPTIONS_DROP_DUPS;
            if ([indexDocument isKindOfClass:[NSString class]]) {
                [MODRagelJsonParser bsonFromJson:&index json:indexDocument error:&error];
            } else {
                [[self.client class] appendObject:indexDocument toBson:&index];
            }
            if (!error) {
                mongoc_collection_create_index(self.mongocCollection, &index, &indexOptions, &bsonError);
                error = [self.client.class errorFromBsonError:bsonError];
            }
            bson_destroy(&index);
        }
        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            callback(mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"createindex" forKey:@"command"];
    [query.mutableParameters setObject:indexDocument forKey:@"index"];
    [query.mutableParameters setObject:[NSNumber numberWithInt:options] forKey:@"options"];
    [query.mutableParameters setObject:name forKey:@"name"];
    [defaultName release];
    return query;
}

- (MODQuery *)dropIndex:(id)indexDocument callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;

        if (!mongoQuery.canceled) {
            bson_t index = BSON_INITIALIZER;
            
            if ([indexDocument isKindOfClass:[NSString class]]) {
                [MODRagelJsonParser bsonFromJson:&index json:indexDocument error:&error];
            } else {
                [[self.client class] appendObject:indexDocument toBson:&index];
            }
            if (error == nil) {
                bson_error_t bsonError = BSON_NO_ERROR;
                
                mongoc_collection_drop_index(self.mongocCollection, self.absoluteName.UTF8String, &bsonError);
                error = [self.client.class errorFromBsonError:bsonError];
            }
            bson_destroy(&index);
        }
        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            callback(mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"dropindex" forKey:@"command"];
    [query.mutableParameters setObject:indexDocument forKey:@"index"];
    return query;
}

- (MODQuery *)reIndexWithCallback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
//    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
//        NSError *error = nil;
//        
//        if (!mongoQuery.canceled) {
//            mongo_reindex(self.mongocClient, self.absoluteName.UTF8String);
//            mongoc_collection_ensure_index(self.mongocCollection, <#const bson_t *keys#>, <#const mongoc_index_opt_t *opt#>, <#bson_error_t *error#>)
//            mongoc_collection_create_index(<#mongoc_collection_t *collection#>, <#const bson_t *keys#>, <#const mongoc_index_opt_t *opt#>, <#bson_error_t *error#>)
//        }
//        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
//            callback(mongoQuery);
//        }];
//    }];
//    [query.mutableParameters setObject:@"reindex" forKey:@"command"];
    return query;
}

- (MODQuery *)mapReduceWithMapFunction:(NSString *)mapFunction reduceFunction:(NSString *)reduceFunction query:(id)mapReduceQuery sort:(id)sort limit:(int64_t)limit output:(id)output keepTemp:(BOOL)keepTemp finalizeFunction:(NSString *)finalizeFunction scope:(id)scope jsmode:(BOOL)jsmode verbose:(BOOL)verbose callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
//    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
//        NSError *error = nil;
//        
//        if (!mongoQuery.canceled) {
//            bson_t bsonQuery = BSON_INITIALIZER;
//            bson_t bsonSort = BSON_INITIALIZER;
//            bson_t bsonOutput = BSON_INITIALIZER;
//            bson_t bsonScope = BSON_INITIALIZER;
//            bson_t bsonResult = BSON_INITIALIZER;
//            NSError *error = nil;
//            
//            if (mapReduceQuery && [mapReduceQuery length] > 0) {
//                [MODRagelJsonParser bsonFromJson:&bsonQuery json:mapReduceQuery error:&error];
//            }
//            if (!error) {
//                if (sort) {
//                    [MODRagelJsonParser bsonFromJson:&bsonSort json:sort error:&error];
//                }
//            }
//            if (!error) {
//                if (output) {
//                    [MODRagelJsonParser bsonFromJson:&bsonOutput json:output error:&error];
//                }
//            }
//            if (!error) {
//                if (scope) {
//                    [MODRagelJsonParser bsonFromJson:&bsonScope json:scope error:&error];
//                }
//            }
//            if (!error) {
//                mongoc_collection_re
//                mongo_map_reduce(self.mongocClient, self.absoluteName.UTF8String, mapFunction.UTF8String, reduceFunction.UTF8String, &bsonQuery, &bsonSort, limit, &bsonOutput, keepTemp?1:0, finalizeFunction.UTF8String, &bsonScope, jsmode?1:0, verbose?1:0, &bsonResult);
//                NSLog(@"%@", [self.client.class objectFromBson:&bsonResult]);
//            } else {
//                mongoQuery.error = error;
//            }
//            bson_destroy(&bsonResult);
//        }
//        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
//            callback(mongoQuery);
//        }];
//    }];
//    [query.mutableParameters setObject:@"reindex" forKey:@"command"];
    return query;
}

- (MODQuery *)dropWithCallback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
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

@end
