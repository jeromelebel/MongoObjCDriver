//
//  MODUndefined.h
//  MongoHub
//
//  Created by Jérôme Lebel on 10/01/12.
//  Copyright (c) 2012 ThePeppersStudio.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MODUndefined : NSObject

- (NSString *)tengenString;
- (NSString *)jsonValue;
- (NSString *)jsonValueWithPretty:(BOOL)pretty;

@end
