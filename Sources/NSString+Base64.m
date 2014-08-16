//
//  NSString+Base64.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 28/04/2013.
//
//

#import "NSString+Base64.h"

#define CONVERT_CHAR_TO_BYTE(mychar) ((mychar >= 'A' && mychar <= 'Z')?(mychar - 'A'):(mychar >= 'a' && mychar <= 'z')?(mychar - 'a' + 26):(mychar >= '0' && mychar <= '9')?(mychar - '0' + 52):(mychar == '+')?62:(mychar == '/')?63:-1)

@implementation NSString (Base64)

- (NSData *)dataFromBase64
{
    NSUInteger ii, stringLength = self.length;
    NSMutableData *result = [NSMutableData dataWithCapacity:stringLength / 4 * 3];
    const char *cString = self.UTF8String;
    uint32_t buffer = 0;
    NSUInteger charCounter = 0;
    
    for (ii = 0; ii < stringLength; ii++) {
        char byte;
        
        byte = CONVERT_CHAR_TO_BYTE(cString[ii]);
        if (byte >= 0) {
            buffer = buffer << 6;
            buffer += byte;
            charCounter++;
        } else if (cString[ii] == '=') {
            break;
        }
        if (charCounter == 4) {
            buffer = (buffer >> 16) + (buffer & (255 << 8)) + ((buffer & 255) << 16);
            [result appendBytes:&buffer length:3];
            charCounter = 0;
            buffer = 0;
        }
    }
    if (charCounter == 2) {
        buffer = buffer >> 4;
        [result appendBytes:&buffer length:1];
    } else if (charCounter == 3) {
        buffer = (buffer >> 10) + ((buffer << 6) & (255 << 8));
        [result appendBytes:&buffer length:2];
    }
    return result;
}

@end
