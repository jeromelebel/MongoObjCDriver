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

+ (id)objectFromBsonIterator:(bson_iterator *)iterator
{
    id result = nil;
    bson_iterator subIterator;
    
    switch (bson_iterator_type(iterator)) {
        case BSON_EOO:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_DOUBLE:
            result = [NSNumber numberWithDouble:bson_iterator_double(iterator)];
            break;
        case BSON_STRING:
            result = [NSString stringWithUTF8String:bson_iterator_string(iterator)];
            break;
        case BSON_OBJECT:
            result = [NSMutableDictionary dictionary];
            bson_iterator_subiterator(iterator, &subIterator);
            while (bson_iterator_more(&subIterator)) {
                id value;
                
                value = [self objectFromBsonIterator:&subIterator];
                if (value) {
                    NSString *key;
                    
                    key = [[NSString alloc] initWithUTF8String:bson_iterator_key(&subIterator)];
                    [result setObject:value forKey:key];
                    [key release];
                }
                bson_iterator_next(&subIterator);
            }
            break;
        case BSON_ARRAY:
            result = [NSMutableArray array];
            bson_iterator_subiterator(iterator, &subIterator);
            while (bson_iterator_more(&subIterator)) {
                id value;
                
                value = [self objectFromBsonIterator:&subIterator];
                if (value) {
                    [result addObject:value];
                }
                bson_iterator_next(&subIterator);
            }
            break;
        case BSON_BINDATA:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_UNDEFINED:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            result = nil;
            break;
        case BSON_OID:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_BOOL:
            result = [NSNumber numberWithBool:bson_iterator_bool(iterator) == true];
            break;
        case BSON_DATE:
            result = [NSDate dateWithTimeIntervalSince1970:bson_iterator_date(iterator) / 1000];
            break;
        case BSON_NULL:
            result = [NSNull null];
            break;
        case BSON_REGEX:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_DBREF:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_CODE:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_SYMBOL:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            result = [NSString stringWithUTF8String:bson_iterator_string(iterator)];
            break;
        case BSON_CODEWSCOPE:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_INT:
            result = [NSNumber numberWithInt:bson_iterator_int(iterator)];
            break;
        case BSON_TIMESTAMP:
            NSLog(@"*********************** %d %d", bson_iterator_type(iterator), __LINE__);
            break;
        case BSON_LONG:
            result = [NSNumber numberWithLong:bson_iterator_long(iterator)];
            break;
    }
    return result;
}

+ (NSDictionary *)objectsFromBson:(bson *)bsonObject
{
    bson_iterator iterator;
    NSMutableDictionary *result;
    
    result = [[NSMutableDictionary alloc] init];
    bson_iterator_init(&iterator, bsonObject);
    while (bson_iterator_more(&iterator) != BSON_EOO) {
        NSString *key;
        id value;
        
        key = [[NSString alloc] initWithUTF8String:bson_iterator_key(&iterator)];
        value = [self objectFromBsonIterator:&iterator];
        if (value) {
            [result setObject:value forKey:key];
        }
        bson_iterator_next(&iterator);
    }
    return [result autorelease];
}

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

- (BOOL)authenticateSynchronouslyWithDatabaseName:(NSString *)databaseName userName:(NSString *)userName password:(NSString *)password mongoQuery:(MODQuery *)mongoQuery
{
    BOOL result = YES;
    
    if ([userName length] > 0 && [password length] > 0) {
        const char *dbName;
        
        if ([databaseName length] == 0) {
            dbName = [databaseName UTF8String];
        } else {
            dbName = "admin";
        }
        result = mongo_cmd_authenticate(_mongo, dbName, [userName UTF8String], [password UTF8String]) == MONGO_OK;
    }
    return result;
}

- (void)mongoOperationDidFinish:(MODQuery *)mongoQuery withCallback:(SEL)callbackSelector
{
    [mongoQuery ends];
    if (_mongo->err != MONGO_CONN_SUCCESS) {
        [mongoQuery.mutableParameters setObject:[NSNumber numberWithInt:_mongo->err] forKey:@"error"];
    }
    if (_mongo->errstr) {
        [mongoQuery.mutableParameters setObject:[NSString stringWithUTF8String:_mongo->errstr] forKey:@"errormessage"];
    }
    [self performSelectorOnMainThread:callbackSelector withObject:mongoQuery waitUntilDone:NO];
}

