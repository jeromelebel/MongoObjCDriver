//
//  MODIndex.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 16/12/2014.
//
//

#import <Foundation/Foundation.h>

@class MODSortedDictionary;

@interface MODIndexOptGeo : NSObject
{
    void                        *_mongocIndexOptGeo;
}
@property (nonatomic, readwrite, assign) uint8_t twodSphereVersion;
@property (nonatomic, readwrite, assign) uint8_t twodBitsPrecision;
@property (nonatomic, readwrite, assign) double twodLocationMin;
@property (nonatomic, readwrite, assign) double twodLocationMax;
@property (nonatomic, readwrite, assign) double haystackBucketSize;

- (instancetype)init;
- (instancetype)initWithTwodSphereVersion:(uint8_t)twodSphereVersion
                        twodBitsPercision:(uint8_t)twodBitsPercision
                          twodLocationMin:(double)twodLocationMin
                          twodLocationMax:(double)twodLocationMax
                       haystackBucketSize:(double)haystackBucketSize;

@end

@interface MODIndexOpt : NSObject

@property (nonatomic, readwrite, assign) BOOL isInitialized;
@property (nonatomic, readwrite, assign) BOOL background;
@property (nonatomic, readwrite, assign) BOOL unique;
@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, assign) BOOL dropDups;
@property (nonatomic, readwrite, assign) BOOL sparse;
@property (nonatomic, readwrite, assign) int32_t expireAfterSeconds;
@property (nonatomic, readwrite, assign) int32_t v;
@property (nonatomic, readwrite, strong) MODSortedDictionary *weights;
@property (nonatomic, readwrite, strong) NSString *defaultLanguage;
@property (nonatomic, readwrite, strong) NSString *languageOverride;
@property (nonatomic, readwrite, strong) MODIndexOptGeo *geoOptions;

- (instancetype)init;

@end

