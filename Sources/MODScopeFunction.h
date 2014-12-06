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
{
    NSString *_function;
    MODSortedDictionary *_scope;
}

- (instancetype)initWithFunction:(NSString *)function scope:(MODSortedDictionary *)scope;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON jsonKeySortOrder:(MODJsonKeySortOrder)jsonKeySortOrder;

@property (nonatomic, retain, readwrite) NSString *function;
@property (nonatomic, retain, readwrite) MODSortedDictionary *scope;

@end
