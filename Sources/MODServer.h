//
//  MODServer.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MODQuery;
@class MODDatabase;
@class MODServer;

typedef struct mongo_replset            *mongo_replset_ptr;
typedef struct mongo                    *mongo_ptr;

@protocol MODServerDelegate<NSObject>
@optional
- (void)mongoServerConnectionSucceded:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery;
- (void)mongoServerConnectionFailed:(MODServer *)mongoServer withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoServer:(MODServer *)mongoServer serverStatusFetched:(NSArray *)serverStatus withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoServer:(MODServer *)mongoServer serverStatusDeltaFetched:(NSDictionary *)serverStatusDelta withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoServer:(MODServer *)mongoServer databaseListFetched:(NSArray *)list withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;

- (void)mongoServer:(MODServer *)mongoServer databaseDropedWithMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoServer:(MODServer *)mongoServer collectionCreatedWithMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoServer:(MODServer *)mongoServer collectionDropedWithMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
@end

@interface MODServer : NSObject
{
    mongo_replset_ptr                   _replicaSet;
    mongo_ptr                           _mongo;
    
    BOOL                                _connected;
    id<MODServerDelegate>               _delegate;
    NSOperationQueue                    *_operationQueue;
    NSString                            *_userName;
    NSString                            *_password;
}

- (MODQuery *)connectWithHostName:(NSString *)host;
- (MODQuery *)connectWithReplicaName:(NSString *)name hosts:(NSArray *)hosts;
- (MODQuery *)fetchServerStatus;
- (MODQuery *)fetchServerStatusDelta;
- (MODQuery *)fetchDatabaseList;

- (MODQuery *)dropDatabaseWithName:(NSString *)databaseName;

- (MODDatabase *)databaseForName:(NSString *)databaseName;

@property(nonatomic, readwrite, assign) id<MODServerDelegate> delegate;
@property(nonatomic, readonly, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readwrite, retain) NSString *userName;
@property(nonatomic, readwrite, retain) NSString *password;

@end
