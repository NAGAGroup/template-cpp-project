cmake_minimum_required(VERSION 4.2)
project(
  demo-app
  VERSION 0.1.0
  DESCRIPTION "Demo application (template example consumer)"
  LANGUAGES CXX)

option(DEMO_APP_DEV_MODE "Enable developer warnings (dev presets)" OFF)
# ABI-regime closure (see enginelib): mingw builds cannot link the
# MSVC-built fmt import library — consume fmt header-only there.
option(DEMO_APP_HEADER_ONLY_DEPS
       "Consume fmt header-only (required off-regime, e.g. mingw)" OFF)
if(DEMO_APP_DEV_MODE)
  add_compile_options(
    "$<$<CXX_COMPILER_ID:MSVC>:/W4>"
    "$<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall;-Wextra;-Wpedantic>")
  set(CMAKE_COMPILE_WARNING_AS_ERROR ON)
endif()

find_package(enginelib CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)

add_executable(demo-app src/main.cpp)
target_compile_features(demo-app PRIVATE cxx_std_23)
if(DEMO_APP_HEADER_ONLY_DEPS)
  # Scrub MSVC-baked interface options from the foreign-regime config
  # (see enginelib — regime closure reaches CMake metadata).
  foreach(dep_tgt fmt::fmt fmt::fmt-header-only)
    if(TARGET ${dep_tgt})
      set_target_properties(${dep_tgt} PROPERTIES INTERFACE_COMPILE_OPTIONS "")
    endif()
  endforeach()
  target_link_libraries(demo-app PRIVATE enginelib::enginelib
                                         fmt::fmt-header-only)
else()
  target_link_libraries(demo-app PRIVATE enginelib::enginelib fmt::fmt)
endif()

include(GNUInstallDirs)
install(TARGETS demo-app RUNTIME)
