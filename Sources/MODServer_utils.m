//
//  MODServer.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODServer(utils_internal)

+ (NSError *)errorWithErrorDomain:(NSString *)errorDomain code:(NSInteger)code descriptionDetails:(NSString *)descriptionDetails
{
    return nil;
//    NSError *error;
//    NSString *description = nil;
//    
//    if ([errorDomain isEqualToString:MODMongoErrorDomain]) {
//        switch (code) {
//            case MONGO_CONN_SUCCESS:
//                description = @"Connection success!";
//                break;
//            case MONGO_CONN_NO_SOCKET:
//                description = @"Could not create a socket.";
//                break;
//            case MONGO_CONN_FAIL:
//                description = @"An error occured while calling connect().";
//                break;
//            case MONGO_CONN_ADDR_FAIL:
//                description = @"Cannot get an ip address with this domain name.";
//                break;
//            case MONGO_CONN_NOT_MASTER:
//                description = @"Connected to a non-master node (read-only).";
//                break;
//            case MONGO_CONN_BAD_SET_NAME:
//                description = @"Given rs name doesn't match this replica set.";
//                break;
//            case MONGO_CONN_NO_PRIMARY:
//                description = @"Can't find primary in replica set. Connection closed.";
//                break;
//            case MONGO_IO_ERROR:
//                description = @"An error occurred while reading or writing on the socket.";
//                break;
//            case MONGO_READ_SIZE_ERROR:
//                description = @"The response is not the expected length.";
//                break;
//            case MONGO_COMMAND_FAILED:
//                if (descriptionDetails) {
//                    description = [NSString stringWithFormat:@"Error returned by the server: \"%@\"", descriptionDetails];
//                    descriptionDetails = nil;
//                } else {
//                    description = @"The command returned with 'ok' value of 0.";
//                }
//                break;
//            case MONGO_BSON_INVALID:
//                description = @"BSON not valid for the specified op.";
//                break;
//            case MONGO_BSON_NOT_FINISHED:
//                description = @"BSON object has not been finished.";
//                break;
//            default:
//                description = @"";
//                break;
//        }
//        if (descriptionDetails) {
//            description = [NSString stringWithFormat:@"%@ - %@", description, descriptionDetails];
//        }
//    } else if ([errorDomain isEqualToString:MODJsonParserErrorDomain]) {
//        switch (code) {
//            case JSON_PARSER_ERROR_EXPECTED_END:
//                description = @"json end is unexpected";
//                break;
//            default:
//                break;
//        }
//        if (descriptionDetails) {
//            description = [NSString stringWithFormat:@"%@ - \"%@\"", description, descriptionDetails];
//        }
//    } else if ([errorDomain isEqualToString:MODMongoCursorErrorDomain]) {
//        switch (code) {
//            case MONGO_CURSOR_EXHAUSTED:
//                description = @"The cursor has no more results.";
//                break;
//            case MONGO_CURSOR_INVALID:
//                description = @"The cursor has timed out or is not recognized.";
//                break;
//            case MONGO_CURSOR_PENDING:
//                description = @"Tailable cursor still alive but no data.";
//                break;
//            case MONGO_CURSOR_QUERY_FAIL:
//                description = @"The server returned an '$err' object, indicating query failure.";
//                break;
//            case MONGO_CURSOR_BSON_ERROR:
//                description = @"Something is wrong with the BSON provided.";
//                break;
//            case MONGO_CURSOR_BSON_TOO_LARGE:
//                description = @"the message to send is too long";
//                break;
//            default:
//                description = @"";
//                break;
//        }
//        if (descriptionDetails) {
//            description = [NSString stringWithFormat:@"%@ - \"%@\"", description, descriptionDetails];
//        }
//    } else {
//        if (descriptionDetails) {
//            description = [NSString stringWithFormat:@"Unknown error %ld (%@) - %@", (long)code, errorDomain, descriptionDetails];
//        } else {
//            description = [NSString stringWithFormat:@"Unknown error %ld (%@)", (long)code, errorDomain];
//        }
//    }
//    if (!description) {
//        description = [NSString stringWithFormat:@"Unknown error %ld - %@", (long)code, errorDomain];
//    }
//    error = [NSError errorWithDomain:errorDomain code:code userInfo:[NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, nil]];
//    return error;
}

