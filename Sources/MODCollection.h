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

@protocol MODCollectionDelegate <NSObject>
@optional
- (void)mongoCollection:(MODCollection *)collection queryResultFetched:(NSArray *)result withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error;
- (void)mongoCollection:(MODCollection *)collection queryCountWithValue:(long long)value withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error;
- (void)mongoCollection:(MODCollection *)collection insertWithMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error;
- (void)mongoCollection:(MODCollection *)collection updateDonwWithMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error;
@end

@interface MODCollection : NSObject
{
    id<MODCollectionDelegate>           _delegate;
    MODDatabase                         *_mongoDatabase;
    NSString                            *_absoluteCollectionName;
}

- (id)initWithMongoDatabase:(MODDatabase *)mongoDatabase collectionName:(NSString *)collectionName;

- (MODCursor *)cursorWithQuery:(NSString *)query fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(NSString *)sort;
- (MODQuery *)findWithQuery:(NSString *)query fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(NSString *)sort;
- (MODQuery *)countWithQuery:(NSString *)query;
- (MODQuery *)insertWithDocuments:(NSArray *)documents;
- (MODQuery *)updateWithQuery:(NSString *)query fields:(NSString *)fields upset:(BOOL)upset;
- (MODQuery *)saveJsonString:(NSString *)jsonString withRecordId:(NSString *)recordId;

@property(nonatomic, readonly, retain) MODServer *mongoServer;
@property(nonatomic, retain, readonly) MODDatabase *mongoDatabase;
@property(nonatomic, retain, readonly) NSString *collectionName;
@property(nonatomic, retain, readonly) NSString *absoluteCollectionName;
@property(nonatomic, readwrite, assign) id<MODCollectionDelegate> delegate;

@end
