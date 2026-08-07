cmake_minimum_required(VERSION 4.2)
project(mathkit-tests LANGUAGES CXX)

# Tests are a CONSUMER PROJECT: they find_package() the installed mathkit.
option(MATHKIT_TESTS_DEV_MODE "Enable developer warnings (dev presets)" OFF)
if(MATHKIT_TESTS_DEV_MODE)
  add_compile_options(
    "$<$<CXX_COMPILER_ID:MSVC>:/W4>"
    "$<$<NOT:$<CXX_COMPILER_ID:MSVC>>:-Wall;-Wextra;-Wpedantic>")
  set(CMAKE_COMPILE_WARNING_AS_ERROR ON)
endif()

find_package(mathkit CONFIG REQUIRED)
find_package(Catch2 3 CONFIG REQUIRED)

add_executable(mathkit-tests src/test_mathkit.cpp)
target_compile_features(mathkit-tests PRIVATE cxx_std_23)
target_link_libraries(mathkit-tests PRIVATE mathkit::mathkit
                                            Catch2::Catch2WithMain)

include(CTest)
include(Catch)
catch_discover_tests(mathkit-tests)

include(GNUInstallDirs)
install(TARGETS mathkit-tests RUNTIME)