+ (NSError *)errorFromBsonError:(bson_error_t)error
{
    return [NSError errorWithDomain:[NSString stringWithFormat:@"bson-%d", error.domain] code:error.code userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithUTF8String:error.message],NSLocalizedDescriptionKey, nil]];
}

//+ (NSError *)errorFromMongo:(mongo_ptr)mongo
//{
//    NSError *result = nil;
//    
//    if (mongo->err != MONGO_CONN_SUCCESS) {
//        result = [self errorWithErrorDomain:MODMongoErrorDomain code:mongo->err descriptionDetails:nil];
//    }
//    return result;
//}

+ (id)objectFromBsonIterator:(bson_iter_t *)iterator
{
    id result = nil;
    bson_iter_t subIterator;
    
    switch (bson_iter_type(iterator)) {
        case BSON_TYPE_EOD:
            NSLog(@"*********************** %d %d", bson_iter_type(iterator), __LINE__);
            NSAssert(NO, @"BSON_TYPE_EOO");
            break;
        case BSON_TYPE_DOUBLE:
            result = [NSNumber numberWithDouble:bson_iter_double(iterator)];
            break;
        case BSON_TYPE_UTF8:
            result = [NSString stringWithUTF8String:bson_iter_utf8(iterator, NULL)];
            break;
        case BSON_TYPE_DOCUMENT:
            result = [[[MODSortedMutableDictionary alloc] init] autorelease];
            bson_iter_recurse(iterator, &subIterator);
            while (bson_iter_next(&subIterator)) {
                id value;
                
                value = [self objectFromBsonIterator:&subIterator];
                if (value) {
                    NSString *key;
                    
                    key = [[NSString alloc] initWithUTF8String:bson_iter_key(&subIterator)];
                    [result setObject:value forKey:key];
                    [key release];
                }
            }
            break;
        case BSON_TYPE_ARRAY:
            result = [NSMutableArray array];
            bson_iter_recurse(iterator, &subIterator);
            while (bson_iter_next(&subIterator)) {
                id value;
                
                value = [self objectFromBsonIterator:&subIterator];
                if (value) {
                    [result addObject:value];
                }
            }
            break;
        case BSON_TYPE_BINARY:
            {
                NSData *data;
                bson_subtype_t subType;
                uint32_t length;
                const uint8_t *binary;
                
                bson_iter_binary(iterator, &subType, &length, &binary);
                data = [[NSData alloc] initWithBytes:binary length:length];
                result = [[[MODBinary alloc] initWithData:data binaryType:subType] autorelease];
                [data release];
            }
            break;
        case BSON_TYPE_UNDEFINED:
            result = [[[MODUndefined alloc] init] autorelease];
            break;
        case BSON_TYPE_OID:
            result = [[[MODObjectId alloc] initWithOid:bson_iter_oid(iterator)] autorelease];
            break;
        case BSON_TYPE_BOOL:
            result = [NSNumber numberWithBool:bson_iter_bool(iterator) == true];
            break;
        case BSON_TYPE_DATE_TIME:
            result = [NSDate dateWithTimeIntervalSince1970:bson_iter_date_time(iterator) / 1000.0];
            break;
        case BSON_TYPE_NULL:
            result = [NSNull null];
            break;
        case BSON_TYPE_REGEX:
            {
                const char *cStringOptions;
                NSString *pattern = nil;
                NSString *options = nil;
                
                pattern = [[NSString alloc] initWithUTF8String:bson_iter_regex(iterator, &cStringOptions)];
                if (cStringOptions) {
                    options = [[NSString alloc] initWithUTF8String:cStringOptions];
                }
                result = [[[MODRegex alloc] initWithPattern:pattern options:options] autorelease];
                [pattern release];
                [options release];
            }
            break;
        case BSON_TYPE_DBPOINTER:
            NSLog(@"*********************** %d %d", bson_iter_type(iterator), __LINE__);
            NSAssert(NO, @"BSON_TYPE_DBREF");
            break;
        case BSON_TYPE_CODE:
            NSLog(@"*********************** %d %d", bson_iter_type(iterator), __LINE__);
            NSAssert(NO, @"BSON_TYPE_CODE");
            break;
        case BSON_TYPE_SYMBOL:
            {
                NSString *value;
                
                value = [[NSString alloc] initWithUTF8String:bson_iter_symbol(iterator, NULL)];
                result = [[[MODSymbol alloc] initWithValue:value] autorelease];
                [value release];
            }
            break;
        case BSON_TYPE_CODEWSCOPE:
            NSLog(@"*********************** %d %d", bson_iter_type(iterator), __LINE__);
            NSAssert(NO, @"BSON_CODEWSCOPE");
            break;
        case BSON_TYPE_INT32:
            result = [NSNumber numberWithInt:bson_iter_int32(iterator)];
            break;
        case BSON_TYPE_TIMESTAMP:
            {
                uint32_t timestamp, increment;
                
                bson_iter_timestamp(iterator, &timestamp, &increment);
                result = [[[MODTimestamp alloc] initWithTValue:timestamp iValue:increment] autorelease];
            }
            break;
        case BSON_TYPE_INT64:
            result = [NSNumber numberWithLongLong:bson_iter_int64(iterator)];
            break;
        case BSON_TYPE_MINKEY:
            result = [[[MODMinKey alloc] init] autorelease];
            break;
        case BSON_TYPE_MAXKEY:
            result = [[[MODMaxKey alloc] init] autorelease];
            break;
    }
    return result;
}

