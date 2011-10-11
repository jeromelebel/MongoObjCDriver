//
//  MODJsonParser.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 24/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

static void my_debug(void)
{
    return;
}

typedef struct {
    id target;
    void *latestStructure;
    BOOL latestStructureObject;
    BOOL shouldSkipNextEndStructure;
    bson *bsonResult;
    struct {
        char *objectKeyToCreate;
        BOOL isObject;
        enum {
            NO_BSON_TYPE,
            TIMESTAMP_BSON_TYPE,
            REGEX_BSON_TYPE,
            JSON_DATA_BINARY_TYPE,
        } bsonType;
        struct {
            BOOL hasTValue;
            int32_t tValue;
            BOOL hasIValue;
            int32_t iValue;
            BOOL closeOne;
        } timestampBson;
        struct {
            char *pattern;
            char *options;
        } regexBson;
        struct {
            char *binary;
            size_t length;
            BOOL hasBinaryType;
            char binaryType;
        } dataBinary;
    } pendingBsonValue;
    
} JsonParserContext;

typedef struct {
    int type;
    const char *data;
    size_t length;
} ParserDataInfo;

static char *copyString(const char *string)
{
    char *result;
    size_t stringLength;
    
    stringLength = strlen(string);
    result = malloc(stringLength + 1);
    strncpy(result, string, stringLength);
    return result;
}

static unsigned char convertCharToByte(char my_char, BOOL *isValid)
{
    unsigned char result = 0;
    
    *isValid = YES;
    if (my_char == '0') {
        result = 0;
    } else if (my_char >= '1' && my_char <= '9') {
        result = my_char - '1' + 1;
    } else if (my_char >= 'a' && my_char <= 'f') {
        result = my_char - 'a' + 10;
    } else if (my_char >= 'A' && my_char <= 'F') {
        result = my_char - 'A' + 10;
    } else {
        *isValid = NO;
    }
    return result;
}

static BOOL process_json(const char *json, json_parser_dom *helper, int *errorCode, size_t *totalProcessed)
{
    json_parser parser;
    json_config config;
    uint32_t processed;
    size_t jsonToProcessLength = strlen(json);
    BOOL result;
    
    assert(totalProcessed != nil);
    assert(errorCode != nil);
    *totalProcessed = 0;
    *errorCode = 0;
    
	memset(&config, 0, sizeof(json_config));
    config.allow_c_comments = 1;
    config.allow_yaml_comments = 1;
    json_parser_init(&parser, &config, json_parser_dom_callback, helper);
    
    while (jsonToProcessLength > UINT32_MAX) {
        *errorCode = json_parser_string(&parser, json, UINT32_MAX, &processed);
        *totalProcessed += processed;
        jsonToProcessLength -= UINT32_MAX;
        if (*errorCode != 0) {
            break;
        }
    }
    if (*errorCode == 0) {
        *errorCode = json_parser_string(&parser, json, (uint32_t)jsonToProcessLength, &processed);
        *totalProcessed += processed;
    }
    
    result = json_parser_is_done(&parser)?YES:NO;
    json_parser_free(&parser);
    return result;
}

static void clear_pending_value(JsonParserContext *context, BOOL shouldSkipNextEndStructure)
{
    if (context->pendingBsonValue.objectKeyToCreate) {
        free(context->pendingBsonValue.objectKeyToCreate);
    }
    if (context->pendingBsonValue.regexBson.pattern) {
        free(context->pendingBsonValue.regexBson.pattern);
    }
    if (context->pendingBsonValue.regexBson.options) {
        free(context->pendingBsonValue.regexBson.options);
    }
    if (context->pendingBsonValue.dataBinary.binary) {
        free(context->pendingBsonValue.dataBinary.binary);
    }
    bzero(&(context->pendingBsonValue), sizeof(context->pendingBsonValue));
    context->pendingBsonValue.bsonType = NO_BSON_TYPE;
    context->shouldSkipNextEndStructure = shouldSkipNextEndStructure;
}

static BOOL create_waiting_structure_if_needed(JsonParserContext *context)
{
    BOOL result = YES;
    
    my_debug();
    if (context->pendingBsonValue.objectKeyToCreate) {
        if (context->pendingBsonValue.isObject) {
            context->latestStructure = [context->target openDictionaryWithPreviousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject key:context->pendingBsonValue.objectKeyToCreate];
        } else {
            context->latestStructure = [context->target openArrayWithPreviousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject key:context->pendingBsonValue.objectKeyToCreate];
        }
        context->latestStructureObject = context->pendingBsonValue.isObject;
        clear_pending_value(context, NO);
        result = context->latestStructure != NULL;
    }
    return result;
}

