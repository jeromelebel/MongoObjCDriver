//
//  MODMinKey.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/06/13.
//
//

#import "MODMinKey.h"

@implementation MODMinKey

- (NSString *)tengenString
{
    return @"MinKey";
}

- (NSString *)jsonValue
{
    return [self jsonValueWithPretty:YES];
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty
{
    NSString *result;
    
    if (pretty) {
        result = [NSString stringWithFormat:@"MinKey"];
    } else {
        result = [NSString stringWithFormat:@"MinKey"];
    }
    return result;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[self class]];
}

@end
