//
//  MODIndex.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 16/12/2014.
//
//

#import "MongoObjCDriver-private.h"

@implementation MODIndexOptGeo

@synthesize mongocIndexOptGeo = _mongocIndexOptGeo;

+ (instancetype)indexOptGeoWithMongocIndexOptGeo:(const mongoc_index_opt_geo_t *)mongocIndexOptGeo
{
    return [[[[self class] alloc] initWithMongocIndexOptGeo:mongocIndexOptGeo] autorelease];
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

- (void)dealloc
{
    if (self.mongocIndexOptGeo) free(self.mongocIndexOptGeo);
    [super dealloc];
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

+ (instancetype)indexOptWithMongocIndexOpt:(const mongoc_index_opt_t *)mongocIndexOpt
{
    return [[[[self class] alloc] initWithMongocIndexOpt:mongocIndexOpt] autorelease];
}

- (instancetype)init
{
    if (self = [super init]) {
        _mongocIndexOpt = malloc(sizeof(mongoc_index_opt_t));
        mongoc_index_opt_geo_init(_mongocIndexOpt);
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

- (void)dealloc
{
    self.mongocIndexOpt = NULL;
    [super dealloc];
}

- (mongoc_index_opt_t *)mongocIndexOpt
{
    return _mongocIndexOpt;
}

- (void)setMongocIndexOpt:(const mongoc_index_opt_t *)mongocIndexOpt
{
    NSParameterAssert(mongocIndexOpt);
    NSAssert(_mongocIndexOpt, @"need to have a pointer to _mongocIndexOpt");
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->default_language) free((void *)((mongoc_index_opt_t *)_mongocIndexOpt)->default_language);
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->geo_options) free(((mongoc_index_opt_t *)_mongocIndexOpt)->geo_options);
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->language_override) free((void *)((mongoc_index_opt_t *)_mongocIndexOpt)->language_override);
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->name) free((void *)((mongoc_index_opt_t *)_mongocIndexOpt)->name);
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->weights) bson_destroy((void *)((mongoc_index_opt_t *)_mongocIndexOpt)->weights);
    
    memcpy(_mongocIndexOpt, mongocIndexOpt, sizeof(*mongocIndexOpt));
    if (mongocIndexOpt->default_language) {
        ((mongoc_index_opt_t *)_mongocIndexOpt)->default_language = strdup(mongocIndexOpt->default_language);
    }
    if (mongocIndexOpt->language_override) {
        ((mongoc_index_opt_t *)_mongocIndexOpt)->language_override = strdup(mongocIndexOpt->language_override);
    }
    if (mongocIndexOpt->name) {
        ((mongoc_index_opt_t *)_mongocIndexOpt)->name = strdup(mongocIndexOpt->name);
    }
    if (mongocIndexOpt->weights) {
        ((mongoc_index_opt_t *)_mongocIndexOpt)->weights = bson_copy(mongocIndexOpt->weights);
    }
    if (mongocIndexOpt->geo_options) {
        MODIndexOptGeo *indexOptGeo = [MODIndexOptGeo indexOptGeoWithMongocIndexOptGeo:mongocIndexOpt->geo_options];
        
        self.geoOptions = indexOptGeo;
    }
}

- (BOOL)isInitialized
{
    return ((mongoc_index_opt_t *)_mongocIndexOpt)->is_initialized;
}

- (void)setIsInitialized:(BOOL)isInitialized
{
    ((mongoc_index_opt_t *)_mongocIndexOpt)->is_initialized = isInitialized;
}

- (BOOL)background
{
    return ((mongoc_index_opt_t *)_mongocIndexOpt)->background;
}

- (void)setBackground:(BOOL)background
{
    ((mongoc_index_opt_t *)_mongocIndexOpt)->background = background;
}

- (BOOL)unique
{
    return ((mongoc_index_opt_t *)_mongocIndexOpt)->unique;
}

- (void)setUnique:(BOOL)unique
{
    ((mongoc_index_opt_t *)_mongocIndexOpt)->unique = unique;
}

