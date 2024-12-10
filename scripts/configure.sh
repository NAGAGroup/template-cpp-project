#!/bin/bash

set -e

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == "1" ]]; then
  echo "Cross-compilation is not supported at the moment."
  exit 1
fi

preset="$1"
if [ -z "$preset" ]; then
  preset="dev"
else
  shift
fi

cmake_args="${CMAKE_ARGS/-DCMAKE_BUILD_TYPE=Release//g}"
cmake_args="${CMAKE_ARGS/-DCMAKE_BUILD_TYPE=Debug//g}"

cmake_cmd="cmake . --preset $preset $cmake_args $*"

bash -c "$cmake_cmd"

# Define the path to the compile_commands.json file
compile_commands_json="$PROJECT_ROOT/build/dev/compile_commands.json"

python "$PROJECT_ROOT/scripts/fix-compile-commands.py" "$compile_commands_json"
