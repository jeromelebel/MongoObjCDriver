//
//  MODDBRef.h
//  MongoHub
//
//  Created by Jérôme Lebel on 29/09/11.
//

#import <Foundation/Foundation.h>

@interface MODDBRef : NSObject
{
    NSString *_refValue;
    unsigned char _idValue[12];
}

- (id)initWithRefValue:(NSString *)refValue idValue:(const unsigned char[12])idValue;
- (const unsigned char *)idValue;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@property(nonatomic, readonly, retain) NSString *refValue;

@end
