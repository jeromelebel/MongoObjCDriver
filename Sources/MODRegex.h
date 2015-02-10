//
//  MODRegex.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 25/09/2011.
//

#import <Foundation/Foundation.h>

@interface MODRegex : NSObject

@property (nonatomic, copy, readonly) NSString *pattern;
@property (nonatomic, copy, readonly) NSString *options;

- (instancetype)initWithPattern:(NSString *)pattern options:(NSString *)options;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@end
