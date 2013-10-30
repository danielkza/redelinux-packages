#!/bin/bash

set -e 

LIBGUESTFS_VERSION='1.24.0'
LIBGUESTFS_FOLDER="libguestfs-${LIBGUESTFS_VERSION}"
LIBGUESTFS_DEBIAN_FOLDER="libguestfs_${LIBGUESTFS_VERSION}"
LIBGUESTFS_ARCHIVE="${LIBGUESTFS_FOLDER}.tar.gz"
LIBGUESTFS_URL="http://libguestfs.org/download/1.24-stable/${LIBGUESTFS_ARCHIVE}"

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

first_file() {
	if [ $# -le 0 ]; then
		return 1
	fi

	if [ ! -f "$1" ]; then
		return 1
	fi

	echo "$1"
	return 0
}

package_missing=0
for pkg in $AUGEAS_PACKAGES; do
	if ! dpkg -s "$pkg" 2>&1 > /dev/null; then
		package_missing=1
		break
	fi
done

if [ $package_missing -ne 0 ]; then
	echo "Pacote do augeas '$pkg' faltando"

	AUGEAS_PACKAGE_DIR=$(readlink -f "$BASE_DIR/..")"/packages/augeas"

	package_not_built=0bbnlbkxx

	for pkg in $AUGEAS_PACKAGES; do
		pkg_file=$(first_file $AUGEAS_PACKAGE_DIR/${pkg}_*.deb)
		echo $pkg_file
		if [ $? -ne 0 ]; then
			package_not_built=1
			break
		fi
	done

	if [ $package_not_built -ne 0 ]; then
		echo "Pacote '$pkg' não existe, recompilando augeas"
		(cd "$BASE_DIR/../augeas" && ./build.sh)
	fi

	echo "Instalando pacotes do augeas..."
        
        packages=
	for pkg in $AUGEAS_PACKAGES; do
		packages="$packages "$AUGEAS_PACKAGE_DIR/${pkg}_*.deb
	done
        
        sudo dpkg -i $packages || true
	sudo apt-get install -f
fi

sudo mk-build-deps --install "$BASE_DIR/debian/control"

mkdir -p "$BUILD_DIR"

wget "$LIBGUESTFS_URL" -c -P "$BASE_DIR/download/"

download_archive="$BASE_DIR/download/$LIBGUESTFS_ARCHIVE"
orig_archive="$BUILD_DIR/${LIBGUESTFS_DEBIAN_FOLDER}.orig.tar.gz"

ln -s "$download_archive" "$orig_archive"
tar -xzf "$orig_archive" -C "$BUILD_DIR/"

cp -R "$BASE_DIR/debian" "$BUILD_DIR/$LIBGUESTFS_FOLDER"

cd "$BUILD_DIR/$LIBGUESTFS_FOLDER"

if [ -d "/usr/lib/ccache" ]; then
	debuild --prepend-path=/usr/lib/ccache --preserve-envvar='CCACHE_*' -us -uc -j12
else
	debuild -us -uc -j12
fi

mv "$BUILD_DIR/*.deb" "$PACKAGE_DEST_DIR"