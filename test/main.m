//
//  main.m
//  test
//
//  Created by Jérôme Lebel on 17/10/2014.
//
//

#import <Foundation/Foundation.h>
#import <MongoObjCDriver/mongoc.h>

int main(int argc, const char * argv[])
{
    mongoc_client_t *client;
    mongoc_database_t *database;
    mongoc_collection_t *collection;
    bson_error_t bsonError;
    bson_t bson = BSON_INITIALIZER;
    bson_t childBson = BSON_INITIALIZER;
    bson_oid_t oid;
    
    bson_oid_init_from_string(&oid, "5126bc054aed4daf9e2ab772");
    
    client = mongoc_client_new("mongodb://192.168.174.202");
    database = mongoc_client_get_database(client, "test");
    collection = mongoc_database_get_collection(database, "test");
    
    bson_append_document_begin(&bson, "user", -1, &childBson);
    bson_append_utf8(&childBson, "$ref", -1, "User", -1);
    bson_append_oid(&childBson, "$id", -1, &oid);
//    bson_append_utf8(&childBson, "$id", -1, "5374d465c43a034f528b45ba", -1);
    bson_append_utf8(&childBson, "$db", -1, "db_name", -1);
    bson_append_document_end(&bson, &childBson);
    
#if 1
        printf("inserted %d\n", mongoc_collection_insert(collection, MONGOC_INSERT_NONE, &bson, NULL, &bsonError));
#else
        mongoc_bulk_operation_t *bulk;
        
        bulk = mongoc_collection_create_bulk_operation(collection, NO, NULL);
        mongoc_bulk_operation_insert(bulk, &bson);
        mongoc_bulk_operation_execute(bulk, NULL, &bsonError);
#endif
    printf("error %d %d %s\n", bsonError.domain, bsonError.code, bsonError.message);
    return 0;
}
