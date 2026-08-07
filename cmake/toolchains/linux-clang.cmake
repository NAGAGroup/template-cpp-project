# Example toolchain file: build with clang from the active conda env.
#
# Toolchain files carry what CMake presets shouldn't: compiler/platform
# machinery. Use from a dev env (which provides clang via its closure or
# feature deps):
#   cmake --preset dev -DCMAKE_TOOLCHAIN_FILE=../../cmake/toolchains/linux-clang.cmake
#
# In the pixi-build world the PACKAGE toolchain is owned by the backend
# (compilers = [...] in [package.build.config], or compilers = [] plus
# explicit build-dependencies — see enginelib's coverage variant). This
# file exists for in-tree experimentation and as the template for the
# own-toolchain variation described in docs/toolchains.md.
set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
