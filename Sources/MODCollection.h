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
@class MODSortedMutableDictionary;
@class MODWriteConcern;

enum MOD_INDEX_OPTIONS {
    MOD_INDEX_OPTIONS_UNIQUE = ( 1<<0 ),
    MOD_INDEX_OPTIONS_DROP_DUPS = ( 1<<2 ),
    MOD_INDEX_OPTIONS_BACKGROUND = ( 1<<3 ),
    MOD_INDEX_OPTIONS_SPARSE = ( 1<<4 )
};

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

- (MODQuery *)commandSimpleWithCommand:(MODSortedMutableDictionary *)command readPreferences:(MODReadPreferences *)readPreferences callback:(void (^)(MODQuery *query, MODSortedMutableDictionary *reply))callback;
- (MODQuery *)renameWithNewDatabase:(MODDatabase *)newDatabase newCollectionName:(NSString *)newCollectionName dropTargetBeforeRenaming:(BOOL)dropTargetBeforeRenaming callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)statsWithCallback:(void (^)(MODSortedMutableDictionary *stats, MODQuery *mongoQuery))callback;
- (MODCursor *)cursorWithCriteria:(MODSortedMutableDictionary *)jsonCriteria
                           fields:(MODSortedMutableDictionary *)fields
                             skip:(int32_t)skip
                            limit:(int32_t)limit
                             sort:(MODSortedMutableDictionary *)sort;
- (MODQuery *)findWithCriteria:(MODSortedMutableDictionary *)criteria
                        fields:(MODSortedMutableDictionary *)fields
                          skip:(int32_t)skip
                         limit:(int32_t)limit
                          sort:(MODSortedMutableDictionary *)sort
                      callback:(void (^)(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery))callback;
- (MODQuery *)countWithCriteria:(MODSortedMutableDictionary *)criteria readPreferences:(MODReadPreferences *)readPreferences callback:(void (^)(int64_t count, MODQuery *mongoQuery))callback;
- (MODQuery *)insertWithDocuments:(NSArray *)documents
                     writeConcern:(MODWriteConcern *)writeConcern
                         callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)updateWithCriteria:(MODSortedMutableDictionary *)criteria
                          update:(MODSortedMutableDictionary *)update
                          upsert:(BOOL)upsert
                     multiUpdate:(BOOL)multiUpdate
                    writeConcern:(MODWriteConcern *)writeConcern callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)saveWithDocument:(MODSortedMutableDictionary *)document callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)removeWithCriteria:(id)jsonCriteria callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)dropWithCallback:(void (^)(MODQuery *mongoQuery))callback;

- (MODQuery *)indexListWithCallback:(void (^)(NSArray *documents, MODQuery *mongoQuery))callback;
- (MODQuery *)createIndex:(id)indexDocument name:(NSString *)name options:(enum MOD_INDEX_OPTIONS)options callback:(void (^)(MODQuery *mongoQuery))callback;
- (MODQuery *)dropIndexName:(NSString *)indexDocument callback:(void (^)(MODQuery *mongoQuery))callback;

- (MODQuery *)aggregateWithFlags:(int)flags
                        pipeline:(MODSortedMutableDictionary *)pipeline
                         options:(MODSortedMutableDictionary *)options
                 readPreferences:(MODReadPreferences *)readPreferences
                        callback:(void (^)(MODQuery *mongoQuery, MODCursor *cursor))callback;
- (MODQuery *)mapReduceWithMapFunction:(NSString *)mapFunction
                        reduceFunction:(NSString *)reduceFunction
                                 query:(MODSortedMutableDictionary *)query
                                  sort:(MODSortedMutableDictionary *)sort
                                 limit:(int64_t)limit
                                output:(MODSortedMutableDictionary *)output
                              keepTemp:(BOOL)keepTemp
                      finalizeFunction:(NSString *)finalizeFunction
                                 scope:(MODSortedMutableDictionary *)scope
                                jsmode:(BOOL)jsmode
                               verbose:(BOOL)verbose
                       readPreferences:(MODReadPreferences *)readPreferences
                              callback:(void (^)(MODQuery *mongoQuery, MODSortedMutableDictionary *documents))callback;

@end
