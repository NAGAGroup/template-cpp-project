# this one is important
set(CMAKE_SYSTEM_NAME Windows)

set(CMAKE_SYSTEM_PROCESSOR "x86_64")

set(CMAKE_FIND_ROOT_PATH $ENV{CONDA_PREFIX})

# search for programs in the build host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)

# for libraries and headers in the target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
