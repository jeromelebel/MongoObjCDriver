//
//  main.m
//  mongo-test
//
//  Created by Jérôme Lebel on 02/09/2011.
//

#import <Foundation/Foundation.h>
#import "MOD_internal.h"
#import "NSData+Base64.h"
#import "NSString+Base64.h"
#import "MODBsonComparator.h"
#import "MODDocumentComparator.h"

#define DATABASE_NAME_TEST @"database_test"
#define COLLECTION_NAME_TEST @"collection_test"

void logMongoQuery(MODQuery *mongoQuery);

void logMongoQuery(MODQuery *mongoQuery)
{
    if (mongoQuery.error) {
        NSLog(@"********* ERROR ************");
        NSLog(@"%@", mongoQuery.error);
    }
    if (mongoQuery.name == nil) {
        NSLog(@"********* ERROR ************");
        NSLog(@"Need to set the command name in the query parameters of mongo query");
    }
    NSLog(@"%@ %@", mongoQuery.name, mongoQuery.parameters);
    assert(mongoQuery.name != nil);
    assert(mongoQuery.error == nil);
}

static void testTypes(void)
{
    MODSortedMutableDictionary *document;
    MODBinary *binary;
    NSData *data;
    bson_t myBson = BSON_INITIALIZER;
    bson_oid_t bsonOid;
    MODObjectId *objectOid;
    const char *oid = "4e9807f88157f608b4000002";
    
    document = [[MODSortedMutableDictionary alloc] init];
    
    data = [[NSData alloc] initWithBytes:"1234567890" length:10];
    binary = [[MODBinary alloc] initWithData:data binaryType:0];
    [document setObject:binary forKey:@"binary"];
    [data release];
    [binary release];
    
    [MODClient appendObject:document toBson:&myBson];
    
    if (![document isEqualTo:[MODClient objectFromBson:&myBson]]) {
        NSLog(@"********* ERROR ************");
    }
    bson_destroy(&myBson);
    
    bson_oid_init_from_string(&bsonOid, oid);
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
    bson_t bsonResult = BSON_INITIALIZER;
    
    if (!jsonExpected) {
        jsonExpected = jsonToParse;
    }
    [MODRagelJsonParser bsonFromJson:&bsonResult json:jsonToParse error:&error];
    if (error) {
        NSLog(@"***** parsing errors for:");
        NSLog(@"%@", jsonToParse);
        NSLog(@"%@", error);
        assert(0);
    }
    objectsFromBson = [MODClient objectFromBson:&bsonResult];
    if (([shouldEqual isKindOfClass:[NSArray class]] && ![[objectsFromBson objectForKey:@"array"] isEqual:shouldEqual])
        || ([shouldEqual isKindOfClass:[MODSortedMutableDictionary class]] && ![objectsFromBson isEqual:shouldEqual])) {
        NSLog(@"***** problem to convert bson to objects:");
        NSLog(@"json: %@", jsonToParse);
        NSLog(@"expecting: %@", shouldEqual);
        NSLog(@"received: %@", objectsFromBson);
        NSLog(@"difference in: %@", [MODClient findAllDifferencesInObject1:shouldEqual object2:objectsFromBson]);
        assert(0);
    }
    bson_destroy(&bsonResult);
    objects = [MODRagelJsonParser objectsFromJson:jsonToParse withError:&error];
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
        
        jsonFromObjects = [MODClient convertObjectToJson:shouldEqual pretty:NO strictJson:NO];
        if (![jsonFromObjects isEqualToString:jsonExpected]) {
            NSLog(@"problem to convert objects to json %@", shouldEqual);
            NSLog(@"expecting: '%@'", jsonToParse);
            NSLog(@"received: '%@'", jsonFromObjects);
            assert([jsonFromObjects isEqualToString:jsonToParse]);
        }
    }
    NSLog(@"OK: %@", jsonToParse);
    if (jsonExpected != jsonToParse) {
        testObjects(jsonExpected, nil, shouldEqual);
    }
}

