//
//  MODCollection.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"
#import "json.h"

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

void bson_from_json(bson *bsonResult, const char *mainKey, const char *json, size_t length, int *error, size_t *totalProcessed);
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
    NSError *error;
    
    result = [mongoQuery.parameters objectForKey:@"result"];
    error = [mongoQuery.parameters objectForKey:@"error"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryResultFetched:withMongoQuery:error:)]) {
        [_delegate mongoCollection:self queryResultFetched:result withMongoQuery:mongoQuery error:error];
    }
}

- (MODQuery *)findWithQuery:(NSString *)jsonQuery fields:(NSArray *)fields skip:(int)skip limit:(int)limit sort:(NSString *)sort
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        NSMutableArray *response;
        
        response = [[NSMutableArray alloc] initWithCapacity:limit];
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson *bsonQuery = NULL;
            bson *bsonFields = NULL;
            int error;
            size_t totalProcessed;
            mongo_cursor cursor;
            
            mongo_cursor_init(&cursor, _mongoDatabase.mongoServer.mongo, [_absoluteCollectionName UTF8String]);
            
            bsonQuery = malloc(sizeof(*bsonQuery));
            bson_init(bsonQuery);
            bson_from_json(bsonQuery, "$query", [jsonQuery UTF8String], [jsonQuery length], &error, &totalProcessed);
            if (error == 0) {
                if ([sort length] > 0) {
                    bson_from_json(bsonQuery, "$orderby", [sort UTF8String], [sort length], &error, &totalProcessed);
                    if (error == 0) {
                    }
                }
                bson_finish(bsonQuery);
                NSLog(@"* %@", [MODServer objectsFromBson:bsonQuery]);
                mongo_cursor_set_query(&cursor, bsonQuery);
            } else {
                bson_finish(bsonQuery);
            }
            if ([fields count] > 0) {
                NSUInteger index = 0;
                char indexString[128];
                
                bsonFields = malloc(sizeof(*bsonFields));
                bson_init(bsonFields);
                for (NSString *field in fields) {
                    snprintf(indexString, sizeof(indexString), "%lu", index);
                    bson_append_string(bsonFields, [field UTF8String], indexString);
                }
                bson_finish(bsonFields);
                mongo_cursor_set_fields(&cursor, bsonFields);
            }
            mongo_cursor_set_skip(&cursor, skip);
            mongo_cursor_set_limit(&cursor, limit);
            
            while (mongo_cursor_next(&cursor) == MONGO_OK) {
                [response addObject:[[_mongoDatabase.mongoServer class] objectsFromBson:&(&cursor)->current]];
            }
            
            mongo_cursor_destroy(&cursor);
            if (bsonQuery) {
                bson_destroy(bsonQuery);
                free(bsonQuery);
            }
            if (bsonFields) {
                bson_destroy(bsonFields);
                free(bsonFields);
            }
            [mongoQuery.mutableParameters setObject:response forKey:@"response"];
        }
        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(findCallback:)];
        [response release];
    }];
    if (query) {
        [query.mutableParameters setObject:query forKey:@"query"];
    }
    if (fields) {
        [query.mutableParameters setObject:fields forKey:@"fields"];
    }
    [query.mutableParameters setObject:[NSNumber numberWithInt:skip] forKey:@"skip"];
    [query.mutableParameters setObject:[NSNumber numberWithInt:limit] forKey:@"limit"];
    if (sort) {
        [query.mutableParameters setObject:sort forKey:@"sort"];
    }
    [query.mutableParameters setObject:self forKey:@"collection"];
    return query;
}

- (void)countCallback:(MODQuery *)mongoQuery
{
    long long int count;
    NSError *error;
    
    count = [[mongoQuery.parameters objectForKey:@"count"] longLongValue];
    error = [mongoQuery.parameters objectForKey:@"error"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:queryCountWithValue:withMongoQuery:error:)]) {
        [_delegate mongoCollection:self queryCountWithValue:count withMongoQuery:mongoQuery error:error];
    }
}

- (MODQuery *)countWithQuery:(NSString *)jsonQuery
{
    MODQuery *query = nil;
    
    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        if ([_mongoDatabase authenticateSynchronouslyWithMongoQuery:mongoQuery]) {
            bson *bsonQuery = NULL;
            int error;
            size_t totalProcessed;
            NSNumber *response;
            uint64_t count;
            
            bsonQuery = malloc(sizeof(*bsonQuery));
            bson_init(bsonQuery);
            bson_from_json(bsonQuery, "$query", [jsonQuery UTF8String], [jsonQuery length], &error, &totalProcessed);
            if (error == 0) {
                bson_finish(bsonQuery);
            } else {
                bson_finish(bsonQuery);
            }
            
            if (bsonQuery) {
                bson_destroy(bsonQuery);
                free(bsonQuery);
            }
            count = mongo_count(_mongoDatabase.mongoServer.mongo, [_mongoDatabase.databaseName UTF8String], [_collectionName UTF8String], bsonQuery);
            response = [[NSNumber alloc] initWithUnsignedLongLong:count];
            [mongoQuery.mutableParameters setObject:response forKey:@"count"];
            [response release];
        }
        [_mongoDatabase.mongoServer mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(findCallback:)];
    }];
    if (query) {
        [query.mutableParameters setObject:query forKey:@"query"];
    }
    [query.mutableParameters setObject:self forKey:@"collection"];
    return query;
}

- (void)updateCallback:(MODQuery *)mongoQuery
{
    NSError *error;
    
    [mongoQuery ends];
    error = [mongoQuery.parameters objectForKey:@"error"];
    if ([_delegate respondsToSelector:@selector(mongoCollection:updateDonwWithMongoQuery:error:)]) {
        [_delegate mongoCollection:self updateDonwWithMongoQuery:mongoQuery error:error];
    }
}

//- (MODQuery *)updateWithQuery:(NSString *)jsonQuery fields:(NSString *)fields upset:(BOOL)upset
//{
//    MODQuery *query = nil;
//    
//    query = [_mongoDatabase.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
//        NSError *error;
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
//            error = [[NSString alloc] initWithUTF8String:e.what()];
//            [mongoQuery.mutableParameters setObject:error forKey:@"error"];
//            [error release];
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
//        NSError *error;
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
//            error = [[NSString alloc] initWithUTF8String:e.what()];
//            [mongoQuery.mutableParameters setObject:error forKey:@"error"];
//            [error release];
//        }
//        [self performSelectorOnMainThread:@selector(updateCallback:) withObject:mongoQuery waitUntilDone:NO];
//    }];
//    [query.mutableParameters setObject:jsonString forKey:@"jsonstring"];
//    [query.mutableParameters setObject:recordId forKey:@"recordid"];
//    [query.mutableParameters setObject:self forKey:@"collection"];
//    return query;
//}

@end
