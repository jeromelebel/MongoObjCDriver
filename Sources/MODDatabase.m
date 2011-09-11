//
//  MODDatabase.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODDatabase

@synthesize delegate = _delegate, mongoServer = _mongoServer, databaseName = _databaseName, userName = _userName, password = _password;

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

- (void)mongoOperationDidFinish:(MODQuery *)mongoQuery withCallback:(SEL)callbackSelector
{
    [mongoQuery ends];
    if (self.mongoServer.mongo->err != MONGO_CONN_SUCCESS) {
        [mongoQuery.mutableParameters setObject:[NSNumber numberWithInt:self.mongoServer.mongo->err] forKey:@"error"];
    }
    if (self.mongoServer.mongo->errstr) {
        [mongoQuery.mutableParameters setObject:[NSString stringWithUTF8String:self.mongoServer.mongo->errstr] forKey:@"error"];
    }
    [self performSelectorOnMainThread:callbackSelector withObject:mongoQuery waitUntilDone:NO];
}

- (void)fetchDatabaseStatsCallback:(MODQuery *)mongoQuery
{
    NSArray *databaseStats;
    NSString *databaseName;
    
    databaseName = [mongoQuery.parameters objectForKey:@"databasename"];
    databaseStats = [mongoQuery.parameters objectForKey:@"databasestats"];
    if ([_delegate respondsToSelector:@selector(mongoDatabase:databaseStatsFetched:withMongoQuery:error:)]) {
        [_delegate mongoDatabase:self databaseStatsFetched:databaseStats withMongoQuery:mongoQuery error:mongoQuery.error];
    }
}

- (MODQuery *)fetchDatabaseStats
{
    MODQuery *query;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery){
        if ([self.mongoServer authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            bson output;
            
            if (mongo_simple_int_command(self.mongoServer.mongo, [_databaseName UTF8String], "dbstats", 1, &output) == MONGO_OK) {
                [mongoQuery.mutableParameters setObject:[[self.mongoServer class] objectsFromBson:&output] forKey:@"databasestats"];
                bson_destroy(&output);
            }
        }
        [_mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(fetchDatabaseStatsCallback:)];
    }];
    return query;
}

- (void)fetchCollectionListCallback:(MODQuery *)mongoQuery
{
    NSArray *collectionList;
    
    collectionList = [mongoQuery.parameters objectForKey:@"collectionlist"];
    if ([_delegate respondsToSelector:@selector(mongoDatabase:collectionListFetched:withMongoQuery:error:)]) {
        [_delegate mongoDatabase:self collectionListFetched:collectionList withMongoQuery:mongoQuery error:mongoQuery.error];
    }
}

- (MODQuery *)fetchCollectionList
{
    MODQuery *query;
    
    query = [self.mongoServer addQueryInQueue:^(MODQuery *mongoQuery){
        if ([self.mongoServer authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            char command[256];
            mongo_cursor cursor[1];
            NSMutableArray *collections;
            
            snprintf(command, sizeof(command), "%s.system.namespaces", [_databaseName UTF8String]);
            mongo_cursor_init(cursor, self.mongoServer.mongo, command);
            
            collections = [[NSMutableArray alloc] init];
            while (mongo_cursor_next(cursor) == MONGO_OK) {
                NSString *collection;
                
                collection = [[[self.mongoServer class] objectsFromBson:&cursor->current] objectForKey:@"name"];
                if ([collection rangeOfString:@"$"].location == NSNotFound) {
                    [collections addObject:[collection substringFromIndex:[_databaseName length] + 1]];
                }
            }
            [mongoQuery.mutableParameters setObject:collections forKey:@"collectionlist"];
            mongo_cursor_destroy(cursor);
            [collections release];
        }
        [_mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(fetchCollectionListCallback:)];
    }];
    return query;
}

- (MODCollection *)collectionForName:(NSString *)name
{
    MODCollection *result;
    
    result = [[MODCollection alloc] initWithMongoDatabase:self collectionName:name];
    return result;
}

- (mongo *)mongo
{
    return _mongoServer.mongo;
}

@end
