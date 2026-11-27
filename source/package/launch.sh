#!/bin/sh
set -eu
PKG_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
exec /bin/sh "$PKG_DIR/activate.sh"
