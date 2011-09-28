//
//  MODTimestamp.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 24/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODTimestamp

- (id)initWithTValue:(int)tValue iValue:(int)iValue
{
    if (self = [self init]) {
        _iValue = iValue;
        _tValue = tValue;
    }
    return self;
}

- (NSString *)jsonValue
{
    return [NSString stringWithFormat:@"{ \"$timestamp\" : [ %d, %d ] }", _tValue, _iValue];
}

- (void)getBsonTimestamp:(bson_timestamp_t *)ts
{
    ts->i = _iValue;
    ts->t = _tValue;
}

@end
