//
//  MODDocumentComparator.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 16/01/2014.
//
//

#import "MODDocumentComparator.h"
#import "MODSortedMutableDictionary.h"

@interface MODDocumentComparator ()
@property (nonatomic, readwrite, strong) MODSortedMutableDictionary *document1;
@property (nonatomic, readwrite, strong) MODSortedMutableDictionary *document2;
@property (nonatomic, readwrite, strong) NSMutableArray *differences;

@end

@implementation MODDocumentComparator

@synthesize document1 = _document1;
@synthesize document2 = _document2;
@synthesize differences = _differences;

- (instancetype)initWithDocument1:(MODSortedMutableDictionary *)document1 document2:(MODSortedMutableDictionary *)document2
{
    self = [self init];
    if (self) {
        self.document1 = document1;
        self.document2 = document2;
        self.differences = [NSMutableArray array];
    }
    return self;
}

- (void)dealloc
{
    self.document1 = nil;
    self.document2 = nil;
    self.differences = nil;
    [super dealloc];
}

- (BOOL)compareValue1:(id)value1 withValue2:(id)value2 prefix:(NSString *)prefix
{
    BOOL result = YES;
    
    if (![value1 isMemberOfClass:[value2 class]]) {
        [(NSMutableArray *)self.differences addObject:prefix];
        result = NO;
    } else if ([value1 isKindOfClass:MODSortedMutableDictionary.class]) {
        result = [self compareObject1:value1 withObject2:value2 prefix:prefix];
    } else if ([value1 isKindOfClass:NSArray.class]) {
        result = [self compareArray1:value1 withArray2:value2 prefix:prefix];
    } else if (![value1 isEqual:value2]) {
        [(NSMutableArray *)self.differences addObject:prefix];
        result = NO;
    }
    return result;
}

- (BOOL)compareObject1:(MODSortedMutableDictionary *)object1 withObject2:(MODSortedMutableDictionary *)object2 prefix:(NSString *)prefix
{
    BOOL stillContinue = YES;
    BOOL result = YES;
    NSEnumerator *enumerator1, *enumerator2;
    
    enumerator1 = object1.keyEnumerator;
    enumerator2 = object2.keyEnumerator;
    while (stillContinue) {
        NSString *key1, *key2;
        
        key1 = enumerator1.nextObject;
        key2 = enumerator2.nextObject;
        if (!key1 && !key2) {
            stillContinue = NO;
        } else if (!key2 || !key1) {
            if (prefix) {
                [(NSMutableArray *)self.differences addObject:prefix];
            } else {
                [(NSMutableArray *)self.differences addObject:@"*"];
            }
            stillContinue = NO;
            result = NO;
        } else {
            if (![key1 isEqualToString:key2]) {
                [(NSMutableArray *)self.differences addObject:@"*"];
                stillContinue = NO;
                result = NO;
            } else {
                NSString *newPrefix;
                
                if (prefix) {
                    newPrefix = [NSString stringWithFormat:@"%@.%@", prefix, key1];
                } else {
                    newPrefix = key1;
                }
                result = [self compareValue1:[object1 objectForKey:key1] withValue2:[object2 objectForKey:key2] prefix:newPrefix];
                if (!result) {
                    stillContinue = NO;
                }
            }
        }
    }
    return result;
}

- (BOOL)compareArray1:(NSArray *)array1 withArray2:(NSArray *)array2 prefix:(NSString *)prefix
{
    BOOL stillContinue = YES;
    BOOL result = YES;
    NSUInteger ii = 0;
    NSEnumerator *enumerator1, *enumerator2;
    
    enumerator1 = array1.objectEnumerator;
    enumerator2 = array2.objectEnumerator;
    while (stillContinue) {
        id object1, object2;
        
        object1 = enumerator1.nextObject;
        object2 = enumerator2.nextObject;
        if (!object1 && !object2) {
            stillContinue = NO;
        } else if (!object1 || !object2) {
            if (prefix) {
                [(NSMutableArray *)self.differences addObject:prefix];
            } else {
                [(NSMutableArray *)self.differences addObject:@"*"];
            }
            stillContinue = NO;
            result = NO;
        } else {
            NSString *newPrefix;
            
            if (prefix) {
                newPrefix = [NSString stringWithFormat:@"%@.%d", prefix, (int)ii];
            } else {
                newPrefix = [NSString stringWithFormat:@"%d", (int)ii];
            }
            result = [self compareValue1:object1 withValue2:object2 prefix:newPrefix];
            if (!result) {
                stillContinue = NO;
            }
        }
        ii++;
    }
    return result;
}

- (BOOL)compare
{
    return [self compareObject1:self.document1 withObject2:self.document2 prefix:nil];
}

@end
