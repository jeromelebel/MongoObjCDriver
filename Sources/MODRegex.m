//
//  MODRegex.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 25/09/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODRegex

- (id)initWithPattern:(NSString *)pattern options:(NSString *)options
{
    if (self = [self init]) {
        _pattern = [pattern retain];
        if (options) {
            _options = [options retain];
        } else {
            _options = [@"" retain];
        }
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

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    if (!strictJSON) {
        return [NSString stringWithFormat:@"/%@/%@", [MODClient escapeSlashesForString:_pattern], [MODClient escapeSlashesForString:_options]];
    } else if (pretty && _options && [_options length] > 0) {
        return [NSString stringWithFormat:@"{ \"$regex\": \"%@\", \"$options\": \"%@\" }", [MODClient escapeQuotesForString:_pattern], [MODClient escapeQuotesForString:_options]];
    } else if (pretty) {
        return [NSString stringWithFormat:@"{ \"$regex\": \"%@\" }", [MODClient escapeQuotesForString:_pattern]];
    } else if (_options && [_options length] > 0) {
        return [NSString stringWithFormat:@"{\"$regex\":\"%@\",\"$options\":\"%@\"}", [MODClient escapeQuotesForString:_pattern], [MODClient escapeQuotesForString:_options]];
    } else {
        return [NSString stringWithFormat:@"{\"$regex\":\"%@\"}", [MODClient escapeQuotesForString:_pattern]];
    }
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [[object pattern] isEqual:_pattern] && [[(MODRegex *)object options] isEqual:_options];
    }
    return NO;
}

@end
