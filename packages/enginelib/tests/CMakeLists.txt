cmake_minimum_required(VERSION 4.2)
project(enginelib-tests LANGUAGES CXX)

# Tests are a CONSUMER PROJECT: they find_package() the installed
# enginelib rather than being built inside its tree. Cross-project
# consumption is pixi's job, not CMake's.

# ---- Variant knobs (tests must be built like the lib they test) ------------
set(ENGINELIB_TESTS_SANITIZER "" CACHE STRING
    "Sanitizers to enable (must match the enginelib variant under test)")
option(ENGINELIB_TESTS_COVERAGE "Enable llvm-cov coverage instrumentation" OFF)
set(ENGINELIB_TESTS_BUILD_TYPE "" CACHE STRING
    "Override the build type (empty = respect CMAKE_BUILD_TYPE)")

if(ENGINELIB_TESTS_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE ${ENGINELIB_TESTS_BUILD_TYPE})
endif()
if(ENGINELIB_TESTS_SANITIZER)
  add_compile_options(-fsanitize=${ENGINELIB_TESTS_SANITIZER}
                      -fno-omit-frame-pointer)
  add_link_options(-fsanitize=${ENGINELIB_TESTS_SANITIZER})
  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    foreach(san IN ITEMS address thread undefined)
      if(ENGINELIB_TESTS_SANITIZER MATCHES ${san})
        string(REGEX REPLACE "address" "asan" flag ${san})
        string(REGEX REPLACE "thread" "tsan" flag ${flag})
        string(REGEX REPLACE "undefined" "ubsan" flag ${flag})
        add_link_options(-static-lib${flag})
      endif()
    endforeach()
  endif()
endif()
if(ENGINELIB_TESTS_COVERAGE)
  add_compile_options(-fprofile-instr-generate -fcoverage-mapping)
  add_link_options(-fprofile-instr-generate)
endif()

# ---- Dependencies ----------------------------------------------------------
find_package(enginelib CONFIG REQUIRED)
find_package(Catch2 3 CONFIG REQUIRED)

# ---- Test binary -----------------------------------------------------------
add_executable(enginelib-tests src/test_engine.cpp)
target_compile_features(enginelib-tests PRIVATE cxx_std_23)
target_link_libraries(enginelib-tests PRIVATE enginelib::enginelib
                                              Catch2::Catch2WithMain)

include(CTest)
include(Catch)
catch_discover_tests(enginelib-tests)

include(GNUInstallDirs)
install(TARGETS enginelib-tests RUNTIME)
