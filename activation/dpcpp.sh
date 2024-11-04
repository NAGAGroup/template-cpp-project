if [ -z "$DPCPP_ROOT" ]; then
  export DPCPP_ROOT="$HOME/intel/dpcpp"
fi
gcc_toolchain="$(find "$CONDA_PREFIX/lib/gcc/$HOST" -maxdepth 1 -wholename "*/$HOST/*")"
export GCC_TOOLCHAIN="$gcc_toolchain"
if [ -z "$PIXI_DPCPP_ACTIVE" ]; then
  source "$DPCPP_ROOT/setvars.sh"
  export CXXFLAGS="$DPCPP_CXXFLAGS"
  export CFLAGS="$DPCPP_CFLAGS"
  export LDFLAGS="$DPCPP_LDFLAGS"
  export CMAKE_TOOLCHAIN_FILE="$PIXI_PROJECT_ROOT/toolchains/dpcpp-linux.cmake"
  export PIXI_DPCPP_ACTIVE=1
fi
