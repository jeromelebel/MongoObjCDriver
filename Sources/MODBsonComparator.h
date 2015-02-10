//
//  MODBsonComparator.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 05/12/2013.
//
//

#import <Foundation/Foundation.h>

@interface MODBsonComparator : NSObject

@property (nonatomic, readonly, strong) NSArray *differences;

- (instancetype)initWithBsonData1:(NSData *)bson1 bsonData2:(NSData *)bson2;
- (BOOL)compare;

@end
