//
//  MODIndex.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 16/12/2014.
//
//

#import "MongoObjCDriver-private.h"

@implementation MODIndexOptGeo

+ (instancetype)indexOptGeoWithMongocIndexOptGeo:(const mongoc_index_opt_geo_t *)mongocIndexOptGeo
{
    return MOD_AUTORELEASE([[[self class] alloc] initWithMongocIndexOptGeo:mongocIndexOptGeo]);
}

- (instancetype)init
{
    if ([super init]) {
        self.mongocIndexOptGeo = malloc(sizeof(mongoc_index_opt_geo_t));
        mongoc_index_opt_geo_init(self.mongocIndexOptGeo);
    }
    return self;
}

- (instancetype)initWithTwodSphereVersion:(uint8_t)twodSphereVersion
                        twodBitsPercision:(uint8_t)twodBitsPercision
                          twodLocationMin:(double)twodLocationMin
                          twodLocationMax:(double)twodLocationMax
                       haystackBucketSize:(double)haystackBucketSize
{
    if ([self init]) {
        self.mongocIndexOptGeo->twod_sphere_version = twodSphereVersion;
        self.mongocIndexOptGeo->twod_bits_precision = twodBitsPercision;
        self.mongocIndexOptGeo->twod_location_min = twodLocationMin;
        self.mongocIndexOptGeo->twod_location_max = twodLocationMax;
        self.mongocIndexOptGeo->haystack_bucket_size = haystackBucketSize;
    }
    return self;
}

- (instancetype)initWithMongocIndexOptGeo:(const mongoc_index_opt_geo_t *)mongocIndexOptGeo
{
    if (self = [self init]) {
        memccpy(self.mongocIndexOptGeo, mongocIndexOptGeo, 1, sizeof(*mongocIndexOptGeo));
    }
    return self;
}

- (instancetype)copy
{
    return [MODIndexOptGeo indexOptGeoWithMongocIndexOptGeo:self.mongocIndexOptGeo];
}

- (void)dealloc
{
    if (self.mongocIndexOptGeo) free(self.mongocIndexOptGeo);
    MOD_SUPER_DEALLOC();
}

- (uint8_t)twodSphereVersion
{
    return self.mongocIndexOptGeo->twod_sphere_version;
}

- (void)setTwodSphereVersion:(uint8_t)twodSphereVersion
{
    self.mongocIndexOptGeo->twod_sphere_version = twodSphereVersion;
}

- (uint8_t)twodBitsPrecision
{
    return self.mongocIndexOptGeo->twod_bits_precision;
}

- (void)setTwodBitsPrecision:(uint8_t)twodBitsPrecision
{
    self.mongocIndexOptGeo->twod_bits_precision = twodBitsPrecision;
}

- (double)twodLocationMin
{
    return self.mongocIndexOptGeo->twod_location_min;
}

- (void)setTwodLocationMin:(double)twodLocationMin
{
    self.mongocIndexOptGeo->twod_location_min = twodLocationMin;
}

- (double)twodLocationMax
{
    return self.mongocIndexOptGeo->twod_location_max;
}

- (void)setTwodLocationMax:(double)twodLocationMax
{
    self.mongocIndexOptGeo->twod_location_max = twodLocationMax;
}

- (double)haystackBucketSize
{
    return self.mongocIndexOptGeo->haystack_bucket_size;
}

- (void)setHaystackBucketSize:(double)haystackBucketSize
{
    self.mongocIndexOptGeo->haystack_bucket_size = haystackBucketSize;
}


@end


@implementation MODIndexOpt
{
    MODIndexOptGeo                              *_geoOptions;
    mongoc_index_opt_t                          *_mongocIndexOpt;
}

+ (instancetype)indexOptWithMongocIndexOpt:(const mongoc_index_opt_t *)mongocIndexOpt
{
    return MOD_AUTORELEASE([[[self class] alloc] initWithMongocIndexOpt:mongocIndexOpt]);
}

- (instancetype)init
{
    if (self = [super init]) {
        _mongocIndexOpt = malloc(sizeof(mongoc_index_opt_t));
        mongoc_index_opt_init(_mongocIndexOpt);
    }
    return self;
}

- (instancetype)initWithMongocIndexOpt:(const mongoc_index_opt_t *)mongocIndexOpt
{
    if (self = [self init]) {
        self.mongocIndexOpt = mongocIndexOpt;
    }
    return self;
}


- (instancetype)copy
{
    return [MODIndexOpt indexOptWithMongocIndexOpt:self.mongocIndexOpt];
}

- (void)dealloc
{
    self.weights = nil;
    self.name = nil;
    self.defaultLanguage = nil;
    self.geoOptions = nil;
    self.languageOverride = nil;
    free(_mongocIndexOpt);
    MOD_SUPER_DEALLOC();
}

- (mongoc_index_opt_t *)mongocIndexOpt
{
    return _mongocIndexOpt;
}

