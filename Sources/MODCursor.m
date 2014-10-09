//
//  MODCursor.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 11/09/2011.
//

#import "MongoObjCDriver-private.h"

@interface MODCursor ()

@property (nonatomic, strong, readwrite) MODCollection *mongoCollection;
@property (nonatomic, strong, readwrite) MODSortedMutableDictionary *query;
@property (nonatomic, strong, readwrite) NSArray *fields;
@property (nonatomic, assign, readwrite) uint32_t skip;
@property (nonatomic, assign, readwrite) uint32_t limit;
@property (nonatomic, assign, readwrite) uint32_t batchSize;
@property (nonatomic, strong, readwrite) MODSortedMutableDictionary * sort;
@property (nonatomic, assign, readwrite) mongoc_cursor_t *mongocCursor;
@property (nonatomic, strong, readwrite) NSError *internalError;

- (void)_createMongocCursor;

@end

@implementation MODCursor

@synthesize mongoCollection = _mongoCollection, query = _query, fields = _fields, skip = _skip, limit = _limit, sort = _sort, mongocCursor = _mongocCursor, tailable = _tailable, batchSize = _batchSize, internalError = _internalError;

- (instancetype)initWithMongoCollection:(MODCollection *)mongoCollection
{
    if (self = [self init]) {
        self.mongoCollection = mongoCollection;
    }
    return self;
}

- (instancetype)initWithMongoCollection:(MODCollection *)mongoCollection query:(MODSortedMutableDictionary *)query fields:(NSArray *)fields skip:(uint32_t)skip limit:(uint32_t)limit sort:(MODSortedMutableDictionary *)sort
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
    if (self.mongocCursor) {
        mongoc_cursor_destroy(self.mongocCursor);
        self.mongocCursor = nil;
    }
    self.internalError = nil;
    self.query = nil;
    self.fields = nil;
    self.sort = nil;
    self.mongoCollection = nil;
    [super dealloc];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock
{
    [self.mongoCollection mongoQueryDidFinish:mongoQuery withError:error callbackBlock:callbackBlock];
}

- (void)_createMongocCursor
{
    bson_t bsonQuery = BSON_INITIALIZER;
    bson_t bsonFields = BSON_INITIALIZER;
    NSAssert(self.mongocCursor == NULL, @"cursor already created");
    
    if (self.query && self.query.count > 0) {
        bson_t bsonQueryChild;
        
        bson_append_document_begin(&bsonQuery, "$query", -1, &bsonQueryChild);
        [MODClient appendObject:self.query toBson:&bsonQueryChild];
        bson_append_document_end(&bsonQuery, &bsonQueryChild);
    } else {
        bson_t bsonQueryChild;
        
        bson_append_document_begin(&bsonQuery, "$query", -1, &bsonQueryChild);
        bson_append_document_end(&bsonQuery, &bsonQueryChild);
    }
    if (self.internalError == nil) {
        if (self.sort && self.sort.count > 0) {
            bson_t bsonQueryChild;
            
            bson_append_document_begin(&bsonQuery, "$orderby", -1, &bsonQueryChild);
            [MODClient appendObject:self.sort toBson:&bsonQueryChild];
            bson_append_document_end(&bsonQuery, &bsonQueryChild);
        }
    }
    if (self.internalError == nil && self.fields.count > 0) {
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
    
    NSAssert(error != NULL, @"please give a pointer to get the error back");
    *error = nil;
    if ([self more]) {
        const bson_t *bson;
        
        if (bsonData) *bsonData = nil;
        if (self.error) {
            *error = self.error;
        } else if (mongoc_cursor_next(self.mongocCursor, &bson)) {
            result = [self.mongoCollection.client.class objectFromBson:bson];
            if (bsonData) {
                const bson_t *bson;
                
                bson = mongoc_cursor_current(self.mongocCursor);
                *bsonData = [[[NSData alloc] initWithBytes:bson_get_data(bson) length:bson->len] autorelease];
            }
        } else {
            bson_error_t error = BSON_NO_ERROR;
            
            mongoc_cursor_error(self.mongocCursor, &error);
            self.internalError = [self.mongoCollection.client.class errorFromBsonError:error];
        }
    }
    return result;
}

- (BOOL)more
{
    return mongoc_cursor_more(self.mongocCursor);
}

- (NSError *)error
{
    if (self.internalError) {
        return self.internalError;
    } else {
        bson_error_t error = BSON_NO_ERROR;
        
        mongoc_cursor_error(self.mongocCursor, &error);
        return [self.mongoCollection.client.class errorFromBsonError:error];
    }
}


- (MODQuery *)forEachDocumentWithCallbackDocumentCallback:(BOOL (^)(uint64_t index, MODSortedMutableDictionary *document))documentCallback endCallback:(void (^)(uint64_t documentCounts, BOOL cursorStopped, MODQuery *mongoQuery))endCallback
{
    MODQuery *query = nil;
    
    query = [self.mongoCollection.client addQueryInQueue:^(MODQuery *mongoQuery) {
        uint64_t documentCount = 0;
        BOOL cursorStopped = NO;
        NSError *error = nil;
        
        if (!mongoQuery.isCanceled) {
            MODSortedMutableDictionary *document;
            
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
            if (!mongoQuery.isCanceled && endCallback) {
                endCallback(documentCount, cursorStopped, mongoQuery);
            }
        }];
    } owner:self name:@"eachdocument" parameters:nil];
    return query;
}

@end
