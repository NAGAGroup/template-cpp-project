set -e

if [ -z "$DPCPP_ROOT" ]; then
  export DPCPP_ROOT="$HOME/dpcpp"
fi

if [ -z "$CONDA_DPCPP_ENV_ACTIVE" ]; then
  source "$DPCPP_ROOT/conda-activate.sh"
  export MKLROOT="$PREFIX"
  export CC="$BUILD_PREFIX/bin/clang"
  export CXX="$BUILD_PREFIX/bin/clang++"
  export OCL_ICD_VENDORS="$PREFIX/etc/OpenCL/vendors"
  export CONDA_DPCPP_ENV_ACTIVE=1
fi
