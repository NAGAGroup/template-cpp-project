cmake_minimum_required(VERSION 4.2)
project(mathkit-tests LANGUAGES CXX)

# Tests are a CONSUMER PROJECT: they find_package() the installed mathkit.
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
