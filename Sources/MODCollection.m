//
//  MODCollection.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"
#import "json.h"

@implementation MODCollection

@synthesize mongoDatabase = _mongoDatabase, collectionName = _collectionName, absoluteCollectionName = _absoluteCollectionName;

- (id)initWithMongoDatabase:(MODDatabase *)mongoDatabase collectionName:(NSString *)collectionName
{
    if (self = [self init]) {
        _mongoDatabase = [mongoDatabase retain];
        _collectionName = [collectionName retain];
        _absoluteCollectionName = [[NSString alloc] initWithFormat:@"%@.%@", _mongoDatabase.databaseName, _collectionName];
    }
    return self;
}

- (void)dealloc
{
    [_mongoDatabase release];
    [_absoluteCollectionName release];
    [_collectionName release];
    [super dealloc];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withCallbackBlock:(void (^)(void))callbackBlock
{
    [mongoQuery.mutableParameters setObject:self forKey:@"collection"];
    [_mongoDatabase mongoQueryDidFinish:mongoQuery withCallbackBlock:callbackBlock];
}

- (MODQuery *)fetchDatabaseStatsWithCallback:(void (^)(NSDictionary *stats, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSDictionary *stats = nil;
        
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson output;
            
            if (mongo_simple_str_command(_mongoDatabase.mongo, [_mongoDatabase.databaseName UTF8String], "collstats", [_collectionName UTF8String], &output) == MONGO_OK) {
                stats = [[self.mongoServer class] objectsFromBson:&output];
                [mongoQuery.mutableParameters setObject:stats forKey:@"collectionstats"];
                bson_destroy(&output);
            }
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(stats, mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"databasestats" forKey:@"command"];
    return query;
}

- (MODQuery *)indexListWithcallback:(void (^)(NSArray *documents, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSMutableArray *documents;
        MODCursor *cursor;
        NSDictionary *document;
        NSError *error = nil;
        
        documents = [[NSMutableArray alloc] init];
        cursor = [[MODCursor alloc] initWithMongoCollection:self];
        cursor.cursor = mongo_index_list(_mongoDatabase.mongo, [_absoluteCollectionName UTF8String], 50);
        cursor.donotReleaseCursor = YES;
        while ((document = [cursor nextDocumentAsynchronouslyWithError:&error]) != nil) {
            [documents addObject:document];
        }
        if (error) {
            mongoQuery.error = error;
        }
        [mongoQuery.mutableParameters setObject:documents forKey:@"documents"];
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(documents, mongoQuery);
        }];
        [documents release];
        [cursor release];
    }];
    [query.mutableParameters setObject:@"indexlist" forKey:@"command"];
    return query;
}

- (MODQuery *)findWithCriteria:(NSString *)jsonCriteria fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(NSString *)sort callback:(void (^)(NSArray *documents, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSMutableArray *documents;
        MODCursor *cursor;
        NSDictionary *document;
        NSError *error = nil;
        
        documents = [[NSMutableArray alloc] initWithCapacity:limit];
        cursor = [self cursorWithCriteria:jsonCriteria fields:fields skip:skip limit:limit sort:sort];
        while ((document = [cursor nextDocumentAsynchronouslyWithError:&error]) != nil) {
            [documents addObject:document];
        }
        if (error) {
            mongoQuery.error = error;
        }
        [mongoQuery.mutableParameters setObject:documents forKey:@"documents"];
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(documents, mongoQuery);
        }];
        [documents release];
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
    MODCursor *cursor;
    
    cursor = [[MODCursor alloc] initWithMongoCollection:self];
    cursor.query = query;
    cursor.fields = fields;
    cursor.skip = skip;
    cursor.limit = limit;
    cursor.sort = sort;
    return [cursor autorelease];
}

