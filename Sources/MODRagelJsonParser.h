//
//  MODRagelJsonParser.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 01/09/13.
//
//

#import <Foundation/Foundation.h>

@class MODObjectId;

@interface MODRagelJsonParser : NSObject
{
    int                     _maxNesting;
    int                     _currentNesting;
    
    const char              *_cStringBuffer;
}
@property (nonatomic, strong, readonly) NSError *error;

+ (id)objectsFromJson:(NSString *)source withError:(NSError **)error;

- (id)parseJson:(NSString *)source withError:(NSError **)error;
@end
