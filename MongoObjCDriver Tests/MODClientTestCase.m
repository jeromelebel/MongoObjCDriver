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

#define DATABASE_NAME_TEST1 @"database_test"
#define DATABASE_NAME_TEST2 @"database_test"
#define COLLECTION_NAME_TEST @"collection_test"

@interface MODClientTestCase : XCTestCase
@property (nonatomic, readwrite, retain) MODClient *client;
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
    if (mongoQuery.error) {
        NSLog(@"error %@", mongoQuery.error);
    }
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

- (void)setUp
{
    NSString *uri;
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.

    uri = NSProcessInfo.processInfo.environment[@"mongouri"];
    self.client = [[MODClient alloc] initWithURIString:uri];
    self.client.sslOptions = [[MODSSLOptions alloc] initWithPemFileName:nil pemPassword:nil caFileName:nil caDirectory:nil crlFileName:nil weakCertificate:YES];
    if (self.client == nil) {
        NSLog(@"Can't parse uri %@", uri);
        assert(false);
    }
    [self.client serverStatusWithReadPreferences:nil callback:^(MODSortedMutableDictionary *serverStatus, MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [self.client databaseNamesWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
        if ([list indexOfObject:DATABASE_NAME_TEST1] != NSNotFound) {
            [[self.client databaseForName:DATABASE_NAME_TEST1] dropWithCallback:^(MODQuery *mongoQuery) {
                [self logMongoQuery:mongoQuery];
            }];
        }
        if ([list indexOfObject:DATABASE_NAME_TEST2] != NSNotFound) {
            [[self.client databaseForName:DATABASE_NAME_TEST2] dropWithCallback:^(MODQuery *mongoQuery) {
                [self logMongoQuery:mongoQuery];
            }];
        }
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];
    CFRunLoopRun();
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
    
    mongoDatabase = [self.client databaseForName:DATABASE_NAME_TEST1];
    [mongoDatabase statsWithReadPreferences:nil callback:^(MODSortedMutableDictionary *stats, MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [self.client databaseNamesWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
        XCTAssertNotEqual([list indexOfObject:DATABASE_NAME_TEST1], NSNotFound, @"can not find %@", DATABASE_NAME_TEST1);
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
    [mongoCollection updateWithCriteria:[self obj:@"{\"_id\": \"toto\"}"] update:[self obj:@"{\"$inc\": {\"x\": 1}}"] upsert:NO multiUpdate:NO writeConcern:nil callback:^(MODQuery *mongoQuery) {
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
    
    [self.client databaseNamesWithCallback:^(NSArray *list, MODQuery *mongoQuery) {
        XCTAssertEqual([list indexOfObject:DATABASE_NAME_TEST1], NSNotFound, @"should have no more %@ database", DATABASE_NAME_TEST1);
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];
    CFRunLoopRun();
}

- (void)testLotOfCollections
{
    MODDatabase *mongoDatabase;
    NSUInteger ii;
    static NSUInteger collectionCount = -1;
    const NSUInteger collectionCountToAdd = 1000;
    NSMutableArray *collectionNames = [NSMutableArray array];
    
    mongoDatabase = [self.client databaseForName:DATABASE_NAME_TEST1];
    [mongoDatabase createCollectionWithName:@"first" callback:^(MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [mongoDatabase collectionNamesWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
        collectionCount = collectionList.count;
    }];
    for (ii = 0; ii < collectionCountToAdd; ii++) {
        NSString *collectionName = [NSString stringWithFormat:@"test+%lu", (unsigned long)ii];
        
        [collectionNames addObject:collectionName];
        [mongoDatabase createCollectionWithName:collectionName callback:^(MODQuery *mongoQuery) {
            [self logMongoQuery:mongoQuery];
        }];
    }
    [mongoDatabase collectionNamesWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
        XCTAssertEqual(collectionList.count, collectionCount + collectionCountToAdd, @"should have 5001 collections");
    }];
    for (NSString *collectionName in collectionNames) {
        [[mongoDatabase collectionForName:collectionName] dropWithCallback:^(MODQuery *mongoQuery) {
            [self logMongoQuery:mongoQuery];
        }];
    }
    [mongoDatabase collectionNamesWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
        XCTAssertEqual(collectionList.count, collectionCount, @"should have 5001 collections");
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];
    CFRunLoopRun();
}

- (void)testBigDocuments
{
    MODCollection *collection;
    MODSortedMutableDictionary *document;
    NSMutableArray *documents = [NSMutableArray array];
    NSString *value = @"fdsafsdafds afsdafdsafsdafdsafsdaf dsafsdafdsafsdafdsafsdafdsafs dafdsafsdafdsafsdafd safsdafdsafsdaf dsafsdafdsafsdafd safsdafdsafsdafd safsdafdsafsdafdsa fsdafdsafsdafdsa fsdafdsafsdafdsa fsdafdsafsdafdsafsd afdsafsdafdsafsdafdsafsdaf";
    NSUInteger ii;
    const NSUInteger documentCountToInsert = 15;
    
    collection = [[self.client databaseForName:DATABASE_NAME_TEST1] collectionForName:@"BigDocuments"];
    document = [[MODSortedMutableDictionary alloc] init];
    for (ii = 0; ii < 50; ii++) {
        [document setObject:value forKey:[NSString stringWithFormat:@"big key fads f das fd sa fs f    as fdsa  dsa f dsa f %lu", ii]];
    }

    for (ii = 0; ii < documentCountToInsert; ii++) {
        [documents addObject:document];
    }
    [collection removeWithCriteria:nil callback:nil];
    [collection insertWithDocuments:documents callback:^(MODQuery *mongoQuery) {
        [self logMongoQuery:mongoQuery];
    }];
    [collection findWithCriteria:nil fields:nil skip:0 limit:100 sort:nil callback:^(NSArray *documents, NSArray *bsonData, MODQuery *mongoQuery) {
        XCTAssertEqual(documentCountToInsert, documents.count, @"problem to get big documents");
        CFRunLoopStop(CFRunLoopGetCurrent());
    }];
    CFRunLoopRun();
}

- (void)testRenameCollection
{
    MODDatabase *mongoDatabase1;
    MODDatabase *mongoDatabase2;
    mongoDatabase1 = [self.client databaseForName:DATABASE_NAME_TEST1];
    mongoDatabase2 = [self.client databaseForName:DATABASE_NAME_TEST1];
    [mongoDatabase1 createCollectionWithName:@"first" callback:^(MODQuery *mongoQuery) {
        MODCollection *collection;
        
        collection = [mongoDatabase1 collectionForName:@"first"];
        [collection renameWithNewDatabase:nil newCollectionName:@"second" dropTargetBeforeRenaming:NO callback:^(MODQuery *mongoQuery) {
            XCTAssertEqualObjects(collection.name, @"second", @"name should have been updated");
        }];
        [mongoDatabase1 collectionNamesWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
            XCTAssertEqual([collectionList indexOfObject:@"first"], NSNotFound, @"should not find first anymore");
            XCTAssertNotEqual([collectionList indexOfObject:@"second"], NSNotFound, @"should find second anymore");
        }];
        [collection renameWithNewDatabase:mongoDatabase2 newCollectionName:@"first" dropTargetBeforeRenaming:NO callback:^(MODQuery *mongoQuery) {
            XCTAssertEqualObjects(collection.name, @"first", @"name should have been updated");
            XCTAssertEqual(collection.database, mongoDatabase2, @"should give the same instance");
            CFRunLoopStop(CFRunLoopGetCurrent());
        }];
        [mongoDatabase1 collectionNamesWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
            XCTAssertEqual([collectionList indexOfObject:@"first"], NSNotFound, @"should not find first anymore");
            XCTAssertEqual([collectionList indexOfObject:@"second"], NSNotFound, @"should not find second anymore");
        }];
        [mongoDatabase2 collectionNamesWithCallback:^(NSArray *collectionList, MODQuery *mongoQuery) {
            XCTAssertNotEqual([collectionList indexOfObject:@"first"], NSNotFound, @"should not find first anymore");
        }];
    }];
    CFRunLoopRun();
}

@end
