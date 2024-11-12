set -e

if [ -z "$PIXI_LINUX_ACTIVE" ]; then
  export CUDA_ROOT="$CONDA_PREFIX/targets/x86_64-linux"
  export CUDA_LIB_PATH="$CUDA_ROOT/lib/stubs:$CONDA_PREFIX/lib"
  export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:$CUDA_LIB_PATH:$LD_LIBRARY_PATH"
  export VCPKG_ROOT="$PIXI_PROJECT_ROOT/vcpkg"
  export PIXI_LINUX_ACTIVE="1"
fi
