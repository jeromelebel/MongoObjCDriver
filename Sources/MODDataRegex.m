//
//  MODDataRegex.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 25/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MODDataRegex.h"

@implementation MODDataRegex

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

- (NSString *)jsonValue
{
    return [NSString stringWithFormat:@"{ \"$regex\" : \"%@\", \"$options\" : \"%@\" ] }", _pattern, _options];
}

@end
