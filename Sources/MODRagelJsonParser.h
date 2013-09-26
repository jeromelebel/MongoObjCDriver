//
//  MODRagelJsonParser.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 01/09/13.
//
//

#import <Foundation/Foundation.h>

@interface MODRagelJsonParser : NSObject
{
    NSMutableArray          *_stack;
    BOOL                    _parsingName;
    int                     _maxNesting;
    int                     _currentNesting;
    int                     _allowNan;
    const char              *_memo;
}

+ (id)objectsFromJson:(NSString *)source error:(NSError **)error;
@end
