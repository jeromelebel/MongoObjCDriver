//
//  MODBase64TestCase.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 01/10/2014.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "MongoObjCDriver-private.h"

@interface MODBase64TestCase : XCTestCase

@end

@implementation MODBase64TestCase

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNSDataInBase64:(NSData *)dataToConvert base64:(const char *)base64
{
    NSString *base64String;
    
    base64String = [NSString stringWithUTF8String:base64];
    XCTAssertEqualObjects(dataToConvert.mod_base64String, base64String, @"error to encode base 64");
    XCTAssertEqualObjects(base64String.mod_dataFromBase64, dataToConvert, @"error to decode base 64");
}

- (void)testStringInBase64:(const char *)string base64:(const char *)base64
{
    [self testNSDataInBase64:[NSData dataWithBytes:string length:strlen(string)] base64:base64];
}

- (void)testDataInBase64:(const char *)data length:(NSUInteger)length base64:(const char *)base64
{
    [self testNSDataInBase64:[NSData dataWithBytes:data length:length] base64:base64];
}

- (void)testZeroCharacter
{
    [self testDataInBase64:"\0" length:1 base64:"AA=="];
}

- (void)test1Character
{
    [self testStringInBase64:"1" base64:"MQ=="];
}

- (void)test2Characters
{
    [self testStringInBase64:"12" base64:"MTI="];
}

- (void)test3Characters
{
    [self testStringInBase64:"123" base64:"MTIz"];
}

- (void)test4Characters
{
    [self testStringInBase64:"1234" base64:"MTIzNA=="];
}

- (void)test5Characters
{
    [self testStringInBase64:"12345" base64:"MTIzNDU="];
}

- (void)test6Characters
{
    [self testStringInBase64:"123456" base64:"MTIzNDU2"];
}

@end
