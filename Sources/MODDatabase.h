//
//  MODDatabase.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 03/09/2011.
//

#import <Foundation/Foundation.h>

@class MODClient;
@class MODDatabase;
@class MODCollection;
@class MODQuery;
@class MODSortedDictionary;

#define MODDatabase_Dropped_Notification        @"MODDatabase_Dropped_Notification"

@interface MODDatabase : NSObject

@property (nonatomic, strong, readonly) MODClient *client;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, strong, readonly) MODCollection *systemIndexesCollection;
@property (nonatomic, strong, readwrite) MODReadPreferences *readPreferences;
@property (nonatomic, assign, readonly) BOOL dropped;

- (MODQuery *)statsWithReadPreferences:(MODReadPreferences *)readPreferences callback:(void (^)(MODSortedDictionary *databaseStats, MODQuery *mongoQuery))callback;
- (MODQuery *)collectionNamesWithCallback:(void (^)(NSArray *collectionList, MODQuery *mongoQuery))callback;

- (MODQuery *)createCollectionWithName:(NSString *)collectionName callback:(void (^)(MODQuery *mongoQuery))callback;
//- (MODQuery *)createCappedCollectionWithName:(NSString *)collectionName capSize:(int64_t)capSize callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)dropWithCallback:(void (^)(MODQuery *mongoQuery))callback;

- (MODCollection *)collectionForName:(NSString *)name;

@end
