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
    int _tValue;
    int _iValue;
}

- (id)initWithTValue:(int)tValue iValue:(int)iValue;

@end
