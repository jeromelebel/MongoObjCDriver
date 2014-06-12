//
//  MODFunction.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 12/06/2014.
//
//

#import <Foundation/Foundation.h>

@interface MODFunction : NSObject
{
    NSString *_function;
}

- (id)initWithFunction:(NSString *)function;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@property (nonatomic, retain, readwrite) NSString *function;

@end
