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

@protocol MODCollectionDelegate <NSObject>
- (void)mongoCollection:(MODCollection *)collection queryResultFetched:(NSArray *)result withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoCollection:(MODCollection *)collection queryCountWithValue:(long long)value withMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
- (void)mongoCollection:(MODCollection *)collection updateDonwWithMongoQuery:(MODQuery *)mongoQuery errorMessage:(NSString *)errorMessage;
@end

@interface MODCollection : NSObject
{
    id<MODCollectionDelegate>           _delegate;
    MODDatabase                         *_mongoDatabase;
    NSString                            *_absoluteCollectionName;
}

- (id)initWithMongoDatabase:(MODDatabase *)mongoDatabase collectionName:(NSString *)collectionName;

- (MODQuery *)findWithQuery:(NSString *)query fields:(NSString *)fields skip:(int)skip limit:(int)limit sort:(NSString *)sort;
- (MODQuery *)countWithQuery:(NSString *)query;
- (MODQuery *)updateWithQuery:(NSString *)query fields:(NSString *)fields upset:(BOOL)upset;
- (MODQuery *)saveJsonString:(NSString *)jsonString withRecordId:(NSString *)recordId;

@property(nonatomic, retain, readonly) MODDatabase *mongoDatabase;
@property(nonatomic, retain, readonly) NSString *collectionName;
@property(nonatomic, retain, readonly) NSString *absoluteCollectionName;
@property(nonatomic, readwrite, assign) id<MODCollectionDelegate> delegate;

@end
