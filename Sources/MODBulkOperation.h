//
//  MODBulkOperation.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 17/10/2014.
//
//

#import <Foundation/Foundation.h>

@class MODCollection;
@class MODWriteConcern;
@class MODClient;

@interface MODBulkOperation : NSObject

@property (nonatomic, readwrite, strong) MODCollection *collection;
@property (nonatomic, readonly, assign) BOOL ordered;
@property (nonatomic, readwrite, strong) MODWriteConcern *writeConcern;
@property (nonatomic, readonly, assign) MODClient *client;

- (instancetype)initWithCollection:(MODCollection *)collection ordered:(BOOL)ordered writeConcern:(MODWriteConcern *)writeConcern;
- (void)insert:(MODSortedDictionary *)document;

@end
