//
//  MODServer.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MODMongoErrorDomain @"mod.mongo"
#define MODJsonErrorDomain @"mod.json"
#define MODJsonParserErrorDomain @"mod.jsonparser"

enum {
    JSON_PARSER_ERROR_EXPECTED_END
};

@class MODQuery;
@class MODDatabase;
@class MODServer;

typedef struct mongo_replset            *mongo_replset_ptr;
typedef struct mongo                    *mongo_ptr;

@interface MODServer : NSObject
{
    mongo_replset_ptr                   _replicaSet;
    mongo_ptr                           _mongo;
    
    BOOL                                _connected;
    NSOperationQueue                    *_operationQueue;
    NSString                            *_userName;
    NSString                            *_password;
}

- (void)copyWithCallback:(void (^)(MODServer *copyServer, MODQuery *mongoQuery))callback;

- (MODQuery *)connectWithHostName:(NSString *)host callback:(void (^)(BOOL connected, MODQuery *mongoQuery))callback;
- (MODQuery *)connectWithReplicaName:(NSString *)name hosts:(NSArray *)hosts callback:(void (^)(BOOL connected, MODQuery *mongoQuery))callback;
- (MODQuery *)fetchServerStatusWithCallback:(void (^)(NSDictionary *serverStatus, MODQuery *mongoQuery))callback;
- (MODQuery *)fetchDatabaseListWithCallback:(void (^)(NSArray *list, MODQuery *mongoQuery))callback;

- (MODQuery *)dropDatabaseWithName:(NSString *)databaseName callback:(void (^)(MODQuery *mongoQuery))callback;

- (MODDatabase *)databaseForName:(NSString *)databaseName;

@property(nonatomic, readonly, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readwrite, retain) NSString *userName;
@property(nonatomic, readwrite, retain) NSString *password;

@end
