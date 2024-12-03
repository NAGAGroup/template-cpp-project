#!/bin/bash
set -e

if [ "$CONDA_RUNTIME_ENV_ACTIVE" != "1" ]; then
  if [ -f "$INSTALL_PREFIX/conda-activate.sh" ]; then
    source "$INSTALL_PREFIX/conda-activate.sh"
  fi

  export CONDA_RUNTIME_ENV_ACTIVE=1
fi
