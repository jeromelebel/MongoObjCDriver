//
//  MODSymbol.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 29/11/2011.
//  Copyright (c) 2011 Fotonauts. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MODSymbol : NSObject

@property (nonatomic, strong, readwrite) NSString *value;

- (instancetype)initWithValue:(NSString *)value;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@end
