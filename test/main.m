//
//  main.m
//  test
//
//  Created by Jérôme Lebel on 17/10/2014.
//
//

#import <Foundation/Foundation.h>
#import <MongoObjCDriver/mongoc.h>

#define MYMALLOC 1
#define PRINT(x...)  printf(x);

#if MYMALLOC
static int currentMark = 0;

typedef struct _Node {
    void *pointer;
    int mark;
    size_t size;
    struct _Node *next;
    struct _Node *previous;
} Node;

Node *firstNode = NULL;

static Node * findNodeForPointer(void *pointer)
{
    Node *cursor = firstNode;
    
    while (cursor != NULL && cursor->pointer != pointer) {
        cursor = cursor->next;
    }
    return cursor;
}

static Node * addNode(void *pointer, size_t size)
{
    Node *newNode = malloc(sizeof(Node));
    
    newNode->pointer = pointer;
    newNode->size = size;
    newNode->next = firstNode;
    newNode->previous = NULL;
    newNode->mark = currentMark;
    
    if (firstNode) {
        firstNode->previous = newNode;
    }
    firstNode = newNode;
    
    return newNode;
}

static void removeNode(Node *node)
{
    if (node->previous != NULL) {
        node->previous->next = node->next;
    } else {
        assert(node == firstNode);
        firstNode = node->next;
    }
    if (node->next != NULL) {
        node->next->previous = node->previous;
    }
    free(node);
}

static void *mymalloc(size_t size)
{
    void *result = malloc(size);
    
    addNode(result, size);
    PRINT("malloc %p\n", result);
    return result;
}

static void *mycalloc(size_t n_members, size_t size)
{
    void *result = malloc(n_members * size);
    
    addNode(result, n_members * size);
    PRINT("malloc %p\n", result);
    return result;
}

static void *myrealloc(void *pointer, size_t size)
{
    Node *node;
    
    if (pointer) {
        node = findNodeForPointer(pointer);
        assert(node != NULL);
    } else {
        node = addNode(NULL, size);
    }
    PRINT("realloc from %p to %p\n", pointer, node->pointer);
    node->pointer = reallocf(pointer, size);
    return node->pointer;
}

static void myfree(void *pointer)
{
    PRINT("free %p\n", pointer);
    free(pointer);
    if (pointer) {
        Node *node = findNodeForPointer(pointer);
        
        assert(node != NULL);
        removeNode(node);
    }
}

static void printNodeAfterMark(int mark)
{
    Node *cursor = firstNode;
    
    while (cursor != NULL) {
        if (cursor->mark > mark) {
            printf("buffer %p\n", cursor->pointer);
        }
        cursor = cursor->next;
    }
}
#endif


int main(int argc, const char * argv[])
{
    mongoc_client_t *client;
    mongoc_database_t *database;
    bson_t *infos;
    bson_error_t bsonError;
    bson_oid_t oid;
    
#if MYMALLOC
    bson_mem_vtable_t vtable = { mymalloc, mycalloc, myrealloc, myfree };

    bson_mem_set_vtable (&vtable);
#endif
    
    bson_oid_init_from_string(&oid, "5126bc054aed4daf9e2ab772");
    
    client = mongoc_client_new("mongodb://192.168.174.202");
    database = mongoc_client_get_database(client, "test");
    currentMark = 1;
    infos = mongoc_database_get_collection_info (database, NULL, &bsonError);
    if (infos) {
        bson_destroy(infos);
    }
    mongoc_database_destroy(database);
    mongoc_client_destroy(client);
    printf("----\n");
    printNodeAfterMark(-1);
    
    return 0;
}
