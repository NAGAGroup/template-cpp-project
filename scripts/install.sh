#!/bin/bash

set -e

preset="$1"

cmake --install "build/$preset"

cp -r "$PROJECT_ROOT/files/"* "$INSTALL_PREFIX"

if [ -z "$NO_PATCHELF" ]; then
  NO_PATCHELF="0"
fi

if [ "$NO_PATCHELF" != "1" ]; then
  bash "$PROJECT_ROOT/scripts/patch_installed_rpaths.sh"
fi
