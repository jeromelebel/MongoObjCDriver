//
//  MODDatabase.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODDatabase

@synthesize delegate = _delegate, server = _server, databaseName = _databaseName, userName = _userName, password = _password;

- (void)mongoOperationDidFinish:(MODQuery *)mongoQuery withCallback:(SEL)callbackSelector
{
    [mongoQuery ends];
    if (self.server.mongo->err != MONGO_CONN_SUCCESS) {
        [mongoQuery.mutableParameters setObject:[NSNumber numberWithInt:self.server.mongo->err] forKey:@"error"];
    }
    if (self.server.mongo->errstr) {
        [mongoQuery.mutableParameters setObject:[NSString stringWithUTF8String:self.server.mongo->errstr] forKey:@"errormessage"];
    }
    [self performSelectorOnMainThread:callbackSelector withObject:mongoQuery waitUntilDone:NO];
}

- (void)fetchDatabaseStatsCallback:(MODQuery *)mongoQuery
{
    NSArray *databaseStats;
    NSString *databaseName;
    
    databaseName = [mongoQuery.parameters objectForKey:@"databasename"];
    databaseStats = [mongoQuery.parameters objectForKey:@"databasestats"];
    if ([_delegate respondsToSelector:@selector(mongoDatabase:databaseStatsFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoDatabase:self databaseStatsFetched:databaseStats withMongoQuery:mongoQuery errorMessage:[mongoQuery.parameters objectForKey:@"errormessage"]];
    }
}

- (MODQuery *)fetchDatabaseStats
{
    MODQuery *query;
    
    query = [self.server addQueryInQueue:^(MODQuery *mongoQuery){
        if ([self.server authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            bson output;
            
            if (mongo_simple_int_command(self.server.mongo, [_databaseName UTF8String], "dbstats", 1, &output) == MONGO_OK) {
                [mongoQuery.mutableParameters setObject:[[self.server class] objectsFromBson:&output] forKey:@"databasestats"];
                bson_destroy(&output);
            }
        }
        [self mongoOperationDidFinish:mongoQuery withCallback:@selector(fetchDatabaseStatsCallback:)];
    }];
    return query;
}

- (void)fetchCollectionListCallback:(MODQuery *)mongoQuery
{
    NSArray *collectionList;
    
    collectionList = [mongoQuery.parameters objectForKey:@"collectionlist"];
    if ([_delegate respondsToSelector:@selector(mongoDatabase:collectionListFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoDatabase:self collectionListFetched:collectionList withMongoQuery:mongoQuery errorMessage:[mongoQuery.parameters objectForKey:@"errormessage"]];
    }
}

- (MODQuery *)fetchCollectionList
{
    MODQuery *query;
    
    query = [self.server addQueryInQueue:^(MODQuery *mongoQuery){
        if ([self.server authenticateSynchronouslyWithDatabaseName:_databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            char command[256];
            mongo_cursor cursor[1];
            NSMutableArray *collections;
            
            snprintf(command, sizeof(command), "%s.system.namespaces", [_databaseName UTF8String]);
            mongo_cursor_init(cursor, self.server.mongo, command);
            
            collections = [[NSMutableArray alloc] init];
            while (mongo_cursor_next(cursor) == MONGO_OK) {
                NSString *collection;
                
                collection = [[[self.server class] objectsFromBson:&cursor->current] objectForKey:@"name"];
                if ([collection rangeOfString:@"$"].location == NSNotFound) {
                    [collections addObject:[collection substringFromIndex:[_databaseName length] + 1]];
                }
            }
            [mongoQuery.mutableParameters setObject:collections forKey:@"collectionlist"];
            mongo_cursor_destroy(cursor);
            [collections release];
        }
        [self mongoOperationDidFinish:mongoQuery withCallback:@selector(fetchCollectionListCallback:)];
    }];
    return query;
}

@end
