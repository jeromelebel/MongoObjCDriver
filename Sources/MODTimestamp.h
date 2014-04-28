//
//  MODTimestamp.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 24/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MODTimestamp : NSObject
{
    struct timeval _timestamp;
}

- (id)initWithTValue:(int)tValue iValue:(int)iValue;
- (id)initWithTimestamp:(struct timeval *)timestamp;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;
- (NSDate *)dateValue;

@property(nonatomic, readonly, assign) int tValue;
@property(nonatomic, readonly, assign) int iValue;

@end
