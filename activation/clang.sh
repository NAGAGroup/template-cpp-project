set -e

gcc_toolchain="$(find "$CONDA_PREFIX/lib/gcc/$HOST" -maxdepth 1 -wholename "*/$HOST/*")"
export GCC_TOOLCHAIN="$gcc_toolchain"

if [ -z "$PIXI_CLANG_ACTIVE" ]; then
  export CXX="clang++"
  export CC="clang"
  export CXXFLAGS="--sysroot=$CONDA_BUILD_SYSROOT --gcc-install-dir=$GCC_TOOLCHAIN $CXXFLAGS"
  export CFLAGS="--sysroot=$CONDA_BUILD_SYSROOT --gcc-install-dir=$GCC_TOOLCHAIN $CFLAGS"
  export PIXI_CLANG_ACTIVE="1"
fi
