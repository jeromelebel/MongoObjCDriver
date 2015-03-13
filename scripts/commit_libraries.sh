#!/bin/sh

set -eux

COMMENT="$1"
if [ "$COMMENT" = "" ] ; then
  echo "Usage: $(basename $0) COMMENT"
  exit 1
fi


cd Libraries/mongo-c-driver/src/libbson
git commit -m "${COMMENT}" . || true
git push

cd ../..
git submodule status | sed 's/^.//' | awk '{ print $1 }' > src/libbson.sha1
git commit -m "${COMMENT}" . || true
git push

cd ../..
git submodule status | sed 's/^.//' | awk '{ print $1 }' > Libraries/mongo-c-driver.sha1
git commit -m "${COMMENT}" . || true
git push