+ (MODSortedMutableDictionary *)objectFromBson:(bson_t *)bsonObject
{
    MODSortedMutableDictionary *result = nil;
    bson_iter_t iterator;
    
    result = [[MODSortedMutableDictionary alloc] init];
    bson_iter_init(&iterator, bsonObject);
    while (bson_iter_next(&iterator)) {
        NSString *key;
        id value;
        
        key = [[NSString alloc] initWithUTF8String:bson_iter_key(&iterator)];
        value = [self objectFromBsonIterator:&iterator];
        if (value) {
            [result setObject:value forKey:key];
        }
        [key release];
    }
    return [result autorelease];
}

+ (void)appendValue:(id)value key:(NSString *)key toBson:(bson_t *)bson
{
    const char *keyString = key.UTF8String;
    
    if ([value isKindOfClass:NSNull.class]) {
        bson_append_null(bson, keyString, (int)strlen(keyString));
    } else if ([value isKindOfClass:NSString.class]) {
        const char *cStringValue = [value UTF8String];
        
        bson_append_utf8(bson, keyString, (int)strlen(keyString), cStringValue, (int)strlen(cStringValue));
    } else if ([value isKindOfClass:[MODSortedMutableDictionary class]]) {
        bson_t childBson = BSON_INITIALIZER;
        
        bson_append_document_begin(bson, keyString, (int)strlen(keyString), &childBson);
        [self appendObject:value toBson:&childBson];
        bson_append_document_end(bson, &childBson);
    } else if ([value isKindOfClass:[NSArray class]]) {
        size_t ii = 0;
        bson_t childBson = BSON_INITIALIZER;
        
        bson_append_array_begin(bson, keyString, (int)strlen(keyString), &childBson);
        for (id arrayValue in value) {
            NSString *arrayKey;
            
            arrayKey = [[NSString alloc] initWithFormat:@"%ld", ii];
            [self appendValue:arrayValue key:arrayKey toBson:bson];
            [arrayKey release];
            ii++;
        }
        bson_append_array_end(bson, &childBson);
    } else if ([value isKindOfClass:[MODObjectId class]]) {
        bson_append_oid(bson, keyString, (int)strlen(keyString), [value bsonObjectId]);
    } else if ([value isKindOfClass:[MODRegex class]]) {
        bson_append_regex(bson, keyString, (int)strlen(keyString), [value pattern].UTF8String, [(MODRegex *)value options].UTF8String);
    } else if ([value isKindOfClass:[MODTimestamp class]]) {
        bson_append_timestamp(bson, keyString, (int)strlen(keyString), [value tValue], [value iValue]);
    } else if ([value isKindOfClass:[NSNumber class]]) {
        if (strcmp([value objCType], @encode(BOOL)) == 0) {
            bson_append_bool(bson, keyString, (int)strlen(keyString), [value boolValue]);
        } else if (strcmp([value objCType], @encode(int8_t)) == 0
                   || strcmp([value objCType], @encode(uint8_t)) == 0
                   || strcmp([value objCType], @encode(int32_t)) == 0) {
            bson_append_int32(bson, keyString, (int)strlen(keyString), [value intValue]);
        } else if (strcmp([value objCType], @encode(float)) == 0
                   || strcmp([value objCType], @encode(double)) == 0) {
            bson_append_double(bson, keyString, (int)strlen(keyString), [value doubleValue]);
        } else {
            bson_append_int64(bson, keyString, (int)strlen(keyString), [value longLongValue]);
        }
    } else if ([value isKindOfClass:[NSDate class]]) {
        bson_append_date_time(bson, keyString, (int)strlen(keyString), llround([value timeIntervalSince1970] * 1000.0));
    } else if ([value isKindOfClass:[NSData class]]) {
        bson_append_binary(bson, keyString, (int)strlen(keyString), BSON_SUBTYPE_BINARY, [value bytes], (int)[value length]);
    } else if ([value isKindOfClass:[MODBinary class]]) {
        bson_append_binary(bson, keyString, (int)strlen(keyString), [value binaryType], [[value data] bytes], (int)[[value data] length]);
    } else if ([value isKindOfClass:[MODUndefined class]]) {
        bson_append_undefined(bson, keyString, (int)strlen(keyString));
    } else if ([value isKindOfClass:[MODSymbol class]]) {
        bson_append_symbol(bson, keyString, (int)strlen(keyString), [value value].UTF8String, (int)strlen([value value].UTF8String));
    } else if ([value isKindOfClass:[MODUndefined class]]) {
        bson_append_undefined(bson, keyString, (int)strlen(keyString));
    } else if ([value isKindOfClass:[MODMinKey class]]) {
        bson_append_minkey(bson, keyString, (int)strlen(keyString));
    } else if ([value isKindOfClass:[MODMaxKey class]]) {
        bson_append_maxkey(bson, keyString, (int)strlen(keyString));
    } else {
        NSLog(@"*********************** class %@ key %@ %d", NSStringFromClass([value class]), key, __LINE__);
        NSAssert(NO, @"class %@ key %@ line %d", NSStringFromClass([value class]), key, __LINE__);
    }
}

