//
//  MODDatabase.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODDatabase

@synthesize mongoServer = _mongoServer, databaseName = _databaseName, userName = _userName, password = _password;

- (id)initWithMongoServer:(MODServer *)mongoServer databaseName:(NSString *)databaseName
{
    if (self = [self init]) {
        _mongoServer = [mongoServer retain];
        _databaseName = [databaseName retain];
    }
    return self;
}

- (void)dealloc
{
    [_mongoServer release];
    [_databaseName release];
    [super dealloc];
}

- (BOOL)authenticateSynchronouslyWithMongoQuery:(MODQuery *)mongoQuery
{
    return [_mongoServer authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery];
}

- (BOOL)authenticateSynchronouslyWithError:(NSError **)error
{
    return [_mongoServer authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password error:error];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withCallbackBlock:(void (^)(void))callbackBlock
{
    [mongoQuery.mutableParameters setObject:self forKey:@"mongodatabase"];
    [_mongoServer mongoQueryDidFinish:mongoQuery withCallbackBlock:callbackBlock];
}

- (MODQuery *)fetchDatabaseStatsWithCallback:(void (^)(MODSortedMutableDictionary *databaseStats, MODQuery *mongoQuery))callback;
{
    MODQuery *query;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery){
        MODSortedMutableDictionary *stats = nil;
        
        if (!mongoQuery.canceled && [self.mongoServer authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            bson output = { NULL, 0 };
            
            if (mongo_simple_int_command(self.mongoServer.mongo, [_databaseName UTF8String], "dbstats", 1, &output) == MONGO_OK) {
                stats = [[self.mongoServer class] objectFromBson:&output];
                [mongoQuery.mutableParameters setObject:stats forKey:@"databasestats"];
            }
            bson_destroy(&output);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            if (callback) {
                callback(stats, mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"fetchdatabasestats" forKey:@"command"];
    return query;
}

- (MODQuery *)fetchCollectionListWithCallback:(void (^)(NSArray *collectionList, MODQuery *mongoQuery))callback;
{
    MODQuery *query;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery){
        NSMutableArray *collections = nil;
        
        if (!mongoQuery.canceled && [self.mongoServer authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            char command[256];
            mongo_cursor cursor[1];
            
            snprintf(command, sizeof(command), "%s.system.namespaces", [_databaseName UTF8String]);
            mongo_cursor_init(cursor, self.mongoServer.mongo, command);
            
            collections = [[NSMutableArray alloc] init];
            while (mongo_cursor_next(cursor) == MONGO_OK) {
                NSString *collection;
                
                collection = [[[self.mongoServer class] objectFromBson:&cursor->current] objectForKey:@"name"];
                if ([collection rangeOfString:@"$"].location == NSNotFound) {
                    [collections addObject:[collection substringFromIndex:[_databaseName length] + 1]];
                }
            }
            [mongoQuery.mutableParameters setObject:collections forKey:@"collectionlist"];
            mongo_cursor_destroy(cursor);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            if (callback) {
                callback(collections, mongoQuery);
            }
        }];
        [collections release];
    }];
    [query.mutableParameters setObject:@"fetchcollectionlist" forKey:@"command"];
    return query;
}

- (MODCollection *)collectionForName:(NSString *)name
{
    return [[[MODCollection alloc] initWithMongoDatabase:self collectionName:name] autorelease];
}

- (MODQuery *)createCollectionWithName:(NSString *)collectionName callback:(void (^)(MODQuery *mongoQuery))callback;
{
    MODQuery *query;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery){
        if (!mongoQuery.canceled && [self.mongoServer authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            mongo_cmd_create_collection(self.mongoServer.mongo, [_databaseName UTF8String], [collectionName UTF8String]);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            if (callback) {
                callback(mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"createcollection" forKey:@"command"];
    [query.mutableParameters setObject:collectionName forKey:@"collectionname"];
    return query;
}

- (MODQuery *)createCappedCollectionWithName:(NSString *)collectionName capSize:(int64_t)capSize callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery){
        if (!mongoQuery.canceled && [self.mongoServer authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            mongo_cmd_create_capped_collection(self.mongoServer.mongo, [_databaseName UTF8String], [collectionName UTF8String], capSize);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            if (callback) {
                callback(mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"createcappedcollection" forKey:@"command"];
    [query.mutableParameters setObject:collectionName forKey:@"collectionname"];
    [query.mutableParameters setObject:[NSNumber numberWithLongLong:capSize] forKey:@"capsize"];
    return query;
}

- (MODQuery *)dropCollectionWithName:(NSString *)collectionName callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery){
        if (!mongoQuery.canceled && [self.mongoServer authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            mongo_cmd_drop_collection(self.mongoServer.mongo, [_databaseName UTF8String], [collectionName UTF8String]);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            if (callback) {
                callback(mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"dropcollection" forKey:@"command"];
    [query.mutableParameters setObject:collectionName forKey:@"collectionname"];
    return query;
}

- (mongo *)mongo
{
    return _mongoServer.mongo;
}

@end
