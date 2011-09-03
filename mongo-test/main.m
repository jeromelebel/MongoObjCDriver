//
//  main.m
//  mongo-test
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MODServer.h"
#import "MODQuery.h"
#import "MOD_internal.h"

MODServer *server;

@interface MongoDelegate : NSObject<MODServerDelegate, MODDatabaseDelegate>
- (void)mongoServerConnectionSucceded:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery;
- (void)mongoServerConnectionFailed:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
@end

@implementation MongoDelegate

- (void)logQuery:(MODQuery *)query fromSelector:(SEL)selector
{
    NSLog(@"%@ %@", NSStringFromSelector(selector), query.parameters);
}

- (void)mongoServerConnectionSucceded:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoServerConnectionFailed:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoServer:(MODServer *)mongoServer serverStatusFetched:(NSArray *)serverStatus withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoServer:(MODServer *)mongoServer databaseListFetched:(NSArray *)list withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    MODDatabase *database;
    
    [self logQuery:mongoQuery fromSelector:_cmd];
    database = [mongoServer databaseForName:[list objectAtIndex:0]];
    database.delegate = self;
    [database fetchDatabaseStats];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase databaseStatsFetched:(NSArray *)databaseStats withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

@end

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        MongoDelegate *delegate;
        const char *ip;

        ip = argv[1];
        delegate = [[MongoDelegate alloc] init];
        server = [[MODServer alloc] init];
        server.delegate = delegate;
        [server connectWithHostName:[NSString stringWithUTF8String:ip] databaseName:nil userName:nil password:nil];
        [server fetchServerStatus];
        [server fetchDatabaseList];
        
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}

