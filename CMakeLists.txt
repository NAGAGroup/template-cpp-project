cmake_minimum_required(VERSION 3.24)

include(cmake/prelude.cmake)

project(
  template-cpp-project
  VERSION 0.1.0
  DESCRIPTION "Short description"
  HOMEPAGE_URL "https://example.com/"
  LANGUAGES CXX
)

include(cmake/project-is-top-level.cmake)
include(cmake/variables.cmake)
# Uncomment below for SYCL/OneMKL support option(ENABLE_SYCL "Enable
# add_sycl_to_target" OFF)
if(ENABLE_SYCL)
  include(cmake/sycl.cmake)
  # find_package(oneMKL REQUIRED)
endif()

# ---- Declare library ----

file(GLOB_RECURSE SOURCES "${CMAKE_SOURCE_DIR}/source/*.cpp"
     "${CMAKE_SOURCE_DIR}/include/*.h" "${CMAKE_SOURCE_DIR}/include/*.hpp"
)

add_library(template-cpp-project_template-cpp-project ${SOURCES})
add_library(
  template-cpp-project::template-cpp-project ALIAS
  template-cpp-project_template-cpp-project
)

if(ENABLE_SYCL)
  add_sycl(template-cpp-project_template-cpp-project)
  # target_link_libraries(template-cpp-project PUBLIC MKL::onemkl)
endif()

set_target_properties(
  template-cpp-project_template-cpp-project
  PROPERTIES VISIBILITY_INLINES_HIDDEN YES
             VERSION "${PROJECT_VERSION}"
             SOVERSION "${PROJECT_VERSION_MAJOR}"
             EXPORT_NAME template-cpp-project
             OUTPUT_NAME template-cpp-project
)

target_include_directories(
  template-cpp-project_template-cpp-project ${warning_guard}
  PUBLIC "\$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>"
)

target_include_directories(
  template-cpp-project_template-cpp-project SYSTEM
  PUBLIC "\$<BUILD_INTERFACE:${PROJECT_BINARY_DIR}/export>"
)

target_compile_features(
  template-cpp-project_template-cpp-project PUBLIC cxx_std_17
)

find_package(fmt REQUIRED)
target_link_libraries(
  template-cpp-project_template-cpp-project PRIVATE fmt::fmt
)

# ---- Install rules ----

if(NOT CMAKE_SKIP_INSTALL_RULES)
  include(cmake/install-rules.cmake)
endif()

# ---- Developer mode ----

if(NOT template-cpp-project_DEVELOPER_MODE)
  return()
elseif(NOT PROJECT_IS_TOP_LEVEL)
  message(
    AUTHOR_WARNING
      "Developer mode is intended for developers of template-cpp-project"
  )
endif()

include(cmake/dev-mode.cmake)
