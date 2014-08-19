//
//  MODSortedMutableDictionary.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 23/11/2011.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MODSortedMutableDictionary : NSObject
{
    NSMutableDictionary                 *_content;
    NSMutableArray                      *_sortedKeys;
}

@property (nonatomic, strong, readonly) NSDictionary *content;
@property (nonatomic, strong, readonly) NSArray *sortedKeys;
@property (nonatomic, assign, readonly) NSUInteger count;

+ (id)sortedDictionary;
+ (id)sortedDictionaryWithObject:(id)object forKey:(id)key;
+ (id)sortedDictionaryWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)cnt;
+ (id)sortedDictionaryWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
+ (id)sortedDictionaryWithDictionary:(NSDictionary *)dict;
+ (id)sortedDictionaryWithObjects:(NSArray *)objects forKeys:(NSArray *)keys;

- (id)initWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)cnt;
- (id)initWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (id)initWithDictionary:(NSDictionary *)otherDictionary;
- (id)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys;

- (void)removeObjectForKey:(id)aKey;
- (id)objectForKey:(id)aKey;
- (void)setObject:(id)anObject forKey:(id)aKey;
- (NSEnumerator *)keyEnumerator;

- (id)tengenJsonEncodedObject;

@end
