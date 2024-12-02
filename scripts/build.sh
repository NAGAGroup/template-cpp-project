#!/bin/bash

set -e

preset="$1"
shift

cmake --build "build/$preset" "$@"