+ (void)appendObject:(MODSortedMutableDictionary *)object toBson:(bson_t *)bson
{
    for (NSString *key in object.sortedKeys) {
        id value = [object objectForKey:key];
        
        [self appendValue:value key:key toBson:bson];
    }
}

@end

static void convertValueToJson(NSMutableString *result, int indent, id value, NSString *key, BOOL pretty, BOOL useStrictJSON);

static void addIdent(NSMutableString *result, int indent)
{
    int ii = 0;
    
    while (ii < indent) {
        [result appendString:@"  "];
        ii++;
    }
}

static void convertDictionaryToJson(NSMutableString *result, int indent, MODSortedMutableDictionary *value, BOOL pretty, BOOL useStrictJSON)
{
    BOOL first = YES;
    
    [result appendString:@"{"];
    if (pretty) {
        [result appendString:@"\n"];
    }
    for (NSString *key in value.sortedKeys) {
        if (first) {
            first = NO;
        } else if (pretty) {
            [result appendString:@",\n"];
        } else {
            [result appendString:@","];
        }
        convertValueToJson(result, indent + 1, [value objectForKey:key], key, pretty, useStrictJSON);
    }
    if (pretty) {
        [result appendString:@"\n"];
        addIdent(result, indent);
    }
    [result appendString:@"}"];
}

