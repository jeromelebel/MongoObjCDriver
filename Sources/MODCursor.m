//
//  MODCursor.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODCursor

@synthesize mongoCollection = _mongoCollection, query = _query, fields = _fields, skip = _skip, limit = _limit, sort = _sort, cursor = _cursor, donotReleaseCursor = _donotReleaseCursor, tailable = _tailable;

- (id)initWithMongoCollection:(MODCollection *)mongoCollection
{
    if (self = [self init]) {
        _mongoCollection = [mongoCollection retain];
    }
    return self;
}

- (void)dealloc
{
    if (_cursor && !_donotReleaseCursor) {
        mongo_cursor_destroy(_cursor);
        free(_cursor);
    }
    if (_bsonQuery) {
        bson_destroy(_bsonQuery);
        free(_bsonQuery);
    }
    if (_bsonFields) {
        bson_destroy(_bsonFields);
        free(_bsonFields);
    }
    [_query release];
    [_fields release];
    [_sort release];
    [_mongoCollection release];
    [super dealloc];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withCallbackBlock:(void (^)(void))callbackBlock
{
    [mongoQuery.mutableParameters setObject:self forKey:@"cursor"];
    [_mongoCollection mongoQueryDidFinish:mongoQuery withCallbackBlock:callbackBlock];
}

- (BOOL)_startCursorWithError:(NSError **)error
{
    int options = MONGO_AWAIT_DATA;
    NSAssert(error != NULL, @"please give a pointer to get the error back");
    NSAssert(_cursor == NULL, @"cursor already created");
    
    *error = nil;
    _cursor = malloc(sizeof(mongo_cursor));
    mongo_cursor_init(_cursor, _mongoCollection.mongo, [_mongoCollection.absoluteCollectionName UTF8String]);
    _bsonQuery = malloc(sizeof(bson));
    bson_init(_bsonQuery);
    
    bson_append_start_object(_bsonQuery, "$query");
    if (_query && [_query  length] > 0) {
        [MODJsonToBsonParser bsonFromJson:_bsonQuery json:_query error:error];
    }
    bson_append_finish_object(_bsonQuery);
    if (*error == nil) {
        if ([_sort length] > 0) {
            bson_append_start_object(_bsonQuery, "$orderby");
            if (_sort) {
                [MODJsonToBsonParser bsonFromJson:_bsonQuery json:_sort error:error];
            }
            bson_append_finish_object(_bsonQuery);
        }
    }
    bson_finish(_bsonQuery);
    mongo_cursor_set_query(_cursor, _bsonQuery);
    if ([_fields count] > 0 && *error == nil) {
        NSUInteger index = 0;
        char indexString[128];
        
        _bsonFields = malloc(sizeof(bson));
        bson_init(_bsonFields);
        for (NSString *field in _fields) {
            snprintf(indexString, sizeof(indexString), "%lu", (unsigned long)index);
            bson_append_string(_bsonFields, [field UTF8String], indexString);
        }
        bson_finish(_bsonFields);
        mongo_cursor_set_fields(_cursor, _bsonFields);
    }
    mongo_cursor_set_skip(_cursor, _skip);
    mongo_cursor_set_limit(_cursor, _limit);
    if (_tailable) {
        options |= MONGO_TAILABLE;
    }
    mongo_cursor_set_options(_cursor, options);
    
    return *error == nil;
}

- (NSDictionary *)nextDocumentAsynchronouslyWithError:(NSError **)error;
{
    NSDictionary *result = nil;
    
    NSAssert(error != NULL, @"please give a pointer to get the error back");
    *error = nil;
    if (!_cursor) {
        [self _startCursorWithError:error];
        if (*error == nil) {
            [_mongoCollection.mongoDatabase authenticateSynchronouslyWithError:error];
        }
    }
    if (!*error) {
        if (mongo_cursor_next(_cursor) == MONGO_OK) {
            result = [[_mongoCollection.mongoServer class] objectFromBson:&(((mongo_cursor *)_cursor)->current)];
        } else if (((mongo_cursor *)_cursor)->err != MONGO_CURSOR_EXHAUSTED) {
            NSString *details = nil;
            
            if (_mongoCollection.mongoServer.mongo->lasterrstr) {
                details = [[NSString alloc] initWithUTF8String:_mongoCollection.mongoServer.mongo->lasterrstr];
            }
            *error = [[_mongoCollection.mongoServer class] errorWithErrorDomain:MODMongoCursorErrorDomain code:((mongo_cursor *)_cursor)->err descriptionDetails:details];
            [details release];
        }
    }
    return result;
}

- (MODQuery *)forEachDocumentWithCallbackDocumentCallback:(BOOL (^)(uint64_t index, NSDictionary *document))documentCallback endCallback:(void (^)(uint64_t documentCounts, BOOL cursorStopped, MODQuery *mongoQuery))endCallback
{
    MODQuery *query = nil;
    
    query = [_mongoCollection.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        uint64_t documentCount = 0;
        BOOL cursorStopped = NO;
        
        if (!mongoQuery.canceled) {
            NSDictionary *document;
            NSError *error;
            
            [mongoQuery.mutableParameters setObject:self forKey:@"cursor"];
            while (!cursorStopped) {
                documentCount++;
                document = [self nextDocumentAsynchronouslyWithError:&error];
                mongoQuery.error = error;
                if (!document) {
                    break;
                }
                if (documentCallback) {
                    BOOL *cursorStoppedPtr = &cursorStopped;
                    
                    dispatch_sync(dispatch_get_main_queue(), ^(void) {
                        *cursorStoppedPtr = !documentCallback(documentCount, document);
                    });
                }
            };
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            if (endCallback) {
                endCallback(documentCount, cursorStopped, mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"eachdocument" forKey:@"command"];
    return query;
}

@end
