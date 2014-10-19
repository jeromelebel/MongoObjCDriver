//
//  MODJsonParsingTestCase.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 01/10/2014.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "MongoObjCDriver-private.h"

@interface MODJsonParsingTestCase : XCTestCase

@end

@implementation MODJsonParsingTestCase

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)jsonTesterWithJsonToParse:(NSString *)jsonToParse jsonExpected:(NSString *)jsonExpected shouldEqual:(id)shouldEqual
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
        XCTFail(@"Parsing errors");
    }
    objectsFromBson = [MODClient objectFromBson:&bsonResult];
    if (([shouldEqual isKindOfClass:[NSArray class]] && ![[objectsFromBson objectForKey:@"array"] isEqual:shouldEqual])
        || ([shouldEqual isKindOfClass:[MODSortedMutableDictionary class]] && ![objectsFromBson isEqual:shouldEqual])) {
        NSLog(@"***** problem to convert bson to objects:");
        NSLog(@"json: %@", jsonToParse);
        NSLog(@"expecting: %@", shouldEqual);
        NSLog(@"received: %@", objectsFromBson);
        NSLog(@"difference in: %@", [MODClient findAllDifferencesInObject1:shouldEqual object2:objectsFromBson]);
        XCTFail(@"error to convert bson to objects");
    }
    bson_destroy(&bsonResult);
    objects = [MODRagelJsonParser objectsFromJson:jsonToParse withError:&error];
    if (error) {
        NSLog(@"***** parsing errors for:");
        NSLog(@"%@", jsonToParse);
        NSLog(@"%@", error);
        XCTFail(@"parsing errors");
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
        XCTFail(@"objects not equal");
    }
    XCTAssertNil(error, @"should have no error");
    XCTAssertEqualObjects(objects, shouldEqual, @"should be equal");
    
    if ([shouldEqual isKindOfClass:[MODSortedMutableDictionary class]]) {
        NSString *jsonFromObjects;
        
        jsonFromObjects = [MODClient convertObjectToJson:shouldEqual pretty:NO strictJson:NO];
        if (![jsonFromObjects isEqualToString:jsonExpected]) {
            NSLog(@"problem to convert objects to json %@", shouldEqual);
            NSLog(@"expecting: '%@'", jsonToParse);
            NSLog(@"received: '%@'", jsonFromObjects);
            XCTAssertEqualObjects(jsonFromObjects, jsonToParse, @"should be equal");
        }
    }
    if (jsonExpected != jsonToParse) {
        [self jsonTesterWithJsonToParse:jsonExpected jsonExpected:nil shouldEqual:shouldEqual];
    }
}

- (void)testBackslashScopeFunctionParsing
{
    [self jsonTesterWithJsonToParse:@"{\"scopefunction\":{\"$function\":\"\\\"javascript function\\\"\",\"$scope\":{\"x\":\"\\\"\"}}}"
                       jsonExpected:@"{\"scopefunction\":ScopeFunction(\"\\\"javascript function\\\"\",{\"x\":\"\\\"\"})}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODScopeFunction alloc] initWithFunction:@"\"javascript function\"" scope:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"\"", @"x", nil]], @"scopefunction", nil]];
}

- (void)testBackslashFunctionParsing
{
    [self jsonTesterWithJsonToParse:@"{\"function\":{\"$function\":\"\\\"javascript function\\\"\"}}"
                       jsonExpected:@"{\"function\":Function(\"\\\"javascript function\\\"\")}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODFunction alloc] initWithFunction:@"\"javascript function\""], @"function", nil]];
}

