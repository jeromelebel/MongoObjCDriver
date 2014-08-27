#!/bin/sh

set -eu

VERSION="$1"
if [ "$VERSION" = "" ] ; then
  echo "Usage: $(basename $0) VERSION"
  exit 1
fi

git commit -m "version $VERSION" .
git push
git tag -a "$VERSION" -m "version $VERSION"
git push --tags
