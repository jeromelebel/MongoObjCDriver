//
//  MODSortedDictionary.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 05/12/2014.
//
//

#import <Foundation/Foundation.h>

@interface MODSortedDictionary : NSObject

@property (nonatomic, strong, readonly) NSDictionary *content;
@property (nonatomic, strong, readonly) NSArray *sortedKeys;
@property (nonatomic, assign, readonly) NSUInteger count;

+ (instancetype)sortedDictionary;
+ (instancetype)sortedDictionaryWithObject:(id)object forKey:(id)key;
+ (instancetype)sortedDictionaryWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)cnt;
+ (instancetype)sortedDictionaryWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
+ (instancetype)sortedDictionaryWithDictionary:(NSDictionary *)dict;
+ (instancetype)sortedDictionaryWithDictionary:(NSDictionary *)dict sortedKeys:(NSArray *)sortedKeys;
+ (instancetype)sortedDictionaryWithObjects:(NSArray *)objects forKeys:(NSArray *)keys;
+ (instancetype)sortedDictionaryWithSortedDictionary:(MODSortedDictionary *)sortedDictionary;

- (instancetype)initWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)cnt;
- (instancetype)initWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary;
- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary sortedKeys:(NSArray *)sortedKeys;
- (instancetype)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys;
- (instancetype)initWithSortedDictionary:(MODSortedDictionary *)sortedDictionary;

- (id)objectForKey:(id)aKey;
- (NSEnumerator *)keyEnumerator;

- (id)tengenJsonEncodedObject;

@end

@interface MODSortedDictionary (NSFastEnumeration) <NSFastEnumeration>

@end
