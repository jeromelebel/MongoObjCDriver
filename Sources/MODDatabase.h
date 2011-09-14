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

@interface MODDatabase : NSObject
{
    MODServer                   *_mongoServer;
    NSString                    *_databaseName;
    NSString                    *_userName;
    NSString                    *_password;
}

- (MODQuery *)fetchDatabaseStatsWithCallback:(void (^)(NSDictionary *databaseStats, MODQuery *mongoQuery))callback;
- (MODQuery *)fetchCollectionListWithCallback:(void (^)(NSArray *collectionList, MODQuery *mongoQuery))callback;

- (MODQuery *)createCollectionWithName:(NSString *)collectionName callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)dropCollectionWithName:(NSString *)collectionName callback:(void (^)(MODQuery *mongoQuery))callback;

- (MODCollection *)collectionForName:(NSString *)name;

@property(nonatomic, readonly, retain) MODServer *mongoServer;
@property(nonatomic, readonly, retain) NSString *databaseName;
@property(nonatomic, readwrite, retain) NSString *userName;
@property(nonatomic, readwrite, retain) NSString *password;

@end
