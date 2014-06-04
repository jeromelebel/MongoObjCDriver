//
//  MODClient.h
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MODMongoErrorDomain @"mod.mongo"
#define MODMongoCursorErrorDomain @"mod.mongocursor"
#define MODJsonErrorDomain @"mod.json"
#define MODJsonParserErrorDomain @"mod.jsonparser"

@class MODQuery;
@class MODDatabase;
@class MODClient;
@class MODSortedMutableDictionary;

typedef struct mongo_replset            *mongo_replset_ptr;

@interface MODClient : NSObject
{
    mongo_replset_ptr                   _replicaSet;
    void                                *_mongocClient;
    
    BOOL                                _connected;
    NSOperationQueue                    *_operationQueue;
}
@property (nonatomic, readonly, assign, getter = isConnected) BOOL connected;

+ (MODClient *)clientWihtURLString:(NSString *)urlString;
+ (uint16_t)defaultPort;

// can return nil if the URI is invalid
- (id)initWithURIString:(NSString *)urlString;
- (id)initWithURICString:(const char *)urlCString;

- (id)copy;

- (MODQuery *)serverStatusWithCallback:(void (^)(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery))callback;
- (MODQuery *)fetchDatabaseListWithCallback:(void (^)(NSArray *list, MODQuery *mongoQuery))callback;

- (MODDatabase *)databaseForName:(NSString *)databaseName;

@end

@interface MODClient (utils)
+ (NSString *)escapeQuotesForString:(NSString *)string;
+ (NSString *)escapeSlashesForString:(NSString *)string;
+ (NSString *)convertObjectToJson:(MODSortedMutableDictionary *)object pretty:(BOOL)pretty strictJson:(BOOL)strictJson;
+ (BOOL)isEqualWithJson:(NSString *)json toBsonData:(NSData *)document info:(NSDictionary **)info;
+ (BOOL)isEqualWithJson:(NSString *)json toDocument:(id)document info:(NSDictionary **)info;
+ (NSArray *)findAllDifferencesInObject1:(id)object1 object2:(id)object2;
@end