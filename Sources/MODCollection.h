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
@class MODSortedMutableDictionary;

enum MOD_INDEX_OPTIONS {
    MOD_INDEX_OPTIONS_UNIQUE = ( 1<<0 ),
    MOD_INDEX_OPTIONS_DROP_DUPS = ( 1<<2 ),
    MOD_INDEX_OPTIONS_BACKGROUND = ( 1<<3 ),
    MOD_INDEX_OPTIONS_SPARSE = ( 1<<4 )
};

@interface MODCollection : NSObject
{
    MODDatabase                         *_database;
    NSString                            *_absoluteName;
    NSString                            *_name;
    void                                *_mongocCollection;
}

@property (nonatomic, retain, readonly) MODClient *client;
@property (nonatomic, retain, readonly) MODDatabase *database;
@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, retain, readonly) NSString *absoluteName;

- (MODQuery *)statsWithCallback:(void (^)(MODSortedMutableDictionary *stats, MODQuery *mongoQuery))callback;
- (MODCursor *)cursorWithCriteria:(MODSortedMutableDictionary *)jsonCriteria fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(MODSortedMutableDictionary *)sort;
- (MODQuery *)findWithCriteria:(MODSortedMutableDictionary *)criteria fields:(NSArray *)fields skip:(int32_t)skip limit:(int32_t)limit sort:(MODSortedMutableDictionary *)sort callback:(void (^)(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery))callback;
- (MODQuery *)countWithCriteria:(MODSortedMutableDictionary *)criteria callback:(void (^)(int64_t count, MODQuery *mongoQuery))callback;
- (MODQuery *)insertWithDocuments:(NSArray *)documents callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)updateWithCriteria:(MODSortedMutableDictionary *)criteria update:(MODSortedMutableDictionary *)update upsert:(BOOL)upsert multiUpdate:(BOOL)multiUpdate callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)saveWithDocument:(MODSortedMutableDictionary *)document callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)removeWithCriteria:(id)jsonCriteria callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)dropWithCallback:(void (^)(MODQuery *mongoQuery))callback;

- (MODQuery *)indexListWithCallback:(void (^)(NSArray *documents, MODQuery *mongoQuery))callback;
- (MODQuery *)createIndex:(id)indexDocument name:(NSString *)name options:(enum MOD_INDEX_OPTIONS)options callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)dropIndex:(id)indexDocument callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)reIndexWithCallback:(void (^)(MODQuery *mongoQuery))callback;

- (MODQuery *)mapReduceWithMapFunction:(NSString *)mapFunction reduceFunction:(NSString *)reduceFunction query:(id)mapReduceQuery sort:(id)sort limit:(int64_t)limit output:(id)output keepTemp:(BOOL)keepTemp finalizeFunction:(NSString *)finalizeFunction scope:(id)scope jsmode:(BOOL)jsmode verbose:(BOOL)verbose callback:(void (^)(MODQuery *mongoQuery))callback;

@end
