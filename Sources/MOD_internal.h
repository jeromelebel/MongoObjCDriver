//
//  MOD_internal.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MODServer.h"
#import "MODQuery.h"

@interface MODServer()

@property(nonatomic, readwrite, assign, getter=isConnected) BOOL connected;

- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password mongoQuery:(MODQuery *)mongoQuery;
- (BOOL)authUser:(NSString *)user 
            pass:(NSString *)pass 
        database:(NSString *)db;
- (MODQuery *)addQueryInQueue:(void (^)(MODQuery *currentMongoQuery))block;

@end

@interface MODQuery()

- (void)starts;
- (void)ends;
- (void)removeBlockOperation;

@property (nonatomic, readwrite, retain) NSDictionary *parameters;
@property (nonatomic, readwrite, retain) NSMutableDictionary *mutableParameters;
@property (nonatomic, readwrite, assign) NSBlockOperation *blockOperation;

@end
