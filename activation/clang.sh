set -e

if [ -z "$PIXI_CLANG_ACTIVE" ]; then
  gcc_version=$(gcc -dumpversion)
  gcc_install_dir="$PREFIX/lib/gcc/$CONDA_TOOLCHAIN_HOST/$gcc_version"
  export CFLAGS="--gcc-install-dir=$gcc_install_dir --target=$CONDA_TOOLCHAIN_HOST $CFLAGS"
  export CXXFLAGS="--gcc-install-dir=$gcc_install_dir --target=$CONDA_TOOLCHAIN_HOST $CXXFLAGS"
  export PIXI_CLANG_ACTIVE="1"
fi
