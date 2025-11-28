set -e

if [[ "${CONDA_LINUX_ENV_ACTIVE:-0}" != "1" ]]; then
  # Use PIXI_PROJECT_ROOT if PROJECT_ROOT is not set (activation order issue)
  _proj_root="${PROJECT_ROOT:-$PIXI_PROJECT_ROOT}"
  source "$_proj_root/activation/linux.sh"
fi

if [ "${CONDA_DPCPP_ENV_ACTIVE:-0}" == "0" ]; then
  export MKLROOT="$PREFIX"
  export CC="$BUILD_PREFIX/bin/clang"
  export CXX="$BUILD_PREFIX/bin/clang++"
  export OCL_ICD_VENDORS="$PREFIX/etc/OpenCL/vendors"
  export OCL_ICD_FILENAMES=
  export CONDA_DPCPP_ENV_ACTIVE=1
fi
