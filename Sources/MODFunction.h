//
//  MODFunction.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 12/06/2014.
//
//

#import <Foundation/Foundation.h>

@interface MODFunction : NSObject
{
    NSString *_function;
}

- (instancetype)initWithFunction:(NSString *)function;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@property (nonatomic, strong, readwrite) NSString *function;

@end
