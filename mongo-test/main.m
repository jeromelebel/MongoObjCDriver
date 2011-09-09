//
//  main.m
//  mongo-test
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOD_internal.h"

bson *bson_from_json(const char *json, size_t length, int *error, size_t *totalProcessed);

MODServer *server;

@interface MongoDelegate : NSObject<MODServerDelegate, MODDatabaseDelegate, MODCollectionDelegate>
- (void)mongoServerConnectionSucceded:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery;
- (void)mongoServerConnectionFailed:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error;
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

- (void)mongoServerConnectionFailed:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoServer:(MODServer *)mongoServer serverStatusFetched:(NSArray *)serverStatus withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoServer:(MODServer *)mongoServer databaseListFetched:(NSArray *)list withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    NSString *databaseName;
    MODDatabase *database;
    
    [self logQuery:mongoQuery fromSelector:_cmd];
    databaseName = [list objectAtIndex:1];
    databaseName = @"ios_support";
    database = [mongoServer databaseForName:databaseName];
    NSLog(@"database: %@", database.databaseName);
    database.delegate = self;
    [database fetchDatabaseStats];
    [database fetchCollectionList];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase databaseStatsFetched:(NSArray *)databaseStats withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase collectionListFetched:(NSArray *)collectionList withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    NSString *collectionName;
    MODCollection *collection;
    
    [self logQuery:mongoQuery fromSelector:_cmd];
    collectionName = [collectionList objectAtIndex:0];
    collectionName = @"ios_applications";
    collection = [mongoDatabase collectionForName:collectionName];
    collection.delegate = self;
    [collection findWithQuery:@"{}" fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:5 sort:@"{ \"_id\" : 1 }"];
    [collection countWithQuery:@"{}"];
}

- (void)mongoCollection:(MODCollection *)collection queryResultFetched:(NSArray *)result withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoCollection:(MODCollection *)collection queryCountWithValue:(long long)value withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
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
        [server connectWithHostName:[NSString stringWithUTF8String:ip]];
        [server fetchServerStatus];
        [server fetchDatabaseList];
        
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}

