set -e

if [[ "${CONDA_LINUX_ENV_ACTIVE:-0}" != "1" ]]; then
  # Use PIXI_PROJECT_ROOT if PROJECT_ROOT is not set (activation order issue)
  _proj_root="${PROJECT_ROOT:-$PIXI_PROJECT_ROOT}"
  source "$_proj_root/activation/linux.sh"
fi

if [ "${CONDA_CLANG_ENV_ACTIVE:-0}" == "0" ]; then
  gcc_version=$(gcc -dumpversion)
  gcc_install_dir="$PREFIX/lib/gcc/$CONDA_TOOLCHAIN_HOST/$gcc_version"
  export GCC_INSTALL_DIR="$gcc_install_dir"
  export CONDA_CLANG_ENV_ACTIVE="1"
fi