static void testBsonArrayIndex(bson_t *bsonObject)
{
    bson_iter_t iterator;
    bson_iter_t subIterator;
    unsigned int ii = 0;
    
    bson_iter_init(&iterator, bsonObject);
    
    assert(bson_iter_next(&iterator));
    assert(strcmp(bson_iter_key(&iterator), "array") == 0);
    
    bson_iter_recurse(&iterator, &subIterator);
    while (bson_iter_next(&subIterator)) {
        assert(ii == atoi(bson_iter_key(&subIterator)));
        ii++;
    }
    assert(ii == 3);
    
    assert(bson_iter_next(&iterator) == false);
}

static void testJson()
{
    NSError *error;
  
    // more digit for the json, but that's ok
    testObjects(@"{\"scopefunction\":{\"$function\":\"\\\"javascript function\\\"\",\"$scope\":{\"x\":\"\\\"\"}}}", @"{\"scopefunction\":ScopeFunction(\"\\\"javascript function\\\"\",{\"x\":\"\\\"\"})}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODScopeFunction alloc] initWithFunction:@"\"javascript function\"" scope:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"\"", @"x", nil]] autorelease], @"scopefunction", nil]);
    testObjects(@"{\"function\":{\"$function\":\"\\\"javascript function\\\"\"}}", @"{\"function\":Function(\"\\\"javascript function\\\"\")}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODFunction alloc] initWithFunction:@"\"javascript function\""] autorelease], @"function", nil]);
    testObjects(@"{\"scopefunction\":{\"$function\":\"javascript function\",\"$scope\":{\"x\":1}}}", @"{\"scopefunction\":ScopeFunction(\"javascript function\",{\"x\":1})}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODScopeFunction alloc] initWithFunction:@"javascript function" scope:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"x", nil]] autorelease], @"scopefunction", nil]);
    testObjects(@"{\"function\":{\"$function\":\"javascript function\"}}", @"{\"function\":Function(\"javascript function\")}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODFunction alloc] initWithFunction:@"javascript function"] autorelease], @"function", nil]);
    testObjects(@"{\"my symbol\":{\"$symbol\":\"pour fred\"}}", @"{\"my symbol\":Symbol(\"pour fred\")}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODSymbol alloc] initWithValue:@"pour fred"] autorelease], @"my symbol", nil]);
    testObjects(@"{\"date\":new Date(396361048820)}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:396361048.820], @"date", nil]);
    testObjects(@"{int:1}", @"{\"int\":1}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"int", nil]);
    testObjects(@"{$value:1}", @"{\"$value\":1}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"$value", nil]);
    testObjects(@"{\"number\":0.7868957519531251}", @"{\"number\":0.78689575195312511102}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:0.7868957519531251], @"number", nil]);
    testObjects(@"{\"number\":0.786895751953125}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:0.786895751953125], @"number", nil]);
    testObjects(@"{\"int\":1}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"int", nil]);
    testObjects(@"{\"double\":1.0}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:1], @"double", nil]);
    testObjects(@"{\"longlong\":NumberLong(1)}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithLongLong:1], @"longlong", nil]);
    testObjects(@"{\"int\":1}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"int", nil]);
    testObjects(@"{\"date\":new Date(0)}", @"{\"date\":new Date(\"1970-01-01T01:00:00+0100\")}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:0], @"date", nil]);
    testObjects(@"{'_id':'hello'}", @"{\"_id\":\"hello\"}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"hello", @"_id", nil]);
    testObjects(@"{\"_id\":ObjectId(\"4e9807f88157f608b4000002\"),\"type\":\"Activity\"}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODObjectId alloc] initWithCString:"4e9807f88157f608b4000002"] autorelease], @"_id", @"Activity", @"type", nil]);
    testObjects(@"{\"someDate\":new Date(1384297199999)}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:1384297199.999], @"someDate", nil]);
    testObjects(@"{\"someDate\":new Date(1384297199000)}", @"{\"someDate\":new Date(\"2013-11-12T23:59:59+0100\")}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:1384297199], @"someDate", nil]);
    testObjects(@"{\"minkey\":{\"$minKey\":1}}", @"{\"minkey\":MinKey}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODMinKey alloc] init] autorelease], @"minkey", nil]);
    testObjects(@"{\"maxkey\":{\"$maxKey\":1}}", @"{\"maxkey\":MaxKey}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODMaxKey alloc] init] autorelease], @"maxkey", nil]);
    testObjects(@"{\"undefined\":{\"$undefined\":true}}", @"{\"undefined\":undefined}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODUndefined alloc] init] autorelease], @"undefined", nil]);
    testObjects(@"{\"number\":16.039199999999993906}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:16.039199999999994], @"number", nil]);
    testObjects(@"{\"number\":1.2345678909999999728}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:1.234567891], @"number", nil]);
    testObjects(@"{\"number\":3.8365551715863071018e-13}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:3.8365551715863071018e-13], @"number", nil]);
    testObjects(@"{\"data\":{\"$binary\":\"AA==\",\"$type\":\"0\"}}", @"{\"data\":BinData(0,\"AA==\")}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODBinary alloc] initWithBytes:"\0" length:1 binaryType:0] autorelease], @"data", nil]);
    testObjects(@"{\"data\":{\"$binary\":\"SmVyb21l\",\"$type\":\"0\"}}", @"{\"data\":BinData(0,\"SmVyb21l\")}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODBinary alloc] initWithBytes:"Jerome" length:6 binaryType:0] autorelease], @"data", nil]);
    testObjects(@"{\"not data\":{\"$type\":\"encore fred\"}}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"encore fred", @"$type", nil], @"not data", nil]);
    testObjects(@"{\"_id\":\"x\",\"toto\":[1,2,3]}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:2], [NSNumber numberWithInt:3], nil], @"toto", nil]);
    testObjects(@"{\"_id\":\"x\",\"toto\":[{\"1\":2}]}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], nil], @"toto", nil]);
    testObjects(@"{\"_id\":{\"$oid\":\"4e9807f88157f608b4000002\"},\"type\":\"Activity\"}", @"{\"_id\":ObjectId(\"4e9807f88157f608b4000002\"),\"type\":\"Activity\"}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODObjectId alloc] initWithCString:"4e9807f88157f608b4000002"] autorelease], @"_id", @"Activity", @"type", nil]);
    testObjects(@"{\"toto\":{\"$regex\":\"value\"},\"regexp\":{\"$regex\":\"value\",\"$options\":\"x\"}}", @"{\"toto\":/value/,\"regexp\":/value/x}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODRegex alloc] initWithPattern:@"value" options:nil] autorelease], @"toto", [[[MODRegex alloc] initWithPattern:@"value" options:@"x"] autorelease], @"regexp", nil]);
    testObjects(@"{\"_id\":\"x\",\"toto\":[{\"1\":2},{\"2\":true}]}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"2", nil], nil], @"toto", nil]);
    testObjects(@"{\"toto\":1,\"empty_array\":[],\"type\":\"Activity\"}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"toto", [NSArray array], @"empty_array", @"Activity", @"type", nil]);
    testObjects(@"{\"empty_hash\":{},\"toto\":1,\"type\":\"Activity\"}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[MODSortedMutableDictionary sortedDictionary], @"empty_hash", [NSNumber numberWithInt:1], @"toto", @"Activity", @"type", nil]);
    testObjects(@"[{\"hello\":\"1\"},{\"zob\":\"2\"}]", nil, [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"1", @"hello", nil], [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"2", @"zob", nil], nil]);
    testObjects(@"{\"timestamp\":{\"$timestamp\":[1,2]}}", @"{\"timestamp\":Timestamp(1, 2)}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[MODTimestamp alloc] initWithTValue:1 iValue:2] autorelease], @"timestamp", nil]);
    testObjects(@"{\"mydate\":{\"$date\":1320066612000}}", @"{\"mydate\":new Date(\"2011-10-31T14:10:12+0100\")}", [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[[NSDate alloc] initWithTimeIntervalSince1970:1320066612] autorelease], @"mydate", nil]);
    testObjects(@"{\"false\":false,\"true\":true}", nil, [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"false", [NSNumber numberWithBool:YES], @"true", nil]);
    
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
    // https://github.com/jeromelebel/MongoHub-Mac/issues/28
    {
        bson_t bsonObject = BSON_INITIALIZER;
        
        [MODRagelJsonParser bsonFromJson:&bsonObject json:@"{ \"array\": [ 1, {\"x\": 1}, [ 1 ]] }" error:&error];
        testBsonArrayIndex(&bsonObject);
        bson_destroy(&bsonObject);
    }
    
    // test to make sure each items in an array has the correct index
    // https://github.com/jeromelebel/MongoHub-Mac/issues/39
    {
        id objects;
        bson_t bsonObject = BSON_INITIALIZER;
        
        objects = [MODRagelJsonParser objectsFromJson:@"{ \"array\": [ 1, {\"x\": 1}, [ 1 ]] }" withError:&error];
        bson_init(&bsonObject);
        [MODClient appendObject:objects toBson:&bsonObject];
        testBsonArrayIndex(&bsonObject);
        bson_destroy(&bsonObject);
    }
}

static void testNSDataInBase64(NSData *dataToConvert, const char *base64)
{
    NSString *base64String;
    
    base64String = [NSString stringWithUTF8String:base64];
    if (![dataToConvert.mod_base64String isEqualToString:base64String]) {
        NSLog(@"***** Problem to encode base 64");
        NSLog(@"trying to encode %@", dataToConvert);
        NSLog(@"expecting %s", base64);
        NSLog(@"received %@", dataToConvert.mod_base64String);
        assert(false);
    }
    if (![base64String.mod_base64String isEqualToData:dataToConvert]) {
        NSLog(@"***** Problem to decode base 64");
        NSLog(@"trying to decode %s", base64);
        NSLog(@"expecting %@", dataToConvert);
        NSLog(@"received %@", base64String.mod_base64String);
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

static MODSortedMutableDictionary *obj(NSString *json)
{
    NSError *error;
    MODSortedMutableDictionary *result;
    
    result = [MODRagelJsonParser objectsFromJson:json withError:&error];
    assert(error == nil);
    return result;
}

static void runDatabaseTests(MODClient *server)
{
    MODDatabase *mongoDatabase;
    MODCollection *mongoCollection;
    MODCursor *cursor;

    mongoDatabase = [server databaseForName:DATABASE_NAME_TEST];
    [mongoDatabase statsWithReadPreferences:nil callback:^(MODSortedMutableDictionary *stats, MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    [server databaseNamesWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
        assert([list indexOfObject:DATABASE_NAME_TEST] != NSNotFound);
    }];
    [mongoDatabase createCollectionWithName:COLLECTION_NAME_TEST callback:^(MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    [mongoDatabase collectionNamesWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    
    mongoCollection = [mongoDatabase collectionForName:COLLECTION_NAME_TEST];
    [mongoCollection findWithCriteria:obj(@"{}") fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:5 sort:obj(@"{ \"_id\": 1 }") callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection countWithCriteria:obj(@"{ \"_id\": \"xxx\" }") readPreferences:nil callback:^(int64_t count, MODQuery *mongoQuery) {
        assert(count == 0);
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection countWithCriteria:nil readPreferences:nil callback:^(int64_t count, MODQuery *mongoQuery) {
        assert(count == 0);
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection insertWithDocuments:[NSArray arrayWithObjects:@"{ \"_id\": \"toto\" }", nil] callback:^(MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection insertWithDocuments:[NSArray arrayWithObjects:@"{ \"_id\": \"toto1\" }", @"{ \"_id\": { \"$oid\": \"123456789012345678901234\" } }", nil] callback:^(MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection countWithCriteria:nil readPreferences:nil callback:^(int64_t count, MODQuery *mongoQuery) {
        assert(count == 3);
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection countWithCriteria:obj(@"{ \"_id\": \"toto\" }") readPreferences:nil callback:^(int64_t count, MODQuery *mongoQuery) {
        assert(count == 1);
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection findWithCriteria:nil fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:100 sort:nil callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        assert([documents count] == 2);
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection findWithCriteria:nil fields:nil skip:0 limit:0 sort:nil callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
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
    [mongoCollection updateWithCriteria:obj(@"{\"_id\": \"toto\"}") update:obj(@"{\"$inc\": {\"x\": 1}}") upsert:NO multiUpdate:NO callback:^(MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection saveWithDocument:obj(@"{\"_id\": \"toto\", \"y\": null}") callback:^(MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection findWithCriteria:obj(@"{\"_id\": \"toto\"}") fields:nil skip:1 limit:5 sort:obj(@"{ \"_id\": 1 }") callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection removeWithCriteria:obj(@"{\"_id\": \"toto\"}") callback:^(MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    [mongoCollection findWithCriteria:obj(@"{\"_id\": \"toto\"}") fields:nil skip:1 limit:5 sort:obj(@"{ \"_id\": 1 }") callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        assert(documents.count == 0);
        logMongoQuery(mongoQuery);
    }];

    [mongoCollection dropWithCallback:^(MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    [mongoDatabase collectionNamesWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
        assert([collectionList indexOfObject:COLLECTION_NAME_TEST] == NSNotFound);
    }];
    
    [mongoDatabase dropWithCallback:^(MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
    }];
    
    [server databaseNamesWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
        assert([list indexOfObject:DATABASE_NAME_TEST] == NSNotFound);
        NSLog(@"Everything is cool");
        exit(0);
    }];
}

static void removeTestDatabaseAndRunTests(MODClient *server)
{
    [[server databaseForName:DATABASE_NAME_TEST] dropWithCallback:^(MODQuery *mongoQuery) {
        logMongoQuery(mongoQuery);
        runDatabaseTests(server);
    }];
}

static void testCompareIdenticalBson(NSString *json)
{
    bson_t bsonResult = BSON_INITIALIZER;
    NSError *error;
    MODBsonComparator *comparator;
    
    [MODRagelJsonParser bsonFromJson:&bsonResult json:json error:&error];
    assert(error == nil);
    comparator = [[MODBsonComparator alloc] initWithBson1:&bsonResult bson2:&bsonResult];
    if (![comparator compare]) {
        assert([comparator compare]);
    }
    [comparator release];
    bson_destroy(&bsonResult);
    NSLog(@"%@ compare ok", json);
}

static void testCompareDifferentBson(NSString *json1, NSString *json2, NSArray *differences)
{
    bson_t bson1 = BSON_INITIALIZER;
    bson_t bson2 = BSON_INITIALIZER;
    NSError *error;
    MODBsonComparator *comparator;
    
    [MODRagelJsonParser bsonFromJson:&bson1 json:json1 error:&error];
    assert(error == nil);
    [MODRagelJsonParser bsonFromJson:&bson2 json:json2 error:&error];
    assert(error == nil);
    comparator = [[MODBsonComparator alloc] initWithBson1:&bson1 bson2:&bson2];
    if ([comparator compare]) {
        NSLog(@"%@", json1);
        NSLog(@"%@", json2);
        assert(![comparator compare]);
    }
    if (![comparator.differences isEqualToArray:differences]) {
        NSLog(@"%@", comparator.differences);
        NSLog(@"%@", differences);
        assert(![comparator.differences isEqualToArray:differences]);
    }
    NSLog(@"Different: %@ %@", json1, json2);
    [comparator release];
    bson_destroy(&bson1);
    bson_destroy(&bson2);
}

static void testCompareBson(void)
{
    testCompareIdenticalBson(@"{\"teest\":1}");
    testCompareIdenticalBson(@"{}");
    testCompareIdenticalBson(@"{\"teest\": [1, 2, 3]}");
    testCompareDifferentBson(@"{\"test\":[1, 2, 3]}", @"{\"test\":[1, 2, 2]}", @[ @"test.2" ]);
    testCompareDifferentBson(@"{\"test\":{\"x\":2}}", @"{\"test\":{\"x\":3}}", @[ @"test.x" ]);
    testCompareDifferentBson(@"{\"test\":2}", @"{\"test\":1}", @[ @"test" ]);
    testCompareDifferentBson(@"{}", @"{\"test\":2}", @[ @"*" ]);
}

static void testCompareIdenticalDocument(NSString *json)
{
    id document;
    NSError *error;
    MODDocumentComparator *comparator;
    
    document = [MODRagelJsonParser objectsFromJson:json withError:&error];
    assert(error == nil);
    
    comparator = [[MODDocumentComparator alloc] initWithDocument1:document document2:document];
    if (![comparator compare]) {
        assert([comparator compare]);
    }
    [comparator release];
    NSLog(@"%@ compare ok", json);
}

static void testCompareDifferentDocument(NSString *json1, NSString *json2, NSArray *differences)
{
    id document1, document2;
    NSError *error;
    MODDocumentComparator *comparator;
    
    document1 = [MODRagelJsonParser objectsFromJson:json1 withError:&error];
    assert(error == nil);
    document2 = [MODRagelJsonParser objectsFromJson:json2 withError:&error];
    assert(error == nil);
    
    comparator = [[MODDocumentComparator alloc] initWithDocument1:document1 document2:document2];
    if ([comparator compare]) {
        NSLog(@"%@", json1);
        NSLog(@"%@", json2);
        assert(![comparator compare]);
    }
    if (![comparator.differences isEqualToArray:differences]) {
        NSLog(@"%@", comparator.differences);
        NSLog(@"%@", differences);
        assert(![comparator.differences isEqualToArray:differences]);
    }
    NSLog(@"Different: %@ %@", json1, json2);
    [comparator release];
}

static void testCompareDocument(void)
{
    testCompareIdenticalDocument(@"{\"teest\":1}");
    testCompareIdenticalDocument(@"{}");
    testCompareIdenticalDocument(@"{\"teest\": [1, 2, 3]}");
    testCompareDifferentDocument(@"{\"test\":[1, 2, 3]}", @"{\"test\":[1, 2, 2]}", @[ @"test.2" ]);
    testCompareDifferentDocument(@"{\"test\":{\"x\":2}}", @"{\"test\":{\"x\":3}}", @[ @"test.x" ]);
    testCompareDifferentDocument(@"{\"test\":2}", @"{\"test\":1}", @[ @"test" ]);
    testCompareDifferentDocument(@"{}", @"{\"test\":2}", @[ @"*" ]);
}

int main (int argc, const char * argv[])
{
    @autoreleasepool {
        const char *uri;
        MODClient *server = nil;

        testJson();
        testCompareDocument();
        testCompareBson();
        testBase64();
        testTypes();
        if (argc != 2) {
            NSLog(@"need to put the ip a of a mongo server as a parameter, so we can test the objective-c driver");
            exit(1);
        }
        uri = argv[1];
        server = [[MODClient alloc] initWithURICString:uri];
        if (server == nil) {
            NSLog(@"Can't parse uri %s", uri);
            assert(false);
        }
        [server serverStatusWithReadPreferences:nil callback:^(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
        }];
        [server databaseNamesWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
            logMongoQuery(mongoQuery);
            if ([list indexOfObject:DATABASE_NAME_TEST] != NSNotFound) {
                removeTestDatabaseAndRunTests(server);
            } else {
                runDatabaseTests(server);
            }
        }];
        [server release];
    }
    @autoreleasepool {
        [[NSRunLoop mainRunLoop] run];
    }
    return 0;
}

