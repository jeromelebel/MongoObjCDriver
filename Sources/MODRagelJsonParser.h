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
    NSMutableArray          *_stack;
    int                     _maxNesting;
    int                     _currentNesting;
    
    NSError                 *_error;
    const char              *cStringBuffer;
}

+ (id)objectsFromJson:(NSString *)source withError:(NSError **)error;
@end
