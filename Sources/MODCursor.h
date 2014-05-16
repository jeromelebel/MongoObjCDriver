//
//  MODCursor.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MODCursor;
@class MODSortedMutableDictionary;

@interface MODCursor : NSObject
{
    MODCollection                       *_mongoCollection;
    NSString                            *_query;
    NSArray                             *_fields;
    uint32_t                            _skip;
    uint32_t                            _limit;
    uint32_t                            _batchSize;
    NSString                            *_sort;
    NSError                             *_error;

    void                                *_mongocCursor;
    BOOL                                _tailable;
}

@property (nonatomic, readonly, strong) NSError *error;

- (MODQuery *)forEachDocumentWithCallbackDocumentCallback:(BOOL (^)(uint64_t index, MODSortedMutableDictionary *document))documentCallback endCallback:(void (^)(uint64_t documentCounts, BOOL cursorStopped, MODQuery *mongoQuery))endCallback;

@property(nonatomic, readonly, retain) MODCollection *mongoCollection;
@property(nonatomic, readonly, retain) NSString *query;
@property(nonatomic, readonly, retain) NSArray *fields;
@property(nonatomic, readonly, assign) uint32_t skip;
@property(nonatomic, readonly, assign) uint32_t limit;
@property(nonatomic, readonly, retain) NSString * sort;
@property(nonatomic, readwrite, assign) BOOL tailable;

@end
