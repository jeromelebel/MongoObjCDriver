//
//  MODSymbol.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 29/11/2011.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MODSymbol : NSObject
{
    NSString *_value;
}

- (id)initWithValue:(NSString *)value;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@property (nonatomic, retain, readwrite) NSString *value;

@end
