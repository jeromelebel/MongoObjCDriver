//
//  MODMinKey.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/06/2013.
//
//

#import <Foundation/Foundation.h>

@interface MODMinKey : NSObject

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@end