- (MODQuery *)countWithCriteria:(NSString *)jsonCriteria callback:(void (^)(int64_t count, MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        int64_t count = 0;
        
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson *bsonQuery = NULL;
            NSError *error = nil;
            
            bsonQuery = malloc(sizeof(*bsonQuery));
            bson_init(bsonQuery);
            if (jsonCriteria && [jsonCriteria length] > 0) {
                [MODJsonToBsonParser bsonFromJson:bsonQuery json:jsonCriteria error:&error];
            }
            bson_finish(bsonQuery);
            
            if (error) {
                mongoQuery.error = error;
            } else {
                NSNumber *response;
                
                count = mongo_count(_mongoDatabase.mongo, [_mongoDatabase.databaseName UTF8String], [_collectionName UTF8String], bsonQuery);
                response = [[NSNumber alloc] initWithUnsignedLongLong:count];
                [mongoQuery.mutableParameters setObject:response forKey:@"count"];
                [response release];
            }
            bson_destroy(bsonQuery);
            free(bsonQuery);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(count, mongoQuery);
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
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson **data;
            bson **dataCursor;
            NSInteger countCursor;
            NSInteger documentCount = [documents count];
            NSError *error = nil;
            NSInteger ii = 0;
            
            data = calloc(documentCount, sizeof(void *));
            for (id document in documents) {
                data[ii] = malloc(sizeof(bson));
                bson_init(data[ii]);
                if ([document isKindOfClass:[NSString class]]) {
                    [MODJsonToBsonParser bsonFromJson:data[ii] json:document error:&error];
                } else if ([document isKindOfClass:[NSDictionary class]]) {
                    [MODJsonToBsonParser bsonFromJson:data[ii] json:document error:&error];
                }
                bson_finish(data[ii]);
                ii++;
                if (error) {
                    break;
                }
            }
            if (!error) {
                dataCursor = data;
                countCursor = documentCount;
                while (countCursor > INT32_MAX) {
                    if (mongo_insert_batch(_mongoDatabase.mongo, [_absoluteCollectionName UTF8String], dataCursor, INT32_MAX) != MONGO_OK) {
                        error = [[_mongoDatabase.mongoServer class] errorFromMongo:_mongoDatabase.mongo];
                        break;
                    }
                    countCursor -= INT32_MAX;
                    dataCursor += INT32_MAX;
                }
                if (!error) {
                    if (mongo_insert_batch(_mongoDatabase.mongo, [_absoluteCollectionName UTF8String], dataCursor, (int32_t)countCursor) != MONGO_OK) {
                        error = [[_mongoDatabase.mongoServer class] errorFromMongo:_mongoDatabase.mongo];
                    }
                }
            }
            for (NSInteger ii = 0; ii < documentCount; ii++) {
                if (data[ii]) {
                    bson_destroy(data[ii]);
                    free(data[ii]);
                }
            }
            free(data);
            mongoQuery.error = error;
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"insertdocuments" forKey:@"command"];
    [query.mutableParameters setObject:documents forKey:@"documents"];
    return query;
}

