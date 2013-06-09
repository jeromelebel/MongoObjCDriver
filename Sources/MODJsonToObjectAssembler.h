//
//  MODJsonToObjectAssembler.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 09/06/13.
//
//

#import <Foundation/Foundation.h>

@interface MODJsonToObjectAssembler : NSObject
{
    
}
@property (nonatomic, retain, readonly) id mainObject;

+ (id)objectsFromJson:(NSString *)json error:(NSError **)error;
@end
