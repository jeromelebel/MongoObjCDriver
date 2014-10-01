//
//  MODClientTestCase.m
//  MongoObjCDriver
//
//  Created by Jérôme Lebel on 01/10/2014.
//
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "MongoObjCDriver-private.h"

#define DATABASE_NAME_TEST @"database_test"
#define COLLECTION_NAME_TEST @"collection_test"

@interface MODClientTestCase : XCTestCase
@property (nonatomic, readwrite, retain) MODClient *server;
@end

@implementation MODClientTestCase

- (void)logMongoQuery:(MODQuery *)mongoQuery
{
    if (mongoQuery.error) {
        NSLog(@"********* ERROR ************");
        NSLog(@"%@", mongoQuery.error);
    }
    if (mongoQuery.name == nil) {
        NSLog(@"********* ERROR ************");
        NSLog(@"Need to set the command name in the query parameters of mongo query");
    }
//    NSLog(@"%@ %@", mongoQuery.name, mongoQuery.parameters);
    XCTAssertNotNil(mongoQuery.name, @"no query name");
    XCTAssertNil(mongoQuery.error, @"error with %@", mongoQuery.name);
}

- (MODSortedMutableDictionary *)obj:(NSString *)json
{
    NSError *error;
    MODSortedMutableDictionary *result;
    
    result = [MODRagelJsonParser objectsFromJson:json withError:&error];
    XCTAssertNil(error, @"should have no error for %@", json);
    return result;
}

- (void)removeTestDatabase
{
    [[self.server databaseForName:DATABASE_NAME_TEST] dropWithCallback:^(MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
}

- (void)setUp
{
    NSString *uri;
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    uri = NSProcessInfo.processInfo.environment[@"mongouri"];
    self.server = [[MODClient alloc] initWithURIString:uri];
    if (self.server == nil) {
        NSLog(@"Can't parse uri %@", uri);
        assert(false);
    }
    [self.server serverStatusWithReadPreferences:nil callback:^(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [self.server databaseNamesWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
        if ([list indexOfObject:DATABASE_NAME_TEST] != NSNotFound) {
            [self removeTestDatabase];
        }
    }];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testClient
{
    MODDatabase *mongoDatabase;
    MODCollection *mongoCollection;
    MODCursor *cursor;
    
    mongoDatabase = [self.server databaseForName:DATABASE_NAME_TEST];
    [mongoDatabase statsWithReadPreferences:nil callback:^(MODSortedMutableDictionary *stats, MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [self.server databaseNamesWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
        XCTAssertNotEqual([list indexOfObject:DATABASE_NAME_TEST], NSNotFound, @"can not find %@", DATABASE_NAME_TEST);
    }];
    [mongoDatabase createCollectionWithName:COLLECTION_NAME_TEST callback:^(MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [mongoDatabase collectionNamesWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    
    mongoCollection = [mongoDatabase collectionForName:COLLECTION_NAME_TEST];
    [mongoCollection findWithCriteria:[self obj:@"{}"] fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:5 sort:[self obj:@"{ \"_id\": 1 }"] callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection countWithCriteria:[self obj:@"{ \"_id\": \"xxx\" }"] readPreferences:nil callback:^(int64_t count, MODQuery *mongoQuery) {
        XCTAssertEqual(count, 0, @"should have no document");
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection countWithCriteria:nil readPreferences:nil callback:^(int64_t count, MODQuery *mongoQuery) {
        XCTAssertEqual(count, 0, @"should have no document");
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection insertWithDocuments:[NSArray arrayWithObjects:@"{ \"_id\": \"toto\" }", nil] callback:^(MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection insertWithDocuments:[NSArray arrayWithObjects:@"{ \"_id\": \"toto1\" }", @"{ \"_id\": { \"$oid\": \"123456789012345678901234\" } }", nil] callback:^(MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection countWithCriteria:nil readPreferences:nil callback:^(int64_t count, MODQuery *mongoQuery) {
        XCTAssertEqual(count, 3, @"should have 3 documents");
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection countWithCriteria:[self obj:@"{ \"_id\": \"toto\" }"] readPreferences:nil callback:^(int64_t count, MODQuery *mongoQuery) {
        XCTAssertEqual(count, 1, @"should have 1 document");
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection findWithCriteria:nil fields:[NSArray arrayWithObjects:@"_id", @"album_id", nil] skip:1 limit:100 sort:nil callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        XCTAssertEqual(documents.count, 2, @"should have 2 documents");
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection findWithCriteria:nil fields:nil skip:0 limit:0 sort:nil callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        XCTAssertEqual(documents.count, 3, @"should have 3 documents");
        [self logMongoQuery:mongoQuery];
    }];
    cursor = [mongoCollection cursorWithCriteria:nil fields:nil skip:0 limit:0 sort:nil];
    [cursor forEachDocumentWithCallbackDocumentCallback:^(uint64_t index, MODSortedMutableDictionary *document) {
        return YES;
    } endCallback:^(uint64_t count, BOOL stopped, MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection updateWithCriteria:[self obj:@"{\"_id\": \"toto\"}"] update:[self obj:@"{\"$inc\": {\"x\": 1}}"] upsert:NO multiUpdate:NO callback:^(MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection saveWithDocument:[self obj:@"{\"_id\": \"toto\", \"y\": null}"] callback:^(MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection findWithCriteria:[self obj:@"{\"_id\": \"toto\"}"] fields:nil skip:1 limit:5 sort:[self obj:@"{ \"_id\": 1 }"] callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection removeWithCriteria:[self obj:@"{\"_id\": \"toto\"}"] callback:^(MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [mongoCollection findWithCriteria:[self obj:@"{\"_id\": \"toto\"}"] fields:nil skip:1 limit:5 sort:[self obj:@"{ \"_id\": 1 }"] callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        XCTAssertEqual(documents.count, 0, @"should have no document");
        [self logMongoQuery:mongoQuery];
    }];
    
    [mongoCollection dropWithCallback:^(MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [mongoDatabase collectionNamesWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
        XCTAssertEqual([collectionList indexOfObject:COLLECTION_NAME_TEST], NSNotFound, @"should have no more %@ collection", COLLECTION_NAME_TEST);
    }];
    
    [mongoDatabase dropWithCallback:^(MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    
    [self.server databaseNamesWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
        XCTAssertEqual([list indexOfObject:DATABASE_NAME_TEST], NSNotFound, @"should have no more %@ database", DATABASE_NAME_TEST);
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];
    CFRunLoopRun();
}

@end
