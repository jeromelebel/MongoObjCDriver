//
//  MOD_internal.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOD_public.h"
#import "mongoc.h"

#define BSON_NO_ERROR { 0, 0, 0 }

enum {
    JSON_PARSER_ERROR_EXPECTED_END
};

@interface MODServer ()
@property (nonatomic, readwrite, assign, getter=isConnected) BOOL connected;
@property (nonatomic, readwrite, assign) mongoc_client_t *mongocClient;

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock;
- (MODQuery *)addQueryInQueue:(void (^)(MODQuery *currentMongoQuery))block;

@end

@interface MODServer (utils_internal)
+ (NSError *)errorFromBsonError:(bson_error_t)error;
//+ (NSError *)errorFromMongo:(mongoc_client_t *)mongo;
+ (MODSortedMutableDictionary *)objectFromBson:(const bson_t *)bsonObject;
+ (void)appendObject:(MODSortedMutableDictionary *)object toBson:(bson_t *)bson;

@end

@interface MODDatabase ()
@property (nonatomic, readonly, assign) mongoc_client_t *mongocClient;
@property (nonatomic, readwrite, assign) mongoc_database_t *mongocDatabase;

- (id)initWithMongoServer:(MODServer *)mongoServer name:(NSString *)databaseName;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock;

@end

@interface MODCollection ()
@property (nonatomic, readonly, assign) mongoc_client_t *mongocClient;
@property (nonatomic, readwrite, assign) mongoc_collection_t *mongocCollection;

- (id)initWithName:(NSString *)name mongoDatabase:(MODDatabase *)mongoDatabase;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock;

@end

@interface MODCursor ()
- (id)initWithMongoCollection:(MODCollection *)mongoCollection query:(NSString *)query fields:(NSArray *)fields skip:(uint32_t)skip limit:(uint32_t)limit sort:(NSString *)sort;
- (MODSortedMutableDictionary *)nextDocumentWithBsonData:(NSData **)bsonData error:(NSError **)error;

@end

@interface MODQuery ()
@property (nonatomic, readwrite, retain) NSDictionary *parameters;
@property (nonatomic, readwrite, retain) NSMutableDictionary *mutableParameters;
@property (nonatomic, readwrite, assign) NSBlockOperation *blockOperation;
@property (nonatomic, readwrite, retain) NSError *error;

- (void)starts;
- (void)ends;
- (void)removeBlockOperation;

@end

@interface MODObjectId ()
- (id)initWithOid:(const bson_oid_t *)oid;
- (const bson_oid_t *)bsonObjectId;

@end

@interface MODTimestamp ()
@end

@interface MODRagelJsonParser (private)
+ (void)bsonFromJson:(bson_t *)bsonResult json:(NSString *)json error:(NSError **)error;

@end

@interface MODBsonComparator (private)
- (id)initWithBson1:(bson_t *)bson1 bson2:(bson_t *)bson2;

@end
