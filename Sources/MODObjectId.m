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
    NSAssert(sizeof(bson_oid_t) == sizeof(data), @"problem with types");
    return [self initWithBytes:(char *)oid];
}

- (id)initWithBytes:(const char *)bytes
{
    if (self = [self init]) {
        memcpy((char *)data, bytes, sizeof(data));
    }
    return self;
}

- (const char *)bytes
{
    return data;
}

- (NSString *)description
{
    return [[NSData dataWithBytes:data length:sizeof(data)] description];
}

@end
