//
//  MODCursor.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 11/09/2011.
//

#import <Foundation/Foundation.h>

@class MODCursor;
@class MODSortedMutableDictionary;

@interface MODCursor : NSObject
{
    MODCollection                       *_collection;
    MODSortedMutableDictionary          *_query;
    MODSortedMutableDictionary          *_fields;
    uint32_t                            _skip;
    uint32_t                            _limit;
    uint32_t                            _batchSize;
    MODSortedMutableDictionary          *_sort;
    NSError                             *_internalError;

    void                                *_mongocCursor;
    BOOL                                _tailable;
}

@property (nonatomic, readonly, strong) NSError *error;

- (MODQuery *)forEachDocumentWithCallbackDocumentCallback:(BOOL (^)(uint64_t index, MODSortedMutableDictionary *document))documentCallback endCallback:(void (^)(uint64_t documentCounts, BOOL cursorStopped, MODQuery *mongoQuery))endCallback;

@property(nonatomic, strong, readonly) MODCollection *collection;
@property(nonatomic, strong, readonly) MODSortedMutableDictionary *query;
@property(nonatomic, strong, readonly) MODSortedMutableDictionary *fields;
@property(nonatomic, assign, readonly) uint32_t skip;
@property(nonatomic, assign, readonly) uint32_t limit;
@property(nonatomic, strong, readonly) MODSortedMutableDictionary * sort;
@property(nonatomic, assign, readwrite) BOOL tailable;

@end
