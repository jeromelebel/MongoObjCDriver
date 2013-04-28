//
//  MODJsonParser.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 24/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"
#import "NSString+Base64.h"

static void my_debug(void)
{
    return;
}

typedef struct _ObjectStack {
    void *structure;
    BOOL isDictionary;
    struct _ObjectStack *previous;
} ObjectStack;

typedef struct {
    id target;
    ObjectStack *latestStack;
    BOOL shouldSkipNextEndStructure;
    bson *bsonResult;
    struct {
        enum {
            NO_STRUCTURE,
            ARRAY_STRUCTURE,
            OBJECT_STRUCTURE
        } structureWaiting;
        char *objectKeyToCreate;
        int index;
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
    char *result = NULL;
    size_t stringLength;
    
    if (string) {
        stringLength = strlen(string);
        result = malloc(stringLength + 1);
        strncpy(result, string, stringLength + 1);
    }
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
    context->pendingBsonValue.structureWaiting = NO_STRUCTURE;
    context->pendingBsonValue.bsonType = NO_BSON_TYPE;
    context->shouldSkipNextEndStructure = shouldSkipNextEndStructure;
}

static void pushStack(JsonParserContext *context, void *structure, BOOL isDictionary)
{
    ObjectStack *stack;
    
    stack = malloc(sizeof(ObjectStack));
    stack->structure = structure;
    stack->isDictionary = isDictionary;
    stack->previous = context->latestStack;
    context->latestStack = stack;
}

static void popStack(JsonParserContext *context)
{
    ObjectStack *stack;
    
    stack = context->latestStack;
    if (stack) {
        context->latestStack = stack->previous;
        free(stack);
    }
}

static BOOL create_waiting_structure_if_needed(JsonParserContext *context)
{
    BOOL result = YES;
    
    my_debug();
    if (context->pendingBsonValue.structureWaiting != NO_STRUCTURE) {
        void *structure;
        
        if (context->pendingBsonValue.structureWaiting == OBJECT_STRUCTURE) {
            structure = [context->target openDictionaryWithPreviousStructure:context->latestStack->structure key:context->pendingBsonValue.objectKeyToCreate index:context->pendingBsonValue.index];
        } else {
            structure = [context->target openArrayWithPreviousStructure:context->latestStack->structure key:context->pendingBsonValue.objectKeyToCreate index:context->pendingBsonValue.index];
        }
        pushStack(context, structure, context->pendingBsonValue.structureWaiting == OBJECT_STRUCTURE);
        clear_pending_value(context, NO);
        result = structure != NULL;
    }
    return result;
}

static void * begin_structure_for_bson(int nesting, int is_object, void *structure, const char *key, size_t key_length, int index, void *void_user_context)
{
    JsonParserContext *context = void_user_context;
    void *result;
    
    my_debug();
    if (key != NULL || nesting != 0) {
        if (context->shouldSkipNextEndStructure) {
            result = NULL;
        } else if (key != NULL && strcmp(key, "$timestamp") == 0) {
            if (context->pendingBsonValue.bsonType == NO_BSON_TYPE) {
                context->pendingBsonValue.bsonType = TIMESTAMP_BSON_TYPE;
                context->pendingBsonValue.index = index;
                result = context->target;
            } else {
                result = NULL;
            }
        } else {
            if (create_waiting_structure_if_needed(context)) {
                context->pendingBsonValue.structureWaiting = is_object?OBJECT_STRUCTURE:ARRAY_STRUCTURE;
                context->pendingBsonValue.objectKeyToCreate = copyString(key);
                context->pendingBsonValue.index = index;
                result = context->target;
            } else {
                result = NULL;
            }
        }
    } else if (nesting == 0) {
        assert(index == 0);
        if (is_object) {
            [context->target startMainDictionary];
        } else {
            [context->target startMainArray];
        }
        result = [context->target mainObject];
        pushStack(context, [context->target mainObject], is_object == 1);
    }
    return result;
}

static int end_structure_for_bson(int nesting, int is_object, const char *key, size_t key_length, int index, void *structure, void *void_user_context)
{
    JsonParserContext *context = void_user_context;
    int result = 0;
    
    my_debug();
    if (key != NULL || nesting != 0) {
        if (context->pendingBsonValue.regexBson.pattern && context->pendingBsonValue.bsonType == REGEX_BSON_TYPE) {
            result = [context->target appendRegexWithPattern:context->pendingBsonValue.regexBson.pattern options:context->pendingBsonValue.regexBson.options key:context->pendingBsonValue.objectKeyToCreate previousStructure:context->latestStack->structure index:context->pendingBsonValue.index]?0:1;
            clear_pending_value(context, YES);
            context->shouldSkipNextEndStructure = NO;
        } else if (context->pendingBsonValue.bsonType == TIMESTAMP_BSON_TYPE) {
            if (!context->pendingBsonValue.timestampBson.hasIValue || !context->pendingBsonValue.timestampBson.hasTValue) {
                result = 1;
            } else if (!context->pendingBsonValue.timestampBson.closeOne) {
                context->pendingBsonValue.timestampBson.closeOne = YES;
            } else {
                result = [context->target appendTimestampWithTValue:context->pendingBsonValue.timestampBson.tValue iValue:context->pendingBsonValue.timestampBson.iValue key:context->pendingBsonValue.objectKeyToCreate previousStructure:context->latestStack->structure index:context->pendingBsonValue.index]?0:1;
                clear_pending_value(context, YES);
            }
        } else if (context->pendingBsonValue.bsonType != NO_BSON_TYPE) {
            result = 1;
        } else if (is_object && !context->shouldSkipNextEndStructure) {
            create_waiting_structure_if_needed(context);
            result = [context->target closeDictionaryWithStructure:context->latestStack->structure]?0:1;
            popStack(context);
        } else if (!context->shouldSkipNextEndStructure) {
            create_waiting_structure_if_needed(context);
            result = [context->target closeArrayWithStructure:context->latestStack->structure]?0:1;
            popStack(context);
        } else if (context->shouldSkipNextEndStructure) {
            context->shouldSkipNextEndStructure = NO;
        }
    } else if (nesting == 0) {
        if (is_object) {
            [context->target finishMainDictionary];
        } else {
            [context->target finishMainArray];
        }
        popStack(context);
        result = (context->latestStack == NULL)?0:1;
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

static size_t convertHexaStringToData(const char * string, void *data, size_t length)
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

@interface MODJsonParser()
@property (nonatomic, assign, readonly) struct json_tokener *tokener;
@end

@implementation MODJsonParser

@synthesize multiPartParsing = _multiPartParsing, totalParsedLength = _totalParsedLength;

- (id)init
{
    if (self = [super init]) {
        _tokener = json_tokener_new();
    }
    return self;
}

- (void)dealloc
{
    json_tokener_free(self.tokener);
    [super dealloc];
}

- (void)_convertJsonObject:(json_object *)jsonObject previousStructure:(void *)previousStructure
{
    struct json_object_iterator iterator;
    struct json_object_iterator endIterator;
    int ii = 0;
    
    iterator = json_object_iter_begin(jsonObject);
    endIterator = json_object_iter_end(jsonObject);
    while (!json_object_iter_equal(&iterator, &endIterator)) {
        const char *key;
        struct json_object *value;
        void *newStructure;
        
        key = json_object_iter_peek_name(&iterator);
        value = json_object_iter_peek_value(&iterator);
        switch (json_object_get_type(value)) {
            case json_type_null:
                [(id<MODJsonParserProtocol>)self appendNullWithKey:key previousStructure:previousStructure index:ii];
                break;
            case json_type_boolean:
                [(id<MODJsonParserProtocol>)self appendBool:json_object_get_boolean(value) withKey:key previousStructure:previousStructure index:ii];
                break;
            case json_type_double:
                [(id<MODJsonParserProtocol>)self appendDouble:json_object_get_double(value) withKey:key previousStructure:previousStructure index:ii];
                break;
            case json_type_int:
                [(id<MODJsonParserProtocol>)self appendLongLong:json_object_get_int64(value) withKey:key previousStructure:previousStructure index:ii];
                break;
            case json_type_object:
                newStructure = [(id<MODJsonParserProtocol>)self openDictionaryWithPreviousStructure:previousStructure key:key index:ii];
                [self _convertJsonObject:value previousStructure:newStructure];
                [(id<MODJsonParserProtocol>)self closeDictionaryWithStructure:newStructure];
                break;
            case json_type_array:
                newStructure = [(id<MODJsonParserProtocol>)self openArrayWithPreviousStructure:previousStructure key:key index:ii];
                [self _convertJsonObject:value previousStructure:newStructure];
                [(id<MODJsonParserProtocol>)self closeArrayWithStructure:newStructure];
                break;
            case json_type_string:
                [(id<MODJsonParserProtocol>)self appendString:json_object_get_string(value) withKey:key previousStructure:previousStructure index:ii];
                break;
            case json_type_binary:
                [(id<MODJsonParserProtocol>)self appendDataBinary:json_object_get_string(value) withLength:<#(NSUInteger)#> binaryType:<#(char)#> key:key previousStructure:previousStructure index:ii];
                break;
        }
        json_object_iter_next(&iterator);
        ii++;
    }
}

- (void)_processJson:(const char *)json errorCode:(int *)errorCode parsedLength:(size_t *)parsedLength
{
    json_object *object;
    struct json_object_iterator iterator;
    struct json_object_iterator endIterator;
    
    assert(parsedLength != nil);
    assert(errorCode != nil);
    *parsedLength = 0;
    *errorCode = 0;
    
    object = json_tokener_parse_ex(self.tokener, json, -1);
    iterator = json_object_iter_begin(object);
    endIterator = json_object_iter_end(object);
    
    switch (json_object_get_type(object)) {
        case json_type_object:
            [(id<MODJsonParserProtocol>)self startMainDictionary];
            break;
        case json_type_array:
            [(id<MODJsonParserProtocol>)self startMainArray];
            break;
        default:
            NSAssert(NO, @"unknown type %d", json_object_get_type(object));
    }
    [self _convertJsonObject:object previousStructure:[(id<MODJsonParserProtocol>)self mainObject]];
    
    switch (json_object_get_type(object)) {
        case json_type_object:
            [(id<MODJsonParserProtocol>)self finishMainDictionary];
            break;
        case json_type_array:
            [(id<MODJsonParserProtocol>)self finishMainArray];
            break;
        default:
            NSAssert(NO, @"unknown type %d", json_object_get_type(object));
    }
    
    *parsedLength = self.tokener->char_offset;
    *errorCode = self.tokener->err;
}

- (size_t)parseJsonWithCstring:(const char *)json error:(NSError **)error
{
    size_t parsedLength = 0;
    int errorCode = 0;
    
    [self _processJson:json errorCode:&errorCode parsedLength:&parsedLength];
    
    _totalParsedLength += parsedLength;
    if (((!_multiPartParsing && ![self parsingDone]) || errorCode != 0) && error) {
        NSRange range;
        size_t stringLength = strlen(json);
        char substring[21];
        
        range.length = sizeof(substring) - 1;
        if (parsedLength < range.length / 2) {
            range.location = 0;
            range.length -= (range.length / 2) - parsedLength;
        } else {
            range.location = parsedLength - (range.length / 2);
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
    return parsedLength;
}

- (size_t)parseJsonWithString:(NSString *)json error:(NSError **)error
{
    return [self parseJsonWithCstring:[json UTF8String] error:error];
}

- (BOOL)parsingDone
{
    return self.tokener->err != json_tokener_error_parse_eof;
}

- (struct json_tokener *)tokener
{
    return _tokener;
}

@end

@implementation MODJsonToBsonParser

+ (NSInteger)bsonFromJson:(bson *)bsonResult json:(NSString *)json error:(NSError **)error
{
    MODJsonToBsonParser *parser;
    NSInteger result;
    
    parser = [[self alloc] init];
    [parser setBson:bsonResult];
    result = [parser parseJsonWithString:json error:error];
    [parser release];
    return result;
}

- (void)setBson:(bson *)bson
{
    _bson = bson;
}

- (void *)mainObject
{
    return _bson;
}

- (void)startMainDictionary
{
    
}

- (void)finishMainDictionary
{
    
}

- (void)startMainArray
{
    _isMainObjectArray = YES;
    bson_append_start_array(_bson, "array");
}

- (void)finishMainArray
{
    bson_append_finish_array(_bson);
}

- (BOOL)isMainObjectArray
{
    return _isMainObjectArray;
}

- (void *)openDictionaryWithPreviousStructure:(void *)structure key:(const char *)key index:(int)index
{
    void *result = NULL;
    
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    bson_append_start_object(_bson, key);
    result = _bson;
    return result;
}

- (void *)openArrayWithPreviousStructure:(void *)structure key:(const char *)key index:(int)index
{
    void *result = NULL;
    
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    bson_append_start_array(_bson, key);
    result = _bson;
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

- (BOOL)appendTimestampWithTValue:(int)tValue iValue:(int)iValue key:(const char *)key previousStructure:(void *)structure index:(int)index
{
    bson_timestamp_t ts;
    
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    ts.t = tValue;
    ts.i = iValue;
    bson_append_timestamp(_bson, key, &ts);
    return YES;
}

- (BOOL)appendObjectId:(void *)objectId length:(size_t)length withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    bson_append_oid(_bson, key, objectId);
    return YES;
}

- (BOOL)appendString:(const char *)stringValue withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    bson_append_string(_bson, key, stringValue);
    return YES;
}

- (BOOL)appendLongLong:(long long)integer withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    bson_append_long(_bson, key, integer);
    return YES;
}

- (BOOL)appendDouble:(double)doubleValue withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    bson_append_double(_bson, key, doubleValue);
    return YES;
}

- (BOOL)appendNullWithKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    bson_append_null(_bson, key);
    return YES;
}

- (BOOL)appendBool:(BOOL)boolValue withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    bson_append_bool(_bson, key, boolValue?1:0);
    return YES;
}

- (BOOL)appendSymbol:(NSString *)value withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    bson_append_symbol(_bson, key, [value UTF8String]);
    return YES;
}

