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
@class MODSortedDictionary;
@class MODReadPreferences;
@class MODSSLOptions;
@class MODWriteConcern;

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

typedef enum
{
    MODJsonKeySortOrderDocument,
    MODJsonKeySortOrderAscending,
    MODJsonKeySortOrderDescending,
} MODJsonKeySortOrder;

@interface MODClient : NSObject

@property (nonatomic, assign, readonly, getter = isConnected) BOOL connected;
@property (nonatomic, strong, readwrite) MODReadPreferences *readPreferences;
@property (nonatomic, strong, readwrite) MODSSLOptions *sslOptions;
@property (nonatomic, strong, readwrite) MODWriteConcern *writeConcern;
@property (nonatomic, strong, readwrite) NSDictionary *sshMapping;

+ (instancetype)clientWihtURLString:(NSString *)urlString;
+ (uint16_t)defaultPort;
+ (uint32_t)defaultConnectTimeout;
+ (uint32_t)defaultSocketTimeout;

// can return nil if the URI is invalid
- (instancetype)initWithURIString:(NSString *)urlString;
- (instancetype)initWithURICString:(const char *)urlCString;

- (instancetype)copy;

- (MODQuery *)serverStatusWithReadPreferences:(MODReadPreferences *)readPreferences callback:(void (^)(MODSortedDictionary *serverStatus, MODQuery *mongoQuery))callback;
- (MODQuery *)databaseNamesWithCallback:(void (^)(NSArray *list, MODQuery *mongoQuery))callback;
- (MODDatabase *)databaseForName:(NSString *)databaseName;
- (void)cancelAllOperations;

@end

@interface MODClient (utils)
+ (NSString *)escapeQuotesForString:(NSString *)string;
+ (NSString *)escapeSlashesForString:(NSString *)string;

+ (NSArray *)sortKeys:(NSArray *)keys withJsonKeySortOrder:(MODJsonKeySortOrder)jsonKeySortOrder;
+ (NSString *)convertObjectToJson:(MODSortedDictionary *)object pretty:(BOOL)pretty strictJson:(BOOL)strictJson jsonKeySortOrder:(MODJsonKeySortOrder)jsonKeySortOrder;
+ (BOOL)isEqualWithJson:(NSString *)json toBsonData:(NSData *)document info:(NSDictionary **)info;
+ (BOOL)isEqualWithJson:(NSString *)json toDocument:(id)document info:(NSDictionary **)info;
+ (NSArray *)findAllDifferencesInObject1:(id)object1 object2:(id)object2;

+ (void)setLogCallback:(void (^)(MODLogLevel level, const char *domain, const char *message))callback;
+ (NSString *)logLevelStringForLogLevel:(MODLogLevel)level;
+ (void)logWithLevel:(MODLogLevel)logLevel domain:(const char *)domain message:(const char *)message;

@end