//
//  MODQuery.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@interface MODQuery ()
@property (nonatomic, readwrite, strong) id<NSObject> owner;
@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSDictionary *parameters;
@end

@implementation MODQuery

@synthesize owner = _owner, name = _name, parameters = _parameters, userInfo = _userInfo, startDate = _startDate, endDate = _endDate, error = _error, canceled = _canceled;

- (instancetype)initWithOwner:(id<NSObject>)owner name:(NSString *)name parameters:(NSDictionary *)parameters;
{
    NSParameterAssert(owner);
    NSParameterAssert(name);
    if (self = [super init]) {
        self.owner = owner;
        self.name = name;
        self.parameters = parameters;
        _userInfo = [[NSMutableDictionary alloc] init];
        _callbackTargets = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [self removeBlockOperation];
    [_startDate release];
    [_endDate release];
    [_userInfo release];
    [_callbackTargets release];
    self.owner = nil;
    self.name = nil;
    self.parameters = nil;
    self.error = nil;
    [super dealloc];
}

- (void)cancel
{
    _canceled = YES;
}

- (void)starts
{
    NSAssert(_startDate == nil, @"already started");
    NSAssert(_endDate == nil, @"weird");
    _startDate = [[NSDate alloc] init];
}

- (void)endsWithError:(NSError *)error
{
    if (!self.error) self.error = error;
    NSAssert(_startDate != nil, @"needs to be started");
    NSAssert(_endDate == nil, @"already ended");
    _endDate = [[NSDate alloc] init];
    for (id<MODQueryCallbackTarget> target in _callbackTargets) {
        [target mongoQueryDidFinish:self];
    }
}

- (NSTimeInterval)duration
{
    return [_endDate timeIntervalSinceDate:_startDate];
}

- (void)removeBlockOperation
{
    @synchronized(self) {
        [_blockOperation removeObserver:self forKeyPath:@"isFinished"];
        _blockOperation = nil;
    }
}

- (NSBlockOperation *)blockOperation
{
    return _blockOperation;
}

- (void)setBlockOperation:(NSBlockOperation *)blockOperation
{
    _blockOperation = blockOperation;
    [_blockOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (_blockOperation == object) {
        [self removeBlockOperation];
    }
}

- (void)waitUntilFinished
{
    NSBlockOperation *operation;
    
    @synchronized(self) {
        operation = [_blockOperation retain];
    }
    [operation waitUntilFinished];
    [operation release];
}

- (void)addCallbackWithTarget:(id<MODQueryCallbackTarget>)target
{
    [_callbackTargets addObject:target];
}

@end
