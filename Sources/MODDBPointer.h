//
//  MODDBPointer.h
//  MongoHub
//
//  Created by Jérôme Lebel on 29/09/2011.
//

#import <Foundation/Foundation.h>

@class MODObjectId;

@interface MODDBPointer : NSObject

@property (nonatomic, copy, readonly) NSString *collectionName;
@property (nonatomic, strong, readonly) MODObjectId *objectId;

- (instancetype)initWithCollectionName:(NSString *)collectionName objectId:(MODObjectId *)objectId;
- (NSString *)jsonValueWithPretty:(BOOL)pretty strictJSON:(BOOL)strictJSON;

@end
