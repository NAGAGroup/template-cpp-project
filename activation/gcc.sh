set -e

if [ -z "$CONDA_GCC_ENV_ACTIVE" ]; then
  export CFLAGS="--sysroot=$CONDA_BUILD_SYSROOT $CFLAGS"
  export CXXFLAGS="--sysroot=$CONDA_BUILD_SYSROOT $CXXFLAGS"
  export CONDA_GCC_ENV_ACTIVE="1"
fi
