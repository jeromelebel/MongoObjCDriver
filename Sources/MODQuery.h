//
//  MODQuery.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/2011.
//

#import <Foundation/Foundation.h>

@class MODQuery;

@protocol MODQueryCallbackTarget<NSObject>
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery;
@end

@interface MODQuery : NSObject
{
    id<NSObject>        _owner;
    NSString            *_name;
    NSDictionary        *_parameters;
    NSBlockOperation    *_blockOperation;
    NSError             *_error;
    NSMutableDictionary *_userInfo;
    NSDate              *_startDate;
    NSDate              *_endDate;
    NSMutableArray      *_callbackTargets;
    BOOL                _canceled;
}

- (instancetype)initWithOwner:(id<NSObject>)owner name:(NSString *)name parameters:(NSDictionary *)parameters;
- (void)waitUntilFinished;
- (void)addCallbackWithTarget:(id<MODQueryCallbackTarget>)target;
- (void)cancel;

@property (nonatomic, readonly, strong) id<NSObject> owner;
@property (nonatomic, readonly, strong) NSString *name;
@property (nonatomic, readonly, strong) NSDictionary *parameters;

@property (nonatomic, readonly, strong) NSError *error;
@property (nonatomic, readwrite, strong) NSMutableDictionary *userInfo;
@property (nonatomic, readonly, strong) NSDate *startDate;
@property (nonatomic, readonly, strong) NSDate *endDate;
@property (nonatomic, readonly, assign) NSTimeInterval duration;
@property (nonatomic, readonly, assign) BOOL canceled;

@end
