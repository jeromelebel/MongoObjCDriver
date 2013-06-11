//
//  MODServer.h
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
@class MODServer;
@class MODSortedMutableDictionary;

typedef struct mongo_replset            *mongo_replset_ptr;
typedef struct mongo                    *mongo_ptr;

@interface MODServer : NSObject
{
    mongo_replset_ptr                   _replicaSet;
    mongo_ptr                           _mongo;
    
    BOOL                                _connected;
    NSOperationQueue                    *_operationQueue;
    NSString                            *_authDatabase;
    NSString                            *_userName;
    NSString                            *_password;
}

/**
 imported from mongo/bson/bsontypes.h
 
 the complete list of valid BSON types
 see also bsonspec.org
 */

typedef enum BSONType {
    /** smaller than all other types */
    MinKey=-1,
    /** end of object */
    EOO=0,
    /** double precision floating point value */
    NumberDouble=1,
    /** character string, stored in utf8 */
    String=2,
    /** an embedded object */
    Object=3,
    /** an embedded array */
    Array=4,
    /** binary data */
    BinData=5,
    /** Undefined type */
    Undefined=6,
    /** ObjectId */
    jstOID=7,
    /** boolean type */
    Bool=8,
    /** date type */
    Date=9,
    /** null type */
    jstNULL=10,
    /** regular expression, a pattern with options */
    RegEx=11,
    /** deprecated / will be redesigned */
    DBRef=12,
    /** deprecated / use CodeWScope */
    Code=13,
    /** a programming language (e.g., Python) symbol */
    Symbol=14,
    /** javascript code that can execute on the database server, with SavedContext */
    CodeWScope=15,
    /** 32 bit signed integer */
    NumberInt = 16,
    /** Updated to a Date with value next OpTime on insert */
    Timestamp = 17,
    /** 64 bit integer */
    NumberLong = 18,
    /** max type that is not MaxKey */
    JSTypeMax=18,
    /** larger than all other types */
    MaxKey=127
} real_bson_type;


- (void)copyWithCallback:(void (^)(MODServer *copyServer, MODQuery *mongoQuery))callback;

- (MODQuery *)connectWithHostName:(NSString *)host callback:(void (^)(BOOL connected, MODQuery *mongoQuery))callback;
- (MODQuery *)connectWithReplicaName:(NSString *)name hosts:(NSArray *)hosts callback:(void (^)(BOOL connected, MODQuery *mongoQuery))callback;
- (MODQuery *)fetchServerStatusWithCallback:(void (^)(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery))callback;
- (MODQuery *)fetchDatabaseListWithCallback:(void (^)(NSArray *list, MODQuery *mongoQuery))callback;

- (MODQuery *)dropDatabaseWithName:(NSString *)databaseName callback:(void (^)(MODQuery *mongoQuery))callback;

- (MODDatabase *)databaseForName:(NSString *)databaseName;

@property(nonatomic, readonly, assign, getter=isConnected) BOOL connected;
@property(nonatomic, readwrite, retain) NSString *userName;
@property(nonatomic, readwrite, retain) NSString *password;
@property(nonatomic, readwrite, retain) NSString *authDatabase;

@end

@interface MODServer(utils)
+ (NSString *)escapeQuotesForString:(NSString *)string;
+ (NSString *)escapeSlashesForString:(NSString *)string;
+ (NSString *)convertObjectToJson:(MODSortedMutableDictionary *)object pretty:(BOOL)pretty;
+ (void)compareJson:(NSString *)json document:(id)document;
+ (NSString *)findFirstDifferenceInObject:(id)object1 with:(id)object2;
@end