//
//  MODDataBinary.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 28/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODDataBinary

@synthesize data = _data, binaryType = _binaryType;

- (id)initWithData:(NSData *)data binaryType:(char)binaryType
{
    return [self initWithBytes:[data bytes] length:[data length] binaryType:binaryType];
}

- (id)initWithBytes:(const void *)bytes length:(NSUInteger)length binaryType:(char)binaryType
{
    if (self = [self init]) {
        _data = [[NSData alloc] initWithBytes:bytes length:length];
        _binaryType = binaryType;
    }
    return self;
}

@end
