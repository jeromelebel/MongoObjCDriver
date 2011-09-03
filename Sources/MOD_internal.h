//
//  MOD_internal.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MODServer.h"
#import "MODDatabase.h"
#import "MODCollection.h"
#import "MODQuery.h"
#import "mongo.h"

@interface MODServer()

@property(nonatomic, readwrite, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readwrite, assign) mongo_ptr mongo;

+ (NSDictionary *)objectsFromBson:(bson *)bsonObject;

- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password mongoQuery:(MODQuery *)mongoQuery;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withTarget:(id)target callback:(SEL)callbackSelector;
- (MODQuery *)addQueryInQueue:(void (^)(MODQuery *currentMongoQuery))block;

@end

@interface MODDatabase()

- (id)initWithMongoServer:(MODServer *)mongoServer databaseName:(NSString *)databaseName;
- (BOOL)authenticateSynchronouslyWithMongoQuery:(MODQuery *)mongoQuery;

@end

@interface MODQuery()

- (void)starts;
- (void)ends;
- (void)removeBlockOperation;

@property (nonatomic, readwrite, retain) NSDictionary *parameters;
@property (nonatomic, readwrite, retain) NSMutableDictionary *mutableParameters;
@property (nonatomic, readwrite, assign) NSBlockOperation *blockOperation;

@end