- (void)setMongocIndexOpt:(const mongoc_index_opt_t *)mongocIndexOpt
{
    NSParameterAssert(mongocIndexOpt);
    NSAssert(_mongocIndexOpt, @"need to have a pointer to _mongocIndexOpt");
    
    self.weights = nil;
    self.name = nil;
    self.defaultLanguage = nil;
    self.geoOptions = nil;
    self.languageOverride = nil;
    
    memcpy(_mongocIndexOpt, mongocIndexOpt, sizeof(*mongocIndexOpt));
    if (mongocIndexOpt->default_language) {
        _mongocIndexOpt->default_language = strdup(mongocIndexOpt->default_language);
    }
    if (mongocIndexOpt->language_override) {
        _mongocIndexOpt->language_override = strdup(mongocIndexOpt->language_override);
    }
    if (mongocIndexOpt->name) {
        _mongocIndexOpt->name = strdup(mongocIndexOpt->name);
    }
    if (mongocIndexOpt->weights) {
        _mongocIndexOpt->weights = bson_copy(mongocIndexOpt->weights);
    }
    if (mongocIndexOpt->geo_options) {
        MODIndexOptGeo *indexOptGeo = [MODIndexOptGeo indexOptGeoWithMongocIndexOptGeo:mongocIndexOpt->geo_options];
        
        self.geoOptions = indexOptGeo;
    }
}

- (BOOL)isInitialized
{
    return _mongocIndexOpt->is_initialized;
}

- (void)setIsInitialized:(BOOL)isInitialized
{
    _mongocIndexOpt->is_initialized = isInitialized;
}

- (BOOL)background
{
    return _mongocIndexOpt->background;
}

- (void)setBackground:(BOOL)background
{
    _mongocIndexOpt->background = background;
}

- (BOOL)unique
{
    return _mongocIndexOpt->unique;
}

- (void)setUnique:(BOOL)unique
{
    _mongocIndexOpt->unique = unique;
}

- (NSString *)name
{
    if (_mongocIndexOpt->name) {
        return [NSString stringWithUTF8String:_mongocIndexOpt->name];
    } else {
        return nil;
    }
}

- (void)setName:(NSString *)name
{
    if (_mongocIndexOpt->name) {
        free((void *)_mongocIndexOpt->name);
        _mongocIndexOpt->name = NULL;
    }
    if (name) {
        _mongocIndexOpt->name = strdup(name.UTF8String);
    }
}

- (BOOL)dropDups
{
    return _mongocIndexOpt->drop_dups;
}

- (void)setDropDups:(BOOL)dropDups
{
    _mongocIndexOpt->drop_dups = dropDups;
}

- (BOOL)sparse
{
    return _mongocIndexOpt->sparse;
}

- (void)setSparse:(BOOL)sparse
{
    _mongocIndexOpt->sparse = sparse;
}

- (int32_t)expireAfterSeconds
{
    return _mongocIndexOpt->expire_after_seconds;
}

- (void)setExpireAfterSeconds:(int32_t)expireAfterSeconds
{
    _mongocIndexOpt->expire_after_seconds = expireAfterSeconds;
}

- (int32_t)v
{
    return _mongocIndexOpt->v;
}

- (void)setV:(int32_t)v
{
    _mongocIndexOpt->v = v;
}

- (MODSortedDictionary *)weights
{
    if (_mongocIndexOpt->weights) {
        return [MODClient objectFromBson:_mongocIndexOpt->weights];
    } else {
        return nil;
    }
}

- (void)setWeights:(MODSortedDictionary *)weights
{
    if (_mongocIndexOpt->weights) {
        bson_destroy((bson_t *)_mongocIndexOpt->weights);
        _mongocIndexOpt->weights = NULL;
    }
    if (weights) {
        bson_t *bson;
        
        bson = bson_new();
        [MODClient appendObject:weights toBson:bson];
        _mongocIndexOpt->weights = bson;
    }
}

- (NSString *)defaultLanguage
{
    if (_mongocIndexOpt->default_language) {
        return [NSString stringWithUTF8String:_mongocIndexOpt->default_language];
    } else {
        return NULL;
    }
}

- (void)setDefaultLanguage:(NSString *)defaultLanguage
{
    if (_mongocIndexOpt->default_language) {
        free((void *)_mongocIndexOpt->default_language);
        _mongocIndexOpt->default_language = NULL;
    }
    if (defaultLanguage) {
        _mongocIndexOpt->default_language = strdup(defaultLanguage.UTF8String);
    }
}

- (NSString *)languageOverride
{
    if (_mongocIndexOpt->language_override) {
        return [NSString stringWithUTF8String:_mongocIndexOpt->language_override];
    } else {
        return NULL;
    }
}

- (void)setLanguageOverride:(NSString *)languageOverride
{
    if (_mongocIndexOpt->language_override) {
        free((void *)_mongocIndexOpt->language_override);
        _mongocIndexOpt->language_override = NULL;
    }
    if (languageOverride) {
        _mongocIndexOpt->language_override = strdup(languageOverride.UTF8String);
    }
}

- (MODIndexOptGeo *)geoOptions
{
    return _geoOptions;
}

- (void)setGeoOptions:(MODIndexOptGeo *)geoOptions
{
    MOD_RELEASE(_geoOptions);
    _geoOptions = MOD_RETAIN(geoOptions);
    _mongocIndexOpt->geo_options = _geoOptions.mongocIndexOptGeo;
}

@end
