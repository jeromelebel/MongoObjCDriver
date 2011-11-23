//
//  MODServer.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODServer

@synthesize connected = _connected, mongo = _mongo, userName = _userName, password = _password, authDatabase = _authDatabase;

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

- (void)copyWithCallback:(void (^)(MODServer *copyServer, MODQuery *mongoQuery))callback
{
    MODServer *copy;
    
    copy = [[MODServer alloc] init];
    copy.userName = self.userName;
    copy.password = self.password;
    if (_mongo->replset) {
        NSString *replicaName;
        NSMutableArray *hosts;
        mongo_host_port *hostPort;
        
        replicaName = [[NSString alloc] initWithUTF8String:_mongo->replset->name];
        hosts = [[NSMutableArray alloc] init];
        hostPort = _mongo->replset->seeds;
        while (hostPort != NULL) {
            NSString *hostName;
            
            hostName = [[NSString alloc] initWithFormat:@"%s:%d", hostPort->host, hostPort->port];
            [hosts addObject:hostName];
            [hostName release];
            hostPort = hostPort->next;
        }
        [copy connectWithReplicaName:replicaName hosts:hosts callback:^(BOOL connected, MODQuery *mongoQuery) {
            callback(copy, mongoQuery);
        }];
        [replicaName release];
        [hosts release];
    } else {
        NSString *hostName;
        
        hostName = [[NSString alloc] initWithFormat:@"%s:%d", _mongo->primary->host, _mongo->primary->port];
        [copy connectWithHostName:hostName callback:^(BOOL connected, MODQuery *mongoQuery) {
            callback(copy, mongoQuery);
        }];
        [hostName release];
    }
    [copy release];
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
        
        if ([databaseName length] != 0) {
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
        mongoQuery.error = [[self class] errorWithErrorDomain:MODMongoErrorDomain code:_mongo->err descriptionDetails:nil];
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
    if (![mongoQuery.parameters objectForKey:@"command"]) {
        NSLog(@"done with %@", [mongoQuery.parameters objectForKey:@"command"]);
    }
    [self mongoQueryDidFinish:mongoQuery];
    if (callbackBlock) {
        dispatch_async(dispatch_get_main_queue(), callbackBlock);
    }
}

- (MODQuery *)connectWithHostName:(NSString *)host callback:(void (^)(BOOL connected, MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery) {
        mongo_host_port hostPort;
        
        mongo_parse_host([host UTF8String], &hostPort);
        if (!mongoQuery.canceled && mongo_connect(_mongo, hostPort.host, hostPort.port) == MONGO_OK) {
            [self authenticateSynchronouslyWithDatabaseName:_authDatabase userName:_userName password:_password mongoQuery:mongoQuery];
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(mongoQuery.error == nil && !mongoQuery.canceled, mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"connecttohost" forKey:@"command"];
    [query.mutableParameters setObject:host forKey:@"hostname"];
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
        if (!mongoQuery.canceled && mongo_replset_connect(_mongo) == MONGO_OK) {
            [self authenticateSynchronouslyWithDatabaseName:_authDatabase userName:_userName password:_password mongoQuery:mongoQuery];
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(mongoQuery.error == nil && !mongoQuery.canceled, mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"connecttoreplica" forKey:@"command"];
    [query.mutableParameters setObject:replicaName forKey:@"replicaname"];
    [query.mutableParameters setObject:hosts forKey:@"hosts"];
    return query;
}

- (MODQuery *)fetchServerStatusWithCallback:(void (^)(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery){
        bson output;
        MODSortedMutableDictionary *outputObjects = nil;
        
        if (!mongoQuery.canceled && mongo_simple_int_command(_mongo, "admin", "serverStatus", 1, &output) == MONGO_OK) {
            outputObjects = [[self class] objectFromBson:&output];
            [mongoQuery.mutableParameters setObject:outputObjects forKey:@"serverstatus"];
        }
        bson_destroy(&output);
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(outputObjects, mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"fetchserverstatus" forKey:@"command"];
    return query;
}

- (MODQuery *)fetchDatabaseListWithCallback:(void (^)(NSArray *list, MODQuery *mongoQuery))callback;
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery) {
        bson output;
        NSMutableArray *list = nil;
        
        if (!mongoQuery.canceled && mongo_simple_int_command(_mongo, "admin", "listDatabases", 1, &output) == MONGO_OK) {
            MODSortedMutableDictionary *outputObjects;
            
            outputObjects = [[self class] objectFromBson:&output];
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
    [query.mutableParameters setObject:@"fetchdatabaselist" forKey:@"command"];
    return query;
}

- (MODQuery *)dropDatabaseWithName:(NSString *)databaseName callback:(void (^)(MODQuery *mongoQuery))callback
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery){
        if (!mongoQuery.canceled && [self authenticateSynchronouslyWithDatabaseName:databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            mongo_cmd_drop_db(_mongo, [databaseName UTF8String]);
        }
        [self mongoQueryDidFinish:mongoQuery withCallbackBlock:^(void) {
            callback(mongoQuery);
        }];
    }];
    [query.mutableParameters setObject:@"dropdatabase" forKey:@"command"];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    return query;
}

- (MODDatabase *)databaseForName:(NSString *)databaseName
{
    return [[[MODDatabase alloc] initWithMongoServer:self databaseName:databaseName] autorelease];
}

@end
