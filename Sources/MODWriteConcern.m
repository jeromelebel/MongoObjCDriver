//
//  MODWriteConcern.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 27/08/2014.
//
//

#import "MODWriteConcern.h"

@interface MODWriteConcern ()
@property (nonatomic, assign, readwrite) BOOL fsync;
@property (nonatomic, assign, readwrite) BOOL journal;
@property (nonatomic, assign, readwrite) int32_t w;
@property (nonatomic, assign, readwrite) int32_t wtimeout;
@property (nonatomic, strong, readwrite) NSString *wtag;
@property (nonatomic, assign, readwrite) BOOL frozen;
@property (nonatomic, strong, readwrite) id compiled;

@end

@implementation MODWriteConcern

@synthesize fsync = _fsync;
@synthesize journal = _journal;
@synthesize w = _w;
@synthesize wtimeout = _wtimeout;
@synthesize wtag = _wtag;
@synthesize frozen = _frozen;
@synthesize compiled = _compiled;

- (instancetype)initWithFsync:(BOOL)fsync journal:(BOOL)journal w:(int32_t)w wtimeout:(int32_t)wtimeout wtag:(NSString *)wtag frozen:(BOOL)frozen compiled:(id)compiled
{
    if (self = [self init]) {
        self.fsync = fsync;
        self.journal = journal;
        self.w = w;
        self.wtimeout = wtimeout;
        self.wtag = wtag;
        self.frozen = frozen;
        self.compiled = compiled;
    }
    return self;
}

- (void)dealloc
{
    self.wtag = nil;
    self.compiled = nil;
    [super dealloc];
}

@end
