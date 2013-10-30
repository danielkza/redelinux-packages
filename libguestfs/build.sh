#!/bin/bash

set -e 

BASE_DIR=$(readlink -f .)
PACKAGE_DEST_DIR=$(readlink -f "$BASE_DIR/..")"/packages/libguestfs"
BUILD_DIR=/tmp/redelinux-packages/libguestfs

[ -d "$PACKAGE_DEST_DIR" ] || mkdir -p "$PACKAGE_DEST_DIR"

if [ -d "$BUILD_DIR" ]; then
    rm -rf "$BUILD_DIR"
fi

mkdir -p "$BUILD_DIR"

##

if [ ! -f /usr/lib/pkgconfig/python-2.6.pc ]; then
    export PKG_CONFIG_PATH="$BASE_DIR/pkgconfig"
fi

sudo apt-get install -t testing augeas-lenses libaugeas0 libaugeas-dev
sudo apt-get build-dep libguestfs

cp -R "$BASE_DIR/libguestfs" "$BUILD_DIR/"
cp -R "$BASE_DIR/debian" "$BUILD_DIR/libguestfs/"

cd "$BUILD_DIR/libguestfs"
./bootstrap

if [ -d "/usr/lib/ccache" ]; then
	debuild --prepend-path=/usr/lib/ccache --preserve-envvar='CCACHE_*' -us -uc -j12
else
	debuild -us -uc -j12
fi    



