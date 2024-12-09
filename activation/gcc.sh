set -e

if [[ "${CONDA_LINUX_ENV_ACTIVE:-0}" != "1" ]]; then
  source "$PROJECT_ROOT/activation/linux.sh"
fi

if [ -z "$CONDA_GCC_ENV_ACTIVE" ]; then
  export CONDA_GCC_ENV_ACTIVE="1"
fi
