//
//  MODScopeFunction.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 12/06/2014.
//
//

#import <Foundation/Foundation.h>

@class MODSortedDictionary;

@interface MODScopeFunction : NSObject

- (instancetype)initWithFunction:(NSString *)function scope:(MODSortedDictionary *)scope;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON jsonKeySortOrder:(MODJsonKeySortOrder)jsonKeySortOrder;

@property (nonatomic, copy, readonly) NSString *function;
@property (nonatomic, copy, readonly) MODSortedDictionary *scope;

@end
