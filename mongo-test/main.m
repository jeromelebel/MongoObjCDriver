//
//  main.m
//  mongo-test
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOD_internal.h"

MODServer *server;

#define DATABASE_NAME_TEST @"database_test"
#define COLLECTION_NAME_TEST @"collection_test"

@interface MongoDelegate : NSObject<MODServerDelegate, MODDatabaseDelegate, MODCollectionDelegate>
- (void)mongoServerConnectionSucceded:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery;
- (void)mongoServerConnectionFailed:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error;
@end

@implementation MongoDelegate

- (void)logQuery:(MODQuery *)mongoQuery fromSelector:(SEL)selector
{
    if (mongoQuery.error) {
        NSLog(@"********* ERROR ************");
        NSLog(@"%@", mongoQuery.error);
    }
    NSLog(@"%@ %@", NSStringFromSelector(selector), mongoQuery.parameters);
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
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase databaseStatsFetched:(NSArray *)databaseStats withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase collectionListFetched:(NSArray *)collectionList withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoCollection:(MODCollection *)collection queryResultFetched:(NSArray *)result withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoCollection:(MODCollection *)collection queryCountWithValue:(long long)value withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoCollection:(MODCollection *)collection insertWithMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoCollection:(MODCollection *)collection updateWithMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoCollection:(MODCollection *)collection removeCallback:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase collectionDropedWithMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

@end

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        MongoDelegate *delegate;
        const char *ip;
        MODDatabase *mongoDatabase;
        MODCollection *mongoCollection;

        ip = argv[1];
        delegate = [[MongoDelegate alloc] init];
        server = [[MODServer alloc] init];
        server.delegate = delegate;
        [server connectWithHostName:[NSString stringWithUTF8String:ip]];
        [server fetchServerStatus];
        [server fetchDatabaseList];
        
        mongoDatabase = [server databaseForName:DATABASE_NAME_TEST];
        NSLog(@"database: %@", mongoDatabase.databaseName);
        mongoDatabase.delegate = delegate;
        [mongoDatabase fetchDatabaseStats];
        [mongoDatabase fetchCollectionList];
        
        mongoCollection = [mongoDatabase collectionForName:COLLECTION_NAME_TEST];
        mongoCollection.delegate = delegate;
        [mongoCollection findWithQuery:@"{}" fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:5 sort:@"{ \"_id\" : 1 }"];
        [mongoCollection countWithQuery:@"{ \"_id\" : \"com-fotopedia-burma\" }"];
        [mongoCollection countWithQuery:nil];
        [mongoCollection insertWithDocuments:[NSArray arrayWithObjects:@"{ \"_id\" : \"toto\" }", nil]];
        [mongoCollection findWithQuery:nil fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:100 sort:nil];
        [mongoCollection updateWithCriteria:@"{\"_id\": \"toto\"}" update:@"{\"$inc\": {\"x\" : 1}}" upsert:NO multiUpdate:NO];
        [mongoCollection saveWithDocument:@"{\"_id\": \"toto\", \"y\": null}"];
        [mongoCollection findWithQuery:@"{\"_id\": \"toto\"}" fields:nil skip:1 limit:5 sort:@"{ \"_id\" : 1 }"];
        [mongoCollection removeWithCriteria:@"{\"_id\": \"toto\"}"];
        
        [mongoDatabase dropCollectionWithName:COLLECTION_NAME_TEST];
        [server dropDatabaseWithName:DATABASE_NAME_TEST];
        
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}

