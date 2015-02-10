//
//  MODBinary.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 28/09/2011.
//

#import <Foundation/Foundation.h>

@interface MODBinary : NSObject

@property(nonatomic, assign, readonly) char binaryType;
@property(nonatomic, copy, readonly) NSData *binaryData;

+ (BOOL)isValidDataType:(unsigned char)dataType;

- (instancetype)initWithData:(NSData *)data binaryType:(unsigned char)binaryType;
- (instancetype)initWithBytes:(const void *)bytes length:(NSUInteger)length binaryType:(unsigned char)binaryType;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@end
