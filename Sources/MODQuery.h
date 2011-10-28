//
//  MODQuery.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MODQuery;

@protocol MODQueryCallbackTarget<NSObject>
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery;
@end

@interface MODQuery : NSObject
{
    NSBlockOperation    *_blockOperation;
    NSError             *_error;
    NSMutableDictionary *_userInfo;
    NSMutableDictionary *_parameters;
    NSDate              *_startDate;
    NSDate              *_endDate;
    NSMutableArray      *_callbackTargets;
    BOOL                _canceled;
}

- (void)waitUntilFinished;
- (void)addCallbackWithTarget:(id<MODQueryCallbackTarget>)target;
- (void)cancel;

@property (nonatomic, readonly, retain) NSError *error;
@property (nonatomic, readonly, retain) NSDictionary *parameters;
@property (nonatomic, readwrite, retain) NSMutableDictionary *userInfo;
@property (nonatomic, readonly, retain) NSDate *startDate;
@property (nonatomic, readonly, retain) NSDate *endDate;
@property (nonatomic, readonly, assign) NSTimeInterval duration;
@property (nonatomic, readonly, assign) BOOL canceled;

@end
