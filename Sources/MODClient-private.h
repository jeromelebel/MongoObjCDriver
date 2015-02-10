//
//  MODClient-private.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 08/10/2014.
//
//

#import "MongoObjCDriver-private.h"


@interface MODClient ()

@property (nonatomic, readwrite, assign, getter=isConnected) BOOL connected;
@property (nonatomic, readwrite, assign) mongoc_client_t *mongocClient;
@property (nonatomic, readonly, assign) mongoc_read_prefs_t *mongocReadPreferences;

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock;
- (MODQuery *)addQueryInQueue:(void (^)(MODQuery *currentMongoQuery))block owner:(id<NSObject>)owner name:(NSString *)name parameters:(NSDictionary *)parameters;

@end

@interface MODClient (utils_internal)
+ (NSError *)errorWithErrorDomain:(NSString *)errorDomain code:(NSInteger)code descriptionDetails:(NSString *)descriptionDetails;
+ (NSError *)errorFromBsonError:(bson_error_t)error;
//+ (NSError *)errorFromMongo:(mongoc_client_t *)mongo;
+ (MODSortedDictionary *)objectFromBson:(const bson_t *)bsonObject;
+ (void)appendObject:(MODSortedDictionary *)object toBson:(bson_t *)bson;
+ (void)appendArray:(NSArray *)array toBson:(bson_t *)bson;

@end
