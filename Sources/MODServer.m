//
//  MODServer.m
//  mongo-objc-driver
//
//  Created by Jérôme Lebel on 02/09/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MOD_internal.h"

@implementation MODServer

@synthesize delegate = _delegate, connected = _connected, mongo = _mongo, userName = _userName, password = _password;

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

- (void)mongoQueryDidFinish:(MODQuery *)mongoQuery withTarget:(id)target callback:(SEL)callbackSelector
{
    [mongoQuery ends];
    if (_mongo->err != MONGO_CONN_SUCCESS) {
        [mongoQuery.mutableParameters setObject:[NSNumber numberWithInt:_mongo->err] forKey:@"error"];
    }
    if (_mongo->errstr) {
        [mongoQuery.mutableParameters setObject:[NSString stringWithUTF8String:_mongo->errstr] forKey:@"error"];
    }
    [target performSelectorOnMainThread:callbackSelector withObject:mongoQuery waitUntilDone:NO];
}

- (void)connectCallback:(MODQuery *)mongoQuery
{
    NSError *error;
    
    error = mongoQuery.error;
    if (error && [_delegate respondsToSelector:@selector(mongoServerConnectionFailed:withMongoQuery:error:)]) {
        [_delegate mongoServerConnectionFailed:self withMongoQuery:mongoQuery error:error];
    } else if (error == nil && [_delegate respondsToSelector:@selector(mongoServerConnectionSucceded:withMongoQuery:)]) {
        [_delegate mongoServerConnectionSucceded:self withMongoQuery:mongoQuery];
    }
    self.connected = (error == nil);
}

- (MODQuery *)connectWithHostName:(NSString *)host
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery) {
        mongo_host_port hostPort;
        
        mongo_parse_host([host UTF8String], &hostPort);
        if (mongo_connect(_mongo, hostPort.host, hostPort.port) == MONGO_OK) {
            [self authenticateSynchronouslyWithDatabaseName:nil userName:_userName password:_password mongoQuery:mongoQuery];
        }
        [self mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(connectCallback:)];
    }];
    [query.mutableParameters setObject:host forKey:@"host"];
    return query;
}

- (MODQuery *)connectWithReplicaName:(NSString *)replicaName hosts:(NSArray *)hosts
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
        [self mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(connectCallback:)];
    }];
    return query;
}

- (void)fetchServerStatusCallback:(MODQuery *)mongoQuery
{
    NSArray *serverStatus;
    
    serverStatus = [mongoQuery.parameters objectForKey:@"serverstatus"];
    if ([_delegate respondsToSelector:@selector(mongoServer:serverStatusFetched:withMongoQuery:error:)]) {
        [_delegate mongoServer:self serverStatusFetched:serverStatus withMongoQuery:mongoQuery error:mongoQuery.error];
    }
}

- (MODQuery *)fetchServerStatus
{
    return [self addQueryInQueue:^(MODQuery *mongoQuery){
        bson output;
        
        if (mongo_simple_int_command(_mongo, "admin", "serverStatus", 1, &output) == MONGO_OK) {
            NSDictionary *outputObjects;
            
            outputObjects = [[self class] objectsFromBson:&output];
            [mongoQuery.mutableParameters setObject:outputObjects forKey:@"serverstatus"];
            bson_destroy(&output);
        }
        [self mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(fetchServerStatusCallback:)];
    }];
}

- (void)fetchServerStatusDeltaCallback:(MODQuery *)mongoQuery
{
    NSDictionary *serverStatusDelta;
    
    serverStatusDelta = [mongoQuery.parameters objectForKey:@"serverstatusdelta"];
    if ([_delegate respondsToSelector:@selector(mongoDB:serverStatusDeltaFetched:withMongoQuery:error:)]) {
        [_delegate mongoServer:self serverStatusDeltaFetched:serverStatusDelta withMongoQuery:mongoQuery error:mongoQuery.error];
    }
}

- (MODQuery *)fetchServerStatusDelta
{
    return [self addQueryInQueue:^(MODQuery *mongoQuery){
        bson output;
        
        if (mongo_simple_int_command(_mongo, "admin", "serverStatus", 1, &output) == MONGO_OK) {
            NSDictionary *outputObjects;
            
            outputObjects = [[self class] objectsFromBson:&output];
            bson_destroy(&output);
        }
        [self mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(fetchServerStatusDeltaCallback:)];
    }];
}

- (void)fetchDatabaseListCallback:(MODQuery *)mongoQuery
{
    NSArray *list;
    
    list = [mongoQuery.parameters objectForKey:@"databaselist"];
    if ([_delegate respondsToSelector:@selector(mongoServer:databaseListFetched:withMongoQuery:error:)]) {
        [_delegate mongoServer:self databaseListFetched:list withMongoQuery:mongoQuery error:mongoQuery.error];
    }
}

- (MODQuery *)fetchDatabaseList
{
    return [self addQueryInQueue:^(MODQuery *mongoQuery) {
        bson output;
        
        if (mongo_simple_int_command(_mongo, "admin", "listDatabases", 1, &output) == MONGO_OK) {
            NSMutableArray *list;
            NSDictionary *outputObjects;
            
            outputObjects = [[self class] objectsFromBson:&output];
            list = [[NSMutableArray alloc] init];
            for(NSDictionary *element in [outputObjects objectForKey:@"databases"]) {
                [list addObject:[element objectForKey:@"name"]];
            }
            [mongoQuery.mutableParameters setObject:list forKey:@"databaselist"];
            [list release];
            bson_destroy(&output);
        }
        [self mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(fetchDatabaseListCallback:)];
    }];
}

- (void)createDatabaseCallback:(MODQuery *)mongoQuery
{
    if ([_delegate respondsToSelector:@selector(mongoDB:databaseCreatedWithMongoQuery:error:)]) {
        [_delegate mongoServer:self databaseCreatedWithMongoQuery:mongoQuery error:mongoQuery.error];
    }
}

- (MODQuery *)createDatabaseWithName:(NSString *)databaseName
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery){
        if ([self authenticateSynchronouslyWithDatabaseName:databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            bson output;
            
            mongo_simple_int_command(_mongo, "admin", "dropDatabase", 1, &output);
            bson_print(&output);
            bson_destroy(&output);
        }
        [self mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(createDatabaseCallback:)];
    }];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    return query;
}

- (void)dropDatabaseCallback:(MODQuery *)mongoQuery
{
    if ([_delegate respondsToSelector:@selector(mongoDB:databaseDropedWithMongoQuery:error:)]) {
        [_delegate mongoServer:self databaseDropedWithMongoQuery:mongoQuery error:mongoQuery.error];
    }
}

- (MODQuery *)dropDatabaseWithName:(NSString *)databaseName
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery){
        if ([self authenticateSynchronouslyWithDatabaseName:databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            bson output;
            
            mongo_simple_int_command(_mongo, [databaseName UTF8String], "dropDatabase", 1, &output);
            bson_print(&output);
            bson_destroy(&output);
        }
        [self mongoQueryDidFinish:mongoQuery withTarget:self callback:@selector(dropDatabaseCallback:)];
    }];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    return query;
}

- (MODDatabase *)databaseForName:(NSString *)databaseName
{
    return [[[MODDatabase alloc] initWithMongoServer:self databaseName:databaseName] autorelease];
}

@end
