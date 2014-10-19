//
//  MODDBRef.m
//  MongoHub
//
//  Created by Jérôme Lebel on 29/09/2011.
//

#import "MongoObjCDriver-private.h"

@interface MODDBRef ()
@property (nonatomic, readwrite, strong) NSString *collectionName;
@property (nonatomic, readwrite, strong) MODObjectId *objectId;
@property (nonatomic, readwrite, strong) NSString *databaseName;

@end

@implementation MODDBRef

@synthesize collectionName = _collectionName;
@synthesize objectId = _objectId;
@synthesize databaseName = _databaseName;

- (instancetype)initWithCollectionName:(NSString *)collectionName objectId:(MODObjectId *)objectId databaseName:(NSString *)databaseName
{
    if (self = [self init]) {
        self.collectionName = collectionName;
        self.objectId = objectId;
        self.databaseName = databaseName;
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
    
    if (!strictJSON && pretty) {
        if (self.databaseName) {
            result = [NSString stringWithFormat:@"DBRef(\"%@\", \"%@\", \"%@\")", [MODClient escapeQuotesForString:self.collectionName], self.objectId.stringValue, [MODClient escapeQuotesForString:self.databaseName]];
        } else {
            result = [NSString stringWithFormat:@"DBRef(\"%@\", \"%@\")", [MODClient escapeQuotesForString:self.collectionName], self.objectId.stringValue];
        }
    } else if (!strictJSON && !pretty) {
        if (self.databaseName) {
            result = [NSString stringWithFormat:@"DBRef(\"%@\",\"%@\",\"%@\")", [MODClient escapeQuotesForString:self.collectionName], self.objectId.stringValue, [MODClient escapeQuotesForString:self.databaseName]];
        } else {
            result = [NSString stringWithFormat:@"DBRef(\"%@\",\"%@\")", [MODClient escapeQuotesForString:self.collectionName], self.objectId.stringValue];
        }
    } else if (pretty) {
        if (self.databaseName) {
            result = [NSString stringWithFormat:@"{ \"$ref\" : \"%@\", \"$id\" : \"%@\", \"$db\" : \"%@\" }", [MODClient escapeQuotesForString:self.collectionName], self.objectId.stringValue, [MODClient escapeQuotesForString:self.databaseName]];
        } else {
            result = [NSString stringWithFormat:@"{ \"$ref\" : \"%@\", \"$id\" : \"%@\" }", [MODClient escapeQuotesForString:self.collectionName], self.objectId.stringValue];
        }
    } else {
        if (self.databaseName) {
            result = [NSString stringWithFormat:@"{\"$ref\":\"%@\",\"$id\":\"%@\",\"$db\":\"%@\"}", [MODClient escapeQuotesForString:self.collectionName], self.objectId.stringValue, [MODClient escapeQuotesForString:self.databaseName]];
        } else {
            result = [NSString stringWithFormat:@"{\"$ref\":\"%@\",\"$id\":\"%@\"}", [MODClient escapeQuotesForString:self.collectionName], self.objectId.stringValue];
        }
    }
    return result;
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [[object collectionName] isEqual:self.collectionName] && [[object objectId] isEqual:self.objectId] && (self.databaseName == [object databaseName] || (self.databaseName != nil && [object databaseName] != nil && [self.databaseName isEqualToString:[object databaseName]]));
    }
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, %@, %@, %@>", self.class, self, self.collectionName, self.objectId.stringValue, self.databaseName];
}

@end
