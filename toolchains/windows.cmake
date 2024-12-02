set(CMAKE_C_COMPILER
    "$ENV{CC}"
    CACHE FILEPATH "" FORCE
)
set(CMAKE_CXX_COMPILER
    "$ENV{CXX}"
    CACHE FILEPATH "" FORCE
)
set(CMAKE_MAKE_PROGRAM
    "$ENV{BUILD_PREFIX}/bin/ninja"
    CACHE FILEPATH "" FORCE
)

if(template-cpp-project_CFLAGS_PREPEND)
  set(CMAKE_C_FLAGS "${CFLAGS_PREPEND} ${CMAKE_C_FLAGS}")
endif()
if(template-cpp-project_CFLAGS_APPEND)
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${CFLAGS_APPEND}")
endif()

if(template-cpp-project_CXXFLAGS_PREPEND)
  set(CMAKE_CXX_FLAGS "${CXXFLAGS_PREPEND} ${CMAKE_CXX_FLAGS}")
endif()
if(template-cpp-project_CXXFLAGS_APPEND)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${CXXFLAGS_APPEND}")
endif()

if(template-cpp-project_LDLAGS_PREPEND)
  set(CMAKE_EXE_LINKER_FLAGS "${LDLAGS_PREPEND} ${CMAKE_EXE_LINKER_FLAGS}")
  set(CMAKE_SHARED_LINKER_FLAGS
      "${LDLAGS_PREPEND} ${CMAKE_SHARED_LINKER_FLAGS}"
  )
endif()
if(template-cpp-project_LDLAGS_APPEND)
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${LDLAGS_APPEND}")
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} ${LDLAGS_APPEND}")
endif()

if(NOT "$ENV{NO_INSTALL_RPATH}" STREQUAL "1")
  if("$ENV{INSTALL_RPATHS}" STREQUAL "")
    set(CMAKE_INSTALL_RPATH "\$ORIGIN;\$ORIGIN/../lib;\$ORIGIN/../lib64")
  else()
    set(CMAKE_INSTALL_RPATH "$ENV{INSTALL_RPATHS}")
  endif()
  set(CMAKE_SKIP_RPATH
      FALSE
      CACHE BOOL "" FORCE
  )
  set(CMAKE_SKIP_INSTALL_RPATH
      FALSE
      CACHE BOOL "" FORCE
  )
  set(CMAKE_SKIP_BUILD_RPATH
      FALSE
      CACHE BOOL "" FORCE
  )
endif()

if(DEFINED ENV{CONDA_CUDA_ROOT})
  set(CUDAToolkit_ROOT
      "$ENV{CONDA_CUDA_ROOT}"
      CACHE PATH ""
  )
endif()

if(DEFINED ENV{VCPKG_ROOT})
  include("$ENV{VCPKG_ROOT}/scripts/toolchains/windows.cmake")
  include("$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")
endif()
