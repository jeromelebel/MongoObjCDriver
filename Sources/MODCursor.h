//
//  MODCursor.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MODCursor;

@interface MODCursor : NSObject
{
    MODCollection                       *_mongoCollection;
    NSString                            *_query;
    NSArray                             *_fields;
    int32_t                             _skip;
    int32_t                             _limit;
    NSString                            *_sort;

    BOOL                                _donotReleaseCursor;
    void                                *_cursor;
    void                                *_bsonQuery;
    void                                *_bsonFields;
    
    BOOL                                _tailable;
}

- (MODQuery *)forEachDocumentWithCallbackDocumentCallback:(BOOL (^)(uint64_t index, NSDictionary *document))documentCallback endCallback:(void (^)(uint64_t documentCounts, BOOL cursorStopped, MODQuery *mongoQuery))endCallback;

@property(nonatomic, readonly, retain) MODCollection *mongoCollection;
@property(nonatomic, readonly, retain) NSString *query;
@property(nonatomic, readonly, retain) NSArray *fields;
@property(nonatomic, readonly, assign) int32_t skip;
@property(nonatomic, readonly, assign) int32_t limit;
@property(nonatomic, readonly, retain) NSString * sort;
@property(nonatomic, readwrite, assign) BOOL tailable;

@end
