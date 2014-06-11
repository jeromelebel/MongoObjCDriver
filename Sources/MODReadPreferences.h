//
//  MODReadPreferences.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 11/06/2014.
//
//

#import <Foundation/Foundation.h>

@class MODSortedMutableDictionary;

@interface MODReadPreferences : NSObject
{
    void                                *_mongocReadPreferences;
}
@property (nonatomic, readwrite, assign) NSInteger readMode;
@property (nonatomic, readwrite, assign) MODSortedMutableDictionary *tags;

@end