- (NSString *)name
{
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->name) {
        return [NSString stringWithUTF8String:((mongoc_index_opt_t *)_mongocIndexOpt)->name];
    } else {
        return nil;
    }
}

- (void)setName:(NSString *)name
{
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->name) {
        free((void *)((mongoc_index_opt_t *)_mongocIndexOpt)->name);
        ((mongoc_index_opt_t *)_mongocIndexOpt)->name = NULL;
    }
    if (name) {
        ((mongoc_index_opt_t *)_mongocIndexOpt)->name = strdup(name.UTF8String);
    }
}

- (BOOL)dropDups
{
    return ((mongoc_index_opt_t *)_mongocIndexOpt)->drop_dups;
}

- (void)setDropDups:(BOOL)dropDups
{
    ((mongoc_index_opt_t *)_mongocIndexOpt)->drop_dups = dropDups;
}

- (BOOL)sparse
{
    return ((mongoc_index_opt_t *)_mongocIndexOpt)->sparse;
}

- (void)setSparse:(BOOL)sparse
{
    ((mongoc_index_opt_t *)_mongocIndexOpt)->sparse = sparse;
}

- (int32_t)expireAfterSeconds
{
    return ((mongoc_index_opt_t *)_mongocIndexOpt)->expire_after_seconds;
}

- (void)setExpireAfterSeconds:(int32_t)expireAfterSeconds
{
    ((mongoc_index_opt_t *)_mongocIndexOpt)->expire_after_seconds = expireAfterSeconds;
}

- (int32_t)v
{
    return ((mongoc_index_opt_t *)_mongocIndexOpt)->v;
}

- (void)setV:(int32_t)v
{
    ((mongoc_index_opt_t *)_mongocIndexOpt)->v = v;
}

- (MODSortedDictionary *)weights
{
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->weights) {
        return [MODClient objectFromBson:((mongoc_index_opt_t *)_mongocIndexOpt)->weights];
    } else {
        return nil;
    }
}

- (void)setWeights:(MODSortedDictionary *)weights
{
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->weights) {
        bson_destroy((bson_t *)((mongoc_index_opt_t *)_mongocIndexOpt)->weights);
    }
    if (weights) {
        bson_t *bson;
        
        bson = bson_new();
        [MODClient appendObject:weights toBson:bson];
        ((mongoc_index_opt_t *)_mongocIndexOpt)->weights = bson;
    }
}

- (NSString *)defaultLanguage
{
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->default_language) {
        return [NSString stringWithUTF8String:((mongoc_index_opt_t *)_mongocIndexOpt)->default_language];
    } else {
        return NULL;
    }
}

- (void)setDefaultLanguage:(NSString *)defaultLanguage
{
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->default_language) {
        free((void *)((mongoc_index_opt_t *)_mongocIndexOpt)->default_language);
        ((mongoc_index_opt_t *)_mongocIndexOpt)->default_language = NULL;
    }
    if (defaultLanguage) {
        ((mongoc_index_opt_t *)_mongocIndexOpt)->default_language = strdup(defaultLanguage.UTF8String);
    }
}

- (NSString *)languageOverride
{
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->language_override) {
        return [NSString stringWithUTF8String:((mongoc_index_opt_t *)_mongocIndexOpt)->language_override];
    } else {
        return NULL;
    }
}

- (void)setLanguageOverride:(NSString *)languageOverride
{
    if (((mongoc_index_opt_t *)_mongocIndexOpt)->language_override) {
        free((void *)((mongoc_index_opt_t *)_mongocIndexOpt)->language_override);
        ((mongoc_index_opt_t *)_mongocIndexOpt)->language_override = NULL;
    }
    if (languageOverride) {
        ((mongoc_index_opt_t *)_mongocIndexOpt)->language_override = strdup(languageOverride.UTF8String);
    }
}

- (MODIndexOptGeo *)geoOptions
{
    return _geoOptions;
}

- (void)setGeoOptions:(MODIndexOptGeo *)geoOptions
{
    [_geoOptions release];
    _geoOptions = [geoOptions retain];
    ((mongoc_index_opt_t *)_mongocIndexOpt)->geo_options = _geoOptions.mongocIndexOptGeo;
}

@end
