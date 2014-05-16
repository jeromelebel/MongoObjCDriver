//
//  MODCursor.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@interface MODCursor ()

@property (nonatomic, readwrite, retain) MODCollection *mongoCollection;
@property (nonatomic, readwrite, retain) NSString *query;
@property (nonatomic, readwrite, retain) NSArray *fields;
@property (nonatomic, readwrite, assign) uint32_t skip;
@property (nonatomic, readwrite, assign) uint32_t limit;
@property (nonatomic, readwrite, assign) uint32_t batchSize;
@property (nonatomic, readwrite, retain) NSString * sort;
@property (nonatomic, readwrite, assign) mongoc_cursor_t *mongocCursor;
@property (nonatomic, readwrite, strong) NSError *error;

- (void)_createMongocCursor;

@end

@implementation MODCursor

@synthesize mongoCollection = _mongoCollection, query = _query, fields = _fields, skip = _skip, limit = _limit, sort = _sort, mongocCursor = _mongocCursor, tailable = _tailable, batchSize = _batchSize, error = _error;

- (id)initWithMongoCollection:(MODCollection *)mongoCollection
{
    if (self = [self init]) {
        self.mongoCollection = mongoCollection;
    }
    return self;
}

- (id)initWithMongoCollection:(MODCollection *)mongoCollection query:(NSString *)query fields:(NSArray *)fields skip:(uint32_t)skip limit:(uint32_t)limit sort:(NSString *)sort
{
    if (self = [self initWithMongoCollection:mongoCollection]) {
        self.query = query;
        self.fields = fields;
        self.skip = skip;
        self.limit = limit;
        self.sort = sort;
        [self _createMongocCursor];
    }
    return self;
}

- (void)dealloc
{
    self.error = nil;
    self.query = nil;
    self.fields = nil;
    self.sort = nil;
    self.mongoCollection = nil;
    [super dealloc];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock
{
    [mongoQuery.mutableParameters setObject:self forKey:@"cursor"];
    [self.mongoCollection mongoQueryDidFinish:mongoQuery withError:error callbackBlock:callbackBlock];
}

- (void)_createMongocCursor
{
    bson_t bsonQuery = BSON_INITIALIZER;
    bson_t bsonFields = BSON_INITIALIZER;
    NSAssert(self.mongocCursor == NULL, @"cursor already created");
    
    if (self.query && self.query.length > 0) {
        NSError *error;
        bson_t bsonQueryChild;
        
        bson_append_document_begin(&bsonQuery, "$query", -1, &bsonQueryChild);
        [MODRagelJsonParser bsonFromJson:&bsonQueryChild json:self.query error:&error];
        bson_append_document_end(&bsonQuery, &bsonQueryChild);
        self.error = error;
    }
    if (self.error == nil) {
        if (self.sort && self.sort.length > 0) {
            NSError *error;
            bson_t bsonQueryChild;
            
            bson_append_document_begin(&bsonQuery, "$orderby", -1, &bsonQueryChild);
            [MODRagelJsonParser bsonFromJson:&bsonQueryChild json:_sort error:&error];
            bson_append_document_end(&bsonQuery, &bsonQueryChild);
            self.error = error;
        }
    }
    if (self.error == nil && self.fields.count > 0) {
        for (NSString *field in self.fields) {
            bson_append_bool(&bsonFields, field.UTF8String, -1, 1);
        }
    }
    self.mongocCursor = mongoc_collection_find(self.mongoCollection.mongocCollection, MONGOC_QUERY_NONE, self.skip, self.limit, self.batchSize, &bsonQuery, &bsonFields, NULL);
    bson_destroy(&bsonQuery);
    bson_destroy(&bsonFields);
}

- (MODSortedMutableDictionary *)nextDocumentWithBsonData:(NSData **)bsonData error:(NSError **)error;
{
    MODSortedMutableDictionary *result = nil;
    const bson_t *bson;
    
    NSAssert(error != NULL, @"please give a pointer to get the error back");
    *error = nil;
    if (bsonData) *bsonData = nil;
    if (self.error) {
        *error = self.error;
    } else if (mongoc_cursor_next(self.mongocCursor, &bson)) {
        result = [[self.mongoCollection.mongoServer class] objectFromBson:bson];
        if (bsonData) {
            const bson_t *bson;
            
            bson = mongoc_cursor_current(self.mongocCursor);
            *bsonData = [[[NSData alloc] initWithBytes:bson_get_data(bson) length:bson->len] autorelease];
        }
    } else {
        bson_error_t error = BSON_NO_ERROR;
        
        mongoc_cursor_error(self.mongocCursor, &error);
        self.error = [self.mongoCollection.mongoServer.class errorFromBsonError:error];
    }
    return result;
}

- (MODQuery *)forEachDocumentWithCallbackDocumentCallback:(BOOL (^)(uint64_t index, MODSortedMutableDictionary *document))documentCallback endCallback:(void (^)(uint64_t documentCounts, BOOL cursorStopped, MODQuery *mongoQuery))endCallback
{
    MODQuery *query = nil;
    
    query = [self.mongoCollection.mongoServer addQueryInQueue:^(MODQuery *mongoQuery) {
        uint64_t documentCount = 0;
        BOOL cursorStopped = NO;
        NSError *error = nil;
        
        if (!mongoQuery.canceled) {
            MODSortedMutableDictionary *document;
            
            [mongoQuery.mutableParameters setObject:self forKey:@"cursor"];
            while (!cursorStopped) {
                documentCount++;
                document = [self nextDocumentWithBsonData:nil error:&error];
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
        [self mongoQueryDidFinish:mongoQuery withError:error callbackBlock:^(void) {
            if (endCallback) {
                endCallback(documentCount, cursorStopped, mongoQuery);
            }
        }];
    }];
    [query.mutableParameters setObject:@"eachdocument" forKey:@"command"];
    return query;
}

@end
