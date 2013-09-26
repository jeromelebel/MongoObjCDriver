//
//  MODServer.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MODMongoErrorDomain @"mod.mongo"
#define MODMongoCursorErrorDomain @"mod.mongocursor"
#define MODJsonErrorDomain @"mod.json"
#define MODJsonParserErrorDomain @"mod.jsonparser"

@class MODQuery;
@class MODDatabase;
@class MODServer;
@class MODSortedMutableDictionary;

typedef struct mongo_replset            *mongo_replset_ptr;
typedef struct mongo                    *mongo_ptr;

@interface MODServer : NSObject
{
    mongo_replset_ptr                   _replicaSet;
    mongo_ptr                           _mongo;
    
    BOOL                                _connected;
    NSOperationQueue                    *_operationQueue;
    NSString                            *_authDatabase;
    NSString                            *_userName;
    NSString                            *_password;
}

- (void)copyWithCallback:(void (^)(MODServer *copyServer, MODQuery *mongoQuery))callback;

- (MODQuery *)connectWithHostName:(NSString *)host callback:(void (^)(BOOL connected, MODQuery *mongoQuery))callback;
- (MODQuery *)connectWithReplicaName:(NSString *)name hosts:(NSArray *)hosts callback:(void (^)(BOOL connected, MODQuery *mongoQuery))callback;
- (MODQuery *)fetchServerStatusWithCallback:(void (^)(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery))callback;
- (MODQuery *)fetchDatabaseListWithCallback:(void (^)(NSArray *list, MODQuery *mongoQuery))callback;

- (MODQuery *)dropDatabaseWithName:(NSString *)databaseName callback:(void (^)(MODQuery *mongoQuery))callback;

- (MODDatabase *)databaseForName:(NSString *)databaseName;

@property(nonatomic, readonly, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readwrite, retain) NSString *userName;
@property(nonatomic, readwrite, retain) NSString *password;
@property(nonatomic, readwrite, retain) NSString *authDatabase;

@end

@interface MODServer(utils)
+ (NSString *)escapeQuotesForString:(NSString *)string;
+ (NSString *)escapeSlashesForString:(NSString *)string;
+ (NSString *)convertObjectToJson:(MODSortedMutableDictionary *)object pretty:(BOOL)pretty strictJson:(BOOL)strictJson;
+ (void)compareJson:(NSString *)json document:(id)document;
+ (NSArray *)findAllDifferencesInObject1:(id)object1 object2:(id)object2;
@end