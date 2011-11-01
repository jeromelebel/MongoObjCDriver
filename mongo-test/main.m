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
    assert(mongoQuery.error == nil);
}

static void testTypes(void)
{
    NSMutableDictionary *document;
    MODBinary *binary;
    NSData *data;
    bson myBson;
    bson_oid_t bsonOid;
    MODObjectId *objectOid;
    const char *oid = "4E9807F88157F608B4000002";
    
    document = [[NSMutableDictionary alloc] init];
    
    data = [[NSData alloc] initWithBytes:"1234567890" length:10];
    binary = [[MODBinary alloc] initWithData:data binaryType:0];
    [document setObject:binary forKey:@"binary"];
    [data release];
    [binary release];
    
    bson_init(&myBson);
    [MODServer appendObject:document toBson:&myBson];
    bson_finish(&myBson);
    
    if (![document isEqualTo:[MODServer objectFromBson:&myBson]]) {
        NSLog(@"********* ERROR ************");
    }
    bson_destroy(&myBson);
    
    bson_oid_from_string(&bsonOid, oid);
    objectOid = [[MODObjectId alloc] initWithOid:&bsonOid];
    if (strcmp(oid, [[objectOid stringValue] UTF8String]) != 0) {
        NSLog(@"error with objectid, expecting %s, recieved %s", oid, [[objectOid stringValue] UTF8String]);
    }
    assert(strcmp(oid, [[objectOid stringValue] UTF8String]) == 0);
    [objectOid release];
    
    [document release];
}

static void testObjects(NSString *json, id shouldEqual)
{
    NSError *error;
    id objects;
    
    objects = [MODJsonToObjectParser objectsFromJson:json error:&error];
    if (error) {
        NSLog(@"***** parsing errors for:");
        NSLog(@"%@", json);
        NSLog(@"%@", error);
    } else if (![objects isEqual:shouldEqual]) {
        NSLog(@"***** wrong result for:");
        NSLog(@"%@", json);
        NSLog(@"expecting: %@", shouldEqual);
        NSLog(@"received: %@", objects);
        if ([objects isKindOfClass:[NSDictionary class]]) {
            for (NSString *key in [objects allKeys]) {
                if (![[objects objectForKey:key] isEqual:[shouldEqual objectForKey:key]]) {
                    NSLog(@"different value for %@", key);
                }
            }
        }
    }
    assert(error == nil);
    assert([objects isEqual:shouldEqual]);
    
    if ([shouldEqual isKindOfClass:[NSDictionary class]]) {
        NSString *jsonFromObjects;
        
        jsonFromObjects = [MODServer convertObjectToJson:shouldEqual pretty:NO];
        if (![jsonFromObjects isEqualToString:json]) {
            NSLog(@"problem to convert objects to json %@", shouldEqual);
            NSLog(@"expecting: '%@'", json);
            NSLog(@"received: '%@'", jsonFromObjects);
            assert([jsonFromObjects isEqualToString:json]);
        }
    }
    NSLog(@"OK: %@", json);
}

