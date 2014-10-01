//
//  MODObjectsTestCase.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 01/10/2014.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "MongoObjCDriver-private.h"

@interface MODObjectsTestCase : XCTestCase

@end

@implementation MODObjectsTestCase

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBinary
{
    MODSortedMutableDictionary *document;
    MODBinary *binary;
    NSData *data;
    bson_t myBson = BSON_INITIALIZER;
    
    document = [[MODSortedMutableDictionary alloc] init];
    
    data = [[NSData alloc] initWithBytes:"1234567890" length:10];
    binary = [[MODBinary alloc] initWithData:data binaryType:0];
    [document setObject:binary forKey:@"binary"];
    
    [MODClient appendObject:document toBson:&myBson];
    XCTAssertEqualObjects(document, [MODClient objectFromBson:&myBson], @"problem to convert bson into objects");
    bson_destroy(&myBson);
}

- (void)testObjectId
{
    bson_oid_t bsonOid;
    MODObjectId *objectOid;
    const char *oid = "4e9807f88157f608b4000002";
    
    bson_oid_init_from_string(&bsonOid, oid);
    objectOid = [[MODObjectId alloc] initWithOid:&bsonOid];
    XCTAssertEqualObjects([NSString stringWithUTF8String:oid], objectOid.stringValue, @"objectid should be equal");
}

- (void)testBsonArray:(bson_t *)bsonObject count:(unsigned int)count
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
    XCTAssertEqual(ii, count, @"wrong count");
    XCTAssertFalse(bson_iter_next(&iterator), @"we should have no more elements");
}

// test to make sure each items in an array has the correct index
// https://github.com/jeromelebel/MongoHub-Mac/issues/28
- (void)testArrayIndex1
{
    bson_t bsonObject = BSON_INITIALIZER;
    NSError *error = nil;
    
    [MODRagelJsonParser bsonFromJson:&bsonObject json:@"{ \"array\": [ 1, {\"x\": 1}, [ 1 ]] }" error:&error];
    [self testBsonArray:&bsonObject count:3];
    bson_destroy(&bsonObject);
}

// test to make sure each items in an array has the correct index
// https://github.com/jeromelebel/MongoHub-Mac/issues/39
- (void)testArrayIndex2
{
    id objects;
    bson_t bsonObject = BSON_INITIALIZER;
    NSError *error = nil;
    
    objects = [MODRagelJsonParser objectsFromJson:@"{ \"array\": [ 1, {\"x\": 1}, [ 1 ]] }" withError:&error];
    bson_init(&bsonObject);
    [MODClient appendObject:objects toBson:&bsonObject];
    [self testBsonArray:&bsonObject count:3];
    bson_destroy(&bsonObject);
}

@end
