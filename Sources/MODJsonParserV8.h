//
//  MODJsonParserV8.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 01/05/13.
//
//

#import "MODJsonParser.h"

#define MODJsonParserV8ErrorDomain @"v8.error"

@interface MODJsonParserV8 : MODJsonParser

- (id)mainObject;

@end
