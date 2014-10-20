//
//  MODClient.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 02/09/2011.
//

#import "MongoObjCDriver-private.h"
#import "mongoc-log.h"

static void (^logCallback)(MODLogLevel level, const char *domain, const char *message) = nil;

static void defaultLogCallback(mongoc_log_level_t  log_level,
                               const char         *log_domain,
                               const char         *message,
                               void               *user_data)
{
    MODLogLevel logLevel;
    
    switch (log_level) {
        case MONGOC_LOG_LEVEL_ERROR:
            logLevel = MODLogLevelError;
            break;
        case MONGOC_LOG_LEVEL_CRITICAL:
            logLevel = MODLogLevelCritical;
            break;
        case MONGOC_LOG_LEVEL_WARNING:
            logLevel = MODLogLevelWarning;
            break;
        case MONGOC_LOG_LEVEL_MESSAGE:
            logLevel = MODLogLevelMessage;
            break;
        case MONGOC_LOG_LEVEL_INFO:
            logLevel = MODLogLevelInfo;
            break;
        case MONGOC_LOG_LEVEL_DEBUG:
            logLevel = MODLogLevelInfo;
            break;
        case MONGOC_LOG_LEVEL_TRACE:
            logLevel = MODLogLevelTrace;
            break;
    }
    if (logCallback) {
        logCallback(logLevel, log_domain, message);
    }
}

@implementation MODClient(utils_internal)

+ (void)initialize
{
    if (self == MODClient.class) {
        mongoc_log_set_handler(defaultLogCallback, NULL);
    }
}

+ (NSError *)errorWithErrorDomain:(NSString *)errorDomain code:(NSInteger)code descriptionDetails:(NSString *)descriptionDetails
{
    NSError *error;
    NSString *description = nil;
    
    if ([errorDomain isEqualToString:MODJsonParserErrorDomain]) {
        switch (code) {
            case JSON_PARSER_ERROR_EXPECTED_END:
                description = @"json end is unexpected";
                break;
            default:
                break;
        }
        if (descriptionDetails) {
            description = [NSString stringWithFormat:@"%@ - \"%@\"", description, descriptionDetails];
        }
    } else {
        if (descriptionDetails) {
            description = [NSString stringWithFormat:@"Unknown error %ld (%@) - %@", (long)code, errorDomain, descriptionDetails];
        } else {
            description = [NSString stringWithFormat:@"Unknown error %ld (%@)", (long)code, errorDomain];
        }
    }
    if (!description) {
        description = [NSString stringWithFormat:@"Unknown error %ld - %@", (long)code, errorDomain];
    }
    error = [NSError errorWithDomain:errorDomain code:code userInfo:[NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, nil]];
    return error;
}

