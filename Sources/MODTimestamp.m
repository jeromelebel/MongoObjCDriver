//
//  MODTimestamp.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 24/09/2011.
//

#import "MongoObjCDriver-private.h"

@interface MODTimestamp ()

@property(nonatomic, assign, readwrite) uint32_t tValue;
@property(nonatomic, assign, readwrite) uint32_t iValue;

@end

@implementation MODTimestamp

- (instancetype)initWithTValue:(uint32_t)tValue iValue:(uint32_t)iValue
{
    if (self = [self init]) {
        self.iValue = iValue;
        self.tValue = tValue;
    }
    return self;
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    if (!strictJSON) {
        return [NSString stringWithFormat:@"Timestamp(%d, %d)", self.tValue, self.iValue];
    } else if (pretty) {
        return [NSString stringWithFormat:@"{ \"$timestamp\" : [ %d, %d ] }", self.tValue, self.iValue];
    } else {
        return [NSString stringWithFormat:@"{\"$timestamp\":[%d,%d]}", self.tValue, self.iValue];
    }
}

- (NSDate *)dateValue
{
    return [NSDate dateWithTimeIntervalSince1970:self.tValue];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return self.tValue == [object tValue] && self.iValue == [object iValue];
    }
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, (%d, %d)>", self.class, self, self.tValue, self.iValue];
}

@end
