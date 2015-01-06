//
//  MongoObjCDriver-private.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 02/09/2011.
//

#import <Foundation/Foundation.h>
#import "MongoObjCDriver.h"
#import "NSString+MODBase64.h"
#import "NSData+MODBase64.h"
#import "mongoc.h"
#import "MODReadPreferences-private.h"
#import "MODWriteConcern-private.h"
#import "MODClient-private.h"
#import "MODDatabase-private.h"
#import "MODCursor-private.h"
#import "MODDBPointer.h"
#import "MODSortedDictionary-private.h"
#import "MODIndex-private.h"
#import "MODRagelJsonParser-private.h"

#define BSON_NO_ERROR { 0, 0, 0 }

enum {
    JSON_PARSER_ERROR_EXPECTED_END
};

@interface MODCollection ()
@property (nonatomic, readonly, assign) mongoc_client_t *mongocClient;
@property (nonatomic, readwrite, assign) mongoc_collection_t *mongocCollection;
@property (nonatomic, readonly, assign) mongoc_read_prefs_t *mongocReadPreferences;

- (instancetype)initWithName:(NSString *)name database:(MODDatabase *)database;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock;

@end

@interface MODQuery ()
@property (nonatomic, readwrite, assign) NSBlockOperation *blockOperation;
@property (nonatomic, readwrite, strong) NSError *error;
@property (nonatomic, readwrite, strong) id result;
@property (nonatomic, readwrite, strong) NSDate *startDate;
@property (nonatomic, readwrite, strong) NSDate *endDate;

- (void)starts;
- (void)endsWithError:(NSError *)error;
- (void)removeBlockOperation;

@end

@interface MODObjectId ()
- (instancetype)initWithOid:(const bson_oid_t *)oid;
- (const bson_oid_t *)bsonObjectId;

@end

@interface MODTimestamp ()
@end

@interface MODBsonComparator (private)
- (instancetype)initWithBson1:(bson_t *)bson1 bson2:(bson_t *)bson2;

@end

@interface MODSSLOptions (private)
+ (instancetype)sslOptionsWithMongocSSLOpt:(const mongoc_ssl_opt_t *)sslOpt;
- (void)getMongocSSLOpt:(mongoc_ssl_opt_t *)sslOpt;
@end