static void convertArrayToJson(NSMutableString *result, int indent, NSArray *value, BOOL pretty, BOOL useStrictJSON)
{
    BOOL first = YES;
    
    [result appendString:@"["];
    if (pretty) {
        [result appendString:@"\n"];
    }
    for (id arrayValue in value) {
        if (first) {
            first = NO;
        } else if (pretty) {
            [result appendString:@",\n"];
        } else {
            [result appendString:@","];
        }
        convertValueToJson(result, indent + 1, arrayValue, nil, pretty, useStrictJSON);
    }
    if (pretty) {
        [result appendString:@"\n"];
        addIdent(result, indent);
    }
    [result appendString:@"]"];
}

static void convertValueToJson(NSMutableString *result, int indent, id value, NSString *key, BOOL pretty, BOOL useStrictJSON)
{
    if (pretty) {
        addIdent(result, indent);
    }
    if (key) {
        [result appendString:@"\""];
        [result appendString:[MODServer escapeQuotesForString:key]];
        if (pretty) {
            [result appendString:@"\": "];
        } else {
            [result appendString:@"\":"];
        }
    }
    if ([value isKindOfClass:[NSString class]]) {
        [result appendString:@"\""];
        [result appendString:[MODServer escapeQuotesForString:value]];
        [result appendString:@"\""];
    } else if ([value isKindOfClass:[NSDate class]]) {
        if (useStrictJSON && pretty) {
            [result appendFormat:@"{ \"$date\": %lld }", llround([value timeIntervalSince1970] * 1000.0)];
        } else if (useStrictJSON) {
            [result appendFormat:@"{\"$date\":%lld}", llround([value timeIntervalSince1970] * 1000.0)];
        } else if ([value timeIntervalSince1970] == (int64_t)[value timeIntervalSince1970]) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            
            [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZ"];
            [result appendFormat:@"new Date(\"%@\")", [formatter stringFromDate:value]];
            [formatter release];
        } else {
            [result appendFormat:@"new Date(%lld)", llround([value timeIntervalSince1970] * 1000.0)];
        }
    } else if ([value isKindOfClass:[NSNull class]]) {
        [result appendString:@"null"];
    } else if ([value isKindOfClass:[MODSortedMutableDictionary class]]) {
        convertDictionaryToJson(result, indent, value, pretty, useStrictJSON);
    } else if ([value isKindOfClass:[NSArray class]]) {
        convertArrayToJson(result, indent, value, pretty, useStrictJSON);
    } else if ([value isKindOfClass:[NSNumber class]]) {
        if (strcmp([value objCType], @encode(BOOL)) == 0) {
            if ([value boolValue]) {
                [result appendString:@"true"];
            } else {
                [result appendString:@"false"];
            }
        } else if (strcmp([value objCType], @encode(double)) == 0 || strcmp([value objCType], @encode(float)) == 0) {
          NSMutableString *stringValue;
          
          // make sure a double always ends with .0 (at least)
          stringValue = [NSMutableString stringWithFormat:@"%.20g", [value doubleValue]];
          if ([stringValue rangeOfString:@"."].location == NSNotFound) {
              [stringValue appendString:@".0"];
          }
          [result appendString:stringValue];
        } else if (strcmp([value objCType], @encode(long long)) == 0 || strcmp([value objCType], @encode(unsigned long long)) == 0) {
            [result appendFormat:@"NumberLong(%@)", [value description]];
        } else {
            [result appendString:[value description]];
        }
    } else if ([value isKindOfClass:[MODObjectId class]]) {
        [result appendString:[value jsonValueWithPretty:pretty strictJSON:useStrictJSON]];
    } else if ([value isKindOfClass:[MODRegex class]]) {
        [result appendString:[value jsonValueWithPretty:pretty strictJSON:useStrictJSON]];
    } else if ([value isKindOfClass:[MODTimestamp class]]) {
        [result appendString:[value jsonValueWithPretty:pretty strictJSON:useStrictJSON]];
    } else if ([value isKindOfClass:[MODBinary class]]) {
        [result appendString:[value jsonValueWithPretty:pretty strictJSON:useStrictJSON]];
    } else if ([value isKindOfClass:[MODDBRef class]]) {
        [result appendString:[value jsonValueWithPretty:pretty strictJSON:useStrictJSON]];
    } else if ([value isKindOfClass:[MODSymbol class]]) {
        [result appendString:[value jsonValueWithPretty:pretty strictJSON:useStrictJSON]];
    } else if ([value isKindOfClass:[MODUndefined class]]) {
        [result appendString:[value jsonValueWithPretty:pretty strictJSON:useStrictJSON]];
    } else if ([value isKindOfClass:[MODMaxKey class]]) {
        [result appendString:[value jsonValueWithPretty:pretty strictJSON:useStrictJSON]];
    } else if ([value isKindOfClass:[MODMinKey class]]) {
        [result appendString:[value jsonValueWithPretty:pretty strictJSON:useStrictJSON]];
    } else {
        NSLog(@"unknown type: %@", [value class]);
        assert(false);
    }
}

