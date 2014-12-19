//
//  MODSortedDictionary.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 05/12/2014.
//
//

#import <Foundation/Foundation.h>

@interface MODSortedDictionary : NSObject
{
    NSDictionary                        *_content;
    NSArray                             *_sortedKeys;
}

@property (nonatomic, readonly, strong) NSDictionary *content;
@property (nonatomic, readonly, strong) NSArray *sortedKeys;
@property (nonatomic, readonly, assign) NSUInteger count;

+ (id)sortedDictionary;
+ (id)sortedDictionaryWithObject:(id)object forKey:(id)key;
+ (id)sortedDictionaryWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)cnt;
+ (id)sortedDictionaryWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
+ (id)sortedDictionaryWithDictionary:(NSDictionary *)dict;
+ (id)sortedDictionaryWithDictionary:(NSDictionary *)dict sortedKeys:(NSArray *)sortedKeys;
+ (id)sortedDictionaryWithObjects:(NSArray *)objects forKeys:(NSArray *)keys;

- (instancetype)initWithObjects:(const id [])objects forKeys:(const id [])keys count:(NSUInteger)cnt;
- (instancetype)initWithObjectsAndKeys:(id)firstObject, ... NS_REQUIRES_NIL_TERMINATION;
- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary;
- (instancetype)initWithDictionary:(NSDictionary *)otherDictionary sortedKeys:(NSArray *)sortedKeys;
- (instancetype)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys;

- (id)objectForKey:(id)aKey;
- (NSEnumerator *)keyEnumerator;

- (id)tengenJsonEncodedObject;

@end

@interface MODSortedDictionary (NSFastEnumeration) <NSFastEnumeration>

@end
