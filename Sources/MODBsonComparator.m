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
    bson_iterator iterator1;
    bson_iterator iterator2;
    bson_type type1;
    bson_type type2;
} BsonComparatorStack;

@interface MODBsonComparator ()
@property (nonatomic, readwrite, strong) NSData *bson1;
@property (nonatomic, readwrite, strong) NSData *bson2;
@property (nonatomic, readwrite, strong) NSMutableArray *differences;

@end

@implementation MODBsonComparator

- (id)initWithBson1:(NSData *)bson1 bson2:(NSData *)bson2
{
    self = [self init];
    if (self) {
        self.differences = [NSMutableArray array];
        self.bson1 = bson1;
        self.bson2 = bson2;
    }
    return self;
}

- (void)dealloc
{
    self.bson1 = nil;
    self.bson2 = nil;
    self.differences = nil;
    [super dealloc];
}

- (void)compareValueWithStack:(BsonComparatorStack *)stack prefix:(NSString *)prefix
{
    if (stack->type1 != stack->type2) {
        [(NSMutableArray *)self.differences addObject:[NSString stringWithFormat:@"%@%@", prefix, @"*"]];
    } else {
        bson_iterator iterator1 = stack->iterator1;
        bson_iterator iterator2 = stack->iterator2;
        
        bson_iterator_next(&iterator1);
        bson_iterator_next(&iterator2);
        if (iterator1.cur - stack->iterator1.cur != iterator2.cur - stack->iterator2.cur) {
            BsonComparatorStack objectStack;
            
            switch (stack->type1) {
                case BSON_OBJECT:
                    bson_iterator_subiterator(&stack->iterator1, &objectStack.iterator1);
                    bson_iterator_subiterator(&stack->iterator2, &objectStack.iterator2);
                    [self compareObjectWithStack:&objectStack prefix:prefix];
                    break;
                case BSON_ARRAY:
                    break;
                default:
                    [(NSMutableArray *)self.differences addObject:prefix];
                    break;
            }
        }
    }
}

- (void)compareObjectWithStack:(BsonComparatorStack *)stack prefix:(NSString *)prefix
{
    BOOL stillContinue = YES;
    
    while (stillContinue) {
        stack->type1 = bson_iterator_next(&stack->iterator1);
        stack->type2 = bson_iterator_next(&stack->iterator2);
        if (stack->type1 == BSON_EOO && stack->type2 == BSON_EOO) {
            stillContinue = NO;
        } else if (stack->type1 != BSON_EOO || stack->type2 != BSON_EOO) {
            if (prefix) {
                [(NSMutableArray *)self.differences addObject:prefix];
            } else {
                [(NSMutableArray *)self.differences addObject:@"*"];
            }
            stillContinue = NO;
        } else {
            NSString *key1;
            NSString *key2;
            
            key1 = [[NSString alloc] initWithUTF8String:bson_iterator_key(&stack->iterator1)];
            key2 = [[NSString alloc] initWithUTF8String:bson_iterator_key(&stack->iterator2)];
            if (![key1 isEqualToString:key2]) {
                [(NSMutableArray *)self.differences addObject:@"*"];
                stillContinue = NO;
            } else {
                NSString *newPrefix;
                
                if (prefix) {
                    newPrefix = [[NSString alloc] initWithFormat:@"%@.%@", prefix, key1];
                } else {
                    newPrefix = [key1 retain];
                }
                [self compareValueWithStack:stack prefix:newPrefix];
                [newPrefix release];
            }
            [key1 release];
            [key2 release];
        }
    }
}

- (void)compareArrayWithStack:(BsonComparatorStack *)stack prefix:(NSString *)prefix
{
    BOOL stillContinue = YES;
    NSUInteger ii = 0;
    
    while (stillContinue) {
        stack->type1 = bson_iterator_next(&stack->iterator1);
        stack->type2 = bson_iterator_next(&stack->iterator2);
        if (stack->type1 == BSON_EOO && stack->type2 == BSON_EOO) {
            stillContinue = NO;
        } else if (stack->type1 != BSON_EOO || stack->type2 != BSON_EOO) {
            if (prefix) {
                [(NSMutableArray *)self.differences addObject:prefix];
            } else {
                [(NSMutableArray *)self.differences addObject:@"*"];
            }
            stillContinue = NO;
        } else {
            NSString *newPrefix;
            
            if (prefix) {
                newPrefix = [[NSString alloc] initWithFormat:@"%@.%ld", prefix, ii];
            } else {
                newPrefix = [[NSString alloc] initWithFormat:@"%ld", ii];
            }
            [self compareValueWithStack:stack prefix:newPrefix];
            [newPrefix release];
        }
        ii++;
    }
}

- (void)compare
{
    BsonComparatorStack stack;
    
    bson_iterator_from_buffer(&stack.iterator1, self.bson1.bytes);
    bson_iterator_from_buffer(&stack.iterator2, self.bson2.bytes);
    [self compareObjectWithStack:&stack prefix:nil];
}

@end
