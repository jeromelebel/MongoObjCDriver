//
//  MODDBPointer.m
//  MongoHub
//
//  Created by Jérôme Lebel on 29/09/2011.
//

#import "MongoObjCDriver-private.h"

@interface MODDBPointer ()
@property (nonatomic, readwrite, strong) NSString *collectionName;
@property (nonatomic, readwrite, strong) MODObjectId *objectId;

@end

@implementation MODDBPointer

@synthesize collectionName = _collectionName;
@synthesize objectId = _objectId;

- (id)initWithCollectionName:(NSString *)collectionName objectId:(MODObjectId *)objectId
{
    if (self = [self init]) {
        self.collectionName = collectionName;
        self.objectId = objectId;
    }
    return self;
}

- (void)dealloc
{
    self.collectionName = nil;
    self.objectId = nil;
    [super dealloc];
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    NSString *result;
    
    if (!strictJSON) {
        result = [NSString stringWithFormat:@"DBPointer(\"%@\", \"%@\")", self.collectionName, self.objectId.stringValue];
    } else if (pretty) {
        result = [NSString stringWithFormat:@"{ \"$collection\" : \"%@\", \"$oid\" : \"%@\" }", self.collectionName, self.objectId.stringValue];
    } else {
        result = [NSString stringWithFormat:@"{\"$collection\":\"%@\",\"$oid\":\"%@\"}", self.collectionName, self.objectId.stringValue];
    }
    return result;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [[object collectionName] isEqual:self.collectionName] && [[object objectId] isEqual:self.objectId];
    }
    return NO;
}

@end
