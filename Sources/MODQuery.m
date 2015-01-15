//
//  MODQuery.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 02/09/2011.
//

#import "MongoObjCDriver-private.h"

@interface MODQuery ()
@property (nonatomic, readwrite, strong) id<NSObject> owner;
@property (nonatomic, readwrite, strong) NSString *name;
@property (nonatomic, readwrite, strong) NSDictionary *parameters;
@end

@implementation MODQuery

@synthesize owner = _owner;
@synthesize name = _name;
@synthesize parameters = _parameters;
@synthesize userInfo = _userInfo;
@synthesize startDate = _startDate;
@synthesize endDate = _endDate;
@synthesize error = _error;
@synthesize canceled = _canceled;
@synthesize result = _result;

- (instancetype)initWithOwner:(id<NSObject>)owner name:(NSString *)name parameters:(NSDictionary *)parameters;
{
    NSParameterAssert(owner);
    NSParameterAssert(name);
    if (self = [super init]) {
        self.owner = owner;
        self.name = name;
        self.parameters = parameters;
        self.userInfo = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)dealloc
{
    [self removeBlockOperation];
    self.startDate = nil;
    self.endDate = nil;
    self.userInfo = nil;
    self.owner = nil;
    self.name = nil;
    self.parameters = nil;
    self.error = nil;
    self.result = nil;
    MOD_SUPER_DEALLOC();
}

- (void)cancel
{
    _canceled = YES;
    [self.blockOperation cancel];
    [self removeBlockOperation];
}

- (void)starts
{
    NSAssert(self.startDate == nil, @"already started");
    NSAssert(self.endDate == nil, @"weird");
    self.startDate = [NSDate date];
}

- (void)endsWithError:(NSError *)error
{
    if (!self.error) self.error = error;
    NSAssert(self.startDate != nil, @"needs to be started");
    NSAssert(self.endDate == nil, @"already ended");
    self.endDate = [NSDate date];
}

- (NSTimeInterval)duration
{
    return [self.endDate timeIntervalSinceDate:self.startDate];
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
        operation = MOD_RETAIN(_blockOperation);
    }
    [operation waitUntilFinished];
    MOD_RELEASE(operation);
}

@end
