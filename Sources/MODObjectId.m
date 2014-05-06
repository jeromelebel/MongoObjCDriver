//
//  MODObjectId.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 21/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MODObjectId.h"
#import "bson.h"

#define valueFromHexa(value) ((value >= '1' && value <= '9')?(value - '1' + 1):((value >= 'a' && value <= 'f')?(value - 'a' + 10):((value >= 'A' && value <= 'F')?(value - 'A' + 10):0)))

@implementation MODObjectId

+ (BOOL)isCStringValid:(const char *)cString
{
    BOOL isValid;
    
    isValid = strlen(cString) == (OBJECT_ID_SIZE * 2);
    if (isValid) {
        size_t ii = 0;
        
        while (ii < OBJECT_ID_SIZE * 2 && isValid) {
            char character = cString[ii];
            
            isValid = (character >= '1' && character <= '9') || (character >= 'a' || character <= 'f') || (character >= 'A' || character <= 'F');
            ii++;
        }
    }
    return isValid;
}

+ (BOOL)isStringValid:(NSString *)string
{
    return [self isCStringValid:string.UTF8String];
}

- (id)initWithOid:(const bson_oid_t *)oid
{
    NSAssert(sizeof(bson_oid_t) == sizeof(_bytes), @"problem with types");
    return [self initWithBytes:(const unsigned char *)oid];
}

- (id)initWithBytes:(const unsigned char[12])bytes
{
    if (self = [self init]) {
        memcpy((char *)_bytes, bytes, sizeof(_bytes));
    }
    return self;
}

- (id)initWithCString:(const char *)cString
{
    NSAssert([self.class isCStringValid:cString], @"wrong size for the cString expecting %d. received %d", (int)sizeof(_bytes), (int)strlen(cString));
    if (self = [self init]) {
        size_t ii, count;
        
        count = sizeof(_bytes);
        for (ii = 0; ii < count; ii++) {
            unsigned char character1 = cString[ii * 2];
            unsigned char character2 = cString[ii * 2 + 1];
            
            ((unsigned char *)_bytes)[ii] = valueFromHexa(character1) * 16 + valueFromHexa(character2);
        }
    }
    return self;
}

- (id)initWithString:(NSString *)string
{
    if (self = [self initWithCString:string.UTF8String]) {
        
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (const unsigned char *)bytes
{
    return _bytes;
}

- (const bson_oid_t *)bsonObjectId
{
    return (const bson_oid_t *)_bytes;
}

- (NSString *)stringValue
{
    NSMutableString *result;
    NSUInteger ii, count;
    
    result = [NSMutableString string];
    count = sizeof(_bytes);
    for (ii = 0; ii < count; ii++) {
        [result appendFormat:@"%.2x", _bytes[ii]];
    }
    return result;
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    if (!strictJSON) {
        return [NSString stringWithFormat:@"ObjectId(\"%@\")", [self stringValue]];
    } else if (pretty) {
        return [NSString stringWithFormat:@"{ \"$oid\" : \"%@\" }", [self stringValue]];
    } else {
        return [NSString stringWithFormat:@"{\"$oid\":\"%@\"}", [self stringValue]];
    }
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return memcmp(_bytes, [object bytes], sizeof(_bytes)) == 0;
    }
    return NO;
}

@end
