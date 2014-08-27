//
//  NSData+Base64.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 28/04/2013.
//
//

#import "NSData+Base64.h"

static char base64chars[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

#define CHAR_AT_INDEX(buffer, index) ((buffer >> (index * 6)) & 63)

@implementation NSData (MODBase64)

- (NSString *)mod_base64String
{
    NSUInteger ii, dataLength = self.length;
    NSMutableString *result = [NSMutableString stringWithCapacity:(dataLength / 3 * 4) + (((dataLength % 3) > 0)?4:0)];
    const unsigned char *rawData = [self bytes];
    
    for (ii = 0; ii < dataLength; ii += 3) {
        uint32_t buffer;
        unsigned char string[5];
        
        buffer = rawData[ii] << 16;
        if (ii + 1 < dataLength) {
            buffer += rawData[ii + 1] << 8;
            if (ii + 2 < dataLength) {
                buffer += rawData[ii + 2];
            }
        }
        string[0] = base64chars[CHAR_AT_INDEX(buffer, 3)];
        string[1] = base64chars[CHAR_AT_INDEX(buffer, 2)];
        if (dataLength - ii == 1) {
            string[2] = '=';
            string[3] = '=';
        } else if (dataLength - ii == 2) {
            string[2] = base64chars[CHAR_AT_INDEX(buffer, 1)];
            string[3] = '=';
        } else {
            string[2] = base64chars[CHAR_AT_INDEX(buffer, 1)];
            string[3] = base64chars[CHAR_AT_INDEX(buffer, 0)];
        }
        string[4] = 0;
        [result appendFormat:@"%s", string];
    }
    return result;
}

@end
