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

- (bool)_commandSimpleWithCommand:(MODSortedMutableDictionary *)command reply:(MODSortedMutableDictionary **)reply error:(NSError **)error;

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

- (MODQuery *)statsWithCallback:(void (^)(MODSortedMutableDictionary *stats, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        MODSortedMutableDictionary *stats = nil;
        bson_error_t error;
        
        if (!mongoQuery.canceled) {
            bson_t output = BSON_INITIALIZER;
            
            if (mongoc_collection_stats(self.mongocCollection, NULL, &output, &error)) {
                stats = [[self.client class] objectFromBson:&output];
                [mongoQuery.mutableParameters setObject:stats forKey:@"collectionstats"];
            }
            bson_destroy(&output);
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

- (MODQuery *)findWithCriteria:(MODSortedMutableDictionary *)criteria fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(MODSortedMutableDictionary *)sort callback:(void (^)(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery))callback
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
            cursor = [self cursorWithCriteria:criteria fields:fields skip:skip limit:limit sort:sort];
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
    if (criteria) {
        [query.mutableParameters setObject:criteria forKey:@"criteria"];
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

- (MODCursor *)cursorWithCriteria:(MODSortedMutableDictionary *)query fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(MODSortedMutableDictionary *)sort
{
    return [[[MODCursor alloc] initWithMongoCollection:self query:query fields:fields skip:skip limit:limit sort:sort] autorelease];
}

- (MODQuery *)countWithCriteria:(MODSortedMutableDictionary *)criteria callback:(void (^)(int64_t count, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        int64_t count = 0;
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            bson_t bsonQuery = BSON_INITIALIZER;
            
            if (criteria && criteria.count > 0) {
                [self.client.class appendObject:criteria toBson:&bsonQuery];
            }
            
            if (error) {
                mongoQuery.error = error;
            } else {
                NSNumber *response;
                bson_error_t bsonError;
                
                count = mongoc_collection_count(self.mongocCollection, 0, &bsonQuery, 0, 0, NULL, &bsonError);
                if (count == -1) {
                    error = [self.client.class errorFromBsonError:bsonError];
                } else {
                    response = [[NSNumber alloc] initWithUnsignedLongLong:count];
                    [mongoQuery.mutableParameters setObject:response forKey:@"count"];
                    [response release];
                }
            }
            bson_destroy(&bsonQuery);
        }
        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (callback) {
                callback(count, mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"countdocuments" forKey:@"command"];
    if (criteria) {
        [query.mutableParameters setObject:criteria forKey:@"criteria"];
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
                bson_error_t bsonError = BSON_NO_ERROR;
                
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

- (MODQuery *)updateWithCriteria:(MODSortedMutableDictionary *)criteria update:(MODSortedMutableDictionary *)update upsert:(BOOL)upsert multiUpdate:(BOOL)multiUpdate callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            bson_t bsonCriteria = BSON_INITIALIZER;
            bson_t bsonUpdate = BSON_INITIALIZER;
            
            if (criteria && criteria.count > 0) {
                [self.client.class appendObject:criteria toBson:&bsonCriteria];
            }
            if (update && update.count > 0) {
                [self.client.class appendObject:update toBson:&bsonUpdate];
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
    if (criteria) [query.mutableParameters setObject:criteria forKey:@"criteria"];
    if (update) [query.mutableParameters setObject:update forKey:@"update"];
    [query.mutableParameters setObject:[NSNumber numberWithBool:upsert] forKey:@"upsert"];
    [query.mutableParameters setObject:[NSNumber numberWithBool:multiUpdate] forKey:@"multiUpdate"];
    return query;
}

- (MODQuery *)saveWithDocument:(MODSortedMutableDictionary *)document callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            bson_t bsonDocument = BSON_INITIALIZER;
            bson_error_t bsonError = BSON_NO_ERROR;
            
            [self.client.class appendObject:document toBson:&bsonDocument];
            if (!mongoc_collection_save(self.mongocCollection, &bsonDocument, NULL, &bsonError)) {
                error = [self.client.class errorFromBsonError:bsonError];
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
    MODSortedMutableDictionary *dictionary;
    
    dictionary = [[MODSortedMutableDictionary alloc] initWithObjectsAndKeys:self.absoluteName, @"ns", nil];
    query = [self.database.systemIndexesCollection findWithCriteria:dictionary fields:nil skip:0 limit:0 sort:nil callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        callback(documents, mongoQuery);
    }];
    [query.mutableParameters setObject:@"indexlist" forKey:@"command"];
    [dictionary release];
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

- (MODQuery *)dropIndexName:(NSString *)indexDocument callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        NSError *error = nil;

        if (!mongoQuery.canceled) {
            bson_error_t bsonError = BSON_NO_ERROR;
            
            mongoc_collection_drop_index(self.mongocCollection, indexDocument.UTF8String, &bsonError);
            error = [self.client.class errorFromBsonError:bsonError];
        }
        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            callback(mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"dropindex" forKey:@"command"];
    [query.mutableParameters setObject:indexDocument forKey:@"index"];
    return query;
}

- (MODQuery *)aggregateWithFlags:(int)flags pipeline:(MODSortedMutableDictionary *)pipeline options:(MODSortedMutableDictionary *)options callback:(void (^)(MODQuery *mongoQuery, MODCursor *cursor))callback
{
    MODQuery *query = nil;
    
    NSAssert(NO, @"not yet implemented. Need to convert mongoc cursor into a MODCursor");
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        MODCursor *cursor = nil;
        bson_error_t bsonError = BSON_NO_ERROR;

        if (!mongoQuery.canceled) {
            bson_t bsonPipeline = BSON_INITIALIZER;
            bson_t bsonOptions = BSON_INITIALIZER;
            mongoc_cursor_t *mongocCursor = nil;
            
            [self.client.class appendObject:pipeline toBson:&bsonPipeline];
            [self.client.class appendObject:options toBson:&bsonOptions];
            mongocCursor = mongoc_collection_aggregate(self.mongocCollection, flags, &bsonPipeline, &bsonOptions, NULL);
        }
        [self mongoQueryDidFinish:mongoQuery withBsonError:bsonError callbackBlock:^(void) {
            callback(mongoQuery, cursor);
        }];
    }];
    [query.mutableParameters setObject:@"aggregate" forKey:@"command"];
    return nil;
}

- (bool)_commandSimpleWithCommand:(MODSortedMutableDictionary *)command reply:(MODSortedMutableDictionary **)reply error:(NSError **)error
{
    bson_t bsonCommand = BSON_INITIALIZER;
    bson_t bsonReply = BSON_INITIALIZER;
    bson_error_t bsonError = BSON_NO_ERROR;
    bool result;
    
    [self.client.class appendObject:command toBson:&bsonCommand];
    result = mongoc_collection_command_simple(self.mongocCollection, &bsonCommand, NULL, &bsonReply, &bsonError);
    if (reply) *reply = [self.client.class objectFromBson:&bsonReply];
    if (error) *error = [self.client.class errorFromBsonError:bsonError];
    return result;
}

- (MODQuery *)commandSimpleWithCommand:(MODSortedMutableDictionary *)command callback:(void (^)(MODQuery *query, MODSortedMutableDictionary *reply))callback
{
    MODQuery *mongoQuery = nil;
    
    mongoQuery = [self.client addQueryInQueue:^(MODQuery *currentMongoQuery) {
        MODSortedMutableDictionary *reply = nil;
        NSError *error = nil;
        
        if (!currentMongoQuery.canceled) {
            [self _commandSimpleWithCommand:command reply:&reply error:&error];
        }
        [self mongoQueryDidFinish:currentMongoQuery withError:error callbackBlock:^(void) {
            callback(currentMongoQuery, reply);
        }];
    }];
    [mongoQuery.mutableParameters setObject:@"commandsimple" forKey:@"command"];
    return mongoQuery;
}

- (MODQuery *)mapReduceWithMapFunction:(NSString *)mapFunction reduceFunction:(NSString *)reduceFunction query:(MODSortedMutableDictionary *)query sort:(MODSortedMutableDictionary *)sort limit:(int64_t)limit output:(MODSortedMutableDictionary *)output keepTemp:(BOOL)keepTemp finalizeFunction:(NSString *)finalizeFunction scope:(MODSortedMutableDictionary *)scope jsmode:(BOOL)jsmode verbose:(BOOL)verbose callback:(void (^)(MODQuery *mongoQuery, MODSortedMutableDictionary *documents))callback
{
    MODQuery *mongoQuery = nil;
    
    mongoQuery = [self.client addQueryInQueue:^(MODQuery *currentMongoQuery) {
        NSError *error = nil;
        MODSortedMutableDictionary *reply = nil;
        
        if (!currentMongoQuery.canceled) {
            MODSortedMutableDictionary *command;
            
            command = [[MODSortedMutableDictionary alloc] init];
            [command setObject:self.name forKey:@"mapreduce"];
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

            [self _commandSimpleWithCommand:command reply:&reply error:&error];
        }
        [self mongoQueryDidFinish:currentMongoQuery withError:error callbackBlock:^(void) {
            callback(currentMongoQuery, reply);
        }];
    }];
    [mongoQuery.mutableParameters setObject:@"mapreduce" forKey:@"command"];
    return mongoQuery;
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
