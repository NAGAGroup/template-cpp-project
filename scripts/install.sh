#!/bin/bash

set -e

preset="$1"
if [ -z "$preset" ]; then
  preset="dev"
else
  shift
fi

cmake --install "build/$preset"

cp -r "$PROJECT_ROOT/files/"* "$INSTALL_PREFIX"
