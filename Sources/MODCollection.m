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

- (MODQuery *)findWithQuery:(NSString *)jsonQuery fields:(NSArray *)fields skip:(NSUInteger)skip limit:(NSUInteger)limit sort:(NSString *)sort
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

- (MODCursor *)cursorWithQuery:(NSString *)query fields:(NSArray *)fields skip:(NSUInteger)skip limit:(NSUInteger)limit sort:(NSString *)sort
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
            int error;
            size_t totalProcessed;
            NSNumber *response;
            uint64_t count;
            
            bsonQuery = malloc(sizeof(*bsonQuery));
            bson_init(bsonQuery);
            bson_from_json(bsonQuery, "$query", [jsonQuery UTF8String], [jsonQuery length], &error, &totalProcessed);
            if (error == 0) {
                bson_finish(bsonQuery);
            } else {
                bson_finish(bsonQuery);
            }
            
            if (bsonQuery) {
                bson_destroy(bsonQuery);
                free(bsonQuery);
            }
            count = mongo_count(_mongoDatabase.mongoServer.mongo, [_mongoDatabase.databaseName UTF8String], [_collectionName UTF8String], bsonQuery);
            response = [[NSNumber alloc] initWithUnsignedLongLong:count];
            [mongoQuery.mutableParameters setObject:response forKey:@"count"];
            [response release];
        }
        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(findCallback:)];
    }];
    if (query) {
        [query.mutableParameters setObject:query forKey:@"query"];
    }
    [query.mutableParameters setObject:self forKey:@"collection"];
    return query;
}

- (void)updateCallback:(MODQuery *)mongoQuery
{
    [mongoQuery ends];
    if ([_delegate respondsToSelector:@selector(mongoCollection:updateDonwWithMongoQuery:error:)]) {
        [_delegate mongoCollection:self updateDonwWithMongoQuery:mongoQuery error:mongoQuery.error];
    }
}

//- (MODQuery *)updateWithQuery:(NSString *)jsonQuery fields:(NSString *)fields upset:(BOOL)upset
//{
//    MODQuery *query = nil;
//    
//    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        NSError *error;
//        
//        try {
//            if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
//                mongo::BSONObj criticalBSON = mongo::fromjson([jsonQuery UTF8String]);
//                mongo::BSONObj fieldsBSON = mongo::fromjson([[NSString stringWithFormat:@"{$set:%@}", fields] UTF8String]);
//                if (_mongoDatabase.mongoServer.replicaConnexion) {
//                    _mongoDatabase.mongoServer.replicaConnexion->update(std::string([_absoluteCollection UTF8String]), criticalBSON, fieldsBSON, (upset == YES)?true:false);
//                }else {
//                    _mongoDatabase.mongoServer.connexion->update(std::string([_absoluteCollection UTF8String]), criticalBSON, fieldsBSON, (upset == YES)?true:false);
//                }
//            }
//        } catch (mongo::DBException &e) {
//            error = [[NSString alloc] initWithUTF8String:e.what()];
//            [mongoQuery.mutableParameters setObject:error forKey:@"error"];
//            [error release];
//        }
//        [self performSelectorOnMainThread:@selector(updateCallback:) withObject:mongoQuery waitUntilDone:NO];
//    }];
//    [query.mutableParameters setObject:query forKey:@"query"];
//    [query.mutableParameters setObject:fields forKey:@"fields"];
//    [query.mutableParameters setObject:[NSNumber numberWithBool:upset] forKey:@"upset"];
//    [query.mutableParameters setObject:self forKey:@"collection"];
//    return query;
//}

//- (MODQuery *)saveJsonString:(NSString *)jsonString withRecordId:(NSString *)recordId
//{
//    MongoQuery *query = nil;
//    
//    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        NSError *error;
//        try {
//            if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
//                mongo::BSONObj fields = mongo::fromjson([jsonString UTF8String]);
//                mongo::BSONObj critical = mongo::fromjson([[NSString stringWithFormat:@"{\"_id\":%@}", recordId] UTF8String]);
//                
//                if (_mongoDatabase.mongoServer.replicaConnexion) {
//                    _mongoDatabase.mongoServer.replicaConnexion->update(std::string([_absoluteCollection UTF8String]), critical, fields, false);
//                }else {
//                    _mongoDatabase.mongoServer.connexion->update(std::string([_absoluteCollection UTF8String]), critical, fields, false);
//                }
//            }
//        } catch (mongo::DBException &e) {
//            error = [[NSString alloc] initWithUTF8String:e.what()];
//            [mongoQuery.mutableParameters setObject:error forKey:@"error"];
//            [error release];
//        }
//        [self performSelectorOnMainThread:@selector(updateCallback:) withObject:mongoQuery waitUntilDone:NO];
//    }];
//    [query.mutableParameters setObject:jsonString forKey:@"jsonstring"];
//    [query.mutableParameters setObject:recordId forKey:@"recordid"];
//    [query.mutableParameters setObject:self forKey:@"collection"];
//    return query;
//}

- (mongo *)mongo
{
    return _mongoDatabase.mongo;
}

- (MODServer *)mongoServer
{
    return _mongoDatabase.mongoServer;
}

@end