@implementation MODServer(utils)

+ (NSString *)convertObjectToJson:(MODSortedMutableDictionary *)object pretty:(BOOL)pretty strictJson:(BOOL)strictJson
{
    NSMutableString *result;
    
    result = [NSMutableString string];
    convertDictionaryToJson(result, 0, object, pretty, strictJson);
    return result;
}

+ (NSString *)escapeQuotesForString:(NSString *)string
{
    NSMutableString *result;
    NSUInteger ii = 0, count = [string length];
    
    result = [string mutableCopy];
    while (ii < count) {
        if ([result characterAtIndex:ii] == '"' || [result characterAtIndex:ii] == '\\') {
            [result insertString:@"\\" atIndex:ii];
            ii++;
            count++;
        } else if ([result characterAtIndex:ii] == '\n') {
            [result deleteCharactersInRange:NSMakeRange(ii, 1)];
            [result insertString:@"\\n" atIndex:ii];
            ii++;
            count++;
        } else if ([result characterAtIndex:ii] == '\r') {
            [result deleteCharactersInRange:NSMakeRange(ii, 1)];
            [result insertString:@"\\r" atIndex:ii];
            ii++;
            count++;
        } else if ([result characterAtIndex:ii] == '\t') {
            [result deleteCharactersInRange:NSMakeRange(ii, 1)];
            [result insertString:@"\\t" atIndex:ii];
            ii++;
            count++;
        }
        ii++;
    }
    return [result autorelease];
}

+ (NSString *)escapeSlashesForString:(NSString *)string
{
    NSMutableString *result;
    NSUInteger ii = 0, count = [string length];
    
    result = [string mutableCopy];
    while (ii < count) {
        if ([result characterAtIndex:ii] == '/' || [result characterAtIndex:ii] == '\\') {
            [result insertString:@"\\" atIndex:ii];
            ii++;
            count++;
        } else if ([result characterAtIndex:ii] == '\n') {
            [result deleteCharactersInRange:NSMakeRange(ii, 1)];
            [result insertString:@"\\n" atIndex:ii];
            ii++;
            count++;
        } else if ([result characterAtIndex:ii] == '\r') {
            [result deleteCharactersInRange:NSMakeRange(ii, 1)];
            [result insertString:@"\\r" atIndex:ii];
            ii++;
            count++;
        } else if ([result characterAtIndex:ii] == '\t') {
            [result deleteCharactersInRange:NSMakeRange(ii, 1)];
            [result insertString:@"\\t" atIndex:ii];
            ii++;
            count++;
        }
        ii++;
    }
    return [result autorelease];
}

+ (BOOL)isEqualWithJson:(NSString *)json toBsonData:(NSData *)document info:(NSDictionary **)info
{
    bson_t jsonBsonDocument = BSON_INITIALIZER;
    BOOL result;
    NSMutableDictionary *context = [[[NSMutableDictionary alloc] init] autorelease];
    NSError *error;
    
    if (info) {
        *info = context;
    }
    [MODRagelJsonParser bsonFromJson:&jsonBsonDocument json:json error:&error];
    if (error) {
        [context setObject:error forKey:@"error"];
        result = NO;
    } else {
        MODBsonComparator *comparator;
        bson_t *originalBson;
        
        originalBson = bson_new_from_data((void *)document.bytes, (uint32_t)document.length);
        comparator = [[MODBsonComparator alloc] initWithBson1:&jsonBsonDocument bson2:originalBson];
        result = [comparator compare];
        [context setObject:comparator.differences forKey:@"differences"];
        [comparator release];
        bson_destroy(originalBson);
    }
    bson_destroy(&jsonBsonDocument);
    return result;
}