+ (NSError *)errorFromBsonError:(bson_error_t)error
{
    NSString *domain = nil;
    NSString *errorMessage = nil;
    
    if (error.code == 0) {
        return nil;
    }
    switch (error.domain) {
        case MONGOC_ERROR_CLIENT:
            domain = @"MONGOC_ERROR_CLIENT";
            break;
        case MONGOC_ERROR_STREAM:
            domain = @"MONGOC_ERROR_STREAM";
            break;
        case MONGOC_ERROR_PROTOCOL:
            domain = @"MONGOC_ERROR_PROTOCOL";
            break;
        case MONGOC_ERROR_CURSOR:
            domain = @"MONGOC_ERROR_CURSOR";
            break;
        case MONGOC_ERROR_QUERY:
            domain = @"MONGOC_ERROR_QUERY";
            break;
        case MONGOC_ERROR_INSERT:
            domain = @"MONGOC_ERROR_INSERT";
            break;
        case MONGOC_ERROR_SASL:
            domain = @"MONGOC_ERROR_SASL";
            break;
        case MONGOC_ERROR_BSON:
            domain = @"MONGOC_ERROR_BSON";
            break;
        case MONGOC_ERROR_MATCHER:
            domain = @"MONGOC_ERROR_MATCHER";
            break;
        case MONGOC_ERROR_NAMESPACE:
            domain = @"MONGOC_ERROR_NAMESPACE";
            break;
        case MONGOC_ERROR_COMMAND:
            domain = @"MONGOC_ERROR_COMMAND";
            break;
        case MONGOC_ERROR_COLLECTION:
            domain = @"MONGOC_ERROR_COLLECTION";
            break;
    }
    if (domain == nil) {
        NSLog(@"no domain");
    }
    NSAssert(domain != nil, @"no domain found %d", error.domain);
    switch ((mongoc_error_code_t)error.code) {
        case MONGOC_ERROR_STREAM_INVALID_TYPE:
            errorMessage = @"MONGOC_ERROR_STREAM_INVALID_TYPE";
            break;
        case MONGOC_ERROR_STREAM_INVALID_STATE:
            errorMessage = @"MONGOC_ERROR_STREAM_INVALID_STATE";
            break;
        case MONGOC_ERROR_STREAM_NAME_RESOLUTION:
            errorMessage = @"MONGOC_ERROR_STREAM_NAME_RESOLUTION";
            break;
        case MONGOC_ERROR_STREAM_SOCKET:
            errorMessage = @"MONGOC_ERROR_STREAM_SOCKET";
            break;
        case MONGOC_ERROR_STREAM_CONNECT:
            errorMessage = @"MONGOC_ERROR_STREAM_CONNECT";
            break;
        case MONGOC_ERROR_STREAM_NOT_ESTABLISHED:
            errorMessage = @"MONGOC_ERROR_STREAM_NOT_ESTABLISHED";
            break;
        
        case MONGOC_ERROR_CLIENT_NOT_READY:
            errorMessage = @"MONGOC_ERROR_CLIENT_NOT_READY";
            break;
        case MONGOC_ERROR_CLIENT_TOO_BIG:
            errorMessage = @"MONGOC_ERROR_CLIENT_TOO_BIG";
            break;
        case MONGOC_ERROR_CLIENT_TOO_SMALL:
            errorMessage = @"MONGOC_ERROR_CLIENT_TOO_SMALL";
            break;
        case MONGOC_ERROR_CLIENT_GETNONCE:
            errorMessage = @"MONGOC_ERROR_CLIENT_GETNONCE";
            break;
        case MONGOC_ERROR_CLIENT_AUTHENTICATE:
            errorMessage = @"MONGOC_ERROR_CLIENT_AUTHENTICATE";
            break;
        case MONGOC_ERROR_CLIENT_NO_ACCEPTABLE_PEER:
            errorMessage = @"MONGOC_ERROR_CLIENT_NO_ACCEPTABLE_PEER";
            break;
        case MONGOC_ERROR_CLIENT_IN_EXHAUST:
            errorMessage = @"MONGOC_ERROR_CLIENT_IN_EXHAUST";
            break;
        
        case MONGOC_ERROR_PROTOCOL_INVALID_REPLY:
            errorMessage = @"MONGOC_ERROR_PROTOCOL_INVALID_REPLY";
            break;
        case MONGOC_ERROR_PROTOCOL_BAD_WIRE_VERSION:
            errorMessage = @"MONGOC_ERROR_PROTOCOL_BAD_WIRE_VERSION";
            break;
        
        case MONGOC_ERROR_CURSOR_INVALID_CURSOR:
            errorMessage = @"MONGOC_ERROR_CURSOR_INVALID_CURSOR";
            break;
        
        case MONGOC_ERROR_QUERY_FAILURE:
            errorMessage = @"MONGOC_ERROR_QUERY_FAILURE";
            break;
        
        case MONGOC_ERROR_BSON_INVALID:
            errorMessage = @"MONGOC_ERROR_BSON_INVALID";
            break;
        
        case MONGOC_ERROR_MATCHER_INVALID:
            errorMessage = @"MONGOC_ERROR_MATCHER_INVALID";
            break;
        
        case MONGOC_ERROR_NAMESPACE_INVALID:
            errorMessage = @"MONGOC_ERROR_NAMESPACE_INVALID";
            break;
            
        case MONGOC_ERROR_NAMESPACE_INVALID_FILTER_TYPE:
            errorMessage = @"MONGOC_ERROR_NAMESPACE_INVALID_FILTER_TYPE";
            break;
        
        case MONGOC_ERROR_COMMAND_INVALID_ARG:
            errorMessage = @"MONGOC_ERROR_COMMAND_INVALID_ARG";
            break;
        
        case MONGOC_ERROR_COLLECTION_INSERT_FAILED:
            errorMessage = @"MONGOC_ERROR_COLLECTION_INSERT_FAILED";
            break;
        
        case MONGOC_ERROR_COLLECTION_DOES_NOT_EXIST:
            errorMessage = @"MONGOC_ERROR_COLLECTION_DOES_NOT_EXIST";
            break;
        
        case MONGOC_ERROR_GRIDFS_INVALID_FILENAME:
            errorMessage = @"MONGOC_ERROR_GRIDFS_INVALID_FILENAME";
            break;
        
        case MONGOC_ERROR_QUERY_COMMAND_NOT_FOUND:
            errorMessage = @"MONGOC_ERROR_QUERY_COMMAND_NOT_FOUND";
            break;
            
        case MONGOC_ERROR_QUERY_NOT_TAILABLE:
            errorMessage = @"MONGOC_ERROR_QUERY_NOT_TAILABLE";
            break;
    }
    if (strlen(error.message) > 0) {
        errorMessage = [NSString stringWithCString:error.message encoding:NSUTF8StringEncoding];
    }
    NSAssert(domain != nil, @"no error message found %d %@ %d", error.domain, domain, error.code);
    return [NSError errorWithDomain:domain code:error.code userInfo:[NSDictionary dictionaryWithObjectsAndKeys:errorMessage,NSLocalizedDescriptionKey, nil]];
}

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
            result = [MODSortedMutableDictionary sortedDictionary];
            bson_iter_recurse(iterator, &subIterator);
            while (bson_iter_next(&subIterator)) {
                id value;
                NSString *key;
                
                key = [NSString stringWithUTF8String:bson_iter_key(&subIterator)];
                if (!key) {
                    // some bson can be corrupted
                    // if the key is not with UTF8, then that's the end
                    break;
                }
                value = [self objectFromBsonIterator:&subIterator];
                if (value) {
                    if (key == nil) {
                        bson_iter_key(&subIterator);
                    }
                    [result setObject:value forKey:key];
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
            {
                uint32_t collectionLength;
                const char *collectionCString;
                const bson_oid_t *oid;
                NSString *collection;
                MODObjectId *objectId;
                
                bson_iter_dbpointer(iterator, &collectionLength, &collectionCString, &oid);
                collection = [[NSString alloc] initWithBytes:collectionCString length:collectionLength encoding:NSUTF8StringEncoding];
                objectId = [[MODObjectId alloc] initWithOid:oid];
                result = [[[MODDBRef alloc] initWithCollectionName:collection objectId:objectId databaseName:nil] autorelease];
                [collection release];
                [objectId release];
            }
            break;
        case BSON_TYPE_CODE:
            {
                NSString *value;
                
                value = [[NSString alloc] initWithUTF8String:bson_iter_code(iterator, NULL)];
                result = [[[MODFunction alloc] initWithFunction:value] autorelease];
                [value release];
            }
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
            {
                NSString *function;
                const uint8_t *scopeData = NULL;
                uint32_t scopeDataLength;
                MODSortedMutableDictionary *scope = nil;
                bson_t scopeBson;
                
                function = [[NSString alloc] initWithUTF8String:bson_iter_codewscope(iterator, NULL, &scopeDataLength, &scopeData)];
                NSAssert(bson_init_static(&scopeBson, scopeData, scopeDataLength), @"problem to decode bson %@", [NSData dataWithBytes:scopeData length:scopeDataLength]);
                scope = [self objectFromBson:&scopeBson];
                result = [[[MODScopeFunction alloc] initWithFunction:function scope:scope] autorelease];
                [function release];
                bson_destroy(&scopeBson);
            }
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

+ (MODSortedMutableDictionary *)objectFromBson:(const bson_t *)bsonObject
{
    MODSortedMutableDictionary *result = nil;
    bson_iter_t iterator;
    
    result = [[MODSortedMutableDictionary alloc] init];
    bson_iter_init(&iterator, bsonObject);
    while (bson_iter_next(&iterator)) {
        NSString *key;
        id value;
        
        key = [NSString stringWithUTF8String:bson_iter_key(&iterator)];
        if (!key) {
            // if we can't have a NSString, this is probably a corrupted bson
            // just pretend it finished
            break;
        }
        value = [self objectFromBsonIterator:&iterator];
        if (value) {
            [result setObject:value forKey:key];
        }
    }
    return [result autorelease];
}

+ (void)appendValue:(id)value key:(NSString *)key toBson:(bson_t *)bson
{
    const char *keyString = key.UTF8String;
    
    NSParameterAssert(value != NULL);
    NSParameterAssert(key != NULL);
    NSParameterAssert(bson != NULL);
    if ([value isKindOfClass:NSNull.class]) {
        bson_append_null(bson, keyString, strlen(keyString));
    } else if ([value isKindOfClass:NSString.class]) {
        const char *cStringValue = [value UTF8String];
        
        bson_append_utf8(bson, keyString, strlen(keyString), cStringValue, strlen(cStringValue));
    } else if ([value isKindOfClass:[MODSortedMutableDictionary class]]) {
        bson_t childBson = BSON_INITIALIZER;
        
        bson_append_document_begin(bson, keyString, strlen(keyString), &childBson);
        [self appendObject:value toBson:&childBson];
        bson_append_document_end(bson, &childBson);
    } else if ([value isKindOfClass:[NSArray class]]) {
        size_t ii = 0;
        bson_t childBson = BSON_INITIALIZER;
        
        bson_append_array_begin(bson, keyString, strlen(keyString), &childBson);
        for (id arrayValue in value) {
            NSString *arrayKey;
            
            arrayKey = [[NSString alloc] initWithFormat:@"%ld", ii];
            [self appendValue:arrayValue key:arrayKey toBson:&childBson];
            [arrayKey release];
            ii++;
        }
        bson_append_array_end(bson, &childBson);
    } else if ([value isKindOfClass:[MODObjectId class]]) {
        bson_append_oid(bson, keyString, strlen(keyString), [value bsonObjectId]);
    } else if ([value isKindOfClass:[MODRegex class]]) {
        bson_append_regex(bson, keyString, strlen(keyString), [value pattern].UTF8String, [(MODRegex *)value options].UTF8String);
    } else if ([value isKindOfClass:[MODTimestamp class]]) {
        bson_append_timestamp(bson, keyString, strlen(keyString), [value tValue], [value iValue]);
    } else if ([value isKindOfClass:[NSNumber class]]) {
        if (strcmp([value objCType], @encode(BOOL)) == 0) {
            bson_append_bool(bson, keyString, strlen(keyString), [value boolValue]);
        } else if (strcmp([value objCType], @encode(int8_t)) == 0
                   || strcmp([value objCType], @encode(uint8_t)) == 0
                   || strcmp([value objCType], @encode(int32_t)) == 0) {
            bson_append_int32(bson, keyString, strlen(keyString), [value intValue]);
        } else if (strcmp([value objCType], @encode(float)) == 0
                   || strcmp([value objCType], @encode(double)) == 0) {
            bson_append_double(bson, keyString, strlen(keyString), [value doubleValue]);
        } else {
            bson_append_int64(bson, keyString, strlen(keyString), [value longLongValue]);
        }
    } else if ([value isKindOfClass:[NSDate class]]) {
        bson_append_date_time(bson, keyString, strlen(keyString), llround([value timeIntervalSince1970] * 1000.0));
    } else if ([value isKindOfClass:[NSData class]]) {
        bson_append_binary(bson, keyString, strlen(keyString), BSON_SUBTYPE_BINARY, [value bytes], [value length]);
    } else if ([value isKindOfClass:[MODBinary class]]) {
        bson_append_binary(bson, keyString, strlen(keyString), [value binaryType], [value binaryData].bytes, [value binaryData].length);
    } else if ([value isKindOfClass:[MODUndefined class]]) {
        bson_append_undefined(bson, keyString, strlen(keyString));
    } else if ([value isKindOfClass:[MODSymbol class]]) {
        bson_append_symbol(bson, keyString, strlen(keyString), [value value].UTF8String, strlen([value value].UTF8String));
    } else if ([value isKindOfClass:[MODUndefined class]]) {
        bson_append_undefined(bson, keyString, strlen(keyString));
    } else if ([value isKindOfClass:[MODMinKey class]]) {
        bson_append_minkey(bson, keyString, strlen(keyString));
    } else if ([value isKindOfClass:[MODMaxKey class]]) {
        bson_append_maxkey(bson, keyString, strlen(keyString));
    } else if ([value isKindOfClass:[MODFunction class]]) {
        bson_append_code(bson, keyString, strlen(keyString), [value function].UTF8String);
    } else if ([value isKindOfClass:[MODScopeFunction class]]) {
        bson_t bsonScope = BSON_INITIALIZER;
        
        if ([value scope]) {
            [self appendObject:[value scope] toBson:&bsonScope];
        }
        bson_append_code_with_scope(bson, keyString, strlen(keyString), [value function].UTF8String, &bsonScope);
        bson_destroy(&bsonScope);
    } else if ([value isKindOfClass:[MODDBRef class]]) {
        bson_append_dbpointer(bson, keyString, strlen(keyString), [value collectionName].UTF8String, [value objectId].bsonObjectId);
    } else {
        NSLog(@"*********************** class %@ key %@ %d", NSStringFromClass([value class]), key, __LINE__);
        NSAssert(NO, @"class %@ key %@ line %d", NSStringFromClass([value class]), key, __LINE__);
    }
}

+ (void)appendObject:(MODSortedMutableDictionary *)object toBson:(bson_t *)bson
{
    NSParameterAssert(object != NULL);
    NSParameterAssert(bson != NULL);
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
        [result appendString:[MODClient escapeQuotesForString:key]];
        if (pretty) {
            [result appendString:@"\": "];
        } else {
            [result appendString:@"\":"];
        }
    }
    if ([value isKindOfClass:[NSString class]]) {
        [result appendString:@"\""];
        [result appendString:[MODClient escapeQuotesForString:value]];
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
    } else if ([value isKindOfClass:[MODFunction class]]) {
        [result appendString:[value jsonValueWithPretty:pretty strictJSON:useStrictJSON]];
    } else if ([value isKindOfClass:[MODScopeFunction class]]) {
        [result appendString:[value jsonValueWithPretty:pretty strictJSON:useStrictJSON]];
    } else {
        NSLog(@"unknown type: %@", [value class]);
        assert(false);
    }
}

@implementation MODClient(utils)

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
        NSLog(@"%@", [MODClient findAllDifferencesInObject1:document object2:convertedDocument]);
        NSLog(@"%@", [MODClient convertObjectToJson:convertedDocument pretty:YES strictJson:NO]);
        NSLog(@"%@", json);
        NSLog(@"%@", [MODClient convertObjectToJson:document pretty:YES strictJson:NO]);
//        NSAssert([document isEqual:convertedDocument], @"Error to parse values with %@ document id %@", [MODClient findAllDifferencesInObject1:document object2:convertedDocument], [document objectForKey:@"_id"]);
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

+ (void)setLogCallback:(void (^)(MODLogLevel level, const char *domain, const char *message))callback
{
    [logCallback release];
    logCallback = [callback copy];
}

+ (NSString *)logLevelStringForLogLevel:(MODLogLevel)level
{
    NSString *result = @"unknown";
    
    switch(level) {
        case MODLogLevelError:
            result = @"error";
            break;
        case MODLogLevelCritical:
            result = @"critical";
            break;
        case MODLogLevelWarning:
            result = @"warning";
            break;
        case MODLogLevelMessage:
            result = @"message";
            break;
        case MODLogLevelInfo:
            result = @"info";
            break;
        case MODLogLevelDebug:
            result = @"debug";
            break;
        case MODLogLevelTrace:
            result = @"trace";
            break;
    }
    return result;
}

+ (void)logWithLevel:(MODLogLevel)logLevel domain:(const char *)domain message:(const char *)message
{
    logCallback(logLevel, domain, message);
}

@end
