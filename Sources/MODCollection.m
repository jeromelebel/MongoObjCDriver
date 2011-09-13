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
    [_absoluteCollectionName release];
    [super dealloc];
}

- (void)findCallback:(MODQuery *)mongoQuery
{
    NSArray *result;
    
    result = [mongoQuery.parameters objectForKey:@"result"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryResultFetched:withMongoQuery:error:)]) {
        [_delegate mongoCollection:self queryResultFetched:result withMongoQuery:mongoQuery error:mongoQuery.error];
    }
}

- (MODQuery *)findWithQuery:(NSString *)jsonQuery fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(NSString *)sort
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSMutableArray *response;
        MODCursor *cursor;
        NSDictionary *document;
        NSError *error = nil;
        
        response = [[NSMutableArray alloc] initWithCapacity:limit];
        cursor = [self cursorWithQuery:jsonQuery fields:fields skip:skip limit:limit sort:sort];
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
    if (query) {
        [query.mutableParameters setObject:query forKey:@"query"];
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

- (MODCursor *)cursorWithQuery:(NSString *)query fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(NSString *)sort
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
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryCountWithValue:withMongoQuery:error:)]) {
        [_delegate mongoCollection:self queryCountWithValue:count withMongoQuery:mongoQuery error:mongoQuery.error];
    }
}

- (MODQuery *)countWithQuery:(NSString *)jsonQuery
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson *bsonQuery = NULL;
            NSError *error = nil;
            uint64_t count;
            
            bsonQuery = malloc(sizeof(*bsonQuery));
            bson_init(bsonQuery);
            if (jsonQuery) {
                [[_mongoDatabase.mongoServer class] bsonFromJson:bsonQuery json:jsonQuery error:&error];
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
    if (query) {
        [query.mutableParameters setObject:query forKey:@"query"];
    }
    [query.mutableParameters setObject:self forKey:@"collection"];
    return query;
}

- (void)insertCallback:(MODQuery *)mongoQuery
{
    if ([_delegate respondsToSelector:@selector(mongoCollection:insertWithMongoQuery:error:)]) {
        [_delegate mongoCollection:self insertWithMongoQuery:mongoQuery error:mongoQuery.error];
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
    if ([_delegate respondsToSelector:@selector(mongoCollection:updateWithMongoQuery:error:)]) {
        [_delegate mongoCollection:self updateWithMongoQuery:mongoQuery error:mongoQuery.error];
    }
}

- (MODQuery *)updateWithSelector:(NSString *)selector update:(NSString *)update upsert:(BOOL)upsert multiUpdate:(BOOL)multiUpdate
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson bsonSelector;
            bson bsonUpdate;
            NSError *error;
            
            bson_init(&bsonSelector);
            [[_mongoDatabase.mongoServer class] bsonFromJson:&bsonSelector json:selector error:&error];
            bson_finish(&bsonSelector);
            if (error == nil) {
                bson_init(&bsonUpdate);
                [[_mongoDatabase.mongoServer class] bsonFromJson:&bsonUpdate json:update error:&error];
                bson_finish(&bsonUpdate);
            }
            if (error == nil) {
                mongo_update(_mongoDatabase.mongo, [_absoluteCollectionName UTF8String], &bsonSelector, &bsonUpdate, (upsert?MONGO_UPDATE_UPSERT:0) | (multiUpdate?MONGO_UPDATE_MULTI:0));
            } else {
                mongoQuery.error = error;
            }
            bson_destroy(&bsonSelector);
            bson_destroy(&bsonUpdate);
        }
        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(updateCallback:)];
    }];
    [query.mutableParameters setObject:selector forKey:@"selector"];
    [query.mutableParameters setObject:update forKey:@"update"];
    [query.mutableParameters setObject:[NSNumber numberWithBool:upsert] forKey:@"upsert"];
    [query.mutableParameters setObject:[NSNumber numberWithBool:multiUpdate] forKey:@"multiUpdate"];
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

@end
