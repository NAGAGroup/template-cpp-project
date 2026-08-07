cmake_minimum_required(VERSION 4.2)
project(
  enginelib
  VERSION 0.1.0
  DESCRIPTION "Compiled engine library (template example package)"
  LANGUAGES CXX)

# ---- Variant knobs ---------------------------------------------------------
# Variant presets set these PROJECT-OWNED knobs (never raw CMake variables):
# the pixi-build-cmake backend passes its own -D flags (BUILD_SHARED_LIBS=ON,
# CMAKE_BUILD_TYPE=Release, ...) which outrank preset cacheVariables, so the
# mapping to real CMake variables happens HERE, where we always win.
option(ENGINELIB_SHARED "Build enginelib as a shared library" ON)
set(ENGINELIB_BUILD_TYPE "" CACHE STRING
    "Override the build type (empty = respect CMAKE_BUILD_TYPE)")
set(ENGINELIB_SANITIZER "" CACHE STRING
    "Sanitizers to enable (e.g. 'address,undefined' or 'thread')")
option(ENGINELIB_COVERAGE "Enable llvm-cov source-based coverage" OFF)

set(BUILD_SHARED_LIBS ${ENGINELIB_SHARED})
if(ENGINELIB_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE ${ENGINELIB_BUILD_TYPE})
endif()
if(ENGINELIB_SANITIZER)
  add_compile_options(-fsanitize=${ENGINELIB_SANITIZER} -fno-omit-frame-pointer)
  add_link_options(-fsanitize=${ENGINELIB_SANITIZER})
  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # Static sanitizer runtimes: consumers of the packaged variant would
    # otherwise need gcc's dynamic libasan/libtsan at run time.
    foreach(san IN ITEMS address thread undefined)
      if(ENGINELIB_SANITIZER MATCHES ${san})
        string(REGEX REPLACE "address" "asan" flag ${san})
        string(REGEX REPLACE "thread" "tsan" flag ${flag})
        string(REGEX REPLACE "undefined" "ubsan" flag ${flag})
        add_link_options(-static-lib${flag})
      endif()
    endforeach()
  endif()
endif()
if(ENGINELIB_COVERAGE)
  add_compile_options(-fprofile-instr-generate -fcoverage-mapping)
  add_link_options(-fprofile-instr-generate)
endif()

# Installed artifacts must resolve their conda-env dependencies without
# falling back to SYSTEM libraries (zero-system-tooling tenet). Package
# builds get RPATH patching from the build backend; this covers dev-flow
# `cmake --install` into the dev env prefix.
if(UNIX)
  set(CMAKE_INSTALL_RPATH "$ORIGIN")
endif()

option(ENGINELIB_DEV_MODE "Enable developer warnings (dev presets)" OFF)
if(ENGINELIB_DEV_MODE)
  add_compile_options(
    "$<$<CXX_COMPILER_ID:MSVC>:/W4>"
    "$<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall;-Wextra;-Wpedantic>")
  set(CMAKE_COMPILE_WARNING_AS_ERROR ON)
endif()

# ---- Dependencies ----------------------------------------------------------
find_package(mathkit CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)
find_package(stb CONFIG REQUIRED)

# ---- Library ---------------------------------------------------------------
add_library(enginelib src/engine.cpp)
add_library(enginelib::enginelib ALIAS enginelib)
target_include_directories(
  enginelib
  PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
         $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}/include>
         $<INSTALL_INTERFACE:include>)
target_compile_features(enginelib PUBLIC cxx_std_23)
target_link_libraries(
  enginelib
  PUBLIC mathkit::mathkit
  PRIVATE spdlog::spdlog stb::stb)

include(GenerateExportHeader)
generate_export_header(enginelib EXPORT_FILE_NAME
                       ${CMAKE_CURRENT_BINARY_DIR}/include/enginelib/export.hpp)
if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(enginelib PUBLIC ENGINELIB_STATIC_DEFINE)
endif()

# ---- Install / export ------------------------------------------------------
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

install(TARGETS enginelib EXPORT enginelibTargets)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/include/enginelib/export.hpp
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/enginelib)
install(
  EXPORT enginelibTargets
  NAMESPACE enginelib::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/enginelib)

configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/enginelibConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/enginelibConfig.cmake
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/enginelib)
write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/enginelibConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/enginelibConfig.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/enginelibConfigVersion.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/enginelib)
