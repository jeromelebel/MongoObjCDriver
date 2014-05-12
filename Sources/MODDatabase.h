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
@class MODSortedMutableDictionary;

@interface MODDatabase : NSObject
{
    MODServer                           *_mongoServer;
    NSString                            *_name;
    void                                *_mongocDatabase;
}
@property(nonatomic, readonly, retain) MODServer *mongoServer;
@property(nonatomic, readonly, copy) NSString *name;

- (MODQuery *)fetchDatabaseStatsWithCallback:(void (^)(MODSortedMutableDictionary *databaseStats, MODQuery *mongoQuery))callback;
- (MODQuery *)fetchCollectionListWithCallback:(void (^)(NSArray *collectionList, MODQuery *mongoQuery))callback;

- (MODQuery *)createCollectionWithName:(NSString *)collectionName callback:(void (^)(MODQuery *mongoQuery))callback;
//- (MODQuery *)createCappedCollectionWithName:(NSString *)collectionName capSize:(int64_t)capSize callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)dropWithCallback:(void (^)(MODQuery *mongoQuery))callback;

- (MODCollection *)collectionForName:(NSString *)name;

@end
