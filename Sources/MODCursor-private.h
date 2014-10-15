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
- (instancetype)initWithCollection:(MODCollection *)collection query:(MODSortedMutableDictionary *)query fields:(NSArray *)fields skip:(uint32_t)skip limit:(uint32_t)limit sort:(MODSortedMutableDictionary *)sort;
- (MODSortedMutableDictionary *)nextDocumentWithBsonData:(NSData **)bsonData error:(NSError **)error;
- (BOOL)more;
- (NSError *)error;

@end
