//
//  MODJsonParser.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 24/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MODJsonParserProtocol <NSObject>

- (void)startMainDictionary;
- (void)startMainArray;
- (void)finishMainDictionary;
- (void)finishMainArray;
- (BOOL)isMainObjectArray;
- (void *)mainObject;
- (void *)openDictionaryWithPreviousStructure:(void *)structure key:(const char *)key index:(int)index;
- (void *)openArrayWithPreviousStructure:(void *)structure key:(const char *)key index:(int)index;
- (BOOL)closeDictionaryWithStructure:(void *)openedStructure;
- (BOOL)closeArrayWithStructure:(void *)openedStructure;
- (BOOL)appendTimestampWithTValue:(int)tValue iValue:(int)iValue key:(const char *)key previousStructure:(void *)structure index:(int)index;
- (BOOL)appendDate:(int64_t)date withKey:(const char *)key previousStructure:(void *)structure index:(int)index;
- (BOOL)appendObjectId:(void *)objectId length:(size_t)length withKey:(const char *)key previousStructure:(void *)structure index:(int)index;
- (BOOL)appendString:(const char *)stringValue withKey:(const char *)key previousStructure:(void *)structure index:(int)index;
- (BOOL)appendLongLong:(long long)integer withKey:(const char *)key previousStructure:(void *)structure index:(int)index;
- (BOOL)appendDouble:(double)doubleValue withKey:(const char *)key previousStructure:(void *)structure index:(int)index;
- (BOOL)appendNullWithKey:(const char *)key previousStructure:(void *)structure index:(int)index;
- (BOOL)appendBool:(BOOL)boolValue withKey:(const char *)key previousStructure:(void *)structure index:(int)index;
- (BOOL)appendSymbol:(NSString *)value withKey:(const char *)key previousStructure:(void *)structure index:(int)index;
- (BOOL)appendRegexWithPattern:(const char *)pattern options:(const char *)options key:(const char *)key previousStructure:(void *)structure index:(int)index;
- (BOOL)appendDataBinary:(const char *)binary withLength:(NSUInteger)length binaryType:(char)binaryType key:(const char *)key previousStructure:(void *)structure index:(int)index;
- (BOOL)appendUndefinedWithKey:(const char *)key previousStructure:(void *)structure index:(int)index;

@end

@interface MODJsonParser : NSObject
{
    void *_tokener;
    
    size_t _totalParsedLength;
    BOOL _multiPartParsing;
}

@property (nonatomic, assign, readwrite) BOOL multiPartParsing;
@property (nonatomic, assign, readonly) size_t totalParsedLength;

- (size_t)parseJsonWithCstring:(const char *)json error:(NSError **)error;
- (size_t)parseJsonWithString:(NSString *)json error:(NSError **)error;
- (BOOL)parsingDone;

@end

@interface MODJsonToObjectParser : MODJsonParser<MODJsonParserProtocol>
{
    id _mainObject;
    BOOL _isMainObjectArray;
}

+ (id)objectsFromJson:(NSString *)json error:(NSError **)error;

@end