- (MODQuery *)updateWithCriteria:(NSString *)jsonCriteria update:(NSString *)update upsert:(BOOL)upsert multiUpdate:(BOOL)multiUpdate callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson bsonCriteria;
            bson bsonUpdate;
            NSError *error = nil;
            
            bson_init(&bsonCriteria);
            if (jsonCriteria && [jsonCriteria length] > 0) {
                [MODJsonToBsonParser bsonFromJson:&bsonCriteria json:jsonCriteria error:&error];
            } else {
                error = [MODServer errorWithErrorDomain:MODJsonParserErrorDomain code:JSON_PARSER_ERROR_EXPECTED_END descriptionDetails:@""];
            }
            bson_finish(&bsonCriteria);
            bson_init(&bsonUpdate);
            if (error == nil && update && [update length] > 0) {
                [MODJsonToBsonParser bsonFromJson:&bsonUpdate json:update error:&error];
            } else if (error == nil && (!update || [update length] > 0)) {
                error = [MODServer errorWithErrorDomain:MODJsonParserErrorDomain code:JSON_PARSER_ERROR_EXPECTED_END descriptionDetails:@""];
            }
            bson_finish(&bsonUpdate);
            if (error == nil) {
                mongo_update(_mongoDatabase.mongo, [_absoluteCollectionName UTF8String], &bsonCriteria, &bsonUpdate, (upsert?MONGO_UPDATE_UPSERT:0) | (multiUpdate?MONGO_UPDATE_MULTI:0));
            } else {
                mongoQuery.error = error;
            }
            bson_destroy(&bsonCriteria);
            bson_destroy(&bsonUpdate);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
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
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson bsonCriteria;
            bson bsonDocument;
            NSError *error = nil;
            
            bson_init(&bsonDocument);
            [MODJsonToBsonParser bsonFromJson:&bsonDocument json:document error:&error];
            bson_finish(&bsonDocument);
            bson_init(&bsonCriteria);
            if (error == nil) {
                bson_iterator iterator;
                
                bson_iterator_init(&iterator, &bsonDocument);
                while (bson_iterator_next(&iterator)) {
                    if (strcmp(bson_iterator_key(&iterator), "_id") == 0) {
                        bson_timestamp_t timestamp;
                        
                        switch (bson_iterator_type(&iterator)) {
                            case BSON_STRING:
                                bson_append_string(&bsonCriteria, "_id", bson_iterator_string(&iterator));
                                break;
                            case BSON_DATE:
                                bson_append_date(&bsonCriteria, "_id", bson_iterator_date(&iterator));
                                break;
                            case BSON_INT:
                                bson_append_int(&bsonCriteria, "_id", bson_iterator_int(&iterator));
                                break;
                            case BSON_TIMESTAMP:
                                timestamp = bson_iterator_timestamp(&iterator);
                                bson_append_timestamp(&bsonCriteria, "_id", &timestamp);
                                break;
                            case BSON_LONG:
                                bson_append_long(&bsonCriteria, "_id", bson_iterator_long(&iterator));
                                break;
                            case BSON_DOUBLE:
                                bson_append_double(&bsonCriteria, "_id", bson_iterator_double(&iterator));
                                break;
                            case BSON_SYMBOL:
                                bson_append_symbol(&bsonCriteria, "_id", bson_iterator_string(&iterator));
                                break;
                            default:
                                error = [[_mongoDatabase.mongoServer class] errorWithErrorDomain:MODMongoErrorDomain code:MONGO_BSON_INVALID descriptionDetails:@"_id missing in document"];
                                break;
                        }
                        break;
                    }
                }
            }
            bson_finish(&bsonCriteria);
            if (error == nil) {
                mongo_update(_mongoDatabase.mongo, [_absoluteCollectionName UTF8String], &bsonCriteria, &bsonDocument, MONGO_UPDATE_UPSERT);
            } else {
                mongoQuery.error = error;
            }
            bson_destroy(&bsonCriteria);
            bson_destroy(&bsonDocument);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"savedocuments" forKey:@"command"];
    [query.mutableParameters setObject:document forKey:@"document"];
    return query;
}

- (MODQuery *)removeWithCriteria:(NSString *)criteria callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson bsonCriteria;
            NSError *error = nil;
            
            bson_init(&bsonCriteria);
            if (criteria && [criteria length] > 0) {
                [MODJsonToBsonParser bsonFromJson:&bsonCriteria json:criteria error:&error];
            } else {
                error = [MODServer errorWithErrorDomain:MODJsonParserErrorDomain code:JSON_PARSER_ERROR_EXPECTED_END descriptionDetails:@""];
            }
            bson_finish(&bsonCriteria);
            if (error == nil) {
                mongo_remove(_mongoDatabase.mongo, [_absoluteCollectionName UTF8String], &bsonCriteria);
            } else {
                mongoQuery.error = error;
            }
            bson_destroy(&bsonCriteria);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"removedocuments" forKey:@"command"];
    if (criteria) {
        [query.mutableParameters setObject:criteria forKey:@"criteria"];
    }
    return query;
}

- (mongo *)mongo
{
    return _mongoDatabase.mongo;
}

- (MODServer *)mongoServer
{
    return _mongoDatabase.mongoServer;
}

- (NSString *)databaseName
{
    return _mongoDatabase.databaseName;
}

@end
