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

@interface MODServer()

@property(nonatomic, readwrite, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readwrite, assign) mongo_ptr mongo;

- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)user password:(NSString *)password mongoQuery:(MODQuery *)mongoQuery;
- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password error:(NSError **)error;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withTarget:(id)target callback:(SEL)callbackSelector;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withCallbackBlock:(void (^)(void))callbackBlock;
- (MODQuery *)addQueryInQueue:(void (^)(MODQuery *currentMongoQuery))block;

@end

@interface MODServer(utils)

+ (NSInteger)bsonFromJson:(bson *)bsonResult json:(NSString *)json error:(NSError **)error;
+ (id)objectsFromJson:(NSString *)json error:(NSError **)error;
+ (NSError *)errorWithErrorDomain:(NSString *)errorDomain code:(NSInteger)code descriptionDetails:(NSString *)descriptionDetails;
+ (NSError *)errorFromMongo:(mongo_ptr)mongo;
+ (NSDictionary *)objectsFromBson:(bson *)bsonObject;

@end

@interface MODDatabase()

@property(nonatomic, readonly, assign) mongo_ptr mongo;

- (id)initWithMongoServer:(MODServer *)mongoServer databaseName:(NSString *)databaseName;
- (BOOL)authenticateSynchronouslyWithMongoQuery:(MODQuery *)mongoQuery;
- (BOOL)authenticateSynchronouslyWithError:(NSError **)error;
- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withCallbackBlock:(void (^)(void))callbackBlock;

@end

@interface MODCollection()

@property(nonatomic, readonly, assign) mongo_ptr mongo;

- (id)initWithMongoDatabase:(MODDatabase *)mongoDatabase collectionName:(NSString *)collectionName;

@end

@interface MODCursor()

@property(nonatomic, readwrite, retain) NSString *query;
@property(nonatomic, readwrite, retain) NSArray *fields;
@property(nonatomic, readwrite, assign) NSUInteger skip;
@property(nonatomic, readwrite, assign) NSUInteger limit;
@property(nonatomic, readwrite, retain) NSString * sort;

- (id)initWithMongoCollection:(MODCollection *)mongoCollection;
- (NSDictionary *)nextDocumentAsynchronouslyWithError:(NSError **)error;

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
