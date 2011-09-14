//
//  MODServer.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODServer

@synthesize connected = _connected, mongo = _mongo, userName = _userName, password = _password;

- (id)init
{
    if ((self = [super init]) != nil) {
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:1];
        _mongo = malloc(sizeof(*_mongo));
        mongo_init(_mongo);
    }
    return self;
}

- (void)dealloc
{
    mongo_destroy(_mongo);
    free(_mongo);
    [_operationQueue release];
    [super dealloc];
}

- (MODQuery *)addQueryInQueue:(void (^)(MODQuery *currentMongoQuery))block
{
    MODQuery *mongoQuery;
    NSBlockOperation *blockOperation;
    
    mongoQuery = [[MODQuery alloc] init];
    blockOperation = [[NSBlockOperation alloc] init];
    [blockOperation addExecutionBlock:^{
        [mongoQuery starts];
        block(mongoQuery);
    }];
    mongoQuery.blockOperation = blockOperation;
    [_operationQueue addOperation:blockOperation];
    [blockOperation release];
    return [mongoQuery autorelease];
}

- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password error:(NSError **)error
{
    BOOL result = YES;
    
    NSAssert(error != nil, @"please set error variable to get back the value");
    if ([userName length] > 0 && [password length] > 0) {
        const char *dbName;
        
        if ([databaseName length] == 0) {
            dbName = [databaseName UTF8String];
        } else {
            dbName = "admin";
        }
        result = mongo_cmd_authenticate(_mongo, dbName, [userName UTF8String], [password UTF8String]) == MONGO_OK;
        if (!result) {
            *error = [[self class] errorWithErrorDomain:MODMongoErrorDomain code:_mongo->err descriptionDetails:nil];
        }
    }
    return result;
}

- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password mongoQuery:(MODQuery *)mongoQuery
{
    NSError *error = nil;
    
    [self authenticateSynchronouslyWithDatabaseName:databaseName userName:userName password:password error:&error];
    if (error) {
        mongoQuery.error = error;
    }
    return error == nil;
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery
{
    [mongoQuery.mutableParameters setObject:self forKey:@"mongoserver"];
    [mongoQuery ends];
    if (_mongo->err != MONGO_CONN_SUCCESS) {
        [mongoQuery.mutableParameters setObject:[[self class] errorWithErrorDomain:MODMongoErrorDomain code:_mongo->err descriptionDetails:nil] forKey:@"error"];
        _mongo->err = MONGO_CONN_SUCCESS;
    }
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withTarget:(id)target callback:(SEL)callbackSelector
{
    [self mongoQueryDidFinish:mongoQuery];
    [target performSelectorOnMainThread:callbackSelector withObject:mongoQuery waitUntilDone:NO];
}

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withCallbackBlock:(void (^)(void))callbackBlock
{
    [self mongoQueryDidFinish:mongoQuery];
    dispatch_async(dispatch_get_main_queue(), callbackBlock);
}

- (MODQuery *)connectWithHostName:(NSString *)host callback:(void (^)(BOOL connected, MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery) {
        mongo_host_port hostPort;
        
        mongo_parse_host([host UTF8String], &hostPort);
        if (mongo_connect(_mongo, hostPort.host, hostPort.port) == MONGO_OK) {
            [self authenticateSynchronouslyWithDatabaseName:nil userName:_userName password:_password mongoQuery:mongoQuery];
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(mongoQuery.error == nil, mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:host forKey:@"host"];
    return query;
}

- (MODQuery *)connectWithReplicaName:(NSString *)replicaName hosts:(NSArray *)hosts callback:(void (^)(BOOL connected, MODQuery *mongoQuery))callback
{
    MODQuery *query;
    mongo_host_port hostPort;
    
    mongo_replset_init(_mongo, [replicaName UTF8String]);
    for (NSString *host in hosts) {
        mongo_parse_host([host UTF8String], &hostPort);
        mongo_replset_add_seed(_mongo, hostPort.host, hostPort.port);
    }
    query = [self addQueryInQueue:^(MODQuery *mongoQuery) {
        if (mongo_replset_connect(_mongo) == MONGO_OK) {
            [self authenticateSynchronouslyWithDatabaseName:nil userName:_userName password:_password mongoQuery:mongoQuery];
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(mongoQuery.error == nil, mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:replicaName forKey:@"replicaname"];
    [query.mutableParameters setObject:hosts forKey:@"hosts"];
    return query;
}

- (MODQuery *)fetchServerStatusWithCallback:(void (^)(NSDictionary *serverStatus, MODQuery *mongoQuery))callback
{
    return [self addQueryInQueue:^(MODQuery *mongoQuery){
        bson output;
        NSDictionary *outputObjects = nil;
        
        if (mongo_simple_int_command(_mongo, "admin", "serverStatus", 1, &output) == MONGO_OK) {
            outputObjects = [[self class] objectsFromBson:&output];
            [mongoQuery.mutableParameters setObject:outputObjects forKey:@"serverstatus"];
        }
        bson_destroy(&output);
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(outputObjects, mongoQuery);
        }];
    }];
}

//- (void)fetchServerStatusDeltaCallback:(MODQuery *)mongoQuery
//{
//    NSDictionary *serverStatusDelta;
//    
//    serverStatusDelta = [mongoQuery.parameters objectForKey:@"serverstatusdelta"];
//    if ([_delegate respondsToSelector:@selector(mongoDB:serverStatusDeltaFetched:withMongoQuery:)]) {
//        [_delegate mongoServer:self serverStatusDeltaFetched:serverStatusDelta withMongoQuery:mongoQuery];
//    }
//}
//
//- (MODQuery *)fetchServerStatusDelta
//{
//    return [self addQueryInQueue:^(MODQuery *mongoQuery){
//        NSDictionary *outputObjects;
//        bson output;
//        
//        if (mongo_simple_int_command(_mongo, "admin", "serverStatus", 1, &output) == MONGO_OK) {
//            outputObjects = [[self class] objectsFromBson:&output];
//        }
//        bson_destroy(&output);
//        [self mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(fetchServerStatusDeltaCallback:)];
//    }];
//}

- (MODQuery *)fetchDatabaseListWithCallback:(void (^)(NSArray *list, MODQuery *mongoQuery))callback;
{
    return [self addQueryInQueue:^(MODQuery *mongoQuery) {
        bson output;
        NSMutableArray *list = nil;
        
        if (mongo_simple_int_command(_mongo, "admin", "listDatabases", 1, &output) == MONGO_OK) {
            NSDictionary *outputObjects;
            
            outputObjects = [[self class] objectsFromBson:&output];
            list = [[NSMutableArray alloc] init];
            for(NSDictionary *element in [outputObjects objectForKey:@"databases"]) {
                [list addObject:[element objectForKey:@"name"]];
            }
            [mongoQuery.mutableParameters setObject:list forKey:@"databaselist"];
            bson_destroy(&output);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(list, mongoQuery);
        }];
        [list release];
    }];
}

- (MODQuery *)dropDatabaseWithName:(NSString *)databaseName callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery){
        if ([self authenticateSynchronouslyWithDatabaseName:databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            mongo_cmd_drop_db(_mongo, [databaseName UTF8String]);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    return query;
}

- (MODDatabase *)databaseForName:(NSString *)databaseName
{
    return [[[MODDatabase alloc] initWithMongoServer:self databaseName:databaseName] autorelease];
}

@end
