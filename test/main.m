//
//  main.m
//  test
//
//  Created by Jérôme Lebel on 17/10/2014.
//
//

#import <Foundation/Foundation.h>
#import <MongoObjCDriver/mongoc.h>

int main(int argc, const char * argv[]) {
    mongoc_client_t *client;
    mongoc_database_t *database;
    mongoc_collection_t *collection;
    bson_t bson = BSON_INITIALIZER;
    
    client = mongoc_client_new("mongodb://192.168.174.202");
    database = mongoc_client_get_database(client, "test");
    collection = mongoc_database_get_collection(database, "test");
    
    return 0;
}
