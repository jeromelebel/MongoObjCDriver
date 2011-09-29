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

- (NSString *)tengenString
{
    return [self jsonValue];
}

- (NSString *)jsonValue
{
    char *bufferString;
    const unsigned char *bytes;
    NSString *result;
    size_t ii, count;
    
    bytes = [_data bytes];
    bufferString = malloc(([_data length] * 2) + 1);
    count = [_data length];
    for(ii = 0; ii < count; ii++) {
        snprintf(bufferString + (ii * 2), 3, "%0.2X", bytes[ii]);
    }
    bufferString[(ii * 2) + 1] = 0;
    result = [NSString stringWithFormat:@"{ \"$binary\" : \"%s\", \"$type\" : \"%d\" }", bufferString, (int)_binaryType];
    free(bufferString);
    return result;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [[object data] isEqual:_data] && [object binaryType] == _binaryType;
    }
    return NO;
}

@end
