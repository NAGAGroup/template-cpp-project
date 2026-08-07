cmake_minimum_required(VERSION 4.2)
project(
  mathkit
  VERSION 0.1.0
  DESCRIPTION "Header-only math utilities (template example package)"
  LANGUAGES CXX)

option(MATHKIT_DEV_MODE "Enable developer warnings (dev presets)" OFF)
if(MATHKIT_DEV_MODE)
  add_compile_options(
    "$<$<CXX_COMPILER_ID:MSVC>:/W4>"
    "$<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall;-Wextra;-Wpedantic>")
  set(CMAKE_COMPILE_WARNING_AS_ERROR ON)
endif()

add_library(mathkit INTERFACE)
add_library(mathkit::mathkit ALIAS mathkit)
target_include_directories(
  mathkit INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
                    $<INSTALL_INTERFACE:include>)
target_compile_features(mathkit INTERFACE cxx_std_23)

# ---- Install / export ------------------------------------------------------
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

install(TARGETS mathkit EXPORT mathkitTargets)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(
  EXPORT mathkitTargets
  NAMESPACE mathkit::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/mathkit)

configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/mathkitConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/mathkitConfig.cmake
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/mathkit)
write_basic_package_version_file(
  ${CMAKE_CURRENT_BINARY_DIR}/mathkitConfigVersion.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
  ARCH_INDEPENDENT)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/mathkitConfig.cmake
              ${CMAKE_CURRENT_BINARY_DIR}/mathkitConfigVersion.cmake
        DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/mathkit)
