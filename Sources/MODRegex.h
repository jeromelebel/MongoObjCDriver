//
//  MODRegex.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 25/09/2011.
//

#import <Foundation/Foundation.h>

@interface MODRegex : NSObject
{
    NSString *_pattern;
    NSString *_options;
}

- (id)initWithPattern:(NSString *)pattern options:(NSString *)options;
- (NSString *)pattern;
- (NSString *)options;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@end