- (BOOL)appendDate:(int64_t)date withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    bson_append_date(_bson, key, date);
    return YES;
}

- (BOOL)appendRegexWithPattern:(const char *)pattern options:(const char *)options key:(const char *)key previousStructure:(void *)structure index:(int)index
{
    BOOL result = NO;
    
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    if (pattern) {
        if (!options) {
            options = "";
        }
        bson_append_regex(_bson, key, pattern, options);
        result = YES;
    }
    return result;
}

- (BOOL)appendDataBinary:(const char *)binary withLength:(NSUInteger)length binaryType:(char)binaryType key:(const char *)key previousStructure:(void *)structure index:(int)index
{
    void *buffer = malloc(length / 2);
    
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    convertHexaStringToData(binary, buffer, length / 2);
    bson_append_binary(_bson, key, binaryType, buffer, length / 2);
    free(buffer);
    return YES;
}

- (BOOL)appendUndefinedWithKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    if (key == NULL) {
        snprintf(_indexKey, sizeof(_indexKey), "%d", index);
        key = _indexKey;
    }
    bson_append_undefined(_bson, key);
    return YES;
}

@end

@implementation MODJsonToObjectParser

+ (id)objectsFromJson:(NSString *)json error:(NSError **)error
{
    id objects = nil;
    MODJsonToObjectParser *parser;
    
    parser = [[MODJsonToObjectParser alloc] init];
    [parser parseJsonWithString:json error:error];
    if ([parser parsingDone]) {
        objects = [(id)[parser mainObject] retain];
    }
    [parser release];
    return [objects autorelease];
}

