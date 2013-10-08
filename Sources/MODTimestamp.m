//
//  MODTimestamp.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 24/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODTimestamp

@synthesize tValue = _tValue, iValue = _iValue;

- (id)initWithTValue:(int)tValue iValue:(int)iValue
{
    if (self = [self init]) {
        _iValue = iValue;
        _tValue = tValue;
    }
    return self;
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    if (!strictJSON) {
        return [NSString stringWithFormat:@"Timestamp(%d, %d)", _tValue, _iValue];
    } else if (pretty) {
        return [NSString stringWithFormat:@"{ \"$timestamp\" : [ %d, %d ] }", _tValue, _iValue];
    } else {
        return [NSString stringWithFormat:@"{\"$timestamp\":[%d,%d]}", _tValue, _iValue];
    }
}

- (NSDate *)dateValue
{
    return [NSDate dateWithTimeIntervalSince1970:_tValue];
}

- (void)getBsonTimestamp:(bson_timestamp_t *)ts
{
    ts->i = _iValue;
    ts->t = _tValue;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return _tValue == [object tValue] && _iValue == [object iValue];
    }
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, (%d, %d)>", self.class, self, _tValue, _iValue];
}

@end
