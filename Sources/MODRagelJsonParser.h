//
//  MODRagelJsonParser.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 01/09/2013.
//
//

#import <Foundation/Foundation.h>

@class MODObjectId;

@interface MODRagelJsonParser : NSObject
{
    int                     _maxNesting;
    int                     _currentNesting;
    
    const char              *_cStringBuffer;
    NSError                 *_error;
}
@property (nonatomic, strong, readonly) NSError *error;

+ (id)objectsFromJson:(NSString *)source withError:(NSError **)error;

- (id)parseJson:(NSString *)source withError:(NSError **)error;
@end
