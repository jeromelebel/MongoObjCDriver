//
//  MODBsonComparatorTestCase.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 01/10/2014.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "MongoObjCDriver-private.h"

@interface MODBsonComparatorTestCase : XCTestCase

@end

@implementation MODBsonComparatorTestCase

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCompareIdenticalBsonWithJson:(NSString *)json
{
    bson_t bsonResult = BSON_INITIALIZER;
    NSError *error;
    MODBsonComparator *comparator;
    
    [MODRagelJsonParser bsonFromJson:&bsonResult json:json error:&error];
    XCTAssertNil(error, @"should have no error with %@", json);
    
    comparator = [[MODBsonComparator alloc] initWithBson1:&bsonResult bson2:&bsonResult];
    XCTAssertTrue([comparator compare], @"problem to compare json %@", json);
    bson_destroy(&bsonResult);
}

- (void)testCompareDifferentBsonWithJson1:(NSString *)json1 json2:(NSString *)json2 differences:(NSArray *)differences
{
    bson_t bson1 = BSON_INITIALIZER;
    bson_t bson2 = BSON_INITIALIZER;
    NSError *error;
    MODBsonComparator *comparator;
    
    [MODRagelJsonParser bsonFromJson:&bson1 json:json1 error:&error];
    XCTAssertNil(error, @"should have no error with %@", json1);
    [MODRagelJsonParser bsonFromJson:&bson2 json:json2 error:&error];
    XCTAssertNil(error, @"should have no error with %@", json2);
    
    comparator = [[MODBsonComparator alloc] initWithBson1:&bson1 bson2:&bson2];
    XCTAssertFalse([comparator compare], @"should be different %@ and %@", json1, json2);
    XCTAssertEqualObjects(comparator.differences, differences, @"problem to find differences in %@ and %@", json1, json2);
    bson_destroy(&bson1);
    bson_destroy(&bson2);
}

- (void)testCompareIdenticalBson1
{
    [self testCompareIdenticalBsonWithJson:@"{\"teest\":1}"];
}

- (void)testCompareIdenticalBson2
{
    [self testCompareIdenticalBsonWithJson:@"{}"];
}

- (void)testCompareIdenticalBson3
{
    [self testCompareIdenticalBsonWithJson:@"{\"teest\": [1, 2, 3]}"];
}

- (void)testCompareDifferentBson1
{
    [self testCompareDifferentBsonWithJson1:@"{\"test\":[1, 2, 3]}" json2:@"{\"test\":[1, 2, 2]}" differences:@[ @"test.2" ]];
}

- (void)testCompareDifferentBson2
{
    [self testCompareDifferentBsonWithJson1:@"{\"test\":{\"x\":2}}" json2:@"{\"test\":{\"x\":3}}" differences:@[ @"test.x" ]];
}

- (void)testCompareDifferentBson3
{
    [self testCompareDifferentBsonWithJson1:@"{\"test\":2}" json2:@"{\"test\":1}" differences:@[ @"test" ]];
}

- (void)testCompareDifferentBson4
{
    [self testCompareDifferentBsonWithJson1:@"{}" json2:@"{\"test\":2}" differences:@[ @"*" ]];
}

- (void)testCompareDifferentBson5
{
    [self testCompareDifferentBsonWithJson1:@"{\"test\":3}" json2:@"{\"test\":2}" differences:@[ @"test" ]];
}

@end