static void * begin_structure_for_bson(int nesting, int is_object, void *structure, int is_object_structure, const char *key, size_t key_length, void *void_user_context)
{
    JsonParserContext *context = void_user_context;
    void *result;
    
    my_debug();
    if (key != NULL) {
        if (context->shouldSkipNextEndStructure) {
            result = NULL;
        } else if (strcmp(key, "$timestamp") == 0) {
            if (context->pendingBsonValue.bsonType == NO_BSON_TYPE) {
                context->pendingBsonValue.bsonType = TIMESTAMP_BSON_TYPE;
                result = context->target;
            } else {
                result = NULL;
            }
        } else {
            if (create_waiting_structure_if_needed(context)) {
                context->pendingBsonValue.isObject = is_object;
                context->pendingBsonValue.objectKeyToCreate = copyString(key);
                result = context->target;
            } else {
                result = NULL;
            }
        }
    } else {
        result = context->target;
    }
    return result;
}

static int end_structure_for_bson(int nesting, int is_object, const char *key, size_t key_length, void *structure, void *void_user_context)
{
    JsonParserContext *context = void_user_context;
    int result = 0;
    
    my_debug();
    if (key != NULL) {
        if (context->pendingBsonValue.bsonType == TIMESTAMP_BSON_TYPE) {
            if (!context->pendingBsonValue.timestampBson.hasIValue || !context->pendingBsonValue.timestampBson.hasTValue) {
                result = 1;
            } else if (!context->pendingBsonValue.timestampBson.closeOne) {
                context->pendingBsonValue.timestampBson.closeOne = YES;
            } else {
                result = [context->target appendTimestampWithTValue:context->pendingBsonValue.timestampBson.tValue iValue:context->pendingBsonValue.timestampBson.iValue key:context->pendingBsonValue.objectKeyToCreate previousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject]?0:1;
                clear_pending_value(context, YES);
            }
        } else if (context->pendingBsonValue.bsonType != NO_BSON_TYPE) {
            result = 1;
        } else if (is_object && !context->shouldSkipNextEndStructure) {
            result = [context->target closeDictionaryWithStructure:context->latestStructure]?0:1;
        } else if (!context->shouldSkipNextEndStructure) {
            result = [context->target closeArrayWithStructure:context->latestStructure]?0:1;
        }
    }
    return result;
}

/** callback from the parser_dom callback to create data values */
static void * create_data_for_bson(int type, const char *data, size_t length, void *user_context)
{
    ParserDataInfo *result;
    
    my_debug();
    result = malloc(sizeof(*result));
    result->type = type;
    result->data = data;
    result->length = length;
    return result;
}

static size_t convertStringToData(const char * string, void *data, size_t length)
{
    BOOL isValid = YES;
    size_t count = 0;
    
    while (string[0] != 0 && string[1] != 0 && length > 0 && isValid) {
        unsigned char byte = 0;
        
        byte = convertCharToByte(string[0], &isValid) * 16;
        if (isValid) {
            byte = byte + convertCharToByte(string[1], &isValid);
            ((unsigned char *)data)[0] = byte;
            data++;
            if (isValid) {
                length--;
                string += 2;
                count++;
            }
        }
    }
    return count;
}

/** callback from the parser helper callback to append a value to an object or array value
 * append(parent, key, key_length, val); */
