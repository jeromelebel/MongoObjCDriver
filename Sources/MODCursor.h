//
//  MODCursor.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 11/09/2011.
//

#import <Foundation/Foundation.h>

@class MODCursor;
@class MODSortedDictionary;

@interface MODCursor : NSObject

@property (nonatomic, readonly, strong) NSError *error;

- (MODQuery *)forEachDocumentWithCallbackDocumentCallback:(BOOL (^)(uint64_t index, MODSortedDictionary *document, NSData *data))documentCallback
                                              endCallback:(void (^)(uint64_t documentCounts, BOOL cursorStopped, MODQuery *mongoQuery))endCallback;

@property(nonatomic, strong, readonly) MODCollection *collection;
@property(nonatomic, strong, readonly) MODSortedDictionary *query;
@property(nonatomic, strong, readonly) MODSortedDictionary *fields;
@property(nonatomic, assign, readonly) uint32_t skip;
@property(nonatomic, assign, readonly) uint32_t limit;
@property(nonatomic, strong, readonly) MODSortedDictionary * sort;
@property(nonatomic, assign, readwrite) BOOL tailable;

@end