- (void)dealloc
{
    [_mainObject release];
    [super dealloc];
}

- (void *)mainObject
{
    return _mainObject;
}

- (void)startMainDictionary
{
    _mainObject = [[MODSortedMutableDictionary alloc] init];
}

- (void)startMainArray
{
    _mainObject = [[NSMutableArray alloc] init];
    _isMainObjectArray = YES;
}

- (void)finishMainDictionary
{
}

- (void)finishMainArray
{
}

- (BOOL)isMainObjectArray
{
    return _isMainObjectArray;
}

- (BOOL)addObject:(id)object toStructure:(id)structure withKey:(const char *)key
{
    BOOL result = YES;
    
    if (!structure) {
        structure = [self mainObject];
    }
    if (key != NULL) {
        NSString *stringKey;
        
        stringKey = [[NSString alloc] initWithUTF8String:key];
        [(MODSortedMutableDictionary *)structure setObject:object forKey:stringKey];
        [stringKey release];
    } else {
        [(NSMutableArray *)structure addObject:object];
    }
    return result;
}

- (void *)openDictionaryWithPreviousStructure:(void *)structure key:(const char *)key index:(int)index
{
    MODSortedMutableDictionary *result;
    
    result = [[MODSortedMutableDictionary alloc] init];
    if (![self addObject:result toStructure:structure withKey:key]) {
        [result release];
        result = nil;
    }
    return [result autorelease];
}