static int append_data_for_bson(void *structure, int is_object_structure, int structure_value_count, char *key, size_t key_length, void *obj, void *void_user_context)
{
    ParserDataInfo *dataInfo = obj;
    JsonParserContext *context = void_user_context;
    char arrayKey[32];
    int result = 1;
    
    my_debug();
    if (is_object_structure == false) {
        snprintf(arrayKey, sizeof(arrayKey), "%d", structure_value_count);
        key = arrayKey;
    }
    if (context->shouldSkipNextEndStructure) {
        // error
    } else if (strcmp(key, "$oid") == 0) {
        if (dataInfo->length == sizeof(bson_oid_t) * 2) {
            bson_oid_t oid;
            
            if (convertStringToData(dataInfo->data, &oid, sizeof(bson_oid_t)) == sizeof(bson_oid_t) && context->pendingBsonValue.bsonType == NO_BSON_TYPE && dataInfo->type == JSON_STRING) {
                result = [context->target appendObjectId:&oid length:sizeof(oid) withKey:context->pendingBsonValue.objectKeyToCreate previousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject]?0:1;
                clear_pending_value(context, YES);
            }
        }
    } else if (strcmp(key, "$regex") == 0 || strcmp(key, "$options") == 0) {
        if (strcmp(key, "$regex") == 0 && !context->pendingBsonValue.regexBson.pattern && dataInfo->type == JSON_STRING && (context->pendingBsonValue.bsonType == REGEX_BSON_TYPE || context->pendingBsonValue.bsonType == NO_BSON_TYPE)) {
            context->pendingBsonValue.bsonType = REGEX_BSON_TYPE;
            context->pendingBsonValue.regexBson.pattern = copyString(dataInfo->data);
        } else if (strcmp(key, "$options") == 0 && !context->pendingBsonValue.regexBson.options && dataInfo->type == JSON_STRING && (context->pendingBsonValue.bsonType == REGEX_BSON_TYPE || context->pendingBsonValue.bsonType == NO_BSON_TYPE)) {
            context->pendingBsonValue.bsonType = REGEX_BSON_TYPE;
            context->pendingBsonValue.regexBson.options = copyString(dataInfo->data);
        }
        if (context->pendingBsonValue.regexBson.pattern && context->pendingBsonValue.regexBson.options && context->pendingBsonValue.bsonType == REGEX_BSON_TYPE) {
            result = [context->target appendRegexWithPattern:context->pendingBsonValue.regexBson.pattern options:context->pendingBsonValue.regexBson.options key:context->pendingBsonValue.objectKeyToCreate previousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject]?0:1;
            clear_pending_value(context, YES);
        }
    } else if (strcmp(key, "$date") == 0) {
        if (dataInfo->type == JSON_INT || dataInfo->type == JSON_FLOAT) {
            result = [context->target appendDate:atof(dataInfo->data) withKey:key previousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject]?0:1;
            clear_pending_value(context, YES);
        }
    } else if (strcmp(key, "$data_binary") == 0 || strcmp(key, "$type") == 0) {
        if (strcmp(key, "$data_binary") == 0 && !context->pendingBsonValue.dataBinary.binary && dataInfo->type == JSON_DATA_BINARY_TYPE && (context->pendingBsonValue.bsonType == JSON_DATA_BINARY_TYPE || context->pendingBsonValue.bsonType == NO_BSON_TYPE)) {
            context->pendingBsonValue.dataBinary.binary = malloc(dataInfo->length);
            memcpy(context->pendingBsonValue.dataBinary.binary, dataInfo->data, dataInfo->length);
            context->pendingBsonValue.dataBinary.length = dataInfo->length;
        } else if (strcmp(key, "$type") == 0 && !context->pendingBsonValue.dataBinary.hasBinaryType && dataInfo->type == JSON_DATA_BINARY_TYPE && (context->pendingBsonValue.bsonType == JSON_DATA_BINARY_TYPE || context->pendingBsonValue.bsonType == NO_BSON_TYPE)) {
            context->pendingBsonValue.dataBinary.hasBinaryType = YES;
            context->pendingBsonValue.dataBinary.binaryType = atoi(dataInfo->data);
        }
        if (context->pendingBsonValue.dataBinary.binary && context->pendingBsonValue.dataBinary.hasBinaryType) {
            result = [context->target appendDataBinary:context->pendingBsonValue.dataBinary.binary withLength:context->pendingBsonValue.dataBinary.length binaryType:context->pendingBsonValue.dataBinary.binaryType key:context->pendingBsonValue.objectKeyToCreate previousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject]?0:1;
            clear_pending_value(context, YES);
        }
    } else {
        switch (context->pendingBsonValue.bsonType) {
            case NO_BSON_TYPE:
                switch (dataInfo->type) {
                    case JSON_STRING:
                        if (create_waiting_structure_if_needed(context)) {
                            result = [context->target appendString:dataInfo->data withKey:key previousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject]?0:1;
                        }
                        break;
                    case JSON_INT:
                        if (create_waiting_structure_if_needed(context)) {
                            result = [context->target appendLongLong:atoll(dataInfo->data) withKey:key previousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject]?0:1;
                        }
                        break;
                    case JSON_FLOAT:
                        if (create_waiting_structure_if_needed(context)) {
                            result = [context->target appendDouble:atof(dataInfo->data) withKey:key previousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject]?0:1;
                        }
                        break;
                    case JSON_NULL:
                        if (create_waiting_structure_if_needed(context)) {
                            result = [context->target appendNullWithKey:key previousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject]?0:1;
                        }
                        break;
                    case JSON_TRUE:
                        if (create_waiting_structure_if_needed(context)) {
                            result = [context->target appendBool:YES withKey:key previousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject]?0:1;
                        }
                        break;
                    case JSON_FALSE:
                        if (create_waiting_structure_if_needed(context)) {
                            result = [context->target appendBool:NO withKey:key previousStructure:context->latestStructure previousStructureDictionary:context->latestStructureObject]?0:1;
                        }
                        break;
                    default:
                        break;
                }
                break;
            case TIMESTAMP_BSON_TYPE:
                if (dataInfo->type == JSON_INT) {
                    if (!context->pendingBsonValue.timestampBson.hasTValue) {
                        context->pendingBsonValue.timestampBson.hasTValue = YES;
                        context->pendingBsonValue.timestampBson.tValue = atoi(dataInfo->data);
                        result = context->pendingBsonValue.timestampBson.hasIValue?1:0;
                    } else if (!context->pendingBsonValue.timestampBson.hasIValue) {
                        context->pendingBsonValue.timestampBson.hasIValue = YES;
                        context->pendingBsonValue.timestampBson.iValue = atoi(dataInfo->data);
                        result = context->pendingBsonValue.timestampBson.hasTValue?0:1;
                    }
                }
                break;
            case REGEX_BSON_TYPE:
            case JSON_DATA_BINARY_TYPE:
                // error
                break;
        }
    }
    free(obj);
    return result;
}

