cmake_minimum_required(VERSION 3.14)

project(template-cpp-projectTests LANGUAGES CXX)

include(../cmake/project-is-top-level.cmake)
include(../cmake/folders.cmake)

# ---- Dependencies ----

if(PROJECT_IS_TOP_LEVEL)
  find_package(template-cpp-project REQUIRED)
  enable_testing()
endif()

find_package(Catch2 REQUIRED)
include(Catch)

# ---- Tests ----

add_executable(template-cpp-project_test source/template-cpp-project_test.cpp)
target_link_libraries(
    template-cpp-project_test PRIVATE
    template-cpp-project::template-cpp-project
    Catch2::Catch2WithMain
)
target_compile_features(template-cpp-project_test PRIVATE cxx_std_17)

catch_discover_tests(template-cpp-project_test)

# ---- End-of-file commands ----

add_folders(Test)