- (void)testScopeFunctionParsing
{
    [self jsonTesterWithJsonToParse:@"{\"scopefunction\":{\"$function\":\"javascript function\",\"$scope\":{\"x\":1}}}"
                       jsonExpected:@"{\"scopefunction\":ScopeFunction(\"javascript function\",{\"x\":1})}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODScopeFunction alloc] initWithFunction:@"javascript function" scope:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"x", nil]], @"scopefunction", nil]];
}

- (void)testFunctionParsing
{
    [self jsonTesterWithJsonToParse:@"{\"function\":{\"$function\":\"javascript function\"}}"
                       jsonExpected:@"{\"function\":Function(\"javascript function\")}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODFunction alloc] initWithFunction:@"javascript function"], @"function", nil]];
 }

- (void)testSymbolParsing
{
    [self jsonTesterWithJsonToParse:@"{\"my symbol\":{\"$symbol\":\"pour fred\"}}"
                       jsonExpected:@"{\"my symbol\":Symbol(\"pour fred\")}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODSymbol alloc] initWithValue:@"pour fred"], @"my symbol", nil]];
}

- (void)testDateParsing
{
    [self jsonTesterWithJsonToParse:@"{\"date\":new Date(396361048820)}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:396361048.820], @"date", nil]];
}

- (void)testOldFormatDateParsing
{
    [self jsonTesterWithJsonToParse:@"{\"mydate\":{\"$date\":1320066612000}}"
                       jsonExpected:@"{\"mydate\":new Date(\"2011-10-31T14:10:12+0100\")}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[NSDate alloc] initWithTimeIntervalSince1970:1320066612], @"mydate", nil]];
}

- (void)testZeroDateParsing
{
    [self jsonTesterWithJsonToParse:@"{\"date\":new Date(0)}"
                       jsonExpected:@"{\"date\":new Date(\"1970-01-01T01:00:00+0100\")}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:0], @"date", nil]];
}

- (void)testPrecisionDateParsing1
{
    [self jsonTesterWithJsonToParse:@"{\"someDate\":new Date(1384297199999)}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:1384297199.999], @"someDate", nil]];
}

- (void)testPrecisionDateParsing2
{
    [self jsonTesterWithJsonToParse:@"{\"someDate\":new Date(1384297199000)}"
                       jsonExpected:@"{\"someDate\":new Date(\"2013-11-12T23:59:59+0100\")}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:1384297199], @"someDate", nil]];
}

- (void)testNoQuoteKeyParsing
{
    [self jsonTesterWithJsonToParse:@"{int:1}"
                       jsonExpected:@"{\"int\":1}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"int", nil]];
}

- (void)testDollarParsing
{
    [self jsonTesterWithJsonToParse:@"{$value:1}"
                       jsonExpected:@"{\"$value\":1}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"$value", nil]];
}

- (void)testDoubleParsing1
{
    [self jsonTesterWithJsonToParse:@"{\"number\":0.7868957519531251}"
                       jsonExpected:@"{\"number\":0.78689575195312511102}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:0.7868957519531251], @"number", nil]];
}

- (void)testDoubleParsing2
{
    [self jsonTesterWithJsonToParse:@"{\"number\":0.786895751953125}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:0.786895751953125], @"number", nil]];
}

- (void)testSimpleDoubleParsing
{
    [self jsonTesterWithJsonToParse:@"{\"double\":1.0}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:1], @"double", nil]];
}

- (void)testSimpleLongLongParsing
{
    [self jsonTesterWithJsonToParse:@"{\"longlong\":NumberLong(1)}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithLongLong:1], @"longlong", nil]];
}

- (void)testSimpleParsing
{
    [self jsonTesterWithJsonToParse:@"{\"int\":1}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"int", nil]];
}

- (void)testSingleQuoteParsing
{
    [self jsonTesterWithJsonToParse:@"{'_id':'hello'}"
                       jsonExpected:@"{\"_id\":\"hello\"}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"hello", @"_id", nil]];
}

- (void)testObjectIdParsing
{
    [self jsonTesterWithJsonToParse:@"{\"_id\":ObjectId(\"4e9807f88157f608b4000002\"),\"type\":\"Activity\"}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODObjectId alloc] initWithCString:"4e9807f88157f608b4000002"], @"_id", @"Activity", @"type", nil]];
}

- (void)testMinKeyParsing
{
    [self jsonTesterWithJsonToParse:@"{\"minkey\":{\"$minKey\":1}}"
                       jsonExpected:@"{\"minkey\":MinKey}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODMinKey alloc] init], @"minkey", nil]];
}

- (void)testMaxKeyParsing
{
    [self jsonTesterWithJsonToParse:@"{\"maxkey\":{\"$maxKey\":1}}"
                       jsonExpected:@"{\"maxkey\":MaxKey}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODMaxKey alloc] init], @"maxkey", nil]];
}

- (void)testUndefinedParsing
{
    [self jsonTesterWithJsonToParse:@"{\"undefined\":{\"$undefined\":true}}"
                       jsonExpected:@"{\"undefined\":undefined}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODUndefined alloc] init], @"undefined", nil]];
}

- (void)testPrecisionDoubleParsing1
{
    [self jsonTesterWithJsonToParse:@"{\"number\":16.039199999999993906}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:16.039199999999994], @"number", nil]];
}

- (void)testPrecisionDoubleParsing2
{
    [self jsonTesterWithJsonToParse:@"{\"number\":1.2345678909999999728}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:1.234567891], @"number", nil]];
}

- (void)testPrecisionDoubleParsing3
{
    [self jsonTesterWithJsonToParse:@"{\"number\":3.8365551715863071018e-13}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:3.8365551715863071018e-13], @"number", nil]];
}

- (void)testBinaryParsing1
{
    [self jsonTesterWithJsonToParse:@"{\"data\":{\"$binary\":\"AA==\",\"$type\":\"0\"}}"
                       jsonExpected:@"{\"data\":BinData(0,\"AA==\")}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODBinary alloc] initWithBytes:"\0" length:1 binaryType:0], @"data", nil]];
}

- (void)testBinaryParsing2
{
    [self jsonTesterWithJsonToParse:@"{\"data\":{\"$binary\":\"SmVyb21l\",\"$type\":\"0\"}}"
                       jsonExpected:@"{\"data\":BinData(0,\"SmVyb21l\")}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODBinary alloc] initWithBytes:"Jerome" length:6 binaryType:0], @"data", nil]];
}

- (void)testNoBinaryParsing
{
    [self jsonTesterWithJsonToParse:@"{\"not data\":{\"$type\":\"encore fred\"}}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"encore fred", @"$type", nil], @"not data", nil]];
}

- (void)testArrayParsing
{
    [self jsonTesterWithJsonToParse:@"{\"_id\":\"x\",\"toto\":[1,2,3]}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:2], [NSNumber numberWithInt:3], nil], @"toto", nil]];
}

- (void)testArrayOfDictionaryParsing1
{
    [self jsonTesterWithJsonToParse:@"{\"_id\":\"x\",\"toto\":[{\"1\":2}]}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], nil], @"toto", nil]];
}

- (void)testOldFormatObjectIdParsing
{
    [self jsonTesterWithJsonToParse:@"{\"_id\":{\"$oid\":\"4e9807f88157f608b4000002\"},\"type\":\"Activity\"}"
                       jsonExpected:@"{\"_id\":ObjectId(\"4e9807f88157f608b4000002\"),\"type\":\"Activity\"}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODObjectId alloc] initWithCString:"4e9807f88157f608b4000002"], @"_id", @"Activity", @"type", nil]];
}

- (void)testRegexpParsing
{
    [self jsonTesterWithJsonToParse:@"{\"toto\":{\"$regex\":\"value\"},\"regexp\":{\"$regex\":\"value\",\"$options\":\"x\"}}"
                       jsonExpected:@"{\"toto\":/value/,\"regexp\":/value/x}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODRegex alloc] initWithPattern:@"value" options:nil], @"toto", [[MODRegex alloc] initWithPattern:@"value" options:@"x"], @"regexp", nil]];
}

- (void)testArrayOfDictionaryParsing2
{
    [self jsonTesterWithJsonToParse:@"{\"_id\":\"x\",\"toto\":[{\"1\":2},{\"2\":true}]}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"2", nil], nil], @"toto", nil]];
}

- (void)testEmptyArrayParsing
{
    [self jsonTesterWithJsonToParse:@"{\"toto\":1,\"empty_array\":[],\"type\":\"Activity\"}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"toto", [NSArray array], @"empty_array", @"Activity", @"type", nil]];
}

- (void)testEmptyDictionaryParsing
{
    [self jsonTesterWithJsonToParse:@"{\"empty_hash\":{},\"toto\":1,\"type\":\"Activity\"}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[MODSortedMutableDictionary sortedDictionary], @"empty_hash", [NSNumber numberWithInt:1], @"toto", @"Activity", @"type", nil]];
}

- (void)testArrayWithoutDocumentParsing
{
    [self jsonTesterWithJsonToParse:@"[{\"hello\":\"1\"},{\"zob\":\"2\"}]"
                       jsonExpected:nil
                        shouldEqual:[NSArray arrayWithObjects:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"1", @"hello", nil], [MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:@"2", @"zob", nil], nil]];
}

- (void)testTimestampParsing
{
    [self jsonTesterWithJsonToParse:@"{\"timestamp\":{\"$timestamp\":[1,2]}}"
                       jsonExpected:@"{\"timestamp\":Timestamp(1, 2)}"
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODTimestamp alloc] initWithTValue:1 iValue:2], @"timestamp", nil]];
}

- (void)testTrueFalseParsing
{
    [self jsonTesterWithJsonToParse:@"{\"false\":false,\"true\":true}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"false", [NSNumber numberWithBool:YES], @"true", nil]];
}

- (void)testDBRefParsing
{
    MODObjectId *objectId = [[MODObjectId alloc] initWithString:@"4e9807f88157f608b4000002"];
    
    [self jsonTesterWithJsonToParse:@"{\"dbref\":DBRef(\"prout\",\"4e9807f88157f608b4000002\")}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedMutableDictionary sortedDictionaryWithObjectsAndKeys:[[MODDBRef alloc] initWithCollectionName:@"prout" objectId:objectId databaseName:nil], @"dbref", nil]];
}

@end
