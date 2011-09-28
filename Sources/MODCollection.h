//
//  MODCollection.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 03/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MODDatabase;
@class MODCollection;
@class MODQuery;
@class MODCursor;

@interface MODCollection : NSObject
{
    MODDatabase                         *_mongoDatabase;
    NSString                            *_absoluteCollectionName;
    NSString                            *_collectionName;
}

- (MODQuery *)fetchDatabaseStatsWithCallback:(void (^)(NSDictionary *stats, MODQuery *mongoQuery))callback;
- (MODCursor *)cursorWithCriteria:(NSString *)jsonCriteria fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(NSString *)sort;
- (MODQuery *)indexListWithcallback:(void (^)(NSArray *documents, MODQuery *mongoQuery))callback;
- (MODQuery *)findWithCriteria:(NSString *)jsonCriteria fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(NSString *)sort callback:(void (^)(NSArray *documents, MODQuery *mongoQuery))callback;
- (MODQuery *)countWithCriteria:(NSString *)jsonCriteria callback:(void (^)(int64_t count, MODQuery *mongoQuery))callback;
- (MODQuery *)insertWithDocuments:(NSArray *)documents callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)updateWithCriteria:(NSString *)jsonCriteria update:(NSString *)update upsert:(BOOL)upsert multiUpdate:(BOOL)multiUpdate callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)saveWithDocument:(NSString *)document callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)removeWithCriteria:(NSString *)jsonCriteria callback:(void (^)(MODQuery *mongoQuery))callback;

@property(nonatomic, readonly, retain) MODServer *mongoServer;
@property(nonatomic, retain, readonly) MODDatabase *mongoDatabase;
@property(nonatomic, retain, readonly) NSString *collectionName;
@property(nonatomic, assign, readonly) NSString *databaseName;
@property(nonatomic, retain, readonly) NSString *absoluteCollectionName;

@end
