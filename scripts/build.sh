#!/bin/bash

set -e

preset="$1"
if [ -z "$preset" ]; then
  preset="dev"
else
  shift
fi

cmake --build "build/$preset" "$@"
