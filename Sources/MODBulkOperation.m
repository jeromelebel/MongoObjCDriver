//
//  MODBulkOperation.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 17/10/2014.
//
//

#import "MongoObjCDriver-private.h"

@interface MODBulkOperation ()
@property (nonatomic, assign, readwrite) BOOL ordered;
@property (nonatomic, assign, readwrite) mongoc_bulk_operation_t *mongocBulkOperation;

@end

@implementation MODBulkOperation

- (instancetype)initWithCollection:(MODCollection *)collection ordered:(BOOL)ordered writeConcern:(MODWriteConcern *)writeConcern
{
    if (self = [self init]) {
        self.collection = collection;
        self.ordered = ordered;
        self.writeConcern = writeConcern;
        self.mongocBulkOperation = mongoc_collection_create_bulk_operation(self.collection.mongocCollection, self.ordered, self.writeConcern.mongocWriteConcern);
    }
    return self;
}

- (void)dealloc
{
    self.collection = nil;
    self.writeConcern = nil;
    mongoc_bulk_operation_destroy(self.mongocBulkOperation);
    MOD_SUPER_DEALLOC();
}

- (void)insert:(MODSortedDictionary *)document
{
    bson_t bson = BSON_INITIALIZER;
    
    [MODClient appendObject:document toBson:&bson];
    mongoc_bulk_operation_insert(self.mongocBulkOperation, &bson);
    bson_destroy(&bson);
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock
{
    [self.client mongoQueryDidFinish:mongoQuery withBsonError:error callbackBlock:callbackBlock];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock
{
    [self.client mongoQueryDidFinish:mongoQuery withError:error callbackBlock:callbackBlock];
}

- (MODQuery *)executeWithCallback:(void (^)(MODQuery *mongoQuery, MODSortedDictionary *result))callback
{
    MODQuery *query;
    
    NSParameterAssert(self.collection);
    query = [self.client addQueryInQueue:^(MODQuery *mongoQuery) {
        bson_t reply = BSON_INITIALIZER;
        bson_error_t bsonError = BSON_NO_ERROR;
        MODSortedDictionary *result = nil;
        
        if (!mongoQuery.isCanceled) {
            mongoc_bulk_operation_execute(self.mongocBulkOperation, &reply, &bsonError);
            result = [self.client.class objectFromBson:&reply];
            bson_destroy(&reply);
        }
        [self mongoQueryDidFinish:mongoQuery withBsonError:bsonError callbackBlock:^(void) {
            if (!mongoQuery.isCanceled && callback) {
                callback(mongoQuery, result);
            }
        }];
    } owner:self name:@"execute" parameters:@{}];
    return query;
}

- (MODClient *)client
{
    return self.collection.client;
}
             
@end
