//
//  MODMaxKey.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/06/13.
//
//

#import "MODMaxKey.h"

@implementation MODMaxKey

- (NSString *)tengenString
{
    return @"MaxKey";
}

- (NSString *)jsonValue
{
    return [self jsonValueWithPretty:YES];
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty
{
    NSString *result;
    
    if (pretty) {
        result = @"{ \"$maxKey\": 1 }";
    } else {
        result = @"{\"$maxKey\":1}";
    }
    return result;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[self class]];
}

@end
