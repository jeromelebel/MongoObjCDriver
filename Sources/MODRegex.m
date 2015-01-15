//
//  MODRegex.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 25/09/2011.
//

#import "MongoObjCDriver-private.h"

@implementation MODRegex

- (instancetype)initWithPattern:(NSString *)pattern options:(NSString *)options
{
    if (self = [self init]) {
        _pattern = MOD_RETAIN(pattern);
        if (options) {
            _options = MOD_RETAIN(options);
        } else {
            _options = MOD_RETAIN(@"");
        }
    }
    return self;
}

- (void)dealloc
{
    MOD_RELEASE(_pattern);
    MOD_RELEASE(_options);
    MOD_SUPER_DEALLOC();
}

- (NSString *)pattern
{
    return _pattern;
}

- (NSString *)options
{
    return _options;
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    if (!strictJSON) {
        return [NSString stringWithFormat:@"/%@/%@", [MODClient escapeSlashesForString:_pattern], [MODClient escapeSlashesForString:_options]];
    } else if (pretty && _options && [_options length] > 0) {
        return [NSString stringWithFormat:@"{ \"$regex\": \"%@\", \"$options\": \"%@\" }", [MODClient escapeQuotesForString:_pattern], [MODClient escapeQuotesForString:_options]];
    } else if (pretty) {
        return [NSString stringWithFormat:@"{ \"$regex\": \"%@\" }", [MODClient escapeQuotesForString:_pattern]];
    } else if (_options && [_options length] > 0) {
        return [NSString stringWithFormat:@"{\"$regex\":\"%@\",\"$options\":\"%@\"}", [MODClient escapeQuotesForString:_pattern], [MODClient escapeQuotesForString:_options]];
    } else {
        return [NSString stringWithFormat:@"{\"$regex\":\"%@\"}", [MODClient escapeQuotesForString:_pattern]];
    }
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [[object pattern] isEqual:_pattern] && [[(MODRegex *)object options] isEqual:_options];
    }
    return NO;
}

@end
