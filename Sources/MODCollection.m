//
//  MODCollection.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

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
    NSString *errorMessage;
    
    [mongoQuery ends];
    result = [mongoQuery.parameters objectForKey:@"result"];
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryResultFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoCollection:self queryResultFetched:result withMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

//- (MODQuery *)findWithQuery:(NSString *)jsonQuery fields:(NSString *)fields skip:(int)skip limit:(int)limit sort:(NSString *)sort
//{
//    MODQuery *query = nil;
//    
//    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        NSMutableArray *response;
//        NSString *errorMessage = nil;
//        NSString *oid = nil;
//        NSString *oidType = nil;
//        NSString *jsonString = nil;
//        NSString *jsonStringb = nil;
//        NSMutableArray *repArr = nil;
//        NSMutableArray *oriArr = nil;
//        NSMutableDictionary *item = nil;
//        
//        response = [[NSMutableArray alloc] initWithCapacity:limit];
//            if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
//                mongo::BSONObj queryBSON = mongo::fromjson([jsonQuery UTF8String]);
//                mongo::BSONObj sortBSON = mongo::fromjson([sort UTF8String]);
//                mongo::BSONObj fieldsToReturn;
//                
//                if ([fields length] > 0) {
//                    NSArray *keys = [fields componentsSeparatedByString:@","];
//                    
//                    mongo::BSONObjBuilder builder;
//                    for (NSString *str in keys) {
//                        builder.append([str UTF8String], 1);
//                    }
//                    fieldsToReturn = builder.obj();
//                }
//                
//                std::auto_ptr<mongo::DBClientCursor> cursor;
//                if (_mongoDatabase.mongoServer.replicaConnexion) {
//                    cursor = _mongoDatabase.mongoServer.replicaConnexion->query(std::string([_absoluteCollectionName UTF8String]), mongo::Query(queryBSON).sort(sortBSON), limit, skip, &fieldsToReturn);
//                } else {
//                    cursor = _mongoDatabase.mongoServer.connexion->query(std::string([_absoluteCollectionName UTF8String]), mongo::Query(queryBSON).sort(sortBSON), limit, skip, &fieldsToReturn);
//                }
//                while (cursor->more()) {
//                    mongo::BSONObj b = cursor->next();
//                    mongo::BSONElement e;
//                    b.getObjectID (e);
//                    
//                    if (e.type() == mongo::jstOID) {
//                        oidType = @"ObjectId";
//                        [oid release];
//                        oid = [[NSString alloc] initWithUTF8String:e.__oid().str().c_str()];
//                    } else {
//                        oidType = @"String";
//                        [oid release];
//                        oid = [[NSString alloc] initWithUTF8String:e.str().c_str()];
//                    }
//                    [jsonString release];
//                    jsonString = [[NSString alloc] initWithUTF8String:b.jsonString(mongo::TenGen).c_str()];
//                    [jsonStringb release];
//                    jsonStringb = [[NSString alloc] initWithUTF8String:b.jsonString(mongo::TenGen, 1).c_str()];
//                    if (jsonString == nil) {
//                        jsonString = [@"" retain];
//                    }
//                    if (jsonStringb == nil) {
//                        jsonStringb = [@"" retain];
//                    }
//                    [repArr release];
//                    repArr = [[NSMutableArray alloc] initWithCapacity:4];
//                    id regx2 = [RKRegex regexWithRegexString:@"(Date\\(\\s\\d+\\s\\))" options:RKCompileCaseless];
//                    RKEnumerator *matchEnumerator2 = [jsonString matchEnumeratorWithRegex:regx2];
//                    while([matchEnumerator2 nextRanges] != NULL) {
//                        NSString *enumeratedStr=NULL;
//                        [matchEnumerator2 getCapturesWithReferences:@"$1", &enumeratedStr, nil];
//                        [repArr addObject:enumeratedStr];
//                    }
//                    [oriArr release];
//                    oriArr = [[NSMutableArray alloc] initWithCapacity:4];
//                    id regx = [RKRegex regexWithRegexString:@"(Date\\(\\s+\"[^^]*?\"\\s+\\))" options:RKCompileCaseless];
//                    RKEnumerator *matchEnumerator = [jsonStringb matchEnumeratorWithRegex:regx];
//                    while([matchEnumerator nextRanges] != NULL) {
//                        NSString *enumeratedStr=NULL;
//                        [matchEnumerator getCapturesWithReferences:@"$1", &enumeratedStr, nil];
//                        [oriArr addObject:enumeratedStr];
//                    }
//                    for (unsigned int i=0; i<[repArr count]; i++) {
//                        NSString *old;
//                        
//                        old = jsonStringb;
//                        jsonStringb = [[jsonStringb stringByReplacingOccurrencesOfString:[oriArr objectAtIndex:i] withString:[repArr objectAtIndex:i]] retain];
//                        [old release];
//                    }
//                    [item release];
//                    item = [[NSMutableDictionary alloc] initWithCapacity:6];
//                    [item setObject:@"_id" forKey:@"name"];
//                    [item setObject:oidType forKey:@"type"];
//                    [item setObject:oid forKey:@"value"];
//                    [item setObject:jsonString forKey:@"raw"];
//                    [item setObject:jsonStringb forKey:@"beautified"];
//                    [item setObject:[[_mongoDatabase.mongoServer class] bsonDictWrapper:b] forKey:@"child"];
//                    [response addObject:item];
//                }
//                [mongoQuery.mutableParameters setObject:response forKey:@"result"];
//            }
//        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(findCallback:)];
//        [response release];
//        [oid release];
//        [jsonString release];
//        [jsonStringb release];
//        [repArr release];
//        [oriArr release];
//        [item release];
//    }];
//    [query.mutableParameters setObject:query forKey:@"query"];
//    [query.mutableParameters setObject:fields forKey:@"fields"];
//    [query.mutableParameters setObject:[NSNumber numberWithInt:skip] forKey:@"skip"];
//    [query.mutableParameters setObject:[NSNumber numberWithInt:limit] forKey:@"limit"];
//    [query.mutableParameters setObject:sort forKey:@"sort"];
//    [query.mutableParameters setObject:self forKey:@"collection"];
//    return query;
//}

