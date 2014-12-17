//
//  MODCollection.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 03/09/2011.
//

#import <Foundation/Foundation.h>

@class MODDatabase;
@class MODCollection;
@class MODQuery;
@class MODCursor;
@class MODSortedDictionary;
@class MODWriteConcern;
@class MODIndexOpt;

#define MODCollection_Dropped_Notification        @"MODCollection_Dropped_Notification"

@interface MODCollection : NSObject
{
    MODDatabase                         *_database;
    NSString                            *_absoluteName;
    NSString                            *_name;
    void                                *_mongocCollection;
    MODReadPreferences                  *_readPreferences;
    BOOL                                _dropped;
}

@property (nonatomic, strong, readonly) MODClient *client;
@property (nonatomic, strong, readonly) MODDatabase *database;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *absoluteName;
@property (nonatomic, strong, readwrite) MODReadPreferences *readPreferences;
@property (nonatomic, assign, readonly) BOOL dropped;

- (MODQuery *)commandSimpleWithCommand:(MODSortedDictionary *)command readPreferences:(MODReadPreferences *)readPreferences callback:(void (^)(MODQuery *query, MODSortedDictionary *reply))callback;
- (MODQuery *)renameWithNewDatabase:(MODDatabase *)newDatabase newCollectionName:(NSString *)newCollectionName dropTargetBeforeRenaming:(BOOL)dropTargetBeforeRenaming callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)statsWithCallback:(void (^)(MODSortedDictionary *stats, MODQuery *mongoQuery))callback;
- (MODCursor *)cursorWithCriteria:(MODSortedDictionary *)jsonCriteria
                           fields:(MODSortedDictionary *)fields
                             skip:(int32_t)skip
                            limit:(int32_t)limit
                             sort:(MODSortedDictionary *)sort;
- (MODQuery *)findWithCriteria:(MODSortedDictionary *)criteria
                        fields:(MODSortedDictionary *)fields
                          skip:(int32_t)skip
                         limit:(int32_t)limit
                          sort:(MODSortedDictionary *)sort
                      callback:(void (^)(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery))callback;
- (MODQuery *)countWithCriteria:(MODSortedDictionary *)criteria readPreferences:(MODReadPreferences *)readPreferences callback:(void (^)(int64_t count, MODQuery *mongoQuery))callback;
- (MODQuery *)insertWithDocuments:(NSArray *)documents
                     writeConcern:(MODWriteConcern *)writeConcern
                         callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)updateWithCriteria:(MODSortedDictionary *)criteria
                          update:(MODSortedDictionary *)update
                          upsert:(BOOL)upsert
                     multiUpdate:(BOOL)multiUpdate
                    writeConcern:(MODWriteConcern *)writeConcern callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)saveWithDocument:(MODSortedDictionary *)document callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)removeWithCriteria:(id)jsonCriteria callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)dropWithCallback:(void (^)(MODQuery *mongoQuery))callback;

- (MODQuery *)indexListWithCallback:(void (^)(NSArray *documents, MODQuery *mongoQuery))callback;
- (MODQuery *)createIndex:(id)indexDocument indexOptions:(MODIndexOpt *)indexOptions callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)dropIndexName:(NSString *)indexDocument callback:(void (^)(MODQuery *mongoQuery))callback;

- (MODQuery *)aggregateWithFlags:(int)flags
                        pipeline:(MODSortedDictionary *)pipeline
                         options:(MODSortedDictionary *)options
                 readPreferences:(MODReadPreferences *)readPreferences
                        callback:(void (^)(MODQuery *mongoQuery, MODCursor *cursor))callback;
- (MODQuery *)mapReduceWithMapFunction:(NSString *)mapFunction
                        reduceFunction:(NSString *)reduceFunction
                                 query:(MODSortedDictionary *)query
                                  sort:(MODSortedDictionary *)sort
                                 limit:(int64_t)limit
                                output:(MODSortedDictionary *)output
                              keepTemp:(BOOL)keepTemp
                      finalizeFunction:(NSString *)finalizeFunction
                                 scope:(MODSortedDictionary *)scope
                                jsmode:(BOOL)jsmode
                               verbose:(BOOL)verbose
                       readPreferences:(MODReadPreferences *)readPreferences
                              callback:(void (^)(MODQuery *mongoQuery, MODSortedDictionary *documents))callback;

@end
