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

- (instancetype)initWithDatabaseName:(NSString *)databaseName collectionName:(NSString *)collectionName objectId:(MODObjectId *)objectId
{
    if (self = [self init]) {
        if (!databaseName) databaseName = @"";
        if (!collectionName) collectionName = @"";
        self.databaseName = databaseName;
        self.collectionName = collectionName;
        self.objectId = objectId;
    }
    return self;
}

- (instancetype)initWithAbsoluteCollectionName:(NSString *)absoluteCollectionName objectId:(MODObjectId *)objectId
{
    NSArray *elements = [absoluteCollectionName componentsSeparatedByString:@"."];
    
    switch (elements.count) {
        case 0:
            self = [self initWithDatabaseName:nil collectionName:nil objectId:objectId];
            break;

        case 1:
            self = [self initWithDatabaseName:elements[0] collectionName:nil objectId:objectId];
            break;
            
        default:
            self = [self initWithDatabaseName:elements[0] collectionName:elements[1] objectId:objectId];
            break;
    }
    return self;
}

- (void)dealloc
{
    self.collectionName = nil;
    self.objectId = nil;
    [super dealloc];
}

- (NSString *)absoluteCollectionName
{
    NSString *databaseName = self.databaseName?self.databaseName:@"";
    NSString *collectionName = self.collectionName?self.collectionName:@"";
    
    return [NSString stringWithFormat:@"%@.%@", databaseName, collectionName];
}

- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON
{
    NSString *result;
    
    if (!strictJSON && pretty) {
        if (self.collectionName.length > 0) {
            result = [NSString stringWithFormat:@"DBRef(\"%@\", \"%@\")", [MODClient escapeQuotesForString:[NSString stringWithFormat:@"%@.%@", self.databaseName, self.collectionName]], self.objectId.stringValue];
        } else {
            result = [NSString stringWithFormat:@"DBRef(\"%@\", \"%@\")", [MODClient escapeQuotesForString:[NSString stringWithFormat:@"%@", self.databaseName]], self.objectId.stringValue];
        }
    } else if (!strictJSON && !pretty) {
        if (self.collectionName.length > 0) {
            result = [NSString stringWithFormat:@"DBRef(\"%@\",\"%@\")", [MODClient escapeQuotesForString:[NSString stringWithFormat:@"%@.%@", self.databaseName, self.collectionName]], self.objectId.stringValue];
        } else {
            result = [NSString stringWithFormat:@"DBRef(\"%@\",\"%@\")", [MODClient escapeQuotesForString:[NSString stringWithFormat:@"%@", self.databaseName]], self.objectId.stringValue];
        }
    } else if (pretty) {
        result = [NSString stringWithFormat:@"{ \"$ref\" : \"%@\", \"$id\" : \"%@\", \"$db\" : \"%@\" }", [MODClient escapeQuotesForString:self.collectionName], self.objectId.stringValue, [MODClient escapeQuotesForString:self.databaseName]];
    } else {
        result = [NSString stringWithFormat:@"{\"$ref\":\"%@\",\"$id\":\"%@\",\"$db\":\"%@\"}", [MODClient escapeQuotesForString:self.collectionName], self.objectId.stringValue, [MODClient escapeQuotesForString:self.databaseName]];
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
    return [NSString stringWithFormat:@"<%@: %p, %@.%@, %@>", self.class, self, self.databaseName, self.collectionName, self.objectId.stringValue];
}

@end
