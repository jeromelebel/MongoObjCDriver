#!/bin/sh

pushd .
cd Libraries/mongo-c-driver/src/libbson/
./autogen.sh 
cp src/bson/bson-config.h src/bson/bson-stdint.h src/bson/bson-version.h ../../../../Sources/generated-headers
popd

pushd .
cd Libraries/mongo-c-driver
./autogen.sh 
cp src/mongoc/mongoc-config.h src/mongoc/mongoc-version.h ../../Sources/generated-headers
popd
