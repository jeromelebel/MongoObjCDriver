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
        if (databaseName.length == 0) databaseName = nil;
        if (collectionName.length == 0) collectionName = nil;
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
            self = [self initWithDatabaseName:nil collectionName:elements[0] objectId:objectId];
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
    NSString *collectionName = self.collectionName?self.collectionName:@"";
    NSString *databaseName = self.databaseName?self.databaseName:@"";
    
    if (!strictJSON && pretty) {
        if (self.databaseName) {
            result = [NSString stringWithFormat:@"DBRef(\"%@\", \"%@\")", [MODClient escapeQuotesForString:[NSString stringWithFormat:@"%@.%@", self.databaseName, collectionName]], self.objectId.stringValue];
        } else {
            result = [NSString stringWithFormat:@"DBRef(\"%@\", \"%@\")", [MODClient escapeQuotesForString:[NSString stringWithFormat:@"%@", collectionName]], self.objectId.stringValue];
        }
    } else if (!strictJSON && !pretty) {
        if (self.databaseName) {
            result = [NSString stringWithFormat:@"DBRef(\"%@\",\"%@\")", [MODClient escapeQuotesForString:[NSString stringWithFormat:@"%@.%@", self.databaseName, collectionName]], self.objectId.stringValue];
        } else {
            result = [NSString stringWithFormat:@"DBRef(\"%@\",\"%@\")", [MODClient escapeQuotesForString:[NSString stringWithFormat:@"%@", collectionName]], self.objectId.stringValue];
        }
    } else if (pretty) {
        result = [NSString stringWithFormat:@"{ \"$ref\" : \"%@\", \"$id\" : \"%@\", \"$db\" : \"%@\" }", [MODClient escapeQuotesForString:collectionName], self.objectId.stringValue, [MODClient escapeQuotesForString:databaseName]];
    } else {
        result = [NSString stringWithFormat:@"{\"$ref\":\"%@\",\"$id\":\"%@\",\"$db\":\"%@\"}", [MODClient escapeQuotesForString:collectionName], self.objectId.stringValue, [MODClient escapeQuotesForString:databaseName]];
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
                && (self.databaseName == [object databaseName]
                    || (self.databaseName != nil
                        && [object databaseName] != nil
                        && [self.databaseName isEqualToString:[object databaseName]]))
                && [[object objectId] isEqual:self.objectId];
    }
    return NO;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, %@.%@, %@>", self.class, self, self.databaseName, self.collectionName, self.objectId.stringValue];
}

@end
