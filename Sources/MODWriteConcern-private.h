//
//  MODWriteConcern-private.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 27/08/2014.
//
//

#import "MongoObjCDriver-private.h"

@interface MODWriteConcern ()
@property (nonatomic, readwrite, assign) mongoc_write_concern_t *mongocWriteConcern;

+ (instancetype)writeConcernWithMongocWriteConcern:(const mongoc_write_concern_t *)mongocWriteConcern;

- (instancetype)initWithMongocWriteConcern:(const mongoc_write_concern_t *)mongocWriteConcern;

@end
