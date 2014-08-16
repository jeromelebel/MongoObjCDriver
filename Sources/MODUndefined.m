//
//  MODUndefined.m
//  MongoHub
//
//  Created by Jérôme Lebel on 10/01/2012.
//

#import "MODUndefined.h"

@implementation MODUndefined

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    if (!strictJSON) {
        return @"undefined";
    } else if (pretty) {
        return @"{ \"$undefined\": true }";
    } else {
        return @"{\"$undefined\":true}";
    }
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[self class]];
}

@end
