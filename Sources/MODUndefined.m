//
//  MODUndefined.m
//  MongoHub
//
//  Created by Jérôme Lebel on 10/01/12.
//  Copyright (c) 2012 ThePeppersStudio.COM. All rights reserved.
//

#import "MODUndefined.h"

@implementation MODUndefined

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    if (!strictJSON) {
        return @"undefined";
    } else if (pretty) {
        return @"{ \"$undefined\": \"$undefined\" }";
    } else {
        return @"{\"$undefined\":\"$undefined\"}";
    }
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[self class]];
}

@end
