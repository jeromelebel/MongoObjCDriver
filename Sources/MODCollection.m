//
//  MODCollection.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"
#import "json.h"

#if 1
typedef struct {
    int type;
    const char *data;
    uint32_t length;
} ParserDataInfo;

static void * begin_structure(int nesting, int is_object, const char *key, int key_length, void *user_context)
{
    if (key == NULL) {
        key = "main";
    }
    if (is_object) {
        bson_append_start_object(user_context, key);
    } else {
        bson_append_start_array(user_context, key);
    }
    return user_context;
}

static int end_structure(int nesting, int is_object, const char *key, int key_length, void *structure, void *user_context)
{
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
static int append(void *structure, int is_object_structure, int structure_value_count, char *key, uint32_t key_length, void *obj, void *user_context)
{
    ParserDataInfo *dataInfo = obj;
    char arrayKey[32];
    
    if (is_object_structure == false) {
        snprintf(arrayKey, sizeof(arrayKey), "%d", structure_value_count);
        key = arrayKey;
    }
    switch (dataInfo->type) {
        case JSON_STRING:
            bson_append_string_n(user_context, key, dataInfo->data, dataInfo->length);
            break;
        case JSON_INT:
            bson_append_long(user_context, key, atoll(dataInfo->data));
            break;
        case JSON_FLOAT:
            bson_append_double(user_context, key, atof(dataInfo->data));
            break;
        case JSON_NULL:
            bson_append_null(user_context, key);
            break;
        case JSON_TRUE:
            bson_append_bool(user_context, key, 0);
            break;
        case JSON_FALSE:
            bson_append_bool(user_context, key, 0);
            break;
        default:
            break;
    }
    free(obj);
    return 0;
}

bson *bson_from_json(const char *json, size_t length, int *error, size_t *totalProcessed);
bson *bson_from_json(const char *json, size_t length, int *error, size_t *totalProcessed)
{
    json_parser_dom helper;
    json_config config;
    json_parser parser;
    bson *bsonResult;
    uint32_t processed;

	memset(&config, 0, sizeof(json_config));
    config.allow_c_comments = 1;
    config.allow_yaml_comments = 1;
    bsonResult = malloc(sizeof(bson));
    bson_init(bsonResult);
    json_parser_dom_init(&helper, begin_structure, end_structure, create_data, append, bsonResult);
    json_parser_init(&parser, &config, json_parser_dom_callback, &helper);
    *error = json_parser_string(&parser, json, length, &processed);
    *totalProcessed = processed;
    json_parser_dom_free(&helper);
    json_parser_free(&parser);
    bson_finish(bsonResult);
    if (processed != length) {
        bson_destroy(bsonResult);
        free(bsonResult);
        bsonResult = NULL;
    }
    return bsonResult;
}
#else
typedef struct {
    bson            *bsonResult;
    char            *key;
} ParserContext;

static int parserCallback(ParserContext* ctx, int type, const JSON_value* value)
{
    int result = true;
    
    switch (type) {
        case JSON_T_NONE:
            break;
        case JSON_T_ARRAY_BEGIN:
            bson_append_start_array(ctx->bsonResult, ctx->key);
            break;
        case JSON_T_ARRAY_END:
            bson_append_finish_array(ctx->bsonResult);
            break;
        case JSON_T_OBJECT_BEGIN:
            bson_append_start_object(ctx->bsonResult, ctx->key);
            break;
        case JSON_T_OBJECT_END:
            bson_append_finish_object(ctx->bsonResult);
            break;
        case JSON_T_INTEGER:
            bson_append_long(ctx->bsonResult, ctx->key, value->vu.integer_value);
            break;
        case JSON_T_FLOAT:
            bson_append_double(ctx->bsonResult, ctx->key, value->vu.float_value);
            break;
        case JSON_T_NULL:
            bson_append_null(ctx->bsonResult, ctx->key);
            break;
        case JSON_T_TRUE:
            bson_append_bool(ctx->bsonResult, ctx->key, value->vu.integer_value != 0);
            break;
        case JSON_T_FALSE:
            bson_append_bool(ctx->bsonResult, ctx->key, value->vu.integer_value != 0);
            break;
        case JSON_T_STRING:
            bson_append_string_n(ctx->bsonResult, ctx->key, value->vu.str.value, value->vu.str.length);
            break;
        case JSON_T_KEY:
            if (ctx->key) {
                free(ctx->key);
            }
            ctx->key = malloc(value->vu.str.length + 1);
            memccpy(ctx->key, value->vu.str.value, 1, value->vu.str.length + 1);
            break;
        case JSON_T_MAX:
            assert(false);
            break;
        default:
            break;
    }
    return result;
}

bson *bson_from_json(const char *json, size_t length, int *error, size_t *totalProcessed)
{
    ParserContext context;
    JSON_config config;
    struct JSON_parser_struct* parser;
    size_t ii = 0;
    bson *bsonResult;
    const char *mainKey = "main";
    
    bsonResult = malloc(sizeof(*bsonResult));
    bson_init(bsonResult);
    context.bsonResult = bsonResult;
    context.key = malloc(strlen(mainKey) + 1);
    memccpy(context.key, mainKey, 1, strlen(mainKey));
    
    init_JSON_config(&config);
    config.depth = 256;
    config.callback = (JSON_parser_callback)&parserCallback;
    config.callback_ctx = &context;
    config.allow_comments = 1;
    config.handle_floats_manually = 0;
    
    if (error) {
        *error = JSON_E_NONE;
    }
    parser = new_JSON_parser(&config);
    while (json[ii] != 0) {
        if (!JSON_parser_char(parser, json[ii])) {
            if (error) {
                *error = JSON_parser_get_last_error(parser);
                break;
            }
        }
        ii++;
    }
    free(context.key);
    if (totalProcessed) {
        *totalProcessed = ii;
    }
    bson_finish(bsonResult);
    return bsonResult;
}
#endif

@implementation MODCollection

@synthesize mongoDatabase = _mongoDatabase, collectionName = _collectionName, absoluteCollectionName = _absoluteCollectionName, delegate = _delegate;

- (id)initWithMongoDatabase:(MODDatabase *)mongoDatabase collectionName:(NSString *)collectionName
{
    if (self = [self init]) {
        _mongoDatabase = [mongoDatabase retain];
        _collectionName = [collectionName retain];
        _absoluteCollectionName = [[NSString alloc] initWithFormat:@"%@.%@", _mongoDatabase.databaseName, _collectionName];
    }
    return self;
}

- (void)dealloc
{
    [_mongoDatabase release];
    [_absoluteCollectionName release];
    [_collectionName release];
    [_absoluteCollectionName release];
    [super dealloc];
}

- (void)findCallback:(MODQuery *)mongoQuery
{
    NSArray *result;
    NSString *errorMessage;
    
    [mongoQuery ends];
    result = [mongoQuery.parameters objectForKey:@"result"];
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryResultFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoCollection:self queryResultFetched:result withMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

- (MODQuery *)findWithQuery:(NSString *)jsonQuery fields:(NSString *)fields skip:(int)skip limit:(int)limit sort:(NSString *)sort
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSMutableArray *response;
//        NSString *errorMessage = nil;
//        NSString *oid = nil;
//        NSString *oidType = nil;
//        NSString *jsonString = nil;
//        NSString *jsonStringb = nil;
//        NSMutableArray *repArr = nil;
//        NSMutableArray *oriArr = nil;
//        NSMutableDictionary *item = nil;
//        
        response = [[NSMutableArray alloc] initWithCapacity:limit];
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson *bsonQuery = NULL;
            bson *bsonSort = NULL;
            bson bsonFields;
            int error;
            size_t totalProcessed;
            
            bsonQuery = bson_from_json([jsonQuery UTF8String], [jsonQuery length], &error, &totalProcessed);
            if (!bsonQuery) {
                
            } else {
                bsonSort = bson_from_json([sort UTF8String], [sort length], &error, &totalProcessed);
                if (bsonSort) {
                    
                }
            }
            bson_init(&bsonFields);
            if ([fields length] > 0) {
                NSUInteger index = 0;
                char indexString[128];
                
                for (NSString *field in [fields componentsSeparatedByString:@","]) {
                    snprintf(indexString, sizeof(indexString), "%lu", index);
                    bson_append_string(&bsonFields, [[field stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] UTF8String], indexString);
                }
                bson_finish(&bsonFields);
            }
//            std::auto_ptr<mongo::DBClientCursor> cursor;
//            if (_mongoDatabase.mongoServer.replicaConnexion) {
//                cursor = _mongoDatabase.mongoServer.replicaConnexion->query(std::string([_absoluteCollectionName UTF8String]), mongo::Query(queryBSON).sort(sortBSON), limit, skip, &fieldsToReturn);
//            } else {
//                cursor = _mongoDatabase.mongoServer.connexion->query(std::string([_absoluteCollectionName UTF8String]), mongo::Query(queryBSON).sort(sortBSON), limit, skip, &fieldsToReturn);
//            }
//            while (cursor->more()) {
//                mongo::BSONObj b = cursor->next();
//                mongo::BSONElement e;
//                b.getObjectID (e);
//                
//                if (e.type() == mongo::jstOID) {
//                    oidType = @"ObjectId";
//                    [oid release];
//                    oid = [[NSString alloc] initWithUTF8String:e.__oid().str().c_str()];
//                } else {
//                    oidType = @"String";
//                    [oid release];
//                    oid = [[NSString alloc] initWithUTF8String:e.str().c_str()];
//                }
//                [jsonString release];
//                jsonString = [[NSString alloc] initWithUTF8String:b.jsonString(mongo::TenGen).c_str()];
//                [jsonStringb release];
//                jsonStringb = [[NSString alloc] initWithUTF8String:b.jsonString(mongo::TenGen, 1).c_str()];
//                if (jsonString == nil) {
//                    jsonString = [@"" retain];
//                }
//                if (jsonStringb == nil) {
//                    jsonStringb = [@"" retain];
//                }
//                [repArr release];
//                repArr = [[NSMutableArray alloc] initWithCapacity:4];
//                id regx2 = [RKRegex regexWithRegexString:@"(Date\\(\\s\\d+\\s\\))" options:RKCompileCaseless];
//                RKEnumerator *matchEnumerator2 = [jsonString matchEnumeratorWithRegex:regx2];
//                while([matchEnumerator2 nextRanges] != NULL) {
//                    NSString *enumeratedStr=NULL;
//                    [matchEnumerator2 getCapturesWithReferences:@"$1", &enumeratedStr, nil];
//                    [repArr addObject:enumeratedStr];
//                }
//                [oriArr release];
//                oriArr = [[NSMutableArray alloc] initWithCapacity:4];
//                id regx = [RKRegex regexWithRegexString:@"(Date\\(\\s+\"[^^]*?\"\\s+\\))" options:RKCompileCaseless];
//                RKEnumerator *matchEnumerator = [jsonStringb matchEnumeratorWithRegex:regx];
//                while([matchEnumerator nextRanges] != NULL) {
//                    NSString *enumeratedStr=NULL;
//                    [matchEnumerator getCapturesWithReferences:@"$1", &enumeratedStr, nil];
//                    [oriArr addObject:enumeratedStr];
//                }
//                for (unsigned int i=0; i<[repArr count]; i++) {
//                    NSString *old;
//                    
//                    old = jsonStringb;
//                    jsonStringb = [[jsonStringb stringByReplacingOccurrencesOfString:[oriArr objectAtIndex:i] withString:[repArr objectAtIndex:i]] retain];
//                    [old release];
//                }
//                [item release];
//                item = [[NSMutableDictionary alloc] initWithCapacity:6];
//                [item setObject:@"_id" forKey:@"name"];
//                [item setObject:oidType forKey:@"type"];
//                [item setObject:oid forKey:@"value"];
//                [item setObject:jsonString forKey:@"raw"];
//                [item setObject:jsonStringb forKey:@"beautified"];
//                [item setObject:[[_mongoDatabase.mongoServer class] bsonDictWrapper:b] forKey:@"child"];
//                [response addObject:item];
//            }
//            [mongoQuery.mutableParameters setObject:response forKey:@"result"];
            if (bsonQuery) {
                bson_destroy(bsonQuery);
                free(bsonQuery);
            }
            if (bsonSort) {
                bson_destroy(bsonSort);
                free(bsonSort);
            }
            bson_destroy(&bsonFields);
        }
        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(findCallback:)];
        [response release];
