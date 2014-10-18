//
//  MODDocumentCompatorTestCase.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 01/10/2014.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "MongoObjCDriver-private.h"

@interface MODDocumentCompatorTestCase : XCTestCase

@end

@implementation MODDocumentCompatorTestCase

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}


- (void)testCompareIdenticalDocument:(NSString *)json
{
    id document;
    NSError *error;
    MODDocumentComparator *comparator;
    
    document = [MODRagelJsonParser objectsFromJson:json withError:&error];
    XCTAssertNil(error, @"should have no error");
    
    comparator = [[MODDocumentComparator alloc] initWithDocument1:document document2:document];
    XCTAssertTrue([comparator compare], @"problem to compare %@", json);
}

- (void)testCompareDifferentDocumentWithJson1:(NSString *)json1 json2:(NSString *)json2 differences:(NSArray *)differences
{
    id document1, document2;
    NSError *error;
    MODDocumentComparator *comparator;
    
    document1 = [MODRagelJsonParser objectsFromJson:json1 withError:&error];
    XCTAssertNil(error, @"should have no error");
    document2 = [MODRagelJsonParser objectsFromJson:json2 withError:&error];
    XCTAssertNil(error, @"should have no error");
    
    comparator = [[MODDocumentComparator alloc] initWithDocument1:document1 document2:document2];
    XCTAssertFalse([comparator compare], @"problem to compare %@ and %@", json1, json2);
    XCTAssertEqualObjects(comparator.differences, differences, @"problem to get the differences");
}

- (void)testIdenticalDocument1
{
    [self testCompareIdenticalDocument:@"{\"teest\":1}"];
}

- (void)testIdenticalDocument2
{
    [self testCompareIdenticalDocument:@"{}"];
}

- (void)testIdenticalDocuement3
{
    [self testCompareIdenticalDocument:@"{\"teest\": [1, 2, 3]}"];
}

- (void)testDifferentDocument1
{
    [self testCompareDifferentDocumentWithJson1:@"{\"test\":[1, 2, 3]}" json2:@"{\"test\":[1, 2, 2]}" differences:@[ @"test.2" ]];
}

- (void)testDifferentDocument2
{
    [self testCompareDifferentDocumentWithJson1:@"{\"test\":{\"x\":2}}" json2:@"{\"test\":{\"x\":3}}" differences:@[ @"test.x" ]];
}

- (void)testDifferentDocument3
{
    [self testCompareDifferentDocumentWithJson1:@"{\"test\":2}" json2:@"{\"test\":1}" differences:@[ @"test" ]];
}

- (void)testDifferentDocument4
{
    [self testCompareDifferentDocumentWithJson1:@"{}" json2:@"{\"test\":2}" differences:@[ @"*" ]];
}

- (void)testCompareDifferentBson5
{
    [self testCompareDifferentDocumentWithJson1:@"{\"test\":3}" json2:@"{\"test\":2}" differences:@[ @"test" ]];
}

@end
