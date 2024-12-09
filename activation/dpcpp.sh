set -e

if [[ "${CONDA_LINUX_ENV_ACTIVE:-0}" != "1" ]]; then
  source "$PROJECT_ROOT/activation/linux.sh"
fi

if [ "${CONDA_DPCPP_ENV_ACTIVE:-0}" == "0" ]; then
  export MKLROOT="$PREFIX"
  export OCL_ICD_VENDORS="$PREFIX/etc/OpenCL/vendors"
  export OCL_ICD_FILENAMES=
  export CONDA_DPCPP_ENV_ACTIVE=1
fi