//        [oid release];
//        [jsonString release];
//        [jsonStringb release];
//        [repArr release];
//        [oriArr release];
//        [item release];
    }];
    [query.mutableParameters setObject:query forKey:@"query"];
    [query.mutableParameters setObject:fields forKey:@"fields"];
    [query.mutableParameters setObject:[NSNumber numberWithInt:skip] forKey:@"skip"];
    [query.mutableParameters setObject:[NSNumber numberWithInt:limit] forKey:@"limit"];
    [query.mutableParameters setObject:sort forKey:@"sort"];
    [query.mutableParameters setObject:self forKey:@"collection"];
    return query;
}

- (void)countCallback:(MODQuery *)mongoQuery
{
    long long int count;
    NSString *errorMessage;
    
    [mongoQuery ends];
    count = [[mongoQuery.parameters objectForKey:@"count"] longLongValue];
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryCountWithValue:withMongoQuery:errorMessage:)]) {
        [_delegate mongoCollection:self queryCountWithValue:count withMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

//- (MODQuery *)countWithQuery:(NSString *)jsonQuery
//{
//    MODQuery *query = nil;
//    
//    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        NSString *errorMessage;
//        
//        try {
//            if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
//                long long int value;
//                NSNumber *count;
//                
//                mongo::BSONObj criticalBSON = mongo::fromjson([jsonQuery UTF8String]);
//                
//                if (_mongoDatabase.mongoServer.replicaConnexion) {
//                    value = _mongoDatabase.mongoServer.replicaConnexion->count(std::string([_absoluteCollectionName UTF8String]), criticalBSON);
//                }else {
//                    value = _mongoDatabase.mongoServer.connexion->count(std::string([_absoluteCollectionName UTF8String]), criticalBSON);
//                }
//                count = [[NSNumber alloc] initWithLongLong:value];
//                [mongoQuery.mutableParameters setObject:count forKey:@"count"];
//                [count release];
//            }
//        } catch (mongo::DBException &e) {
//            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
//            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
//            [errorMessage release];
//        }
//        [self performSelectorOnMainThread:@selector(countCallback:) withObject:mongoQuery waitUntilDone:NO];
//    }];
//    [query.mutableParameters setObject:query forKey:@"query"];
//    [query.mutableParameters setObject:self forKey:@"collection"];
//    return query;
//}

- (void)updateCallback:(MODQuery *)mongoQuery
{
    NSString *errorMessage;
    
    [mongoQuery ends];
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:updateDonwWithMongoQuery:errorMessage:)]) {
        [_delegate mongoCollection:self updateDonwWithMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

//- (MODQuery *)updateWithQuery:(NSString *)jsonQuery fields:(NSString *)fields upset:(BOOL)upset
//{
//    MODQuery *query = nil;
//    
//    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        NSString *errorMessage;
//        
//        try {
//            if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
//                mongo::BSONObj criticalBSON = mongo::fromjson([jsonQuery UTF8String]);
//                mongo::BSONObj fieldsBSON = mongo::fromjson([[NSString stringWithFormat:@"{$set:%@}", fields] UTF8String]);
//                if (_mongoDatabase.mongoServer.replicaConnexion) {
//                    _mongoDatabase.mongoServer.replicaConnexion->update(std::string([_absoluteCollection UTF8String]), criticalBSON, fieldsBSON, (upset == YES)?true:false);
//                }else {
//                    _mongoDatabase.mongoServer.connexion->update(std::string([_absoluteCollection UTF8String]), criticalBSON, fieldsBSON, (upset == YES)?true:false);
//                }
//            }
//        } catch (mongo::DBException &e) {
//            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
//            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
//            [errorMessage release];
//        }
//        [self performSelectorOnMainThread:@selector(updateCallback:) withObject:mongoQuery waitUntilDone:NO];
//    }];
//    [query.mutableParameters setObject:query forKey:@"query"];
//    [query.mutableParameters setObject:fields forKey:@"fields"];
//    [query.mutableParameters setObject:[NSNumber numberWithBool:upset] forKey:@"upset"];
//    [query.mutableParameters setObject:self forKey:@"collection"];
//    return query;
//}

//- (MODQuery *)saveJsonString:(NSString *)jsonString withRecordId:(NSString *)recordId
//{
//    MongoQuery *query = nil;
//    
//    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        NSString *errorMessage;
//        try {
//            if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
//                mongo::BSONObj fields = mongo::fromjson([jsonString UTF8String]);
//                mongo::BSONObj critical = mongo::fromjson([[NSString stringWithFormat:@"{\"_id\":%@}", recordId] UTF8String]);
//                
//                if (_mongoDatabase.mongoServer.replicaConnexion) {
//                    _mongoDatabase.mongoServer.replicaConnexion->update(std::string([_absoluteCollection UTF8String]), critical, fields, false);
//                }else {
//                    _mongoDatabase.mongoServer.connexion->update(std::string([_absoluteCollection UTF8String]), critical, fields, false);
//                }
//            }
//        } catch (mongo::DBException &e) {
//            errorMessage = [[NSString alloc] initWithUTF8String:e.what()];
//            [mongoQuery.mutableParameters setObject:errorMessage forKey:@"errormessage"];
//            [errorMessage release];
//        }
//        [self performSelectorOnMainThread:@selector(updateCallback:) withObject:mongoQuery waitUntilDone:NO];
//    }];
//    [query.mutableParameters setObject:jsonString forKey:@"jsonstring"];
//    [query.mutableParameters setObject:recordId forKey:@"recordid"];
//    [query.mutableParameters setObject:self forKey:@"collection"];
//    return query;
//}

@end
