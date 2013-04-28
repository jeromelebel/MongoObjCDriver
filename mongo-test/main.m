//
//  main.m
//  mongo-test
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOD_internal.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"

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
    MODSortedMutableDictionary *document;
    MODBinary *binary;
    NSData *data;
    bson myBson;
    bson_oid_t bsonOid;
    MODObjectId *objectOid;
    const char *oid = "4e9807f88157f608b4000002";
    
    document = [[MODSortedMutableDictionary alloc] init];
    
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
    MODSortedMutableDictionary *objectsFromBson;
    NSError *error;
    id objects;
    bson bsonResult;
    
    bson_init(&bsonResult);
    [MODJsonToBsonParser bsonFromJson:&bsonResult json:json error:&error];
    bson_finish(&bsonResult);
    if (error) {
        NSLog(@"***** parsing errors for:");
        NSLog(@"%@", json);
        NSLog(@"%@", error);
        assert(0);
    }
    objectsFromBson = [MODServer objectFromBson:&bsonResult];
    if (([shouldEqual isKindOfClass:[NSArray class]] && ![[objectsFromBson objectForKey:@"array"] isEqual:shouldEqual])
        || ([shouldEqual isKindOfClass:[MODSortedMutableDictionary class]] && ![objectsFromBson isEqual:shouldEqual])) {
        NSLog(@"***** problem to convert bson to objects:");
        NSLog(@"json: %@", json);
        NSLog(@"expecting: %@", shouldEqual);
        NSLog(@"received: %@", objectsFromBson);
        assert(0);
    }
    bson_destroy(&bsonResult);
    objects = [MODJsonToObjectParser objectsFromJson:json error:&error];
    if (error) {
        NSLog(@"***** parsing errors for:");
        NSLog(@"%@", json);
        NSLog(@"%@", error);
        assert(0);
    } else if (![objects isEqual:shouldEqual]) {
        NSLog(@"***** wrong result for:");
        NSLog(@"%@", json);
        NSLog(@"expecting: %@", shouldEqual);
        NSLog(@"received: %@", objects);
        if ([objects isKindOfClass:[MODSortedMutableDictionary class]]) {
            for (NSString *key in [objects allKeys]) {
                if (![[objects objectForKey:key] isEqual:[shouldEqual objectForKey:key]]) {
                    NSLog(@"different value for %@", key);
                }
            }
        }
        assert(0);
    }
    assert(error == nil);
    assert([objects isEqual:shouldEqual]);
    
    if ([shouldEqual isKindOfClass:[MODSortedMutableDictionary class]]) {
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

static void testBsonArrayIndex(bson *bsonObject)
{
    bson_iterator iterator;
    bson_iterator subIterator;
    unsigned int ii = 0;
    
    bson_iterator_init(&iterator, bsonObject);
    
    assert(bson_iterator_next(&iterator) != BSON_EOO);
    assert(strcmp(bson_iterator_key(&iterator), "array") == 0);
    
    bson_iterator_subiterator(&iterator, &subIterator);
    while (bson_iterator_next(&subIterator) != BSON_EOO) {
        assert(ii == atoi(bson_iterator_key(&subIterator)));
        ii++;
    }
    assert(ii == 3);
    
    assert(bson_iterator_next(&iterator) == BSON_EOO);
}

static void testJson()
{
    MODJsonToObjectParser *parser;
    NSError *error;
    id value;
    
    testObjects(@"{\"data\":BinData(0,\":\"AA==\")}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODBinary alloc] initWithBytes:"\0" length:1 binaryType:0] autorelease], @"data", nil]);
    testObjects(@"{\"data\":{\"$binary\":\"SmVyb21l\",\"$type\":\"0\"}}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODBinary alloc] initWithBytes:"Jerome" length:6 binaryType:0] autorelease], @"data", nil]);
    testObjects(@"{\"not data\":{\"$type\":\"encore fred\"}}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"encore fred", @"$type", nil], @"not data", nil]);
    testObjects(@"{\"_id\":\"x\",\"toto\":[1,2,3]}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:2], [NSNumber numberWithInt:3], nil], @"toto", nil]);
    testObjects(@"{\"_id\":\"x\",\"toto\":[{\"1\":2}]}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], nil], @"toto", nil]);
    testObjects(@"{\"_id\":{\"$oid\":\"4e9807f88157f608b4000002\"},\"type\":\"Activity\"}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODObjectId alloc] initWithCString:"4e9807f88157f608b4000002"] autorelease], @"_id", @"Activity", @"type", nil]);
    testObjects(@"{\"toto\":{\"$regex\":\"value\"},\"regexp\":{\"$regex\":\"value\",\"$options\":\"x\"}}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODRegex alloc] initWithPattern:@"value" options:nil] autorelease], @"toto", [[[MODRegex alloc] initWithPattern:@"value" options:@"x"] autorelease], @"regexp", nil]);
    testObjects(@"{\"_id\":\"x\",\"toto\":[{\"1\":2},{\"2\":true}]}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"2", nil], nil], @"toto", nil]);
    testObjects(@"{\"toto\":1,\"empty_array\":[],\"type\":\"Activity\"}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"toto", [NSArray array], @"empty_array", @"Activity", @"type", nil]);
    testObjects(@"{\"empty_hash\":{},\"toto\":1,\"type\":\"Activity\"}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[MODSortedMutableDictionary sortedDictionary], @"empty_hash", [NSNumber numberWithInt:1], @"toto", @"Activity", @"type", nil]);
    testObjects(@"[{\"hello\":\"1\"},{\"zob\":\"2\"}]", [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"1", @"hello", nil], [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"2", @"zob", nil], nil]);
    testObjects(@"{\"timestamp\":{\"$timestamp\":[1,2]}}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODTimestamp alloc] initWithTValue:1 iValue:2] autorelease], @"timestamp", nil]);
    testObjects(@"{\"mydate\":{\"$date\":1320066612000.000000}}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[NSDate alloc] initWithTimeIntervalSince1970:1320066612] autorelease], @"mydate", nil]);
    testObjects(@"{\"false\":false,\"true\":true}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"false", [NSNumber numberWithBool:YES], @"true", nil]);
    testObjects(@"{\"my symbol\":{\"$symbol\":\"pour fred\"}}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODSymbol alloc] initWithValue:@"pour fred"] autorelease], @"my symbol", nil]);
    testObjects(@"{\"undefined value\":{\"$undefined\":\"$undefined\"}}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODUndefined alloc] init] autorelease], @"undefined value", nil]);
    
    // test if can parse json in chunks, and we should get an error at the end of json
    parser = [[MODJsonToObjectParser alloc] init];
    parser.multiPartParsing = YES;
    [parser parseJsonWithString:@"{\"_id\":\"x\"" error:&error];
    assert(error == nil);
    [parser parseJsonWithString:@",\"toto\":[{\"1\":2}]}fdsa" error:&error];
    assert(parser.totalParsedLength == 28);
    assert(error != nil);
    NSLog(@"[error code] %ld", [error code]);
//    assert([error code] == JSON_ERROR_UNEXPECTED_CHAR);
    assert([[error domain] isEqualToString:MODJsonErrorDomain]);
    value = [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], nil], @"toto", nil];
    assert([(id)[parser mainObject] isEqual:value]);
    
    // test to make sure each items in an array has the correct index
    // https://github.com/fotonauts/MongoHub-Mac/issues/28
    {
        bson bsonObject;
        
        bson_init(&bsonObject);
        [MODJsonToBsonParser bsonFromJson:&bsonObject json:@"{ \"array\": [ 1, {\"x\": 1}, [ 1 ]] }" error:&error];
        bson_finish(&bsonObject);
        testBsonArrayIndex(&bsonObject);
        bson_destroy(&bsonObject);
    }
    
    // test to make sure each items in an array has the correct index
    // https://github.com/fotonauts/MongoHub-Mac/issues/39
    {
        id objects;
        bson bsonObject;
        
        objects = [MODJsonToObjectParser objectsFromJson:@"{ \"array\": [ 1, {\"x\": 1}, [ 1 ]] }" error:&error];
        bson_init(&bsonObject);
        [MODServer appendObject:objects toBson:&bsonObject];
        bson_finish(&bsonObject);
        testBsonArrayIndex(&bsonObject);
        bson_destroy(&bsonObject);
    }
}

static void testNSDataInBase64(NSData *dataToConvert, const char *base64)
{
    NSString *base64String;
    
    base64String = [NSString stringWithUTF8String:base64];
    if (![[dataToConvert base64String] isEqualToString:base64String]) {
        NSLog(@"***** Problem to encode base 64");
        NSLog(@"trying to encode %@", dataToConvert);
        NSLog(@"expecting %s", base64);
        NSLog(@"received %@", [dataToConvert base64String]);
        assert(false);
    }
    if (![[base64String dataFromBase64] isEqualToData:dataToConvert]) {
        NSLog(@"***** Problem to decode base 64");
        NSLog(@"trying to decode %s", base64);
        NSLog(@"expecting %@", dataToConvert);
        NSLog(@"received %@", [base64String dataFromBase64]);
        assert(false);
    }
}

static void testStringInBase64(const char *string, const char *base64)
{
    testNSDataInBase64([NSData dataWithBytes:string length:strlen(string)], base64);
}

static void testDataInBase64(const char *data, NSUInteger length, const char *base64)
{
    testNSDataInBase64([NSData dataWithBytes:data length:length], base64);
}

static void testBase64(void)
{
    testDataInBase64("\0", 1, "AA==");
    testStringInBase64("1", "MQ==");
    testStringInBase64("12", "MTI=");
    testStringInBase64("123", "MTIz");
    testStringInBase64("1234", "MTIzNA==");
    testStringInBase64("12345", "MTIzNDU=");
    testStringInBase64("123456", "MTIzNDU2");
}

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        const char *ip;
        MODServer *server;
        MODDatabase *mongoDatabase;
        MODCollection *mongoCollection;
        MODCursor *cursor;

        testBase64();
        //testTypes();
        testJson();
        if (argc != 2) {
            NSLog(@"need to put the ip a of a mongo server as a parameter, so we can test the objective-c driver");
            exit(1);
        }
        ip = argv[1];
        server = [[MODServer alloc] init];
        [server connectWithHostName:[NSString stringWithUTF8String:ip] callback:^(BOOL connected, MODQuery *mongoQuery) {
            NSLog(@"connecting to %s…", ip);
            logMongoQuery(mongoQuery);
        }];
        [server fetchServerStatusWithCallback:^(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [server fetchDatabaseListWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        
        mongoDatabase = [server databaseForName:DATABASE_NAME_TEST];
        [mongoDatabase fetchDatabaseStatsWithCallback:^(MODSortedMutableDictionary *stats, MODQuery *mongoQuery) {
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
        [cursor forEachDocumentWithCallbackDocumentCallback:^(uint64_t index, MODSortedMutableDictionary *document) {
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

