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

enum {
    JSON_PARSER_ERROR_EXPECTED_END
};

@interface MODServer()
@property(nonatomic, readwrite, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readwrite, assign) mongoc_client_t *mongocClient;

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock;
- (MODQuery *)addQueryInQueue:(void (^)(MODQuery *currentMongoQuery))block;
@end

@interface MODServer(utils_internal)
+ (NSError *)errorWithErrorDomain:(NSString *)errorDomain code:(NSInteger)code descriptionDetails:(NSString *)descriptionDetails;
+ (NSError *)errorFromBsonError:(bson_error_t)error;
//+ (NSError *)errorFromMongo:(mongoc_client_t *)mongo;
+ (MODSortedMutableDictionary *)objectFromBson:(bson_t *)bsonObject;
+ (void)appendObject:(MODSortedMutableDictionary *)object toBson:(bson_t *)bson;
@end

@interface MODDatabase()
@property(nonatomic, readonly, assign) mongoc_client_t *mongocClient;
@property(nonatomic, readwrite, assign) mongoc_database_t *mongocDatabase;

- (id)initWithMongoServer:(MODServer *)mongoServer name:(NSString *)databaseName;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock;
@end

@interface MODCollection()
@property(nonatomic, readonly, assign) mongoc_client_t *mongocClient;

- (id)initWithMongoDatabase:(MODDatabase *)mongoDatabase collectionName:(NSString *)collectionName;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock;
@end

@interface MODCursor()
@property(nonatomic, readwrite, retain) NSString *query;
@property(nonatomic, readwrite, retain) NSArray *fields;
@property(nonatomic, readwrite, assign) int32_t skip;
@property(nonatomic, readwrite, assign) int32_t limit;
@property(nonatomic, readwrite, retain) NSString * sort;
@property(nonatomic, readwrite, assign) void *cursor;
@property(nonatomic, readwrite, assign) BOOL donotReleaseCursor;

- (id)initWithMongoCollection:(MODCollection *)mongoCollection;
//- (MODSortedMutableDictionary *)nextDocumentWithBsonData:(NSData **)bsonData error:(NSError **)error;
@end

@interface MODQuery()
- (void)starts;
- (void)ends;
- (void)removeBlockOperation;

@property (nonatomic, readwrite, retain) NSDictionary *parameters;
@property (nonatomic, readwrite, retain) NSMutableDictionary *mutableParameters;
@property (nonatomic, readwrite, assign) NSBlockOperation *blockOperation;
@property (nonatomic, readwrite, retain) NSError *error;
@end

@interface MODObjectId()
- (id)initWithOid:(const bson_oid_t *)oid;
- (const bson_oid_t *)bsonObjectId;
@end

@interface MODTimestamp()
@end

@interface MODRagelJsonParser (private)
+ (void)bsonFromJson:(bson_t *)bsonResult json:(NSString *)json error:(NSError **)error;
@end

@interface MODBsonComparator (Private)
- (id)initWithBson1:(bson_t *)bson1 bson2:(bson_t *)bson2;
@end
