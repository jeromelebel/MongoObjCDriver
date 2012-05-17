//
//  MODSortedMutableDictionary.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 23/11/11.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import "MODSortedMutableDictionary.h"

@implementation MODSortedMutableDictionary

@synthesize content = _content, sortedKeys = _sortedKeys;

+ (id)sortedDictionary
{
    return [[[self alloc] init] autorelease];
}

+ (id)sortedDictionaryWithObject:(id)object forKey:(id)key
{
    return [[[self alloc] initWithObjects:&object forKeys:&key count:1] autorelease];
}

+ (id)sortedDictionaryWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)cnt
{
    return [[[self alloc] initWithObjects:objects forKeys:keys count:cnt] autorelease];
}

+ (id)sortedDictionaryWithObjectsAndKeys:(id)firstObject, ...
{
    va_list(ap);
    id object;
    id key;
    MODSortedMutableDictionary *result;
    
    result = [[[self alloc] init] autorelease];
    object = firstObject;
    va_start(ap, firstObject);
    while (object != nil) {
        key = va_arg(ap, id);
        NSAssert(key, @"can't have nil as a key");
        [result setObject:object forKey:key];
        object = va_arg(ap, id);
    }
    va_end(ap);
    return result;
}

+ (id)sortedDictionaryWithDictionary:(NSDictionary *)dict
{
    return [[[self alloc] initWithDictionary:dict] autorelease];
}

+ (id)sortedDictionaryWithObjects:(NSArray *)objects forKeys:(NSArray *)keys
{
    return [[[self alloc] initWithObjects:objects forKeys:keys] autorelease];
}

- (id)initWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)cnt
{
    if (self = [self init]) {
        NSUInteger ii;
        
        for (ii = 0; ii < cnt; ii++) {
            [self setObject:objects[ii] forKey:keys[ii]];
        }
    }
    return self;
}

- (id)initWithObjectsAndKeys:(id)firstObject, ...
{
    if (self = [self init]) {
        va_list(ap);
        id object;
        id key;
        
        va_start(ap, firstObject);
        object = firstObject;
        while (object != nil) {
            key = va_arg(ap, id);
            NSAssert(key, @"can't have nil as a key");
            [self setObject:object forKey:key];
            object = va_arg(ap, id);
        }
        va_end(ap);
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)otherDictionary
{
    if (self = [self init]) {
        [_content addEntriesFromDictionary:otherDictionary];
        [_sortedKeys addObjectsFromArray:[otherDictionary allKeys]];
    }
    return self;
}

- (id)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys
{
    if (self = [self init]) {
        NSUInteger ii, count;
        
        count = [keys count];
        for (ii = 0; ii < count; ii++) {
            [self setObject:[objects objectAtIndex:ii] forKey:[keys objectAtIndex:ii]];
        }
    }
    return self;
}

- (id)init
{
    if (self = [super init]) {
        _content = [[NSMutableDictionary alloc] init];
        _sortedKeys = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [_content release];
    [_sortedKeys release];
    [super dealloc];
}

- (void)removeObjectForKey:(id)aKey
{
    [_sortedKeys removeObject:aKey];
    [_content removeObjectForKey:aKey];
}

- (void)setObject:(id)anObject forKey:(id)aKey
{
    if (![_content objectForKey:aKey]) {
        [_sortedKeys addObject:aKey];
    }
    [_content setObject:anObject forKey:aKey];
}

- (id)objectForKey:(id)aKey
{
    return [_content objectForKey:aKey];
}

- (NSArray *)allKeys
{
    return _sortedKeys;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [self.content isEqual:[object content]] && [self.sortedKeys isEqual:[object sortedKeys]];
    }
    return NO;
}

- (NSUInteger)count
{
    return [_content count];
}

- (NSString *)description
{
    NSMutableDictionary *hack;
    NSString *result;
    
    hack = [[NSMutableDictionary alloc] init];
    [hack addEntriesFromDictionary:_content];
    [hack setObject:_sortedKeys forKey:@"__sorted_keys__"];
    result = [[hack description] retain];
    [hack release];
    return [result autorelease];
}

@end
