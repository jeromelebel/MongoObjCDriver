//
//  MODReadPreferences.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/06/2014.
//
//

#import <Foundation/Foundation.h>

@class MODSortedMutableDictionary;

typedef enum
{
    MODReadPreferencesReadPrimaryMode               = (1 << 0),
    MODReadPreferencesReadSecondaryMode             = (1 << 1),
    MODReadPreferencesReadPrimaryPreferredMode      = (1 << 2) | MODReadPreferencesReadPrimaryMode,
    MODReadPreferencesReadSecondaryPreferredMode    = (1 << 2) | MODReadPreferencesReadSecondaryMode,
    MODReadPreferencesReadNearestMode               = (1 << 3) | MODReadPreferencesReadSecondaryMode
} MODReadPreferencesReadMode;

@interface MODReadPreferences : NSObject
{
    void                                *_mongocReadPreferences;
}
@property (nonatomic, readwrite, assign) MODReadPreferencesReadMode readMode;
@property (nonatomic, readwrite, assign) MODSortedMutableDictionary *tags;

+ (MODReadPreferences *)readPreferencesWithReadMode:(MODReadPreferencesReadMode)readMode;
+ (MODReadPreferences *)readPreferencesWithReadMode:(MODReadPreferencesReadMode)readMode tags:(MODSortedMutableDictionary *)tags;

@end
