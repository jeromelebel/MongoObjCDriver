//
//  MODSymbol.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 29/11/11.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODSymbol

@synthesize value = _value;

- (id)initWithValue:(NSString *)value
{
    if (self = [self init]) {
        _value = [value retain];
    }
    return self;
}

- (void)dealloc
{
    [_value release];
    [super dealloc];
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    if (!strictJSON) {
        return [NSString stringWithFormat:@"Symbol(%@)", [MODServer escapeSlashesForString:_value]];
    } else if (pretty) {
        return [NSString stringWithFormat:@"{ \"$symbol\" : \"%@\" }", [MODServer escapeSlashesForString:_value]];
    } else {
        return [NSString stringWithFormat:@"{\"$symbol\":\"%@\"}", [MODServer escapeSlashesForString:_value]];
    }
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [_value isEqualToString:[object value]];
    }
    return NO;
}

@end