@implementation MODJsonParser

- (size_t)parseJsonWithCstring:(const char *)json error:(NSError **)error
{
    json_parser_dom helper;
    JsonParserContext context;
    size_t totalProcessed = strlen(json);
    int errorCode = 0;
    BOOL parserDone = YES;
    
    bzero(&context, sizeof(context));
    context.target = self;
    context.pendingBsonValue.bsonType = NO_BSON_TYPE;
    json_parser_dom_init(&helper, begin_structure_for_bson, end_structure_for_bson, create_data_for_bson, append_data_for_bson, &context);
    parserDone = process_json(json, &helper, &errorCode, &totalProcessed);
    json_parser_dom_free(&helper);
    clear_pending_value(&context, YES);
    
    if ((!parserDone || errorCode != 0) && error) {
        NSRange range;
        size_t stringLength = strlen(json);
        char substring[21];
        
        range.length = sizeof(substring) - 1;
        if (totalProcessed < range.length / 2) {
            range.location = 0;
            range.length -= (range.length / 2) - totalProcessed;
        } else {
            range.location = totalProcessed - (range.length / 2);
        }
        if (range.location + range.length > stringLength) {
            range.length = stringLength - range.location;
        }
        strncpy(substring, json + range.location, range.length);
        substring[range.length] = 0;
        if (errorCode != 0) {
            *error = [MODServer errorWithErrorDomain:MODJsonErrorDomain code:errorCode descriptionDetails:[NSString stringWithUTF8String:substring]];
        } else {
            *error = [MODServer errorWithErrorDomain:MODJsonParserErrorDomain code:JSON_PARSER_ERROR_EXPECTED_END descriptionDetails:[NSString stringWithUTF8String:substring]];
        }
    } else if (errorCode == 0 && error) {
        *error = nil;
    }
    return totalProcessed;
}

- (size_t)parseJsonWithString:(NSString *)json withError:(NSError **)error
{
    return [self parseJsonWithCstring:[json UTF8String] error:error];
}

@end

@implementation MODJsonToBsonParser

+ (NSInteger)bsonFromJson:(bson *)bsonResult json:(NSString *)json error:(NSError **)error
{
    MODJsonToBsonParser *parser;
    NSInteger result;
    
    parser = [[self alloc] init];
    [parser setBson:bsonResult];
    result = [parser parseJsonWithString:json withError:error];
    [parser release];
    return result;
}

