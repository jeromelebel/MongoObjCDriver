//
//  MODDocumentComparator.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 16/01/2014.
//
//

#import <Foundation/Foundation.h>

@class MODSortedDictionary;

@interface MODDocumentComparator : NSObject
{
    MODSortedDictionary            *_document1;
    MODSortedDictionary            *_document2;
    NSArray                                 *_differences;
}

@property (nonatomic, readonly, strong) MODSortedDictionary *document1;
@property (nonatomic, readonly, strong) MODSortedDictionary *document2;
@property (nonatomic, readonly, strong) NSArray *differences;

- (instancetype)initWithDocument1:(MODSortedDictionary *)document1 document2:(MODSortedDictionary *)document2;
- (BOOL)compare;

@end
