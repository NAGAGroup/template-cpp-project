cmake_minimum_required(VERSION 4.2)
project(
  demo-app
  VERSION 0.1.0
  DESCRIPTION "Demo application (template example consumer)"
  LANGUAGES CXX)

option(DEMO_APP_DEV_MODE "Enable developer warnings (dev presets)" OFF)
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
target_link_libraries(demo-app PRIVATE enginelib::enginelib fmt::fmt)

include(GNUInstallDirs)
install(TARGETS demo-app RUNTIME)
