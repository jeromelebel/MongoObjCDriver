//
//  MODBinary.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 28/09/2011.
//

#import "MOD_internal.h"
#import "NSData+Base64.h"

@implementation MODBinary

@synthesize data = _data, binaryType = _binaryType;

+ (BOOL)isValidDataType:(unsigned char)dataType
{
    BOOL result = NO;
    
    switch (dataType) {
        case BSON_SUBTYPE_BINARY:
        case BSON_SUBTYPE_FUNCTION:
        case BSON_SUBTYPE_BINARY_DEPRECATED:
        case BSON_SUBTYPE_UUID_DEPRECATED:
        case BSON_SUBTYPE_UUID:
        case BSON_SUBTYPE_MD5:
        case BSON_SUBTYPE_USER:
            result = YES;
            break;
            
        default:
            break;
    }
    return result;
}

- (id)initWithData:(NSData *)data binaryType:(unsigned char)binaryType
{
    return [self initWithBytes:[data bytes] length:[data length] binaryType:binaryType];
}

- (id)initWithBytes:(const void *)bytes length:(NSUInteger)length binaryType:(unsigned char)binaryType
{
    if (self = [self init]) {
        _data = [[NSData alloc] initWithBytes:bytes length:length];
        _binaryType = binaryType;
    }
    return self;
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    NSString *result;
    
    if (!strictJSON && pretty) {
        result = [NSString stringWithFormat:@"BinData(%x, \"%@\")", (int)_binaryType, [_data base64String]];
    } else if (!strictJSON) {
        result = [NSString stringWithFormat:@"BinData(%x,\"%@\")", (int)_binaryType, [_data base64String]];
    } else if (pretty) {
        result = [NSString stringWithFormat:@"{ \"$binary\" : \"%@\", \"$type\" : \"%d\" }", [_data base64String], (int)_binaryType];
    } else {
        result = [NSString stringWithFormat:@"{\"$binary\":\"%@\",\"$type\":\"%d\"}", [_data base64String], (int)_binaryType];
    }
    return result;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [[object data] isEqual:_data] && [object binaryType] == _binaryType;
    }
    return NO;
}

@end
