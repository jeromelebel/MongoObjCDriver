//
//  MODDocumentComparator.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 16/01/2014.
//
//

#import <Foundation/Foundation.h>

@class MODSortedMutableDictionary;

@interface MODDocumentComparator : NSObject
{
    MODSortedMutableDictionary            *_document1;
    MODSortedMutableDictionary            *_document2;
    NSArray                                 *_differences;
}

@property (nonatomic, readonly, strong) MODSortedMutableDictionary *document1;
@property (nonatomic, readonly, strong) MODSortedMutableDictionary *document2;
@property (nonatomic, readonly, strong) NSArray *differences;

- (id)initWithDocument1:(MODSortedMutableDictionary *)document1 document2:(MODSortedMutableDictionary *)document2;
- (BOOL)compare;

@end