+ (BOOL)isEqualWithJson:(NSString *)json toDocument:(id)document info:(NSDictionary **)info
{
    NSError *error;
    id convertedDocument;
    BOOL result = YES;
  
    convertedDocument = [MODRagelJsonParser objectsFromJson:json withError:&error];
    NSAssert(error == nil, @"Error while parsing to objects %@, %@", json, error);
    if (![document isEqual:convertedDocument]) {
        NSLog(@"%@", [MODServer findAllDifferencesInObject1:document object2:convertedDocument]);
        NSLog(@"%@", [MODServer convertObjectToJson:convertedDocument pretty:YES strictJson:NO]);
        NSLog(@"%@", json);
        NSLog(@"%@", [MODServer convertObjectToJson:document pretty:YES strictJson:NO]);
//        NSAssert([document isEqual:convertedDocument], @"Error to parse values with %@ document id %@", [MODServer findAllDifferencesInObject1:document object2:convertedDocument], [document objectForKey:@"_id"]);
        result = NO;
    }
    return result;
}

+ (NSArray *)findAllDifferencesInArray1:(NSArray *)array1 array2:(NSArray *)array2
{
    NSMutableArray *result = NSMutableArray.array;
    
    if ([array1 count] != [array2 count]) {
        [result addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"*", @"key", array1, @"value1", array2, @"value2", nil]];
    } else {
        NSInteger ii, count = [array1 count];
        
        for (ii = 0; ii < count; ii++) {
            NSArray *subDifferences;
            
            subDifferences = [self findAllDifferencesInObject1:[array1 objectAtIndex:ii] object2:[array2 objectAtIndex:ii]];
            for (NSMutableDictionary *difference in subDifferences) {
                [difference setObject:[NSString stringWithFormat:@"%ld.%@", (long)ii, [difference objectForKey:@"key"]] forKey:@"key"];
                [result addObject:difference];
            }
        }
    }
    if (result.count == 0) {
        result = nil;
    }
    return result;
}

+ (NSArray *)findAllDifferencesInSortedDictionary1:(MODSortedMutableDictionary *)dictionary1 sortedDictionary2:(MODSortedMutableDictionary *)dictionary2
{
    NSMutableArray *result = NSMutableArray.array;
    
    if (![dictionary1.sortedKeys isEqual:dictionary2.sortedKeys]) {
        [result addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"*", @"key", dictionary1, @"value1", dictionary2, @"value2", nil]];
    } else {
        for (NSString *key in dictionary1.sortedKeys) {
            NSArray *subDifferences;
            
            subDifferences = [self findAllDifferencesInObject1:[dictionary1 objectForKey:key] object2:[dictionary2 objectForKey:key]];
            for (NSMutableDictionary *difference in subDifferences) {
                [difference setObject:[NSString stringWithFormat:@"%@.%@", key, [difference objectForKey:@"key"]] forKey:@"key"];
                [result addObject:difference];
            }
        }
    }
    if (result.count == 0) {
        result = nil;
    }
    return result;
}

+ (NSArray *)findAllDifferencesInObject1:(id)object1 object2:(id)object2
{
    if ([object1 isKindOfClass:NSArray.class] && [object2 isKindOfClass:NSArray.class]) {
        return [self findAllDifferencesInArray1:object1 array2:object2];
    } else if ([object1 isKindOfClass:MODSortedMutableDictionary.class] && [object2 isKindOfClass:MODSortedMutableDictionary.class]) {
        return [self findAllDifferencesInSortedDictionary1:object1 sortedDictionary2:object2];
    } else if ([object1 isEqual:object2]) {
        return nil;
    } else {
        return @[ [NSMutableDictionary dictionaryWithObjectsAndKeys:@"*", @"key", object1, @"value1", object2, @"value2", nil]];
    }
}

@end
