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

typedef enum {
    MODQueryFlagsNone              = 0,
    MODQueryFlagsTailableCursor    = 1 << 1,
    MODQueryFlagsSlaveOk           = 1 << 2,
    MODQueryFlagsOplogReplay       = 1 << 3,
    MODQueryFlagsNoCursorTimeout   = 1 << 4,
    MODQueryFlagsAwaitData         = 1 << 5,
    MODQueryFlagsExhaust           = 1 << 6,
    MODQueryFlagsPartial           = 1 << 7,
} MODQueryFlags;

@interface MODCollection : NSObject

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

- (MODQuery *)findIndexesWithCallback:(void (^)(NSArray *indexes, MODQuery *mongoQuery))callback;
- (MODQuery *)createIndexWithKeys:(id)keys indexOptions:(MODIndexOpt *)indexOptions callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)dropIndexName:(NSString *)indexDocument callback:(void (^)(MODQuery *mongoQuery))callback;

- (MODQuery *)aggregateWithFlags:(MODQueryFlags)flags
                        pipeline:(NSArray *)pipeline
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