- (void *)openArrayWithPreviousStructure:(void *)structure key:(const char *)key index:(int)index
{
    NSMutableArray *result;
    
    result = [NSMutableArray array];
    if (![self addObject:result toStructure:structure withKey:key]) {
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

- (BOOL)appendTimestampWithTValue:(int)tValue iValue:(int)iValue key:(const char *)key previousStructure:(void *)structure index:(int)index
{
    MODTimestamp *ts;
    BOOL result;
    
    ts = [[MODTimestamp alloc] initWithTValue:tValue iValue:iValue];
    result = [self addObject:ts toStructure:structure withKey:key];
    [ts release];
    return result;
}

- (BOOL)appendObjectId:(void *)objectId length:(size_t)length withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    MODObjectId *object;
    BOOL result = NO;
    
    if (length == sizeof(bson_oid_t)) {
        object = [[MODObjectId alloc] initWithOid:objectId];
        result = [self addObject:object toStructure:structure withKey:key];
        [object release];
    }
    return result;
}

- (BOOL)appendString:(const char *)stringValue withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    NSString *object;
    BOOL result;
    
    object = [[NSString alloc] initWithUTF8String:stringValue];
    result = [self addObject:object toStructure:structure withKey:key];
    [object release];
    return result;
}

- (BOOL)appendLongLong:(long long)integerValue withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    NSNumber *object;
    BOOL result;
    
    object = [[NSNumber alloc] initWithLongLong:integerValue];
    result = [self addObject:object toStructure:structure withKey:key];
    [object release];
    return result;
}

