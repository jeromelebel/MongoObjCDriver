//
//  MODDataBinary.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 28/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MODDataBinary : NSObject
{
    NSData *_data;
    char _binaryType;
}

- (id)initWithData:(NSData *)data binaryType:(char)binaryType;
- (id)initWithBytes:(const void *)bytes length:(NSUInteger)length binaryType:(char)binaryType;

@property(nonatomic, readonly, assign)char binaryType;
@property(nonatomic, readonly, assign)NSData *data;

@end
