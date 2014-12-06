//
//  MODReadPreferences.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 11/06/2014.
//
//

#import <Foundation/Foundation.h>

@class MODSortedDictionary;

typedef enum
{
    MODReadPreferencesReadPrimaryMode               = (1 << 0),
    MODReadPreferencesReadSecondaryMode             = (1 << 1),
    MODReadPreferencesReadPrimaryPreferredMode      = (1 << 2) | MODReadPreferencesReadPrimaryMode,
    MODReadPreferencesReadSecondaryPreferredMode    = (1 << 2) | MODReadPreferencesReadSecondaryMode,
    MODReadPreferencesReadNearestMode               = (1 << 3) | MODReadPreferencesReadSecondaryMode
} MODReadPreferencesReadMode;

/*
    MODReadPreferences is non mutable since MODClient instance doesn't keep it around
    this avoid errors like :
    client.readPreferences.readMode = MODReadPreferencesReadSecondaryMode;
*/

@interface MODReadPreferences : NSObject
{
    void                                *_mongocReadPreferences;
}
@property (nonatomic, assign, readonly) MODReadPreferencesReadMode readMode;
@property (nonatomic, assign, readonly) MODSortedDictionary *tags;

+ (MODReadPreferences *)readPreferencesWithReadMode:(MODReadPreferencesReadMode)readMode;
+ (MODReadPreferences *)readPreferencesWithReadMode:(MODReadPreferencesReadMode)readMode tags:(MODSortedDictionary *)tags;

- (instancetype)initWithReadMode:(MODReadPreferencesReadMode)readMode tags:(MODSortedDictionary *)tags;

@end
