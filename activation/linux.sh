#!/bin/bash
set -e

if [ "${CONDA_LINUX_ENV_ACTIVE:-0}" != "1" ]; then
  if [ -z "$BUILD_PREFIX" ]; then
    export BUILD_PREFIX="$CONDA_PREFIX"
  fi
  if [ -z "$PREFIX" ]; then
    export PREFIX="$BUILD_PREFIX"
  fi
  if [ -z "$INSTALL_PREFIX" ]; then
    export INSTALL_PREFIX="$HOME/.local/share/dev"
  fi
  if [ -z "$CONDA_TOOLCHAIN_HOST" ]; then
    export CONDA_TOOLCHAIN_HOST="$HOST"
  fi
  # Use PIXI_PROJECT_ROOT if PROJECT_ROOT is not set (activation order issue)
  _proj_root="${PROJECT_ROOT:-$PIXI_PROJECT_ROOT}"
  if [ -z "$_proj_root" ]; then
    echo "ERROR: Neither PROJECT_ROOT nor PIXI_PROJECT_ROOT is set" >&2
    exit 1
  fi
  # Export PROJECT_ROOT if it wasn't already set
  export PROJECT_ROOT="$_proj_root"

  CONDA_CUDA_ROOT="$PREFIX/targets/x86_64-linux"
  if [ -d "$CONDA_CUDA_ROOT" ]; then
    export CONDA_CUDA_ROOT="$CONDA_CUDA_ROOT"
    export CUDA_LIB_PATH="$CONDA_CUDA_ROOT/lib/stubs"
    export LD_LIBRARY_PATH="$CONDA_CUDA_ROOT/lib:$CONDA_CUDA_ROOT/lib/stubs:$LD_LIBRARY_PATH"
  fi

  if [ "${ENABLE_LD_LIBRARY_PATH:-0}" == "1" ]; then
    export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
  fi

  export PROJECT_TOOLCHAIN_FILE="$_proj_root/toolchains/linux.cmake"

  if [ -d "$_proj_root/vcpkg" ]; then
    export VCPKG_ROOT="$_proj_root/vcpkg"
  fi

  export CONDA_LINUX_ENV_ACTIVE=1
fi
