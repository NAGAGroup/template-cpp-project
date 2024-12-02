#!/bin/bash

set -e

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} != "1" ]]; then
  echo "Cross-compilation is not supported at the moment."
  exit 1
fi

preset="$1"
shift

cmake_args="${CMAKE_ARGS/-DCMAKE_BUILD_TYPE=Release//g}"
cmake_args="${CMAKE_ARGS/-DCMAKE_BUILD_TYPE=Debug//g}"

cmake_cmd="cmake . --preset $preset $cmake_args $*"

bash -c "$cmake_cmd"
