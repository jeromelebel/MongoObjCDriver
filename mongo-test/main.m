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

void logMongoQuery(MODQuery *mongoQuery);

void logMongoQuery(MODQuery *mongoQuery)
{
    if (mongoQuery.error) {
        NSLog(@"********* ERROR ************");
        NSLog(@"%@", mongoQuery.error);
    }
    NSLog(@"%@", mongoQuery.parameters);
}

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        const char *ip;
        MODServer *server;
        MODDatabase *mongoDatabase;
        MODCollection *mongoCollection;

        ip = argv[1];
        server = [[MODServer alloc] init];
        [server autorelease];
        [server connectWithHostName:[NSString stringWithUTF8String:ip] callback:^(BOOL connected, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [server fetchServerStatusWithCallback:^(NSDictionary *serverStatus, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [server fetchDatabaseListWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        
        mongoDatabase = [server databaseForName:DATABASE_NAME_TEST];
        [mongoDatabase fetchDatabaseStatsWithCallback:^(NSDictionary *stats, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoDatabase createCollectionWithName:COLLECTION_NAME_TEST callback:^(MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoDatabase fetchCollectionListWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        
        mongoCollection = [mongoDatabase collectionForName:COLLECTION_NAME_TEST];
        [mongoCollection findWithCriteria:@"{}" fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:5 sort:@"{ \"_id\" : 1 }" callback:^(NSArray *documents, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection countWithCriteria:@"{ \"_id\" : \"com-fotopedia-burma\" }" callback:^(int64_t count, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection countWithCriteria:nil callback:^(int64_t count, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection insertWithDocuments:[NSArray arrayWithObjects:@"{ \"_id\" : \"toto\" }", nil] callback:^(MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection findWithCriteria:nil fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:100 sort:nil callback:^(NSArray *documents, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection updateWithCriteria:@"{\"_id\": \"toto\"}" update:@"{\"$inc\": {\"x\" : 1}}" upsert:NO multiUpdate:NO callback:^(MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection saveWithDocument:@"{\"_id\": \"toto\", \"y\": null}" callback:^(MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection findWithCriteria:@"{\"_id\": \"toto\"}" fields:nil skip:1 limit:5 sort:@"{ \"_id\" : 1 }" callback:^(NSArray *documents, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection removeWithCriteria:@"{\"_id\": \"toto\"}" callback:^(MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        
        [mongoDatabase dropCollectionWithName:COLLECTION_NAME_TEST callback:^(MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [server dropDatabaseWithName:DATABASE_NAME_TEST callback:^(MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        
    }
    @autoreleasepool {
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}

