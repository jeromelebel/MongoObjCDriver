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

- (instancetype)initWithCollectionName:(NSString *)collectionName objectId:(MODObjectId *)objectId;
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
    MOD_SUPER_DEALLOC();
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    NSString *result;
    NSString *collectionName = self.collectionName?self.collectionName:@"";
    
    if (pretty) {
        result = [NSString stringWithFormat:@"DBPointer(\"%@\", \"%@\")", [MODClient escapeQuotesForString:collectionName], self.objectId.stringValue];
    } else {
        result = [NSString stringWithFormat:@"DBPointer(\"%@\",\"%@\")", [MODClient escapeQuotesForString:collectionName], self.objectId.stringValue];
    }
    return result;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return (self.collectionName == [object collectionName]
                    || (self.collectionName != nil
                        && [object collectionName] != nil
                        && [self.collectionName isEqualToString:[object collectionName]]))
                && [[object objectId] isEqual:self.objectId];
    }
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, %@, %@>", self.class, self, self.collectionName, self.objectId.stringValue];
}

@end
