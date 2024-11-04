# this one is important
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_PLATFORM Linux)

# where is the target environment
set(CMAKE_FIND_ROOT_PATH $ENV{DPCPP_ROOT} $ENV{CONDA_PREFIX}
                         $ENV{CONDA_BUILD_SYSROOT} $ENV{CUDA_ROOT})

set(CUDA_TOOLKIT_ROOT_DIR $ENV{CUDA_ROOT})

set(CMAKE_SYSROOT $ENV{CONDA_BUILD_SYSROOT})

# search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
