//
//  MODDBPointer.h
//  MongoHub
//
//  Created by Jérôme Lebel on 29/09/2011.
//

#import <Foundation/Foundation.h>

@class MODObjectId;

@interface MODDBPointer : NSObject
{
    NSString                    *_collectionName;
    MODObjectId                 *_objectId;
    NSString                    *_databaseName;
}
@property (nonatomic, readonly, strong) NSString *collectionName;
@property (nonatomic, readonly, strong) NSString *databaseName;
@property (nonatomic, readonly, strong) MODObjectId *objectId;

- (instancetype)initWithCollectionName:(NSString *)collectionName objectId:(MODObjectId *)objectId databaseName:(NSString *)databaseName;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@end