- (void)setBson:(bson *)bson
{
    _bson = bson;
}

- (void *)mainDictionary
{
    return _bson;
}

- (void *)openDictionaryWithPreviousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary key:(const char *)key
{
    void *result = NULL;
    
    if (key != NULL) {
        bson_append_start_object(_bson, key);
        result = _bson;
    }
    return result;
}

- (void *)openArrayWithPreviousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary key:(const char *)key
{
    void *result = NULL;
    
    if (key != NULL) {
        bson_append_start_array(_bson, key);
        result = _bson;
    }
    return result;
}

- (BOOL)closeDictionaryWithStructure:(void *)openedStructure
{
    bson_append_finish_object(_bson);
    return YES;
}

- (BOOL)closeArrayWithStructure:(void *)openedStructure
{
    bson_append_finish_array(_bson);
    return YES;
}

- (BOOL)appendTimestampWithTValue:(int)tValue iValue:(int)iValue key:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    BOOL result = NO;
    
    if (key != NULL) {
        bson_timestamp_t ts;
        
        ts.t = tValue;
        ts.i = iValue;
        bson_append_timestamp(_bson, key, &ts);
        result = YES;
    }
    return result;
}

- (BOOL)appendObjectId:(void *)objectId length:(size_t)length withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    BOOL result = NO;
    
    if (key != NULL) {
        bson_append_oid(_bson, key, objectId);
        result = YES;
    }
    return result;
}

- (BOOL)appendString:(const char *)stringValue withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    BOOL result = NO;
    
    if (key != NULL) {
        bson_append_string(_bson, key, stringValue);
        result = YES;
    }
    return result;
}

- (BOOL)appendLongLong:(long long)integer withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    BOOL result = NO;
    
    if (key != NULL) {
        bson_append_long(_bson, key, integer);
        result = YES;
    }
    return result;
}

- (BOOL)appendDouble:(double)doubleValue withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    BOOL result = NO;
    
    if (key != NULL) {
        bson_append_double(_bson, key, doubleValue);
        result = YES;
    }
    return result;
}

- (BOOL)appendNullWithKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    BOOL result = NO;
    
    if (key != NULL) {
        bson_append_null(_bson, key);
        result = YES;
    }
    return result;
}

- (BOOL)appendBool:(BOOL)boolValue withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    BOOL result = NO;
    
    if (key != NULL) {
        bson_append_bool(_bson, key, YES?1:0);
        result = YES;
    }
    return result;
}

- (BOOL)appendDate:(int64_t)date withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    BOOL result = NO;
    
    if (key != NULL) {
        bson_append_date(_bson, key, date);
        result = YES;
    }
    return result;
}

- (BOOL)appendRegexWithPattern:(const char *)pattern options:(const char *)options key:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    BOOL result = NO;
    
    if (pattern && options) {
        bson_append_regex(_bson, key, pattern, options);
        result = YES;
    }
    return result;
}

- (BOOL)appendDataBinary:(const char *)binary withLength:(NSUInteger)length binaryType:(char)binaryType key:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    BOOL result = NO;
    
    if (key != NULL) {
        bson_append_binary(_bson, key, binaryType, binary, length);
        result = YES;
    }
    return result;
}

@end

@implementation MODJsonToObjectParser

+ (id)objectsFromJson:(NSString *)json error:(NSError **)error
{
    id objects;
    MODJsonToObjectParser *parser;
    
    parser = [[MODJsonToObjectParser alloc] init];
    [parser parseJsonWithString:json withError:error];
    objects = [[parser objects] retain];
    [parser release];
    return [objects autorelease];
}

- (void *)mainDictionary
{
    if (!_mainObject) {
        _mainObject = [[NSMutableDictionary alloc] init];
    }
    return _mainObject;
}

- (id)objects
{
    return _mainObject;
}

- (BOOL)addObject:(id)object toStructure:(id)structure isDictionary:(BOOL)isDictionary withKey:(const char *)key
{
    BOOL result = YES;
  
    if (key == NULL) {
        result = NO;
    } else if (isDictionary) {
        NSString *stringKey;
        
        stringKey = [[NSString alloc] initWithUTF8String:key];
        [(NSMutableDictionary *)structure setObject:object forKey:stringKey];
        [stringKey release];
    } else {
        [(NSMutableArray *)structure addObject:object];
    }
    return result;
}

