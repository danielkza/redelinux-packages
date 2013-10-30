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

AUGEAS_PACKAGES='libaugeas0 libaugeas-dev augeas-lenses'

package_missing=0
for pkg in $AUGEAS_PACKAGES; do
	if ! dpkg -s "$pkg" 2>&1 > /dev/null; then
		package_missing=1
		break
	fi
done

if [ $package_missing -ne 0 ]; then
	echo "Pacote do augeas `$pkg` faltando"

	AUGEAS_PACKAGE_DIR=$(readlink -f "$BASE_DIR/..")"/packages/augeas"

	package_not_built=0
	for pkg in $AUGEAS_PACKAGES; do
		if [ ! -f "$AUGEAS_PACKAGE_DIR/$pkg_*.deb" ]; then
			package_not_built=1
			break
		fi
	done

	if [ $package_not_built -ne 0 ]; then
		echo "Pacote `$pkg` não existe, recompilando augeas"
		$(cd "$BASE_DIR/../augeas" && ./build.sh)
	fi

	echo "Instalando pacotes do augeas..."

	for pkg in $AUGEAS_PACKAGES; do
		sudo dpkg -i "$AUGEAS_PACKAGE_DIR/$pkg_*.deb"
	done

	sudo apt-get install -f
fi

sudo mk-build-deps --install "$BASE_DIR/debian/control"

cp -R "$BASE_DIR/libguestfs" "$BUILD_DIR/"
cp -R "$BASE_DIR/debian" "$BUILD_DIR/libguestfs/"

cd "$BUILD_DIR/libguestfs"
./bootstrap

if [ -d "/usr/lib/ccache" ]; then
	debuild --prepend-path=/usr/lib/ccache --preserve-envvar='CCACHE_*' -us -uc -j12
else
	debuild -us -uc -j12
fi    



