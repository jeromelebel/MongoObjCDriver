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

@end
