cmake_minimum_required(VERSION 4.2)
project(
  demo-app
  VERSION 0.1.0
  DESCRIPTION "Demo application (template example consumer)"
  LANGUAGES CXX)

find_package(enginelib CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)

add_executable(demo-app src/main.cpp)
target_compile_features(demo-app PRIVATE cxx_std_23)
target_link_libraries(demo-app PRIVATE enginelib::enginelib fmt::fmt)

include(GNUInstallDirs)
install(TARGETS demo-app RUNTIME)
