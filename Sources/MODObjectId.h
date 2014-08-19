//
//  MODObjectId.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 21/09/2011.
//

#import <Foundation/Foundation.h>

#define OBJECT_ID_SIZE 12

@interface MODObjectId : NSObject
{
    const unsigned char _bytes[12];
}
+ (BOOL)isCStringValid:(const char *)cString;
+ (BOOL)isStringValid:(NSString *)string;

- (id)initWithBytes:(const unsigned char[OBJECT_ID_SIZE])bytes;
- (id)initWithCString:(const char *)bytes;
- (id)initWithString:(NSString *)string;
- (const unsigned char *)bytes;
- (NSString *)stringValue;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;
@end
