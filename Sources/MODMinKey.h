//
//  MODMinKey.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/06/13.
//
//

#import <Foundation/Foundation.h>

@interface MODMinKey : NSObject

- (NSString *)tengenString;
- (NSString *)jsonValue;
- (NSString *)jsonValueWithPretty:(BOOL)pretty;

@end
