set -e

if [ -z "$CONDA_CLANG_ENV_ACTIVE" ]; then
  gcc_version=$(gcc -dumpversion)
  gcc_install_dir="$PREFIX/lib/gcc/$CONDA_TOOLCHAIN_HOST/$gcc_version"
  export CFLAGS="--gcc-install-dir=$gcc_install_dir $CFLAGS"
  export CXXFLAGS="--gcc-install-dir=$gcc_install_dir $CXXFLAGS"
  export CONDA_CLANG_ENV_ACTIVE="1"
fi
