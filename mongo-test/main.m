//
//  main.m
//  mongo-test
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOD_internal.h"

#define DATABASE_NAME_TEST @"database_test"
#define COLLECTION_NAME_TEST @"collection_test"

@interface MongoDelegate : NSObject<MODDatabaseDelegate, MODCollectionDelegate>
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

- (void)mongoServerConnectionFailed:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoServer:(MODServer *)mongoServer serverStatusFetched:(NSDictionary *)serverStatus withMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoServer:(MODServer *)mongoServer databaseListFetched:(NSArray *)list withMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase collectionCreatedWithMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase databaseStatsFetched:(NSArray *)databaseStats withMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase collectionListFetched:(NSArray *)collectionList withMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoCollection:(MODCollection *)collection queryResultFetched:(NSArray *)result withMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoCollection:(MODCollection *)collection queryCountWithValue:(long long)value withMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoCollection:(MODCollection *)collection insertWithMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoCollection:(MODCollection *)collection updateWithMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoCollection:(MODCollection *)collection removeCallback:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoDatabase:(MODDatabase *)mongoDatabase collectionDropedWithMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

- (void)mongoServer:(MODServer *)mongoServer databaseDropedWithMongoQuery:(MODQuery *)mongoQuery
{
    [self logQuery:mongoQuery fromSelector:_cmd];
}

@end

MongoDelegate *delegate;

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        const char *ip;
        MODServer *server;
        MODDatabase *mongoDatabase;
        MODCollection *mongoCollection;

        ip = argv[1];
        delegate = [[MongoDelegate alloc] init];
        server = [[MODServer alloc] init];
        [server autorelease];
        [server connectWithHostName:[NSString stringWithUTF8String:ip] callback:^(BOOL connected, MODQuery *mongoQuery) {
            if (connected) {
                [delegate mongoServerConnectionSucceded:server withMongoQuery:mongoQuery];
            } else {
                [delegate mongoServerConnectionFailed:server withMongoQuery:mongoQuery];
            }
        }];
        [server fetchServerStatusWithCallback:^(NSDictionary *serverStatus, MODQuery *mongoQuery) {
            [delegate mongoServer:server serverStatusFetched:serverStatus withMongoQuery:mongoQuery];
        }];
        [server fetchDatabaseListWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
            [delegate mongoServer:server databaseListFetched:list withMongoQuery:mongoQuery];
        }];
        
        mongoDatabase = [server databaseForName:DATABASE_NAME_TEST];
        mongoDatabase.delegate = delegate;
        [mongoDatabase fetchDatabaseStats];
        [mongoDatabase createCollectionWithName:COLLECTION_NAME_TEST];
        [mongoDatabase fetchCollectionList];
        
        mongoCollection = [mongoDatabase collectionForName:COLLECTION_NAME_TEST];
        mongoCollection.delegate = delegate;
        [mongoCollection findWithCriteria:@"{}" fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:5 sort:@"{ \"_id\" : 1 }"];
        [mongoCollection countWithCriteria:@"{ \"_id\" : \"com-fotopedia-burma\" }"];
        [mongoCollection countWithCriteria:nil];
        [mongoCollection insertWithDocuments:[NSArray arrayWithObjects:@"{ \"_id\" : \"toto\" }", nil]];
        [mongoCollection findWithCriteria:nil fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:100 sort:nil];
        [mongoCollection updateWithCriteria:@"{\"_id\": \"toto\"}" update:@"{\"$inc\": {\"x\" : 1}}" upsert:NO multiUpdate:NO];
        [mongoCollection saveWithDocument:@"{\"_id\": \"toto\", \"y\": null}"];
        [mongoCollection findWithCriteria:@"{\"_id\": \"toto\"}" fields:nil skip:1 limit:5 sort:@"{ \"_id\" : 1 }"];
        [mongoCollection removeWithCriteria:@"{\"_id\": \"toto\"}"];
        
        [mongoDatabase dropCollectionWithName:COLLECTION_NAME_TEST];
        [server dropDatabaseWithName:DATABASE_NAME_TEST callback:^(MODQuery *mongoQuery) {
            [delegate mongoServer:server databaseDropedWithMongoQuery:mongoQuery];
        }];
        
    }
    @autoreleasepool {
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}

