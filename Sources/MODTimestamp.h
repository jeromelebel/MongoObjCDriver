//
//  MODTimestamp.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 24/09/2011.
//

#import <Foundation/Foundation.h>

@interface MODTimestamp : NSObject

- (instancetype)initWithTValue:(uint32_t)tValue iValue:(uint32_t)iValue;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;
- (NSDate *)dateValue;

@property(nonatomic, assign, readonly) uint32_t tValue;
@property(nonatomic, assign, readonly) uint32_t iValue;

@end
