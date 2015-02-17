#!/bin/sh

set -eu

VERSION="$1"
if [ "$VERSION" = "" ] ; then
  echo "Usage: $(basename $0) VERSION"
  exit 1
fi


cd Libraries/mongo-c-driver/src/libbson
git commit -m "version $VERSION" .
git push
git tag -a "$VERSION" -m "version $VERSION"
git push --tags

cd ../..
git submodule status | awk '{ print $1 }' | sed 's/^.//' > src/libbson.sha1
git commit -m "version $VERSION" .
git push
git tag -a "$VERSION" -m "version $VERSION"
git push --tags

cd ../..

git submodule status | awk '{ print $1 }' | sed 's/^.//' > Libraries/mongo-c-driver.sha1
git commit -m "version $VERSION" .
git push
git tag -a "$VERSION" -m "version $VERSION"
git push --tags