- (BOOL)appendDouble:(double)doubleValue withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    NSNumber *object;
    BOOL result;

    object = [[NSNumber alloc] initWithDouble:doubleValue];
    result = [self addObject:object toStructure:structure withKey:key];
    [object release];
    return result;
}

- (BOOL)appendBool:(BOOL)boolValue withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    NSNumber *object;
    BOOL result;
    
    object = [[NSNumber alloc] initWithBool:boolValue];
    result = [self addObject:object toStructure:structure withKey:key];
    [object release];
    return result;
}

- (BOOL)appendSymbol:(NSString *)value withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    MODSymbol *object;
    BOOL result;
    
    object = [[MODSymbol alloc] initWithValue:value];
    result = [self addObject:object toStructure:structure withKey:key];
    [object release];
    return result;
}

- (BOOL)appendDate:(int64_t)date withKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    NSDate *object;
    BOOL result;
    
    object = [[NSDate alloc] initWithTimeIntervalSince1970:date / 1000.0];
    result = [self addObject:object toStructure:structure withKey:key];
    [object release];
    return result;
}

- (BOOL)appendNullWithKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    return [self addObject:[NSNull null] toStructure:structure withKey:key];
}

- (BOOL)appendRegexWithPattern:(const char *)pattern options:(const char *)options key:(const char *)key previousStructure:(void *)structure index:(int)index
{
    BOOL result = NO;
    
    if (pattern) {
        MODRegex *dataRegex;
        NSString *patternString;
        NSString *optionsString;
        
        patternString = [[NSString alloc] initWithUTF8String:pattern];
        if (options) {
            optionsString = [[NSString alloc] initWithUTF8String:options];
        } else {
            optionsString = [@"" retain];
        }
        dataRegex = [[MODRegex alloc] initWithPattern:patternString options:optionsString];
        result = [self addObject:dataRegex toStructure:structure withKey:key];
        [patternString release];
        [optionsString release];
        [dataRegex release];
    }
    return result;
}

- (BOOL)appendDataBinary:(const char *)binary withLength:(NSUInteger)length binaryType:(char)binaryType key:(const char *)key previousStructure:(void *)structure index:(int)index
{
    MODBinary *object;
    BOOL result;
    NSString *base64String;
    
    base64String = [[NSString alloc] initWithBytes:binary length:length encoding:NSUTF8StringEncoding];
    object = [[MODBinary alloc] initWithData:[base64String dataFromBase64] binaryType:binaryType];
    result = [self addObject:object toStructure:structure withKey:key];
    [object release];
    [base64String release];
    return result;
}

- (BOOL)appendUndefinedWithKey:(const char *)key previousStructure:(void *)structure index:(int)index
{
    MODUndefined *object;
    BOOL result;
    
    object = [[MODUndefined alloc] init];
    result = [self addObject:object toStructure:structure withKey:key];
    [object release];
    return result;
}

@end
