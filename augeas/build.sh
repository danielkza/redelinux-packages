#!/bin/bash

BASE_DIR=$(readlink -f .)
PACKAGE_DEST_DIR=$(readlink -f "$BASE_DIR/..")"/packages/augeas"

[ -d "$PACKAGE_DEST_DIR" ] || mkdir -p "$PACKAGE_DEST_DIR"

cd "$PACKAGE_DEST_DIR"
apt-source -t testing --build augeas