//
//  MODSortedDictionary-private.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 05/12/2014.
//
//

@interface MODSortedDictionary ()
@property (nonatomic, readwrite, strong) NSDictionary *content;
@property (nonatomic, readwrite, strong) NSArray *sortedKeys;

@end
