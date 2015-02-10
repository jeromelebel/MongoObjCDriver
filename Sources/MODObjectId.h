//
//  MODObjectId.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 21/09/2011.
//

#import <Foundation/Foundation.h>

#define OBJECT_ID_SIZE 12

@interface MODObjectId : NSObject

+ (BOOL)isCStringValid:(const char *)cString;
+ (BOOL)isStringValid:(NSString *)string;

- (instancetype)initWithBytes:(const unsigned char[OBJECT_ID_SIZE])bytes;
- (instancetype)initWithCString:(const char *)bytes;
- (instancetype)initWithString:(NSString *)string;
- (const unsigned char *)bytes;
- (NSString *)stringValue;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;
@end
