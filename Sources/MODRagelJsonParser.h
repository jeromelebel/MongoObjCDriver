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
    int                     _allowNan;
    const char              *_memo;
    
    NSError                 *_error;
}

+ (id)objectsFromJson:(NSString *)source withError:(NSError **)error;
- (const char *)_parseValueWithPointer:(const char *)p endPointer:(const char *)pe result:(id *)result;
- (const char *)_parseObjectIdWithPointer:(const char *)p endPointer:(const char *)pe result:(MODObjectId **)result;
@end
