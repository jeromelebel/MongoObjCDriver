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
    MODSortedDictionary *objectsFromBson;
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
        || ([shouldEqual isKindOfClass:[MODSortedDictionary class]] && ![objectsFromBson isEqual:shouldEqual])) {
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
        if ([objects isKindOfClass:[MODSortedDictionary class]]) {
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
    
    if ([shouldEqual isKindOfClass:[MODSortedDictionary class]]) {
        NSString *jsonFromObjects;
        
        jsonFromObjects = [MODClient convertObjectToJson:shouldEqual pretty:NO strictJson:NO jsonKeySortOrder:MODJsonKeySortOrderDocument];
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
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODScopeFunction alloc] initWithFunction:@"\"javascript function\"" scope:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:@"\"", @"x", nil]], @"scopefunction", nil]];
}

- (void)testBackslashFunctionParsing
{
    [self jsonTesterWithJsonToParse:@"{\"function\":{\"$function\":\"\\\"javascript function\\\"\"}}"
                       jsonExpected:@"{\"function\":Function(\"\\\"javascript function\\\"\")}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODFunction alloc] initWithFunction:@"\"javascript function\""], @"function", nil]];
}

- (void)testScopeFunctionParsing
{
    [self jsonTesterWithJsonToParse:@"{\"scopefunction\":{\"$function\":\"javascript function\",\"$scope\":{\"x\":1}}}"
                       jsonExpected:@"{\"scopefunction\":ScopeFunction(\"javascript function\",{\"x\":1})}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODScopeFunction alloc] initWithFunction:@"javascript function" scope:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"x", nil]], @"scopefunction", nil]];
}

- (void)testFunctionParsing
{
    [self jsonTesterWithJsonToParse:@"{\"function\":{\"$function\":\"javascript function\"}}"
                       jsonExpected:@"{\"function\":Function(\"javascript function\")}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODFunction alloc] initWithFunction:@"javascript function"], @"function", nil]];
 }

- (void)testSymbolParsing
{
    [self jsonTesterWithJsonToParse:@"{\"my symbol\":{\"$symbol\":\"pour fred\"}}"
                       jsonExpected:@"{\"my symbol\":Symbol(\"pour fred\")}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODSymbol alloc] initWithValue:@"pour fred"], @"my symbol", nil]];
}

- (void)testDateParsing
{
    [self jsonTesterWithJsonToParse:@"{\"date\":new Date(396361048820)}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:396361048.820], @"date", nil]];
}

- (void)testOldFormatDateParsing
{
    [self jsonTesterWithJsonToParse:@"{\"mydate\":{\"$date\":1320066612000}}"
                       jsonExpected:@"{\"mydate\":new Date(\"2011-10-31T14:10:12+0100\")}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[NSDate alloc] initWithTimeIntervalSince1970:1320066612], @"mydate", nil]];
}

- (void)testZeroDateParsing
{
    [self jsonTesterWithJsonToParse:@"{\"date\":new Date(0)}"
                       jsonExpected:@"{\"date\":new Date(\"1970-01-01T01:00:00+0100\")}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:0], @"date", nil]];
}

- (void)testPrecisionDateParsing1
{
    [self jsonTesterWithJsonToParse:@"{\"someDate\":new Date(1384297199999)}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:1384297199.999], @"someDate", nil]];
}

- (void)testPrecisionDateParsing2
{
    [self jsonTesterWithJsonToParse:@"{\"someDate\":new Date(1384297199000)}"
                       jsonExpected:@"{\"someDate\":new Date(\"2013-11-12T23:59:59+0100\")}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSDate dateWithTimeIntervalSince1970:1384297199], @"someDate", nil]];
}

- (void)testNoQuoteKeyParsing
{
    [self jsonTesterWithJsonToParse:@"{int:1}"
                       jsonExpected:@"{\"int\":1}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"int", nil]];
}

- (void)testDollarParsing
{
    [self jsonTesterWithJsonToParse:@"{$value:1}"
                       jsonExpected:@"{\"$value\":1}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"$value", nil]];
}

- (void)testDoubleParsing1
{
    [self jsonTesterWithJsonToParse:@"{\"number\":0.7868957519531251}"
                       jsonExpected:@"{\"number\":0.78689575195312511102}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:0.7868957519531251], @"number", nil]];
}

- (void)testDoubleParsing2
{
    [self jsonTesterWithJsonToParse:@"{\"number\":0.786895751953125}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:0.786895751953125], @"number", nil]];
}

- (void)testSimpleDoubleParsing
{
    [self jsonTesterWithJsonToParse:@"{\"double\":1.0}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:1], @"double", nil]];
}

- (void)testSimpleLongLongParsing
{
    [self jsonTesterWithJsonToParse:@"{\"longlong\":NumberLong(1)}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithLongLong:1], @"longlong", nil]];
}

- (void)testSimpleParsing
{
    [self jsonTesterWithJsonToParse:@"{\"int\":1}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"int", nil]];
}

- (void)testSingleQuoteParsing
{
    [self jsonTesterWithJsonToParse:@"{'_id':'hello'}"
                       jsonExpected:@"{\"_id\":\"hello\"}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:@"hello", @"_id", nil]];
}

- (void)testObjectIdParsing
{
    [self jsonTesterWithJsonToParse:@"{\"_id\":ObjectId(\"4e9807f88157f608b4000002\"),\"type\":\"Activity\"}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODObjectId alloc] initWithCString:"4e9807f88157f608b4000002"], @"_id", @"Activity", @"type", nil]];
}

- (void)testMinKeyParsing
{
    [self jsonTesterWithJsonToParse:@"{\"minkey\":{\"$minKey\":1}}"
                       jsonExpected:@"{\"minkey\":MinKey}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODMinKey alloc] init], @"minkey", nil]];
}

- (void)testMaxKeyParsing
{
    [self jsonTesterWithJsonToParse:@"{\"maxkey\":{\"$maxKey\":1}}"
                       jsonExpected:@"{\"maxkey\":MaxKey}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODMaxKey alloc] init], @"maxkey", nil]];
}

- (void)testUndefinedParsing
{
    [self jsonTesterWithJsonToParse:@"{\"undefined\":{\"$undefined\":true}}"
                       jsonExpected:@"{\"undefined\":undefined}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODUndefined alloc] init], @"undefined", nil]];
}

- (void)testPrecisionDoubleParsing1
{
    [self jsonTesterWithJsonToParse:@"{\"number\":16.039199999999993906}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:16.039199999999994], @"number", nil]];
}

- (void)testPrecisionDoubleParsing2
{
    [self jsonTesterWithJsonToParse:@"{\"number\":1.2345678909999999728}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:1.234567891], @"number", nil]];
}

- (void)testPrecisionDoubleParsing3
{
    [self jsonTesterWithJsonToParse:@"{\"number\":3.8365551715863071018e-13}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:3.8365551715863071018e-13], @"number", nil]];
}

- (void)testPrecisionDoubleParsing4
{
    [self jsonTesterWithJsonToParse:@"{\"number\":8.26171875}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:8.26171875], @"number", nil]];
}

- (void)testBinaryParsing1
{
    [self jsonTesterWithJsonToParse:@"{\"data\":{\"$binary\":\"AA==\",\"$type\":\"0\"}}"
                       jsonExpected:@"{\"data\":BinData(0,\"AA==\")}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODBinary alloc] initWithBytes:"\0" length:1 binaryType:0], @"data", nil]];
}

- (void)testBinaryParsing2
{
    [self jsonTesterWithJsonToParse:@"{\"data\":{\"$binary\":\"SmVyb21l\",\"$type\":\"0\"}}"
                       jsonExpected:@"{\"data\":BinData(0,\"SmVyb21l\")}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODBinary alloc] initWithBytes:"Jerome" length:6 binaryType:0], @"data", nil]];
}

- (void)testNoBinaryParsing
{
    [self jsonTesterWithJsonToParse:@"{\"not data\":{\"$type\":\"encore fred\"}}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:@"encore fred", @"$type", nil], @"not data", nil]];
}

- (void)testArrayParsing
{
    [self jsonTesterWithJsonToParse:@"{\"_id\":\"x\",\"toto\":[1,2,3]}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:2], [NSNumber numberWithInt:3], nil], @"toto", nil]];
}

- (void)testArrayOfDictionaryParsing1
{
    [self jsonTesterWithJsonToParse:@"{\"_id\":\"x\",\"toto\":[{\"1\":2}]}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], nil], @"toto", nil]];
}

- (void)testOldFormatObjectIdParsing
{
    [self jsonTesterWithJsonToParse:@"{\"_id\":{\"$oid\":\"4e9807f88157f608b4000002\"},\"type\":\"Activity\"}"
                       jsonExpected:@"{\"_id\":ObjectId(\"4e9807f88157f608b4000002\"),\"type\":\"Activity\"}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODObjectId alloc] initWithCString:"4e9807f88157f608b4000002"], @"_id", @"Activity", @"type", nil]];
}

- (void)testRegexpParsing
{
    [self jsonTesterWithJsonToParse:@"{\"toto\":{\"$regex\":\"value\"},\"regexp\":{\"$regex\":\"value\",\"$options\":\"x\"}}"
                       jsonExpected:@"{\"toto\":/value/,\"regexp\":/value/x}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODRegex alloc] initWithPattern:@"value" options:nil], @"toto", [[MODRegex alloc] initWithPattern:@"value" options:@"x"], @"regexp", nil]];
}

- (void)testArrayOfDictionaryParsing2
{
    [self jsonTesterWithJsonToParse:@"{\"_id\":\"x\",\"toto\":[{\"1\":2},{\"2\":true}]}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:@"x", @"_id", [NSArray arrayWithObjects:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:2], @"1", nil], [MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"2", nil], nil], @"toto", nil]];
}

- (void)testEmptyArrayParsing
{
    [self jsonTesterWithJsonToParse:@"{\"toto\":1,\"empty_array\":[],\"type\":\"Activity\"}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithInt:1], @"toto", [NSArray array], @"empty_array", @"Activity", @"type", nil]];
}

- (void)testEmptyDictionaryParsing
{
    [self jsonTesterWithJsonToParse:@"{\"empty_hash\":{},\"toto\":1,\"type\":\"Activity\"}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[MODSortedDictionary sortedDictionary], @"empty_hash", [NSNumber numberWithInt:1], @"toto", @"Activity", @"type", nil]];
}

- (void)testArrayWithoutDocumentParsing
{
    [self jsonTesterWithJsonToParse:@"[{\"hello\":\"1\"},{\"zob\":\"2\"}]"
                       jsonExpected:nil
                        shouldEqual:[NSArray arrayWithObjects:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:@"1", @"hello", nil], [MODSortedDictionary sortedDictionaryWithObjectsAndKeys:@"2", @"zob", nil], nil]];
}

- (void)testTimestampParsing
{
    [self jsonTesterWithJsonToParse:@"{\"timestamp\":{\"$timestamp\":[1,2]}}"
                       jsonExpected:@"{\"timestamp\":Timestamp(1, 2)}"
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[[MODTimestamp alloc] initWithTValue:1 iValue:2], @"timestamp", nil]];
}

- (void)testTrueFalseParsing
{
    [self jsonTesterWithJsonToParse:@"{\"false\":false,\"true\":true}"
                       jsonExpected:nil
                        shouldEqual:[MODSortedDictionary sortedDictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], @"false", [NSNumber numberWithBool:YES], @"true", nil]];
}

@end
