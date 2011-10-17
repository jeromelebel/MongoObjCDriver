//
//  MODObjectId.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 21/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MODObjectId.h"
#import "bson.h"

@implementation MODObjectId

- (id)initWithOid:(bson_oid_t *)oid
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

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (const unsigned char *)bytes
{
    return _bytes;
}

- (bson_oid_t *)bsonObjectId
{
    return (bson_oid_t *)_bytes;
}

- (NSString *)tengenString
{
    return [NSString stringWithFormat:@"ObjectId(\"%@\")", [self stringValue]];
}

- (NSString *)stringValue
{
    NSMutableString *result;
    NSUInteger ii, count;
    
    result = [NSMutableString string];
    count = sizeof(_bytes);
    for (ii = 0; ii < count; ii++) {
        [result appendFormat:@"%0.2X", _bytes[ii]];
    }
    return result;
}

- (NSString *)jsonValue
{
    return [NSString stringWithFormat:@"{ \"$oid\" : \"%@\" }", [self stringValue]];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return memcmp(_bytes, [object bytes], sizeof(_bytes));
    }
    return NO;
}

@end
