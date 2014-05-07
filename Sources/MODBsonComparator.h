//
//  MODBsonComparator.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 05/12/2013.
//
//

#import <Foundation/Foundation.h>

@interface MODBsonComparator : NSObject
{
    NSArray                 *_differences;
}

@property (nonatomic, readonly, assign) NSData *bsonData1;
@property (nonatomic, readonly, assign) NSData *bsonData2;
@property (nonatomic, readonly, strong) NSArray *differences;

- (id)initWithBsonData1:(NSData *)bson1 bsonData2:(NSData *)bson2;
- (BOOL)compare;

@end
