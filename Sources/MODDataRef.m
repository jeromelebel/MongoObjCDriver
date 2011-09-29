//
//  MODDataRef.m
//  MongoHub
//
//  Created by Jérôme Lebel on 29/09/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODDataRef

@synthesize refValue = _refValue;

- (id)initWithRefValue:(NSString *)refValue idValue:(const unsigned char[12])idValue
{
    if (self = [self init]) {
        _refValue = [refValue retain];
        memcpy(_idValue, idValue, sizeof(_idValue));
    }
    return self;
}

- (void)dealloc
{
    [_refValue release];
    [super dealloc];
}

- (const unsigned char *)idValue
{
    return _idValue;
}

- (NSString *)tengenString
{
    char *bufferString;
    const unsigned char *bytes;
    NSString *result;
    size_t ii, count;
    
    count = sizeof(_idValue);
    bufferString = malloc((count * 2) + 1);
    for(ii = 0; ii < count; ii++) {
        snprintf(bufferString + (ii * 2), 3, "%0.2X", bytes[ii]);
    }
    bufferString[(ii * 2) + 1] = 0;
    result = [NSString stringWithFormat:@"Dbref(\"%@\", \"%@\")", _refValue, bufferString];
    free(bufferString);
    return result;
}

- (NSString *)jsonValue
{
    char *bufferString;
    const unsigned char *bytes;
    NSString *result;
    size_t ii, count;
    
    count = sizeof(_idValue);
    bufferString = malloc((count * 2) + 1);
    for(ii = 0; ii < count; ii++) {
        snprintf(bufferString + (ii * 2), 3, "%0.2X", bytes[ii]);
    }
    bufferString[(ii * 2) + 1] = 0;
    result = [NSString stringWithFormat:@"{ \"$ref\" : \"%@\", \"$id\" : \"%s\" }", _refValue, bufferString];
    free(bufferString);
    return result;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [[object refValue] isEqual:_refValue] && memcmp(_idValue, [object idValue], sizeof(_idValue)) == 0;
    }
    return NO;
}

@end
