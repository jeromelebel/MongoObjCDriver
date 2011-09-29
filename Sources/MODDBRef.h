//
//  MODDBRef.h
//  MongoHub
//
//  Created by Jérôme Lebel on 29/09/11.
//  Copyright (c) 2011 ThePeppersStudio.COM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MODDBRef : NSObject
{
    NSString *_refValue;
    unsigned char _idValue[12];
}

- (id)initWithRefValue:(NSString *)refValue idValue:(const unsigned char[12])idValue;
- (const unsigned char *)idValue;
- (NSString *)tengenString;
- (NSString *)jsonValue;

@property(nonatomic, readonly, retain) NSString *refValue;

@end
