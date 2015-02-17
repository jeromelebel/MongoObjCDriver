#!/bin/sh

set -eux

VERSION="$1"
if [ "$VERSION" = "" ] ; then
  echo "Usage: $(basename $0) VERSION"
  exit 1
fi


cd Libraries/mongo-c-driver/src/libbson
git commit -m "version $VERSION" . || true
git push
git tag -a "$VERSION" -m "version $VERSION"
git push --tags

cd ../..
git submodule status | sed 's/^.//' | awk '{ print $1 }' > src/libbson.sha1
git commit -m "version $VERSION" . || true
git push
git tag -a "$VERSION" -m "version $VERSION"
git push --tags

cd ../..

git submodule status | sed 's/^.//' | awk '{ print $1 }' > Libraries/mongo-c-driver.sha1
git commit -m "version $VERSION" . || true
git push
git tag -a "$VERSION" -m "version $VERSION"
git push --tags
