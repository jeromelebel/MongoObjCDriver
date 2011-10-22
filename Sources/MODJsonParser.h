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
- (void *)openDictionaryWithPreviousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary key:(const char *)key;
- (void *)openArrayWithPreviousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary key:(const char *)key;
- (BOOL)closeDictionaryWithStructure:(void *)openedStructure;
- (BOOL)closeArrayWithStructure:(void *)openedStructure;
- (BOOL)appendTimestampWithTValue:(int)tValue iValue:(int)iValue key:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary;
- (BOOL)appendDate:(int64_t)date withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary;
- (BOOL)appendObjectId:(void *)objectId length:(size_t)length withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary;
- (BOOL)appendString:(const char *)stringValue withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary;
- (BOOL)appendLongLong:(long long)integer withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary;
- (BOOL)appendDouble:(double)doubleValue withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary;
- (BOOL)appendNullWithKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary;
- (BOOL)appendBool:(BOOL)boolValue withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary;
- (BOOL)appendRegexWithPattern:(const char *)pattern options:(const char *)options key:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary;
- (BOOL)appendDataBinary:(const char *)binary withLength:(NSUInteger)length binaryType:(char)binaryType key:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary;

@end

@interface MODJsonParser : NSObject

- (size_t)parseJsonWithCstring:(const char *)json error:(NSError **)error;
- (size_t)parseJsonWithString:(NSString *)json withError:(NSError **)error;

@end

@interface MODJsonToObjectParser : MODJsonParser<MODJsonParserProtocol>
{
    id _mainObject;
    BOOL _isMainObjectArray;
}

+ (id)objectsFromJson:(NSString *)json error:(NSError **)error;

@end
