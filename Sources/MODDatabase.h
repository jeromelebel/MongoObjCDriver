//
//  MODDatabase.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MODServer;
@class MODDatabase;
@class MODCollection;
@class MODQuery;

@protocol MODDatabaseDelegate<NSObject>
@optional
- (void)mongoDatabase:(MODDatabase *)mongoDatabase databaseStatsFetched:(NSArray *)databaseStats withMongoQuery:(MODQuery *)mongoQuery;
- (void)mongoDatabase:(MODDatabase *)mongoDatabase collectionListFetched:(NSArray *)collectionList withMongoQuery:(MODQuery *)mongoQuery;
- (void)mongoDatabase:(MODDatabase *)mongoDatabase collectionStatsFetched:(NSArray *)databaseStats withMongoQuery:(MODQuery *)mongoQuery;

- (void)mongoDatabase:(MODDatabase *)mongoDatabase collectionCreatedWithMongoQuery:(MODQuery *)mongoQuery;
- (void)mongoDatabase:(MODDatabase *)mongoDatabase collectionDropedWithMongoQuery:(MODQuery *)mongoQuery;
@end

@interface MODDatabase : NSObject
{
    id<MODDatabaseDelegate>     _delegate;
    MODServer                   *_mongoServer;
    NSString                    *_databaseName;
    NSString                    *_userName;
    NSString                    *_password;
}

- (MODQuery *)fetchDatabaseStats;
- (MODQuery *)fetchCollectionList;

- (MODQuery *)createCollectionWithName:(NSString *)collectionName;
- (MODQuery *)dropCollectionWithName:(NSString *)name;

- (MODCollection *)collectionForName:(NSString *)name;

@property(nonatomic, readwrite, assign) id<MODDatabaseDelegate> delegate;
@property(nonatomic, readonly, retain) MODServer *mongoServer;
@property(nonatomic, readonly, retain) NSString *databaseName;
@property(nonatomic, readwrite, retain) NSString *userName;
@property(nonatomic, readwrite, retain) NSString *password;

@end
