//
//  MODRegex.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 25/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MODRegex.h"

@implementation MODRegex

- (id)initWithPattern:(NSString *)pattern options:(NSString *)options
{
    if (self = [self init]) {
        _pattern = [pattern retain];
        _options = [options retain];
    }
    return self;
}

- (void)dealloc
{
    [_pattern release];
    [_options release];
    [super dealloc];
}

- (NSString *)pattern
{
    return _pattern;
}

- (NSString *)options
{
    return _options;
}

- (NSString *)tengenString
{
    return [NSString stringWithFormat:@"/%@/%@", _pattern, _options];
}

- (NSString *)jsonValue
{
    return [NSString stringWithFormat:@"{ \"$regex\" : \"%@\", \"$options\" : \"%@\" ] }", _pattern, _options];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [[object pattern] isEqual:_pattern] && [[(MODRegex *)object options] isEqual:_options];
    }
    return NO;
}

@end
