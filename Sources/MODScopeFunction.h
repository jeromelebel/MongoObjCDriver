//
//  MODScopeFunction.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 12/06/2014.
//
//

#import <Foundation/Foundation.h>

@class MODSortedMutableDictionary;

@interface MODScopeFunction : NSObject
{
    NSString *_function;
    MODSortedMutableDictionary *_scope;
}

- (instancetype)initWithFunction:(NSString *)function scope:(MODSortedMutableDictionary *)scope;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON jsonKeySortOrder:(MODJsonKeySortOrder)jsonKeySortOrder;

@property (nonatomic, retain, readwrite) NSString *function;
@property (nonatomic, retain, readwrite) MODSortedMutableDictionary *scope;

@end
