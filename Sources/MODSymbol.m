//
//  MODSymbol.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 29/11/2011.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import "MongoObjCDriver-private.h"

@implementation MODSymbol

@synthesize value = _value;

- (instancetype)initWithValue:(NSString *)value
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
        return [NSString stringWithFormat:@"Symbol(\"%@\")", [MODClient escapeSlashesForString:_value]];
    } else if (pretty) {
        return [NSString stringWithFormat:@"{ \"$symbol\" : \"%@\" }", [MODClient escapeSlashesForString:_value]];
    } else {
        return [NSString stringWithFormat:@"{\"$symbol\":\"%@\"}", [MODClient escapeSlashesForString:_value]];
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
