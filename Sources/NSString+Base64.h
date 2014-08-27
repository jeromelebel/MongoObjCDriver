//
//  NSString+Base64.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 28/04/2013.
//
//

#import <Foundation/Foundation.h>

@interface NSString (MODBase64)

- (NSData *)mod_dataFromBase64;

@end
