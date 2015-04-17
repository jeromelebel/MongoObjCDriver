//
//  MODSortedMutableDictionary.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 23/11/2011.
//

#import "MODSortedDictionary.h"

@interface MODSortedMutableDictionary : MODSortedDictionary

- (void)removeObjectForKey:(id)aKey;
- (void)setObject:(id)anObject forKey:(id)aKey;

@end
