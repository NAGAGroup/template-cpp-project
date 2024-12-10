set -e

if [[ "${CONDA_LINUX_ENV_ACTIVE:-0}" != "1" ]]; then
  source "$PROJECT_ROOT/activation/linux.sh"
fi

if [ "${CONDA_CLANG_ENV_ACTIVE:-0}" == "0" ]; then
  gcc_version=$(gcc -dumpversion)
  gcc_install_dir="$PREFIX/lib/gcc/$CONDA_TOOLCHAIN_HOST/$gcc_version"
  export GCC_INSTALL_DIR="$gcc_install_dir"
  export CONDA_CLANG_ENV_ACTIVE="1"
fi