- (void)connectCallback:(MODQuery *)query
{
    NSString *errorMessage;
    
    errorMessage = [query.mutableParameters objectForKey:@"errormessage"];
    if (errorMessage && [_delegate respondsToSelector:@selector(mongoServerConnectionFailed:withMongoQuery:errorMessage:)]) {
        [_delegate mongoServerConnectionFailed:self withMongoQuery:query errorMessage:errorMessage];
    } else if (errorMessage == nil && [_delegate respondsToSelector:@selector(mongoServerConnectionSucceded:withMongoQuery:)]) {
        [_delegate mongoServerConnectionSucceded:self withMongoQuery:query];
    }
    self.connected = (errorMessage == nil);
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
        [self mongoOperationDidFinish:mongoQuery withCallback:@selector(connectCallback:)];
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
        [self mongoOperationDidFinish:mongoQuery withCallback:@selector(connectCallback:)];
    }];
    return query;
}

- (void)fetchServerStatusCallback:(MODQuery *)query
{
    NSArray *serverStatus;
    
    serverStatus = [query.parameters objectForKey:@"serverstatus"];
    if ([_delegate respondsToSelector:@selector(mongoServer:serverStatusFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoServer:self serverStatusFetched:serverStatus withMongoQuery:query errorMessage:[query.parameters objectForKey:@"errormessage"]];
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
        [self mongoOperationDidFinish:mongoQuery withCallback:@selector(fetchServerStatusCallback:)];
    }];
}

- (void)fetchServerStatusDeltaCallback:(MODQuery *)mongoQuery
{
    NSDictionary *serverStatusDelta;
    
    serverStatusDelta = [mongoQuery.parameters objectForKey:@"serverstatusdelta"];
    if ([_delegate respondsToSelector:@selector(mongoDB:serverStatusDeltaFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoServer:self serverStatusDeltaFetched:serverStatusDelta withMongoQuery:mongoQuery errorMessage:[mongoQuery.parameters objectForKey:@"errormessage"]];
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
        [self mongoOperationDidFinish:mongoQuery withCallback:@selector(fetchServerStatusDeltaCallback:)];
    }];
}

- (void)fetchDatabaseListCallback:(MODQuery *)query
{
    NSArray *list;
    
    list = [query.parameters objectForKey:@"databaselist"];
    if ([_delegate respondsToSelector:@selector(mongoServer:databaseListFetched:withMongoQuery:errorMessage:)]) {
        [_delegate mongoServer:self databaseListFetched:list withMongoQuery:query errorMessage:[query.parameters objectForKey:@"errormessage"]];
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
        [self mongoOperationDidFinish:mongoQuery withCallback:@selector(fetchDatabaseListCallback:)];
    }];
}

- (void)dropDatabaseCallback:(MODQuery *)mongoQuery
{
    NSString *errorMessage;
    
    errorMessage = [mongoQuery.parameters objectForKey:@"errormessage"];
    if ([_delegate respondsToSelector:@selector(mongoDB:databaseDropedWithMongoQuery:errorMessage:)]) {
        [_delegate mongoServer:self databaseDropedWithMongoQuery:mongoQuery errorMessage:errorMessage];
    }
}

- (MODQuery *)dropDatabaseWithName:(NSString *)databaseName
{
    MODQuery *query;
    
    query = [self addQueryInQueue:^(MODQuery *mongoQuery){
        if ([self authenticateSynchronouslyWithDatabaseName:databaseName userName:_userName password:_password mongoQuery:mongoQuery]) {
            bson output;
            
            mongo_simple_int_command(_mongo, "admin", "dropDatabase", 1, &output);
            bson_print(&output);
            bson_destroy(&output);
        }
        [self mongoOperationDidFinish:mongoQuery withCallback:@selector(dropDatabaseCallback:)];
    }];
    [query.mutableParameters setObject:databaseName forKey:@"databasename"];
    return query;
}

- (MODDatabase *)databaseForName:(NSString *)databaseName
{
    MODDatabase *database;
    
    database = [[MODDatabase alloc] init];
    database.server = self;
    database.databaseName = databaseName;
    return database;
}

@end
