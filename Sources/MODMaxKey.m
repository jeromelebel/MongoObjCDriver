//
//  MODMaxKey.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/06/13.
//
//

#import "MODMaxKey.h"

@implementation MODMaxKey

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    if (!strictJSON) {
        return @"MaxKey";
    } else if (pretty) {
        return @"{ \"$maxKey\": 1 }";
    } else {
        return @"{\"$maxKey\":1}";
    }
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[self class]];
}

@end
