set -e

if [[ "${CONDA_LINUX_ENV_ACTIVE:-0}" != "1" ]]; then
  # Use PIXI_PROJECT_ROOT if PROJECT_ROOT is not set (activation order issue)
  _proj_root="${PROJECT_ROOT:-$PIXI_PROJECT_ROOT}"
  source "$_proj_root/activation/linux.sh"
fi

if [ -z "$CONDA_GCC_ENV_ACTIVE" ]; then
  export CONDA_GCC_ENV_ACTIVE="1"
fi
