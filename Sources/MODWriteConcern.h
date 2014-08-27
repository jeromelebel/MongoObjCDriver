//
//  MODWriteConcern.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 27/08/2014.
//
//

#import <Foundation/Foundation.h>

@interface MODWriteConcern : NSObject
{
    BOOL                            _fsync;
    BOOL                            _journal;
    int32_t                         _w;
    int32_t                         _wtimeout;
    NSString                        *_wtag;
    BOOL                            _frozen;
    id                              _compiled;
}
@property (nonatomic, assign, readonly) BOOL fsync;
@property (nonatomic, assign, readonly) BOOL journal;
@property (nonatomic, assign, readonly) int32_t w;
@property (nonatomic, assign, readonly) int32_t wtimeout;
@property (nonatomic, strong, readonly) NSString *wtag;
@property (nonatomic, assign, readonly) BOOL frozen;
@property (nonatomic, strong, readonly) id compiled;

- (instancetype)initWithFsync:(BOOL)fsync journal:(BOOL)journal w:(int32_t)w wtimeout:(int32_t)wtimeout wtag:(NSString *)wtag frozen:(BOOL)frozen compiled:(id)compiled;

@end
