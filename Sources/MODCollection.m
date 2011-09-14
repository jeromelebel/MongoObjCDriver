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

@synthesize mongoDatabase = _mongoDatabase, collectionName = _collectionName, absoluteCollectionName = _absoluteCollectionName, delegate = _delegate;

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

- (void)findCallback:(MODQuery *)mongoQuery
{
    NSArray *result;
    
    result = [mongoQuery.parameters objectForKey:@"result"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryResultFetched:withMongoQuery:)]) {
        [_delegate mongoCollection:self queryResultFetched:result withMongoQuery:mongoQuery];
    }
}

- (MODQuery *)findWithCriteria:(NSString *)jsonCriteria fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(NSString *)sort
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSMutableArray *response;
        MODCursor *cursor;
        NSDictionary *document;
        NSError *error = nil;
        
        response = [[NSMutableArray alloc] initWithCapacity:limit];
        cursor = [self cursorWithCriteria:jsonCriteria fields:fields skip:skip limit:limit sort:sort];
        while ((document = [cursor nextDocumentAsynchronouslyWithError:&error]) != nil) {
            [response addObject:document];
        }
        if (error) {
            mongoQuery.error = error;
        }
        [mongoQuery.mutableParameters setObject:response forKey:@"result"];
        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(findCallback:)];
        [response release];
    }];
    if (jsonCriteria) {
        [query.mutableParameters setObject:jsonCriteria forKey:@"criteria"];
    }
    if (fields) {
        [query.mutableParameters setObject:fields forKey:@"fields"];
    }
    [query.mutableParameters setObject:[NSNumber numberWithUnsignedInteger:skip] forKey:@"skip"];
    [query.mutableParameters setObject:[NSNumber numberWithUnsignedInteger:limit] forKey:@"limit"];
    if (sort) {
        [query.mutableParameters setObject:sort forKey:@"sort"];
    }
    [query.mutableParameters setObject:self forKey:@"collection"];
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

- (void)countCallback:(MODQuery *)mongoQuery
{
    long long int count;
    
    count = [[mongoQuery.parameters objectForKey:@"count"] longLongValue];
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryCountWithValue:withMongoQuery:)]) {
        [_delegate mongoCollection:self queryCountWithValue:count withMongoQuery:mongoQuery];
    }
}

- (MODQuery *)countWithCriteria:(NSString *)jsonCriteria
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson *bsonQuery = NULL;
            NSError *error = nil;
            uint64_t count;
            
            bsonQuery = malloc(sizeof(*bsonQuery));
            bson_init(bsonQuery);
            if (jsonCriteria) {
                [[_mongoDatabase.mongoServer class] bsonFromJson:bsonQuery json:jsonCriteria error:&error];
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
        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(findCallback:)];
    }];
    if (jsonCriteria) {
        [query.mutableParameters setObject:jsonCriteria forKey:@"criteria"];
    }
    [query.mutableParameters setObject:self forKey:@"collection"];
    return query;
}

- (void)insertCallback:(MODQuery *)mongoQuery
{
    if ([_delegate respondsToSelector:@selector(mongoCollection:insertWithMongoQuery:)]) {
        [_delegate mongoCollection:self insertWithMongoQuery:mongoQuery];
    }
}

- (MODQuery *)insertWithDocuments:(NSArray *)documents
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
            for (NSString *document in documents) {
                data[ii] = malloc(sizeof(bson));
                bson_init(data[ii]);
                [[_mongoDatabase.mongoServer class] bsonFromJson:data[ii] json:document error:&error];
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
        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(insertCallback:)];
    }];
    [query.mutableParameters setObject:documents forKey:@"documents"];
    [query.mutableParameters setObject:self forKey:@"collection"];
    return query;
}

- (void)updateCallback:(MODQuery *)mongoQuery
{
    if ([_delegate respondsToSelector:@selector(mongoCollection:updateWithMongoQuery:)]) {
        [_delegate mongoCollection:self updateWithMongoQuery:mongoQuery];
    }
}

- (MODQuery *)updateWithCriteria:(NSString *)criteria update:(NSString *)update upsert:(BOOL)upsert multiUpdate:(BOOL)multiUpdate
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson bsonCriteria;
            bson bsonUpdate;
            NSError *error;
            
            bson_init(&bsonCriteria);
            [[_mongoDatabase.mongoServer class] bsonFromJson:&bsonCriteria json:criteria error:&error];
            bson_finish(&bsonCriteria);
            bson_init(&bsonUpdate);
            if (error == nil) {
                [[_mongoDatabase.mongoServer class] bsonFromJson:&bsonUpdate json:update error:&error];
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
        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(updateCallback:)];
    }];
    [query.mutableParameters setObject:criteria forKey:@"criteria"];
    [query.mutableParameters setObject:update forKey:@"update"];
    [query.mutableParameters setObject:[NSNumber numberWithBool:upsert] forKey:@"upsert"];
    [query.mutableParameters setObject:[NSNumber numberWithBool:multiUpdate] forKey:@"multiUpdate"];
    [query.mutableParameters setObject:self forKey:@"collection"];
    return query;
}

- (MODQuery *)saveWithDocument:(NSString *)document
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson bsonCriteria;
            bson bsonDocument;
            NSError *error;
            
            bson_init(&bsonDocument);
            [[_mongoDatabase.mongoServer class] bsonFromJson:&bsonDocument json:document error:&error];
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
        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(updateCallback:)];
    }];
    [query.mutableParameters setObject:document forKey:@"document"];
    [query.mutableParameters setObject:self forKey:@"collection"];
    return query;
}


- (void)removeCallback:(MODQuery *)mongoQuery
{
    if ([_delegate respondsToSelector:@selector(mongoCollection:updateWithMongoQuery:)]) {
        [_delegate mongoCollection:self updateWithMongoQuery:mongoQuery];
    }
}

- (MODQuery *)removeWithCriteria:(NSString *)criteria
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson bsonCriteria;
            NSError *error;
            
            bson_init(&bsonCriteria);
            [[_mongoDatabase.mongoServer class] bsonFromJson:&bsonCriteria json:criteria error:&error];
            bson_finish(&bsonCriteria);
            if (error == nil) {
                mongo_remove(_mongoDatabase.mongo, [_absoluteCollectionName UTF8String], &bsonCriteria);
            } else {
                mongoQuery.error = error;
            }
            bson_destroy(&bsonCriteria);
        }
        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(removeCallback:)];
    }];
    [query.mutableParameters setObject:criteria forKey:@"criteria"];
    [query.mutableParameters setObject:self forKey:@"collection"];
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
