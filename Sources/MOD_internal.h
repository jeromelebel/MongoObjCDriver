//
//  MOD_internal.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOD_public.h"
#import "mongo.h"
#import "json.h"

@interface MODServer()

@property(nonatomic, readwrite, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readwrite, assign) mongo_ptr mongo;

- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password mongoQuery:(MODQuery *)mongoQuery;
- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password error:(NSError **)error;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withTarget:(id)target callback:(SEL)callbackSelector;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withCallbackBlock:(void (^)(void))callbackBlock;
- (MODQuery *)addQueryInQueue:(void (^)(MODQuery *currentMongoQuery))block;

@end

@interface MODServer(utils)

+ (NSError *)errorWithErrorDomain:(NSString *)errorDomain code:(NSInteger)code descriptionDetails:(NSString *)descriptionDetails;
+ (NSError *)errorFromMongo:(mongo_ptr)mongo;
+ (NSDictionary *)objectFromBson:(bson *)bsonObject;
+ (void)appendObject:(NSDictionary *)object toBson:(bson *)bson;

@end

@interface MODDatabase()

@property(nonatomic, readonly, assign) mongo_ptr mongo;

- (id)initWithMongoServer:(MODServer *)mongoServer databaseName:(NSString *)databaseName;
- (BOOL)authenticateSynchronouslyWithMongoQuery:(MODQuery *)mongoQuery;
- (BOOL)authenticateSynchronouslyWithError:(NSError **)error;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withCallbackBlock:(void (^)(void))callbackBlock;

@end

@interface MODCollection()

@property(nonatomic, readonly, assign) mongo_ptr mongo;

- (id)initWithMongoDatabase:(MODDatabase *)mongoDatabase collectionName:(NSString *)collectionName;

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
- (NSDictionary *)nextDocumentAsynchronouslyWithError:(NSError **)error;
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
- (id)initWithOid:(bson_oid_t *)oid;
- (bson_oid_t *)bsonObjectId;
@end

@interface MODTimestamp()
- (void)getBsonTimestamp:(bson_timestamp_t *)ts;
@end

@interface MODJsonToBsonParser : MODJsonParser<MODJsonParserProtocol>
{
    bson *_bson;
}
+ (NSInteger)bsonFromJson:(bson *)bsonResult json:(NSString *)json error:(NSError **)error;
- (void)setBson:(bson *)bson;
@end
