//
//  MODSortedMutableDictionary.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 23/11/2011.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import "MongoObjCDriver-private.h"

@interface MODSortedMutableDictionary ()

@end

@implementation MODSortedMutableDictionary

+ (Class)contentDictionaryClass
{
    return NSMutableDictionary.class;
}

+ (Class)keyArrayClass
{
    return NSMutableArray.class;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.content = [[self.class contentDictionaryClass] dictionary];
        self.sortedKeys = [[self.class keyArrayClass] array];
    }
    return self;
}

- (instancetype)copy
{
    return [[[self class] alloc] initWithSortedDictionary:self];
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    return [[[self class] alloc] initWithSortedDictionary:self];
}

- (NSMutableDictionary *)mutableContent
{
    return (NSMutableDictionary *)self.content;
}

- (NSMutableArray *)mutableSortedKeys
{
    return (NSMutableArray *)self.sortedKeys;
}

- (void)removeObjectForKey:(id)aKey
{
    [self.mutableSortedKeys removeObject:aKey];
    [self.mutableContent removeObjectForKey:aKey];
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
    if (![self.mutableContent objectForKey:aKey]) {
        [self.mutableSortedKeys addObject:aKey];
    }
    [self.mutableContent setObject:anObject forKey:aKey];
}

@end
