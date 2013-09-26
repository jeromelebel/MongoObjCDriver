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

static void testObjects(NSString *jsonToParse, NSString *jsonExpected, id shouldEqual)
{
    MODSortedMutableDictionary *objectsFromBson;
    NSError *error;
    id objects;
    bson bsonResult;
    
    if (!jsonExpected) {
        jsonExpected = jsonToParse;
    }
    bson_init(&bsonResult);
    [MODRagelJsonParser bsonFromJson:&bsonResult json:jsonToParse error:&error];
    bson_finish(&bsonResult);
    if (error) {
        NSLog(@"***** parsing errors for:");
        NSLog(@"%@", jsonToParse);
        NSLog(@"%@", error);
        assert(0);
    }
    objectsFromBson = [MODServer objectFromBson:&bsonResult];
    if (([shouldEqual isKindOfClass:[NSArray class]] && ![[objectsFromBson objectForKey:@"array"] isEqual:shouldEqual])
        || ([shouldEqual isKindOfClass:[MODSortedMutableDictionary class]] && ![objectsFromBson isEqual:shouldEqual])) {
        NSLog(@"***** problem to convert bson to objects:");
        NSLog(@"json: %@", jsonToParse);
        NSLog(@"expecting: %@", shouldEqual);
        NSLog(@"received: %@", objectsFromBson);
        NSLog(@"difference in: %@", [MODServer findAllDifferencesInObject1:shouldEqual object2:objectsFromBson]);
        assert(0);
    }
    bson_destroy(&bsonResult);
    objects = [MODRagelJsonParser objectsFromJson:jsonToParse error:&error];
    if (error) {
        NSLog(@"***** parsing errors for:");
        NSLog(@"%@", jsonToParse);
        NSLog(@"%@", error);
        assert(0);
    } else if (![objects isEqual:shouldEqual]) {
        NSLog(@"***** wrong result for:");
        NSLog(@"%@", jsonToParse);
        NSLog(@"expecting: %@", shouldEqual);
        NSLog(@"received: %@", objects);
        if ([objects isKindOfClass:[MODSortedMutableDictionary class]]) {
            for (NSString *key in [objects allKeys]) {
                if (![[objects objectForKey:key] isEqual:[shouldEqual objectForKey:key]]) {
                    NSLog(@"different value for %@", key);
                    NSLog(@"received %@ expected %@", [objects objectForKey:key], [shouldEqual objectForKey:key]);
                    NSLog(@"received %@ expected %@", [[objects objectForKey:key] class], [[shouldEqual objectForKey:key] class]);
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
        if (![jsonFromObjects isEqualToString:jsonExpected]) {
            NSLog(@"problem to convert objects to json %@", shouldEqual);
            NSLog(@"expecting: '%@'", jsonToParse);
            NSLog(@"received: '%@'", jsonFromObjects);
            assert([jsonFromObjects isEqualToString:jsonToParse]);
        }
    }
    NSLog(@"OK: %@", jsonToParse);
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
//    MODRagelJsonParser *parser;
    NSError *error;
//    id value;
    
    testObjects(@"{\"minkey\":{\"$minKey\":1}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODMinKey alloc] init] autorelease], @"minkey", nil]);
    testObjects(@"{\"maxkey\":{\"$maxKey\":1}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODMaxKey alloc] init] autorelease], @"maxkey", nil]);
    testObjects(@"{\"undefined\":{\"$undefined\":true}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODUndefined alloc] init] autorelease], @"undefined", nil]);
    testObjects(@"{\"minkey\":MinKey}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODMinKey alloc] init] autorelease], @"minkey", nil]);
    testObjects(@"{\"maxkey\":MaxKey}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODMaxKey alloc] init] autorelease], @"maxkey", nil]);
    testObjects(@"{\"undefined\":undefined}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODUndefined alloc] init] autorelease], @"undefined", nil]);
    testObjects(@"{\"number\":16.039199999999993906}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:16.039199999999994], @"number", nil]);
    testObjects(@"{\"number\":1.2345678909999999728}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:1.234567891], @"number", nil]);
    testObjects(@"{\"number\":3.8365551715863071018e-13}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:3.8365551715863071018e-13], @"number", nil]);
    testObjects(@"{\"data\":{\"$binary\":\"AA==\",\"$type\":\"0\"}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODBinary alloc] initWithBytes:"\0" length:1 binaryType:0] autorelease], @"data", nil]);
    testObjects(@"{\"data\":{\"$binary\":\"SmVyb21l\",\"$type\":\"0\"}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODBinary alloc] initWithBytes:"Jerome" length:6 binaryType:0] autorelease], @"data", nil]);
    testObjects(@"{\"not data\":{\"$type\":\"encore fred\"}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"encore fred", @"$type", nil], @"not data", nil]);
    testObjects(@"{\"_id\":\"x\",\"toto\":[1,2,3]}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:2], [NSNumber numberWithInt:3], nil], @"toto", nil]);
    testObjects(@"{\"_id\":\"x\",\"toto\":[{\"1\":2}]}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], nil], @"toto", nil]);
    testObjects(@"{\"_id\":{\"$oid\":\"4e9807f88157f608b4000002\"},\"type\":\"Activity\"}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODObjectId alloc] initWithCString:"4e9807f88157f608b4000002"] autorelease], @"_id", @"Activity", @"type", nil]);
    testObjects(@"{\"toto\":{\"$regex\":\"value\"},\"regexp\":{\"$regex\":\"value\",\"$options\":\"x\"}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODRegex alloc] initWithPattern:@"value" options:nil] autorelease], @"toto", [[[MODRegex alloc] initWithPattern:@"value" options:@"x"] autorelease], @"regexp", nil]);
    testObjects(@"{\"_id\":\"x\",\"toto\":[{\"1\":2},{\"2\":true}]}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"2", nil], nil], @"toto", nil]);
    testObjects(@"{\"toto\":1,\"empty_array\":[],\"type\":\"Activity\"}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"toto", [NSArray array], @"empty_array", @"Activity", @"type", nil]);
    testObjects(@"{\"empty_hash\":{},\"toto\":1,\"type\":\"Activity\"}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[MODSortedMutableDictionary sortedDictionary], @"empty_hash", [NSNumber numberWithInt:1], @"toto", @"Activity", @"type", nil]);
    testObjects(@"[{\"hello\":\"1\"},{\"zob\":\"2\"}]", nil, [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"1", @"hello", nil], [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"2", @"zob", nil], nil]);
    testObjects(@"{\"timestamp\":{\"$timestamp\":[1,2]}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODTimestamp alloc] initWithTValue:1 iValue:2] autorelease], @"timestamp", nil]);
    testObjects(@"{\"mydate\":{\"$date\":1320066612000.000000}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[NSDate alloc] initWithTimeIntervalSince1970:1320066612] autorelease], @"mydate", nil]);
    testObjects(@"{\"false\":false,\"true\":true}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"false", [NSNumber numberWithBool:YES], @"true", nil]);
    testObjects(@"{\"my symbol\":{\"$symbol\":\"pour fred\"}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODSymbol alloc] initWithValue:@"pour fred"] autorelease], @"my symbol", nil]);
    testObjects(@"{\"undefined value\":{\"$undefined\":\"$undefined\"}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODUndefined alloc] init] autorelease], @"undefined value", nil]);
    
    // test if can parse json in chunks, and we should get an error at the end of json
#if 0
    parser = [[MODRagelJsonParser alloc] init];
    parser.multiPartParsing = YES;
    [parser parseJsonWithString:@"{\"_id\":\"x\"" error:&error];
    assert(error == nil);
    [parser parseJsonWithString:@",\"toto\":[{\"1\":2}]}fdsa" error:&error];
    assert(parser.totalParsedLength == 28);
    assert(error != nil);
    assert([error code] == JSON_ERROR_UNEXPECTED_CHAR);
    assert([[error domain] isEqualToString:MODJsonErrorDomain]);
    value = [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], nil], @"toto", nil];
    assert([(id)[parser mainObject] isEqual:value]);
#endif
    
    // test to make sure each items in an array has the correct index
    // https://github.com/fotonauts/MongoHub-Mac/issues/28
    {
        bson bsonObject;
        
        bson_init(&bsonObject);
        [MODRagelJsonParser bsonFromJson:&bsonObject json:@"{ \"array\": [ 1, {\"x\": 1}, [ 1 ]] }" error:&error];
        bson_finish(&bsonObject);
        testBsonArrayIndex(&bsonObject);
        bson_destroy(&bsonObject);
    }
    
    // test to make sure each items in an array has the correct index
    // https://github.com/fotonauts/MongoHub-Mac/issues/39
    {
        id objects;
        bson bsonObject;
        
        objects = [MODRagelJsonParser objectsFromJson:@"{ \"array\": [ 1, {\"x\": 1}, [ 1 ]] }" error:&error];
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

static void runDatabaseTests(MODServer *server)
{
    MODDatabase *mongoDatabase;
    MODCollection *mongoCollection;
    MODCursor *cursor;
    
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

static void removeTestDatabaseAndRunTests(MODServer *server)
{
    [server dropDatabaseWithName:DATABASE_NAME_TEST callback:^(MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
        runDatabaseTests(server);
    }];
}

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        const char *ip;
        MODServer *server = nil;

        testBase64();
        testTypes();
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
            if ([list indexOfObject:DATABASE_NAME_TEST] != NSNotFound) {
                removeTestDatabaseAndRunTests(server);
            } else {
                runDatabaseTests(server);
            }
        }];
        
    }
    @autoreleasepool {
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}

