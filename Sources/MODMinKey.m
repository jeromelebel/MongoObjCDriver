//
//  MODMinKey.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/06/2013.
//
//

#import "MODMinKey.h"

@implementation MODMinKey

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    NSString *result;
    
    if (!strictJSON) {
        result = @"MinKey";
    } else if (pretty) {
        result = @"{ \"$minKey\": 1 }";
    } else {
        result = @"{\"$minKey\":1}";
    }
    return result;
}

- (BOOL)isEqual:(id)object
{
    return [object isKindOfClass:[self class]];
}

@end
