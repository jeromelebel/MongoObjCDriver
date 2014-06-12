//
//  MODScopeFunction.h
//  mongo-objc-driver
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

- (id)initWithFunction:(NSString *)function scope:(MODSortedMutableDictionary *)scope;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@property (nonatomic, retain, readwrite) NSString *function;
@property (nonatomic, retain, readwrite) MODSortedMutableDictionary *scope;

@end
