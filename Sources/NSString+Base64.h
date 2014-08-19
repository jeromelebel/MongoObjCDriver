//
//  NSString+Base64.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 28/04/2013.
//
//

#import <Foundation/Foundation.h>

@interface NSString (Base64)

- (NSData *)dataFromBase64;

@end
