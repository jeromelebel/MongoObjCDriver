//
//  MODBsonComparator.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 05/12/2013.
//
//

#import <Foundation/Foundation.h>

@interface MODBsonComparator : NSObject
{
    NSArray                 *_differences;
    void                    *_bson1;
    void                    *_bson2;
    void                    *_bson1ToDestroy;
    void                    *_bson2ToDestroy;
}

@property (nonatomic, readonly, strong) NSArray *differences;

- (instancetype)initWithBsonData1:(NSData *)bson1 bsonData2:(NSData *)bson2;
- (BOOL)compare;

@end
