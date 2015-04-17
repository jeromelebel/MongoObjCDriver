//
//  MODSymbol.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 29/11/2011.
//

#import "MongoObjCDriver-private.h"

@implementation MODSymbol

- (instancetype)initWithValue:(NSString *)value
{
    if (self = [self init]) {
        _value = MOD_RETAIN(value);
    }
    return self;
}

- (void)dealloc
{
    MOD_RELEASE(_value);
    MOD_SUPER_DEALLOC();
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
