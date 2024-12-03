#!/bin/bash

set -e

if [[ ${CONDA_BUILD_CROSS_COMPILATION:-0} == "1" ]]; then
  echo "Cross-compilation is not supported at the moment."
  exit 1
fi

preset="$1"
shift

cmake_args="${CMAKE_ARGS/-DCMAKE_BUILD_TYPE=Release//g}"
cmake_args="${CMAKE_ARGS/-DCMAKE_BUILD_TYPE=Debug//g}"

cmake_cmd="cmake . --preset $preset $cmake_args $*"

bash -c "$cmake_cmd"

# Define the path to the compile_commands.json file
compile_commands_json="$PROJECT_ROOT/build/dev/compile_commands.json"

# Read the compile_commands.json file
json_content=$(cat "$compile_commands_json")

for flag in $FILTER_COMPILE_COMMANDS_FLAGS; do
  # Escape special characters in the flag for sed
  escaped_flag=$(echo "$flag" | sed 's/[]\/$*.^|[]/\\&/g')
  # Remove the flag with or without an argument
  json_content=$(echo "$json_content" | sed -E "s/($escaped_flag(=[^ ]*)?)[ ]*//g")
done

# Write the filtered JSON back to the file
echo "$json_content" >"$compile_commands_json"

echo "Filtered compile_commands.json and removed flags: $FILTER_COMPILE_COMMANDS_FLAGS"
