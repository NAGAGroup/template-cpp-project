#!/bin/bash
set -e

if [ "$CONDA_LINUX_ENV_ACTIVE" != "1" ]; then
  if [ -z "$BUILD_PREFIX" ]; then
    export BUILD_PREFIX="$CONDA_PREFIX"
  fi
  if [ -z "$PREFIX" ]; then
    export PREFIX="$CONDA_PREFIX"
  fi
  if [ -z "$INSTALL_PREFIX" ]; then
    export INSTALL_PREFIX="$PREFIX"
  fi
  if [ -z "$CONDA_TOOLCHAIN_HOST" ]; then
    export CONDA_TOOLCHAIN_HOST="$HOST"
  fi
  if [ -z "$PROJECT_ROOT" ]; then
    export PROJECT_ROOT="$PIXI_PROJECT_ROOT"
  fi

  export CXXFLAGS="--sysroot=$CONDA_BUILD_SYSROOT $CXXFLAGS"
  export CFLAGS="--sysroot=$CONDA_BUILD_SYSROOT $CFLAGS"

  CONDA_CUDA_ROOT="$PREFIX/targets/x86_64-linux"
  if [ -d "$CONDA_CUDA_ROOT" ]; then
    export CONDA_CUDA_ROOT="$CONDA_CUDA_ROOT"
    export CUDA_LIB_PATH="$CONDA_CUDA_ROOT/lib/stubs"
  fi

  export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"

  export PROJECT_TOOLCHAIN_FILE="$PROJECT_ROOT/toolchains/linux.cmake"

  if [ -d "$PROJECT_ROOT/vcpkg" ]; then
    export VCPKG_ROOT="$PROJECT_ROOT/vcpkg"
  fi

  export CONDA_LINUX_ENV_ACTIVE=1
fi
