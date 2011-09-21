//
//  MODObjectId.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 21/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MODObjectId : NSObject
{
    const char data[12];
}
- (id)initWithBytes:(const char *)bytes;
- (const char *)bytes;
@end
