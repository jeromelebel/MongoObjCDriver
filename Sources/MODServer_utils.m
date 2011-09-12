//
//  MODServer.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

typedef struct {
    const char *mainKey;
    bson *userBson;
} ParserUserContext;

typedef struct {
    int type;
    const char *data;
    uint32_t length;
} ParserDataInfo;

static void * begin_structure(int nesting, int is_object, const char *key, int key_length, void *void_user_context)
{
    ParserUserContext * userContext = void_user_context;
    
    if (key == NULL) {
        key = userContext->mainKey;
    }
    if (is_object) {
        bson_append_start_object(userContext->userBson, key);
    } else {
        bson_append_start_array(userContext->userBson, key);
    }
    return userContext->userBson;
}

static int end_structure(int nesting, int is_object, const char *key, int key_length, void *structure, void *void_user_context)
{
    ParserUserContext * userContext = void_user_context;
    
    if (is_object) {
        bson_append_finish_object(userContext->userBson);
    } else {
        bson_append_finish_array(userContext->userBson);
    }
    return 0;
}

/** callback from the parser_dom callback to create data values */
static void * create_data(int type, const char *data, uint32_t length, void *user_context)
{
    ParserDataInfo *result;
    
    result = malloc(sizeof(*result));
    result->type = type;
    result->data = data;
    result->length = length;
    return result;
}

/** callback from the parser helper callback to append a value to an object or array value
 * append(parent, key, key_length, val); */
static int append(void *structure, int is_object_structure, int structure_value_count, char *key, uint32_t key_length, void *obj, void *void_user_context)
{
    ParserDataInfo *dataInfo = obj;
    ParserUserContext * userContext = void_user_context;
    char arrayKey[32];
    
    if (is_object_structure == false) {
        snprintf(arrayKey, sizeof(arrayKey), "%d", structure_value_count);
        key = arrayKey;
    }
    switch (dataInfo->type) {
        case JSON_STRING:
            bson_append_string_n(userContext->userBson, key, dataInfo->data, dataInfo->length);
            break;
        case JSON_INT:
            bson_append_long(userContext->userBson, key, atoll(dataInfo->data));
            break;
        case JSON_FLOAT:
            bson_append_double(userContext->userBson, key, atof(dataInfo->data));
            break;
        case JSON_NULL:
            bson_append_null(userContext->userBson, key);
            break;
        case JSON_TRUE:
            bson_append_bool(userContext->userBson, key, 0);
            break;
        case JSON_FALSE:
            bson_append_bool(userContext->userBson, key, 0);
            break;
        default:
            break;
    }
    free(obj);
    return 0;
}

void bson_from_json(bson *bsonResult, const char *mainKey, const char *json, size_t length, int *error, size_t *totalProcessed)
{
    json_parser_dom helper;
    json_config config;
    json_parser parser;
    uint32_t processed;
    ParserUserContext userContext;
    
    userContext.userBson = bsonResult;
    userContext.mainKey = mainKey;
	memset(&config, 0, sizeof(json_config));
    config.allow_c_comments = 1;
    config.allow_yaml_comments = 1;
    json_parser_dom_init(&helper, begin_structure, end_structure, create_data, append, &userContext);
    json_parser_init(&parser, &config, json_parser_dom_callback, &helper);
    *error = json_parser_string(&parser, json, length, &processed);
    *totalProcessed = processed;
    json_parser_dom_free(&helper);
    json_parser_free(&parser);
}

@implementation MODServer(utils)