static void testJson()
{
    testObjects(@"{\"_id\":{\"$oid\":\"4E9807F88157F608B4000002\"},\"type\":\"Activity\"}", [NSDictionary dictionaryWithObjectsAndKeys:[[[MODObjectId alloc] initWithCString:"4E9807F88157F608B4000002"] autorelease], @"_id", @"Activity", @"type", nil]);
    testObjects(@"{\"regexp\":{\"$regex\":\"value\",\"$options\":\"x\"},\"toto\":{\"$regex\":\"value\"}}", [NSDictionary dictionaryWithObjectsAndKeys:[[[MODRegex alloc] initWithPattern:@"value" options:nil] autorelease], @"toto", [[[MODRegex alloc] initWithPattern:@"value" options:@"x"] autorelease], @"regexp", nil]);
    testObjects(@"{\"_id\":\"x\",\"toto\":[{\"1\":2}]}", [NSDictionary dictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], nil], @"toto", nil]);
    testObjects(@"{\"_id\":\"x\",\"toto\":[{\"1\":2},{\"2\":true}]}", [NSDictionary dictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"2", nil], nil], @"toto", nil]);
    testObjects(@"{\"empty_array\":[],\"toto\":1,\"type\":\"Activity\"}", [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"toto", [NSArray array], @"empty_array", @"Activity", @"type", nil]);
    testObjects(@"{\"empty_hash\":{},\"toto\":1,\"type\":\"Activity\"}", [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"toto", [NSDictionary dictionary], @"empty_hash", @"Activity", @"type", nil]);
    testObjects(@"[{\"hello\":\"1\"},{\"zob\":\"2\"}]", [NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"1", @"hello", nil], [NSDictionary dictionaryWithObjectsAndKeys:@"2", @"zob", nil], nil]);
    testObjects(@"{\"timestamp\":{\"$timestamp\":[1,2]}}", [NSDictionary dictionaryWithObjectsAndKeys:[[[MODTimestamp alloc] initWithTValue:1 iValue:2] autorelease], @"timestamp", nil]);
    testObjects(@"{\"mydate\":{\"$date\":1320066612000.000000}}", [NSDictionary dictionaryWithObjectsAndKeys:[[[NSDate alloc] initWithTimeIntervalSince1970:1320066612] autorelease], @"mydate", nil]);
}

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        const char *ip;
        MODServer *server;
        MODDatabase *mongoDatabase;
        MODCollection *mongoCollection;
        MODCursor *cursor;

        //testTypes();
        testJson();
        if (argc != 2) {
            NSLog(@"need to put the ip a of a mongo server as a parameter, so we can test the objective-c driver");
            exit(1);
        }
        ip = argv[1];
        server = [[MODServer alloc] init];
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
        [mongoCollection findWithCriteria:@"{}" fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:5 sort:@"{ \"_id\": 1 }" callback:^(NSArray *documents, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection countWithCriteria:@"{ \"_id\": \"xxx\" }" callback:^(int64_t count, MODQuery *mongoQuery) {
            assert(count == 0);
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection countWithCriteria:nil callback:^(int64_t count, MODQuery *mongoQuery) {
            assert(count == 0);
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection insertWithDocuments:[NSArray arrayWithObjects:@"{ \"_id\": \"toto\" }", nil] callback:^(MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection insertWithDocuments:[NSArray arrayWithObjects:@"{ \"_id\": \"toto1\" }", @"{ \"_id\": { \"$oid\": \"123456789012345678901234\" } }", nil] callback:^(MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection countWithCriteria:nil callback:^(int64_t count, MODQuery *mongoQuery) {
            assert(count == 3);
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection countWithCriteria:@"{ \"_id\": \"toto\" }" callback:^(int64_t count, MODQuery *mongoQuery) {
            assert(count == 1);
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection findWithCriteria:nil fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:100 sort:nil callback:^(NSArray *documents, MODQuery *mongoQuery) {
            assert([documents count] == 2);
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection findWithCriteria:nil fields:nil skip:0 limit:0 sort:nil callback:^(NSArray *documents, MODQuery *mongoQuery) {
            assert([documents count] == 3);
            logMongoQuery(mongoQuery);
        }];
        cursor = [mongoCollection cursorWithCriteria:nil fields:nil skip:0 limit:0 sort:nil];
        [cursor forEachDocumentWithCallbackDocumentCallback:^(uint64_t index, NSDictionary *document) {
            NSLog(@"++++ %@", document);
            return YES;
        } endCallback:^(uint64_t count, BOOL stopped, MODQuery *query) {
            NSLog(@"++++ ");
            logMongoQuery(query);
        }];
        [mongoCollection updateWithCriteria:@"{\"_id\": \"toto\"}" update:@"{\"$inc\": {\"x\": 1}}" upsert:NO multiUpdate:NO callback:^(MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection saveWithDocument:@"{\"_id\": \"toto\", \"y\": null}" callback:^(MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [mongoCollection findWithCriteria:@"{\"_id\": \"toto\"}" fields:nil skip:1 limit:5 sort:@"{ \"_id\": 1 }" callback:^(NSArray *documents, MODQuery *mongoQuery) {
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
            NSLog(@"Everything is cool");
            exit(0);
        }];
        [server release];
    }
    @autoreleasepool {
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}

