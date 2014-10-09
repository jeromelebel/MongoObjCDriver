//
//  MODDatabase-private.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 08/10/2014.
//
//

#import "MongoObjCDriver-private.h"

@interface MODDatabase ()
@property (nonatomic, assign, readonly) mongoc_client_t *mongocClient;
@property (nonatomic, assign, readwrite) mongoc_database_t *mongocDatabase;
@property (nonatomic, assign, readonly) mongoc_read_prefs_t *mongocReadPreferences;

- (instancetype)initWithClient:(MODClient *)client name:(NSString *)databaseName;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withBsonError:(bson_error_t)error callbackBlock:(void (^)(void))callbackBlock;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withError:(NSError *)error callbackBlock:(void (^)(void))callbackBlock;

@end
