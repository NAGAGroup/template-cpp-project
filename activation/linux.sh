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
  project_root="${PROJECT_ROOT?PROJECT_ROOT must be set before script activation.}"

  CONDA_CUDA_ROOT="$PREFIX/targets/x86_64-linux"
  if [ -d "$CONDA_CUDA_ROOT" ]; then
    export CONDA_CUDA_ROOT="$CONDA_CUDA_ROOT"
    export CUDA_LIB_PATH="$CONDA_CUDA_ROOT/lib/stubs"
    export LD_LIBRARY_PATH="$CONDA_CUDA_ROOT/lib:$CONDA_CUDA_ROOT/lib/stubs:$LD_LIBRARY_PATH"
  fi

  if [ "${ENABLE_LD_LIBRARY_PATH:-0}" == "1" ]; then
    export LD_LIBRARY_PATH="$PREFIX/lib:$LD_LIBRARY_PATH"
  fi

  export PROJECT_TOOLCHAIN_FILE="$PROJECT_ROOT/toolchains/linux.cmake"

  if [ -d "$PROJECT_ROOT/vcpkg" ]; then
    export VCPKG_ROOT="$PROJECT_ROOT/vcpkg"
  fi

  export CONDA_LINUX_ENV_ACTIVE=1
fi
