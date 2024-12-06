set -e

if [ -z "$DPCPP_ROOT" ]; then
  export DPCPP_ROOT="$HOME/dpcpp"
fi

if [ -z "$CONDA_DPCPP_ENV_ACTIVE" ]; then
  source "$DPCPP_ROOT/conda-activate.sh"
  export MKLROOT="$PREFIX"

  export CC="$BUILD_PREFIX/bin/clang"
  export CXX="$BUILD_PREFIX/bin/clang++"
  if [ -n "$CONDA_CUDA_ROOT" ]; then
    export CFLAGS="--cuda-path=$CONDA_CUDA_ROOT $CFLAGS"
    export CXXFLAGS="--cuda-path=$CONDA_CUDA_ROOT $CXXFLAGS"
  fi

  export OCL_ICD_VENDORS="$PREFIX/etc/OpenCL/vendors"
  export OCL_ICD_FILENAMES=
  export CONDA_DPCPP_ENV_ACTIVE=1
fi
