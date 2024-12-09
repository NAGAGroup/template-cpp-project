#!/bin/bash

set -e

install_dir=$(bash -c "cd -- $(dirname -- "${BASH_SOURCE[0]}") &>/dev/null && pwd")
find "$install_dir" -maxdepth 1 -exec cp -r {} "$CONDA_PREFIX" ";"
