//
//  MODReadPreferences.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 11/06/2014.
//
//

#import "MongoObjCDriver-private.h"

@interface MODReadPreferences ()
@property (nonatomic, assign, readwrite) MODReadPreferencesReadMode readMode;
@property (nonatomic, assign, readwrite) MODSortedDictionary *tags;

@end

@implementation MODReadPreferences

@synthesize mongocReadPreferences = _mongocReadPreferences;

+ (MODReadPreferences *)readPreferencesWithReadMode:(MODReadPreferencesReadMode)readMode
{
    return [self readPreferencesWithReadMode:readMode tags:nil];
}

+ (MODReadPreferences *)readPreferencesWithReadMode:(MODReadPreferencesReadMode)readMode tags:(MODSortedDictionary *)tags
{
    MODReadPreferences *readPreferences;
    
    readPreferences = [[[self alloc] init] autorelease];
    readPreferences.readMode = readMode;
    readPreferences.tags = tags;
    return readPreferences;
}

+ (instancetype)readPreferencesWithMongocReadPreferences:(const mongoc_read_prefs_t *)readPreferences
{
    return [[[self alloc] initWithMongocReadPreferences:readPreferences] autorelease];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mongocReadPreferences = mongoc_read_prefs_new(MONGOC_READ_PRIMARY);
    }
    return self;
}

- (instancetype)initWithMongocReadPreferences:(const mongoc_read_prefs_t *)readPreferences
{
    self = [self init];
    if (self) {
        mongoc_read_prefs_destroy(self.mongocReadPreferences);
        self.mongocReadPreferences = mongoc_read_prefs_copy(readPreferences);
    }
    return self;
}

- (instancetype)initWithReadMode:(MODReadPreferencesReadMode)readMode tags:(MODSortedDictionary *)tags
{
    self = [self init];
    if (self) {
        self.readMode = readMode;
        self.tags = tags;
    }
    return self;
}

- (void)dealloc
{
    mongoc_read_prefs_destroy(self.mongocReadPreferences);
    [super dealloc];
}

- (MODReadPreferencesReadMode)readMode
{
    return (MODReadPreferencesReadMode)mongoc_read_prefs_get_mode(self.mongocReadPreferences);
}

- (void)setReadMode:(MODReadPreferencesReadMode)readMode
{
    mongoc_read_prefs_set_mode(self.mongocReadPreferences, (mongoc_read_mode_t)readMode);
}

- (MODSortedDictionary *)tags
{
    const bson_t *tags;
    
    tags = mongoc_read_prefs_get_tags(self.mongocReadPreferences);
    return [self.class objectFromBson:tags];
}

- (void)setTags:(MODSortedDictionary *)tags
{
    if (!tags) {
        mongoc_read_prefs_set_tags(self.mongocReadPreferences, NULL);
    } else {
        bson_t bsonTags = BSON_INITIALIZER;
        
        [MODClient appendObject:tags toBson:&bsonTags];
        mongoc_read_prefs_set_tags(self.mongocReadPreferences, &bsonTags);
        bson_destroy(&bsonTags);
    }
}

@end
