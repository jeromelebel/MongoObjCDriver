//
//  MODBsonComparator.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 05/12/2013.
//
//

#import "MODBsonComparator.h"
#import "bson.h"

typedef struct __BsonComparatorStack {
    bson_iter_t iterator1;
    bson_iter_t iterator2;
    bson_type_t type1;
    bson_type_t type2;
} BsonComparatorStack;

@interface MODBsonComparator ()
@property (nonatomic, readwrite, assign) void *bson1;
@property (nonatomic, readwrite, assign) void *bson2;
@property (nonatomic, readwrite, assign) void *bson1ToDestroy;
@property (nonatomic, readwrite, assign) void *bson2ToDestroy;
@property (nonatomic, readwrite, strong) NSMutableArray *differences;

@end

@implementation MODBsonComparator (Private)

- (id)init
{
    self = [super init];
    if (self) {
        self.differences = [NSMutableArray array];
    }
    return self;
}

- (id)initWithBson1:(bson_t *)bson1 bson2:(bson_t *)bson2
{
    self = [self init];
    if (self) {
        self.bson1 = bson1;
        self.bson2 = bson2;
    }
    return self;
}

@end

@implementation MODBsonComparator

@synthesize bson1 = _bson1, bson2 = _bson2, differences = _differences, bson1ToDestroy = _bson1ToDestroy, bson2ToDestroy = _bson2ToDestroy;

- (id)initWithBsonData1:(NSData *)bsonData1 bsonData2:(NSData *)bsonData2
{
    self = [self init];
    if (self) {
        self.bson1ToDestroy = bson_new_from_data(bsonData1.bytes, (int)bsonData1.length);
        self.bson2ToDestroy = bson_new_from_data(bsonData2.bytes, (int)bsonData2.length);
        self.bson1 = self.bson1ToDestroy;
        self.bson2 = self.bson2ToDestroy;
    }
    return self;
}

- (void)dealloc
{
    self.bson1 = nil;
    self.bson2 = nil;
    if (self.bson1ToDestroy) {
        bson_destroy(self.bson1ToDestroy);
    }
    if (self.bson2ToDestroy) {
        bson_destroy(self.bson2ToDestroy);
    }
    self.differences = nil;
    [super dealloc];
}

- (BOOL)compareValueWithStack:(BsonComparatorStack *)stack prefix:(NSString *)prefix
{
    BOOL result;
    
    if (stack->type1 != stack->type2) {
        [(NSMutableArray *)self.differences addObject:prefix];
        result = NO;
    } else {
        bson_iter_t iterator1 = stack->iterator1;
        bson_iter_t iterator2 = stack->iterator2;
        
        bson_iter_next(&iterator1);
        bson_iter_next(&iterator2);
        if (stack->iterator1.len - iterator1.len != stack->iterator2.len - iterator2.len || memcmp(stack->iterator1.raw, stack->iterator2.raw, stack->iterator1.len - iterator1.len) != 0) {
            BsonComparatorStack objectStack;
            
            switch (stack->type1) {
                case BSON_TYPE_DOCUMENT:
                    bson_iter_recurse(&stack->iterator1, &objectStack.iterator1);
                    bson_iter_recurse(&stack->iterator2, &objectStack.iterator2);
                    result = [self compareObjectWithStack:&objectStack prefix:prefix];
                    break;
                case BSON_TYPE_ARRAY:
                    bson_iter_recurse(&stack->iterator1, &objectStack.iterator1);
                    bson_iter_recurse(&stack->iterator2, &objectStack.iterator2);
                    result = [self compareArrayWithStack:&objectStack prefix:prefix];
                    break;
                default:
                    [(NSMutableArray *)self.differences addObject:prefix];
                    result = NO;
                    break;
            }
        } else {
            result = YES;
        }
    }
    return result;
}

- (BOOL)compareObjectWithStack:(BsonComparatorStack *)stack prefix:(NSString *)prefix
{
    BOOL stillContinue = YES;
    BOOL result = YES;
    
    while (stillContinue) {
        if (bson_iter_next(&stack->iterator1)) {
            stack->type1 = bson_iter_type(&stack->iterator1);
        } else {
            stack->type1 = BSON_TYPE_EOD;
        }
        if (bson_iter_next(&stack->iterator2)) {
            stack->type2 = bson_iter_type(&stack->iterator2);
        } else {
            stack->type2 = BSON_TYPE_EOD;
        }
        if (stack->type1 == BSON_TYPE_EOD && stack->type2 == BSON_TYPE_EOD) {
            stillContinue = NO;
        } else if (stack->type1 != stack->type2) {
            if (prefix) {
                [(NSMutableArray *)self.differences addObject:prefix];
            } else {
                [(NSMutableArray *)self.differences addObject:@"*"];
            }
            stillContinue = NO;
            result = NO;
        } else {
            NSString *key1;
            NSString *key2;
            
            key1 = [[NSString alloc] initWithUTF8String:bson_iter_key(&stack->iterator1)];
            key2 = [[NSString alloc] initWithUTF8String:bson_iter_key(&stack->iterator2)];
            if (![key1 isEqualToString:key2]) {
                [(NSMutableArray *)self.differences addObject:@"*"];
                stillContinue = NO;
                result = NO;
            } else {
                NSString *newPrefix;
                
                if (prefix) {
                    newPrefix = [[NSString alloc] initWithFormat:@"%@.%@", prefix, key1];
                } else {
                    newPrefix = [key1 retain];
                }
                result = [self compareValueWithStack:stack prefix:newPrefix];
                [newPrefix release];
                if (!result) {
                    stillContinue = NO;
                }
            }
            [key1 release];
            [key2 release];
        }
    }
    return result;
}

- (BOOL)compareArrayWithStack:(BsonComparatorStack *)stack prefix:(NSString *)prefix
{
    BOOL stillContinue = YES;
    BOOL result = YES;
    NSUInteger ii = 0;
    
    while (stillContinue) {
        bson_iter_next(&stack->iterator1);
        bson_iter_next(&stack->iterator2);
        stack->type1 = bson_iter_type(&stack->iterator1);
        stack->type2 = bson_iter_type(&stack->iterator2);
        if (stack->type1 == BSON_TYPE_EOD && stack->type2 == BSON_TYPE_EOD) {
            stillContinue = NO;
        } else if (stack->type1 != stack->type2) {
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
                newPrefix = [[NSString alloc] initWithFormat:@"%@.%d", prefix, (int)ii];
            } else {
                newPrefix = [[NSString alloc] initWithFormat:@"%d", (int)ii];
            }
            result = [self compareValueWithStack:stack prefix:newPrefix];
            [newPrefix release];
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
    BsonComparatorStack stack;
    
    bson_iter_init(&stack.iterator1, self.bson1);
    bson_iter_init(&stack.iterator2, self.bson2);
    return [self compareObjectWithStack:&stack prefix:nil];
}

@end
