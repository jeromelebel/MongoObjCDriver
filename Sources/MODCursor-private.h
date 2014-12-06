//
//  MODCursor-private.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 15/10/2014.
//
//

#import "MongoObjCDriver-private.h"

@interface MODCursor ()
- (instancetype)initWithCollection:(MODCollection *)collection mongocCursor:(mongoc_cursor_t *)mongocCursor;
- (instancetype)initWithCollection:(MODCollection *)collection
                             query:(MODSortedDictionary *)query
                            fields:(MODSortedDictionary *)fields
                              skip:(uint32_t)skip
                             limit:(uint32_t)limit
                              sort:(MODSortedDictionary *)sort;
- (MODSortedDictionary *)nextDocumentWithBsonData:(NSData **)bsonData error:(NSError **)error;
- (BOOL)more;
- (NSError *)error;

@end
