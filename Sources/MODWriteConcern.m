//
//  MODWriteConcern.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 27/08/2014.
//
//

#import "MODWriteConcern.h"
#import "MODWriteConcern-private.h"

@interface MODWriteConcern ()
@property (nonatomic, assign, readwrite) BOOL fileSync;
@property (nonatomic, assign, readwrite) BOOL journal;
@property (nonatomic, assign, readwrite) int32_t w;
@property (nonatomic, assign, readwrite) int32_t wtimeout;
@property (nonatomic, strong, readwrite) NSString *wtag;
@property (nonatomic, strong, readwrite) id compiled;

@end

@implementation MODWriteConcern

@synthesize mongocWriteConcern = _mongocWriteConcern;

+ (instancetype)writeConcernWithMongocWriteConcern:(const mongoc_write_concern_t *)mongocWriteConcern
{
    return [[[self alloc] initWithMongocWriteConcern:mongocWriteConcern] autorelease];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.mongocWriteConcern = mongoc_write_concern_new();
    }
    return self;
}

- (instancetype)initWithFileSync:(BOOL)fileSync journal:(BOOL)journal w:(int32_t)w wtimeout:(int32_t)wtimeout wtag:(NSString *)wtag compiled:(id)compiled
{
    if (self = [self init]) {
        self.fileSync = fileSync;
        self.journal = journal;
        self.w = w;
        self.wtimeout = wtimeout;
        self.wtag = wtag;
        self.compiled = compiled;
    }
    return self;
}

- (instancetype)initWithMongocWriteConcern:(const mongoc_write_concern_t *)mongocWriteConcern
{
    self = [self init];
    if (self) {
        mongoc_write_concern_destroy(self.mongocWriteConcern);
        self.mongocWriteConcern = mongoc_write_concern_copy(mongocWriteConcern);
    }
    return self;
}

- (void)dealloc
{
    mongoc_write_concern_destroy(self.mongocWriteConcern);
    [super dealloc];
}

- (BOOL)fileSync
{
    return mongoc_write_concern_get_fsync(self.mongocWriteConcern);
}

- (void)setFileSync:(BOOL)fsync
{
    mongoc_write_concern_set_fsync(self.mongocWriteConcern, fsync);
}

- (BOOL)journal
{
    return mongoc_write_concern_get_journal(self.mongocWriteConcern);
}

- (void)setJournal:(BOOL)journal
{
    mongoc_write_concern_set_journal(self.mongocWriteConcern, journal);
}

- (int32_t)w
{
    return mongoc_write_concern_get_w(self.mongocWriteConcern);
}

- (void)setW:(int32_t)w
{
    mongoc_write_concern_set_w(self.mongocWriteConcern, w);
}

- (int32_t)wtimeout
{
    return mongoc_write_concern_get_wtimeout(self.mongocWriteConcern);
}

- (void)setWtimeout:(int32_t)wtimeout
{
    mongoc_write_concern_set_wtimeout(self.mongocWriteConcern, wtimeout);
}

- (NSString *)wtag
{
    
    return [NSString stringWithUTF8String:mongoc_write_concern_get_wtag(self.mongocWriteConcern)];
}

- (void)setWtag:(NSString *)wtag
{
    mongoc_write_concern_set_wtag(self.mongocWriteConcern, wtag.UTF8String);
}

- (id)compiled
{
    return nil;
}

- (void)setCompiled:(id)compiled
{
    
}

@end
