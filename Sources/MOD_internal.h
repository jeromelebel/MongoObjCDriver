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
#import "MODCursor.h"
#import "MODQuery.h"
#import "mongo.h"
#import "json.h"

void bson_from_json(bson *bsonResult, const char *mainKey, const char *json, size_t length, int *error, size_t *totalProcessed);

@interface MODServer()

@property(nonatomic, readwrite, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readwrite, assign) mongo_ptr mongo;

+ (NSDictionary *)objectsFromBson:(bson *)bsonObject;

- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password mongoQuery:(MODQuery *)mongoQuery;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withTarget:(id)target callback:(SEL)callbackSelector;
- (MODQuery *)addQueryInQueue:(void (^)(MODQuery *currentMongoQuery))block;

@end

@interface MODDatabase()

@property(nonatomic, readonly, assign) mongo_ptr mongo;

- (id)initWithMongoServer:(MODServer *)mongoServer databaseName:(NSString *)databaseName;
- (BOOL)authenticateSynchronouslyWithMongoQuery:(MODQuery *)mongoQuery;

@end

@interface MODCollection()

@property(nonatomic, readonly, assign) mongo_ptr mongo;

@end

@interface MODCursor()

@property(nonatomic, readwrite, retain) NSString *query;
@property(nonatomic, readwrite, retain) NSArray *fields;
@property(nonatomic, readwrite, assign) NSUInteger skip;
@property(nonatomic, readwrite, assign) NSUInteger limit;
@property(nonatomic, readwrite, retain) NSString * sort;

- (id)initWithMongoCollection:(MODCollection *)mongoCollection;
- (void)_startCursorWithQuery:(NSString *)query fields:(NSArray *)fields skip:(NSUInteger)skip limit:(NSUInteger)limit sort:(NSString *)sort;

@end

@interface MODQuery()

- (void)starts;
- (void)ends;
- (void)removeBlockOperation;

@property (nonatomic, readwrite, retain) NSDictionary *parameters;
@property (nonatomic, readwrite, retain) NSMutableDictionary *mutableParameters;
@property (nonatomic, readwrite, assign) NSBlockOperation *blockOperation;
@property (nonatomic, readwrite, retain) NSError *error;

@end
