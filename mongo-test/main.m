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

@interface MongoDelegate : NSObject<MODServerDelegate>
- (void)mongoDBConnectionSucceded:(MODServer *)mongoDB withMongoQuery:(MODQuery *)mongoQuery;
- (void)mongoDBConnectionFailed:(MODServer *)mongoDB withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
@end

@implementation MongoDelegate

- (void)logQuery:(MODQuery *)query fromSelector:(SEL)selector
{
    NSLog(@"%@ %@", NSStringFromSelector(selector), query.parameters);
}

- (void)mongoDBConnectionSucceded:(MODServer *)mongoDB withMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDBConnectionFailed:(MODServer *)mongoDB withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDB:(MODServer *)mongoDB databaseListFetched:(NSArray *)list withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDB:(MODServer *)mongoDB serverStatusFetched:(NSArray *)serverStatus withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

@end

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        MODServer *server;
        MongoDelegate *delegate;
        const char *ip;

        ip = argv[1];
        delegate = [[MongoDelegate alloc] init];
        server = [[MODServer alloc] init];
        server.delegate = delegate;
        [server connectWithHostName:[NSString stringWithUTF8String:ip] databaseName:nil userName:nil password:nil];
        [server fetchDatabaseList];
        
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}

