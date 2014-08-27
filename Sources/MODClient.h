//
//  MODClient.h
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 02/09/2011.
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
@class MODReadPreferences;
@class MODSSLOptions;
@class MODWriteConcern;

typedef struct mongo_replset            *mongo_replset_ptr;

typedef enum
{
    MODLogLevelError,
    MODLogLevelCritical,
    MODLogLevelWarning,
    MODLogLevelMessage,
    MODLogLevelInfo,
    MODLogLevelDebug,
    MODLogLevelTrace,
} MODLogLevel;

@interface MODClient : NSObject
{
    mongo_replset_ptr                   _replicaSet;
    void                                *_mongocClient;
    // we have to keept ssl options so the char * parameters are kept alive
    MODSSLOptions                       *_sslOptions;
    
    BOOL                                _connected;
    NSOperationQueue                    *_operationQueue;
}
@property (nonatomic, assign, readonly, getter = isConnected) BOOL connected;
@property (nonatomic, strong, readwrite) MODReadPreferences *readPreferences;
@property (nonatomic, strong, readwrite) MODSSLOptions *sslOptions;
@property (nonatomic, strong, readwrite) MODWriteConcern *writeConcern;

+ (instancetype)clientWihtURLString:(NSString *)urlString;
+ (uint16_t)defaultPort;

// can return nil if the URI is invalid
- (instancetype)initWithURIString:(NSString *)urlString;
- (instancetype)initWithURICString:(const char *)urlCString;

- (instancetype)copy;

- (MODQuery *)serverStatusWithReadPreferences:(MODReadPreferences *)readPreferences callback:(void (^)(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery))callback;
- (MODQuery *)databaseNamesWithCallback:(void (^)(NSArray *list, MODQuery *mongoQuery))callback;
- (MODDatabase *)databaseForName:(NSString *)databaseName;
- (void)cancelAllOperations;

@end

@interface MODClient (utils)
+ (NSString *)escapeQuotesForString:(NSString *)string;
+ (NSString *)escapeSlashesForString:(NSString *)string;
+ (NSString *)convertObjectToJson:(MODSortedMutableDictionary *)object pretty:(BOOL)pretty strictJson:(BOOL)strictJson;
+ (BOOL)isEqualWithJson:(NSString *)json toBsonData:(NSData *)document info:(NSDictionary **)info;
+ (BOOL)isEqualWithJson:(NSString *)json toDocument:(id)document info:(NSDictionary **)info;
+ (NSArray *)findAllDifferencesInObject1:(id)object1 object2:(id)object2;

+ (void)setLogCallback:(void (^)(MODLogLevel level, const char *domain, const char *message))callback;
+ (NSString *)logLevelStringForLogLevel:(MODLogLevel)level;

@end