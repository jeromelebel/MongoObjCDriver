//
//  MODUndefined.m
//  MongoHub
//
//  Created by Jérôme Lebel on 10/01/12.
//  Copyright (c) 2012 ThePeppersStudio.COM. All rights reserved.
//

#import "MODUndefined.h"

@implementation MODUndefined

- (NSString *)tengenString
{
    return @"undefined";
}

- (NSString *)jsonValue
{
    return [self jsonValueWithPretty:YES];
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty
{
    NSString *result;
    
    if (pretty) {
        result = [NSString stringWithFormat:@"{ \"$undefined\" : \"$undefined\" }"];
    } else {
        result = [NSString stringWithFormat:@"{\"$undefined\":\"$undefined\"}"];
    }
    return result;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[self class]];
}

@end
