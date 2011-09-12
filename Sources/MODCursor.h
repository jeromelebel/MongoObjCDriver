//
//  MODCursor.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MODCursor;

@protocol MODCursorDelegate <NSObject>
@optional
- (void)mongoCursor:(MODCursor *)cursor nextDocumentFetched:(NSArray *)result withMongoQuery:(MODQuery *)mongoQuery error:(NSError *)error;
@end

@interface MODCursor : NSObject
{
    id<MODCursorDelegate>               _delegate;
    
    MODCollection                       *_mongoCollection;
    NSString                            *_query;
    NSArray                             *_fields;
    NSUInteger                          _skip;
    NSUInteger                          _limit;
    NSString                            *_sort;

    void                                *_cursor;
    void                                *_bsonQuery;
    void                                *_bsonFields;
}

- (MODQuery *)fetchNextDocument;

@property(nonatomic, readwrite, assign) id<MODCursorDelegate> delegate;
@property(nonatomic, readonly, retain) MODCollection *mongoCollection;
@property(nonatomic, readonly, retain) NSString *query;
@property(nonatomic, readonly, retain) NSArray *fields;
@property(nonatomic, readonly, assign) NSUInteger skip;
@property(nonatomic, readonly, assign) NSUInteger limit;
@property(nonatomic, readonly, retain) NSString * sort;

@end