- (void)countCallback:(MODQuery *)mongoQuery
{
    long long int count;
    NSString *errorMessage;
    
    [mongoQuery ends];
    count = [[mongoQuery.parameters objectForKey:@"count"] longLongValue];
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryCountWithValue:withMongoQuery:errorMessage:)]) {
        [_delegate mongoCollection:self queryCountWithValue:count withMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

//- (MODQuery *)countWithQuery:(NSString *)jsonQuery
//{
//    MODQuery *query = nil;
//    
//    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        NSString *errorMessage;
//        
//        try {
//            if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
//                long long int value;
//                NSNumber *count;
//                
//                mongo::BSONObj criticalBSON = mongo::fromjson([jsonQuery UTF8String]);
//                
//                if (_mongoDatabase.mongoServer.replicaConnexion) {
//                    value = _mongoDatabase.mongoServer.replicaConnexion->count(std::string([_absoluteCollectionName UTF8String]), criticalBSON);
//                }else {
//                    value = _mongoDatabase.mongoServer.connexion->count(std::string([_absoluteCollectionName UTF8String]), criticalBSON);
//                }
//                count = [[NSNumber alloc] initWithLongLong:value];
//                [mongoQuery.mutableParameters setObject:count forKey:@"count"];
//                [count release];
//            }
//        } catch (mongo::DBException &e) {
//            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
//            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
//            [errorMessage release];
//        }
//        [self performSelectorOnMainThread:@selector(countCallback:) withObject:mongoQuery waitUntilDone:NO];
//    }];
//    [query.mutableParameters setObject:query forKey:@"query"];
//    [query.mutableParameters setObject:self forKey:@"collection"];
//    return query;
//}

- (void)updateCallback:(MODQuery *)mongoQuery
{
    NSString *errorMessage;
    
    [mongoQuery ends];
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:updateDonwWithMongoQuery:errorMessage:)]) {
        [_delegate mongoCollection:self updateDonwWithMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

//- (MODQuery *)updateWithQuery:(NSString *)jsonQuery fields:(NSString *)fields upset:(BOOL)upset
//{
//    MODQuery *query = nil;
//    
//    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        NSString *errorMessage;
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
//            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
//            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
//            [errorMessage release];
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
//        NSString *errorMessage;
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
//            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
//            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
//            [errorMessage release];
//        }
//        [self performSelectorOnMainThread:@selector(updateCallback:) withObject:mongoQuery waitUntilDone:NO];
//    }];
//    [query.mutableParameters setObject:jsonString forKey:@"jsonstring"];
//    [query.mutableParameters setObject:recordId forKey:@"recordid"];
//    [query.mutableParameters setObject:self forKey:@"collection"];
//    return query;
//}

@end
