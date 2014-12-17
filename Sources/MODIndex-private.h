//
//  MODIndex-private.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 16/12/2014.
//
//

#import "MongoObjCDriver-private.h"

@interface MODIndexOptGeo()
@property (nonatomic, readwrite, assign) mongoc_index_opt_geo_t *mongocIndexOptGeo;

+ (instancetype)indexOptGeoWithMongocIndexOptGeo:(const mongoc_index_opt_geo_t *)mongocIndexOptGeo;

- (instancetype)initWithMongocIndexOptGeo:(const mongoc_index_opt_geo_t *)mongocIndexOptGeo;
@end

@interface MODIndexOpt()
+ (instancetype)indexOptWithMongocIndexOpt:(const mongoc_index_opt_t *)mongocIndexOpt;

- (instancetype)initWithMongocIndexOpt:(const mongoc_index_opt_t *)mongocIndexOpt;

- (void)setMongocIndexOpt:(const mongoc_index_opt_t *)mongocIndexOpt;
- (mongoc_index_opt_t *)mongocIndexOpt;
@end
