#!/bin/sh

set -eux

COMMENT="$1"
if [ "${COMMENT}" = "" ] ; then
  echo "Usage: $(basename $0) COMMENT"
  exit 1
fi


cd Libraries/mongo-c-driver/src/libbson
./autogen.sh
./configure
git commit -m "${COMMENT}" . || true
git push

cd ../..
./autogen.sh
./configure
git submodule status | sed 's/^.//' | awk '{ print $1 }' > src/libbson.sha1
git commit -m "${COMMENT}" . || true
git push

cd ../..
git submodule status | sed 's/^.//' | awk '{ print $1 }' > Libraries/mongo-c-driver.sha1
git commit -m "${COMMENT}" . || true
git push


cp Libraries/mongo-c-driver/src/libbson/src/bson/bson-config.h      Sources/generated-headers/bson-config.h
cp Libraries/mongo-c-driver/src/libbson/src/bson/bson-stdint.h      Sources/generated-headers/bson-stdint.h
cp Libraries/mongo-c-driver/src/libbson/src/bson/bson-version.h     Sources/generated-headers/bson-version.h
cp Libraries/mongo-c-driver/src/mongoc/mongoc-config.h              Sources/generated-headers/mongoc-config.h
cp Libraries/mongo-c-driver/src/mongoc/mongoc-version.h             Sources/generated-headers/mongoc-version.h
