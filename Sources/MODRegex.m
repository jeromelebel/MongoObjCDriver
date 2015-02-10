//
//  MODRegex.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 25/09/2011.
//

#import "MongoObjCDriver-private.h"

@interface MODRegex ()
@property (nonatomic, copy, readwrite) NSString *pattern;
@property (nonatomic, copy, readwrite) NSString *options;

@end

@implementation MODRegex

- (instancetype)initWithPattern:(NSString *)pattern options:(NSString *)options
{
    if (self = [self init]) {
        self.pattern = pattern;
        if (options) {
            self.options = options;
        } else {
            self.options = @"";
        }
    }
    return self;
}

- (void)dealloc
{
    self.pattern = nil;
    self.options = nil;
    MOD_SUPER_DEALLOC();
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    if (!strictJSON) {
        return [NSString stringWithFormat:@"/%@/%@", [MODClient escapeSlashesForString:self.pattern], [MODClient escapeSlashesForString:self.options]];
    } else if (pretty && self.options && [self.options length] > 0) {
        return [NSString stringWithFormat:@"{ \"$regex\": \"%@\", \"$options\": \"%@\" }", [MODClient escapeQuotesForString:self.pattern], [MODClient escapeQuotesForString:self.options]];
    } else if (pretty) {
        return [NSString stringWithFormat:@"{ \"$regex\": \"%@\" }", [MODClient escapeQuotesForString:self.pattern]];
    } else if (self.options && [self.options length] > 0) {
        return [NSString stringWithFormat:@"{\"$regex\":\"%@\",\"$options\":\"%@\"}", [MODClient escapeQuotesForString:self.pattern], [MODClient escapeQuotesForString:self.options]];
    } else {
        return [NSString stringWithFormat:@"{\"$regex\":\"%@\"}", [MODClient escapeQuotesForString:self.pattern]];
    }
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [[object pattern] isEqual:self.pattern] && [[(MODRegex *)object options] isEqual:self.options];
    }
    return NO;
}

@end