- (void *)openDictionaryWithPreviousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary key:(const char *)key
{
    NSMutableDictionary *result;
    
    result = [NSMutableDictionary dictionary];
    if (![self addObject:result toStructure:structure isDictionary:isDictionary withKey:key]) {
        result = nil;
    }
    return result;
}

- (void *)openArrayWithPreviousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary key:(const char *)key
{
    NSMutableArray *result;
    
    result = [NSMutableArray array];
    if (![self addObject:result toStructure:structure isDictionary:isDictionary withKey:key]) {
        result = nil;
    }
    return result;
}

- (BOOL)closeDictionaryWithStructure:(void *)openedStructure
{
    return YES;
}

- (BOOL)closeArrayWithStructure:(void *)openedStructure
{
    return YES;
}

- (BOOL)appendTimestampWithTValue:(int)tValue iValue:(int)iValue key:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    MODTimestamp *ts;
    BOOL result;
    
    ts = [[MODTimestamp alloc] initWithTValue:tValue iValue:iValue];
    result = [self addObject:ts toStructure:structure isDictionary:isDictionary withKey:key];
    [ts release];
    return result;
}

- (BOOL)appendObjectId:(void *)objectId length:(size_t)length withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    MODObjectId *object;
    BOOL result = NO;
    
    if (length == sizeof(bson_oid_t)) {
        object = [[MODObjectId alloc] initWithOid:objectId];
        result = [self addObject:object toStructure:structure isDictionary:isDictionary withKey:key];
        [object release];
    }
    return result;
}

- (BOOL)appendString:(const char *)stringValue withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    NSString *object;
    BOOL result;
    
    object = [[NSString alloc] initWithUTF8String:stringValue];
    result = [self addObject:object toStructure:structure isDictionary:isDictionary withKey:key];
    [object release];
    return result;
}

- (BOOL)appendLongLong:(long long)integerValue withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    NSNumber *object;
    BOOL result;
    
    object = [[NSNumber alloc] initWithLongLong:integerValue];
    result = [self addObject:object toStructure:structure isDictionary:isDictionary withKey:key];
    [object release];
    return result;
}

- (BOOL)appendDouble:(double)doubleValue withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    NSNumber *object;
    BOOL result;

    object = [[NSNumber alloc] initWithDouble:doubleValue];
    result = [self addObject:object toStructure:structure isDictionary:isDictionary withKey:key];
    [object release];
    return result;
}

- (BOOL)appendBool:(BOOL)boolValue withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    NSNumber *object;
    BOOL result;
    
    object = [[NSNumber alloc] initWithBool:boolValue];
    result = [self addObject:object toStructure:structure isDictionary:isDictionary withKey:key];
    [object release];
    return result;
}

- (BOOL)appendDate:(int64_t)date withKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    NSDate *object;
    BOOL result;
    
    object = [[NSDate alloc] initWithTimeIntervalSince1970:date / 1000.0];
    result = [self addObject:object toStructure:structure isDictionary:isDictionary withKey:key];
    [object release];
    return result;
}

- (BOOL)appendNullWithKey:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    return [self addObject:[NSNull null] toStructure:structure isDictionary:isDictionary withKey:key];
}

- (BOOL)appendRegexWithPattern:(const char *)pattern options:(const char *)options key:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    BOOL result = NO;
    
    if (pattern && options) {
        MODRegex *dataRegex;
        NSString *patternString;
        NSString *optionsString;
        
        patternString = [[NSString alloc] initWithUTF8String:pattern];
        optionsString = [[NSString alloc] initWithUTF8String:options];
        dataRegex = [[MODRegex alloc] initWithPattern:patternString options:optionsString];
        result = [self addObject:dataRegex toStructure:structure isDictionary:isDictionary withKey:key];
        [patternString release];
        [optionsString release];
        [dataRegex release];
    }
    return result;
}

- (BOOL)appendDataBinary:(const char *)binary withLength:(NSUInteger)length binaryType:(char)binaryType key:(const char *)key previousStructure:(void *)structure previousStructureDictionary:(BOOL)isDictionary
{
    MODBinary *object;
    BOOL result;
    
    object = [[MODBinary alloc] initWithBytes:binary length:length binaryType:binaryType];
    result = [self addObject:object toStructure:structure isDictionary:isDictionary withKey:key];
    [object release];
    return result;
}

@end
