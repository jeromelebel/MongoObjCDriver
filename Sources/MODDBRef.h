//
//  MODDBRef.h
//  MongoHub
//
//  Created by Jérôme Lebel on 29/09/2011.
//

#import <Foundation/Foundation.h>

@interface MODDBRef : NSObject
{
    NSString *_refValue;
    unsigned char _idValue[12];
}
@property(nonatomic, readonly, strong) NSString *refValue;

- (id)initWithRefValue:(NSString *)refValue idValue:(const unsigned char[12])idValue;
- (const unsigned char *)idValue;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@end
