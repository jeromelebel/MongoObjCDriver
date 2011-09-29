//
//  MODDataRegex.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 25/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MODDataRegex : NSObject
{
    NSString *_pattern;
    NSString *_options;
}

- (id)initWithPattern:(NSString *)pattern options:(NSString *)options;
- (NSString *)pattern;
- (NSString *)options;
- (NSString *)tengenString;
- (NSString *)jsonValue;

@end
