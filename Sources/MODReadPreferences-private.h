//
//  MODReadPreferences-private.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 27/08/2014.
//
//

#import "MongoObjCDriver-private.h"

@interface MODReadPreferences ()
@property (nonatomic, readwrite, assign) mongoc_read_prefs_t *mongocReadPreferences;

+ (instancetype)readPreferencesWithMongocReadPreferences:(const mongoc_read_prefs_t *)readPreferences;

- (instancetype)initWithMongocReadPreferences:(const mongoc_read_prefs_t *)readPreferences;

@end
