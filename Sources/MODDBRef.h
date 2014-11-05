//
//  MODDBRef.h
//  MongoHub
//
//  Created by Jérôme Lebel on 29/09/2011.
//

#import <Foundation/Foundation.h>

@class MODObjectId;

@interface MODDBRef : NSObject
{
    NSString                    *_collectionName;
    MODObjectId                 *_objectId;
    NSString                    *_databaseName;
}
@property (nonatomic, readonly, strong) NSString *absoluteCollectionName;
@property (nonatomic, readonly, strong) NSString *collectionName;
@property (nonatomic, readonly, strong) NSString *databaseName;
@property (nonatomic, readonly, strong) MODObjectId *objectId;

- (instancetype)initWithAbsoluteCollectionName:(NSString *)absoluteCollectionName objectId:(MODObjectId *)objectId;
- (instancetype)initWithDatabaseName:(NSString *)databaseName collectionName:(NSString *)collectionName objectId:(MODObjectId *)objectId;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@end
