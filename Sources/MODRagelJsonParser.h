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
    int                     _quirks_mode;
    const char              *_memo;
    char                    _create_additions;
    char                    *_match_string;
}

+ (id)objectsFromJson:(NSString *)source error:(NSError **)error;
@end