+ (NSError *)errorWithErrorDomain:(NSString *)errorDomain code:(NSInteger)code descriptionDetails:(NSString *)descriptionDetails
{
    NSError *error;
    
    if ([errorDomain isEqualToString:MODMongoErrorDomain]) {
        NSString *description;
        switch (code) {
            case MONGO_CONN_SUCCESS:
                description = @"Connection success!";
                break;
            case MONGO_CONN_NO_SOCKET:
                description = @"Could not create a socket.";
                break;
            case MONGO_CONN_FAIL:
                description = @"An error occured while calling connect().";
                break;
            case MONGO_CONN_ADDR_FAIL:
                description = @"An error occured while calling getaddrinfo().";
                break;
            case MONGO_CONN_NOT_MASTER:
                description = @"Warning: connected to a non-master node (read-only).";
                break;
            case MONGO_CONN_BAD_SET_NAME:
                description = @"Given rs name doesn't match this replica set.";
                break;
            case MONGO_CONN_NO_PRIMARY:
                description = @"Can't find primary in replica set. Connection closed.";
                break;
            case MONGO_IO_ERROR:
                description = @"An error occurred while reading or writing on the socket.";
                break;
            case MONGO_READ_SIZE_ERROR:
                description = @"The response is not the expected length.";
                break;
            case MONGO_COMMAND_FAILED:
                description = @"The command returned with 'ok' value of 0.";
                break;
            case MONGO_BSON_INVALID:
                description = @"BSON not valid for the specified op.";
                break;
            case MONGO_BSON_NOT_FINISHED:
                description = @"BSON object has not been finished.";
                break;
            default:
                description = [NSString stringWithFormat:@"Unknown error %ld", code];
                break;
        }
        if (descriptionDetails) {
            description = [NSString stringWithFormat:@"%@ - %@", description, descriptionDetails];
        }
        error = [NSError errorWithDomain:errorDomain code:code userInfo:[NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, nil]];
    } else {
        NSString *description;
        
        if (descriptionDetails) {
            description = [NSString stringWithFormat:@"Unknown error %ld (%@) - %@", code, errorDomain, descriptionDetails];
        } else {
            description = [NSString stringWithFormat:@"Unknown error %ld (%@)", code, errorDomain];
        }
        error = [NSError errorWithDomain:errorDomain code:code userInfo:[NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, nil]];
    }
    return error;
}

+ (id)objectFromBsonIterator:(bson_iterator *)iterator
{
    id result = nil;
    bson_iterator subIterator;
    
    switch (bson_iterator_type(iterator)) {
        case BSON_EOO:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_DOUBLE:
            result = [NSNumber numberWithDouble:bson_iterator_double(iterator)];
            break;
        case BSON_STRING:
            result = [NSString stringWithUTF8String:bson_iterator_string(iterator)];
            break;
        case BSON_OBJECT:
            result = [NSMutableDictionary dictionary];
            bson_iterator_subiterator(iterator, &subIterator);
            while (bson_iterator_next(&subIterator)) {
                id value;
                
                value = [self objectFromBsonIterator:&subIterator];
                if (value) {
                    NSString *key;
                    
                    key = [[NSString alloc] initWithUTF8String:bson_iterator_key(&subIterator)];
                    [result setObject:value forKey:key];
                    [key release];
                }
            }
            break;
        case BSON_ARRAY:
            result = [NSMutableArray array];
            bson_iterator_subiterator(iterator, &subIterator);
            while (bson_iterator_next(&subIterator)) {
                id value;
                
                value = [self objectFromBsonIterator:&subIterator];
                if (value) {
                    [result addObject:value];
                }
            }
            break;
        case BSON_BINDATA:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_UNDEFINED:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            result = nil;
            break;
        case BSON_OID:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_BOOL:
            result = [NSNumber numberWithBool:bson_iterator_bool(iterator) == true];
            break;
        case BSON_DATE:
            result = [NSDate dateWithTimeIntervalSince1970:bson_iterator_date(iterator) / 1000];
            break;
        case BSON_NULL:
            result = [NSNull null];
            break;
        case BSON_REGEX:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_DBREF:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_CODE:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_SYMBOL:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            result = [NSString stringWithUTF8String:bson_iterator_string(iterator)];
            break;
        case BSON_CODEWSCOPE:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_INT:
            result = [NSNumber numberWithInt:bson_iterator_int(iterator)];
            break;
        case BSON_TIMESTAMP:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_LONG:
            result = [NSNumber numberWithLong:bson_iterator_long(iterator)];
            break;
    }
    return result;
}

+ (NSDictionary *)objectsFromBson:(bson *)bsonObject
{
    bson_iterator iterator;
    NSMutableDictionary *result;
    
    result = [[NSMutableDictionary alloc] init];
    bson_iterator_init(&iterator, bsonObject);
    while (bson_iterator_next(&iterator) != BSON_EOO) {
        NSString *key;
        id value;
        
        key = [[NSString alloc] initWithUTF8String:bson_iterator_key(&iterator)];
        value = [self objectFromBsonIterator:&iterator];
        if (value) {
            [result setObject:value forKey:key];
        }
    }
    return [result autorelease];
}

@end
