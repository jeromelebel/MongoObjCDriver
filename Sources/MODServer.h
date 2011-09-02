//
//  MODServer.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

@class MODQuery;
@class MODServer;

typedef struct mongo_replset            *mongo_replset_ptr;
typedef struct mongo                    *mongo_ptr;

@protocol MODServerDelegate<NSObject>
@optional
- (void)mongoDBConnectionSucceded:(MODServer *)mongoDB withMongoQuery:(MODQuery *)mongoQuery;
- (void)mongoDBConnectionFailed:(MODServer *)mongoDB withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MODServer *)mongoDB databaseListFetched:(NSArray *)list withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MODServer *)mongoDB serverStatusFetched:(NSArray *)serverStatus withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MODServer *)mongoDB serverStatusDeltaFetched:(NSDictionary *)serverStatusDelta withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MODServer *)mongoDB collectionListFetched:(NSArray *)collectionList withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MODServer *)mongoDB databaseStatsFetched:(NSArray *)databaseStats withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MODServer *)mongoDB collectionStatsFetched:(NSArray *)databaseStats withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;

- (void)mongoDB:(MODServer *)mongoDB databaseDropedWithMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MODServer *)mongoDB collectionCreatedWithMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoDB:(MODServer *)mongoDB collectionDropedWithMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
@end

@interface MODServer : NSObject
{
    mongo_replset_ptr                   _replicaSet;
    mongo_ptr                           _mongo;
    
    BOOL                                _connected;
    id<MODServerDelegate>               _delegate;
    NSOperationQueue                    *_operationQueue;
}

- (MODQuery *)connectWithHostName:(NSString *)host databaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password;
- (MODQuery *)connectWithReplicaName:(NSString *)name hosts:(NSArray *)hosts databaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password;
- (MODQuery *)fetchDatabaseList;

@property(nonatomic, readwrite, assign) id<MODServerDelegate> delegate;
@property(nonatomic, readonly, assign, getter=isConnected) BOOL connected;

@end
