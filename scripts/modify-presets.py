import json

user_presets = {
    "version": 2,
    "cmakeMinimumRequired": {"major": 3, "minor": 14, "patch": 0},
    "configurePresets": [
        {
            "name": "dev-common",
            "hidden": True,
            "inherits": ["dev-mode", "clang-tidy"],
            "cacheVariables": {
                "BUILD_MCSS_DOCS": "ON",
                "CMAKE_EXPORT_COMPILE_COMMANDS": "ON",
            },
        },
        {
            "name": "dev-linux",
            "binaryDir": "${sourceDir}/build/dev-linux",
            "inherits": ["dev-common", "ci-linux"],
            "cacheVariables": {"CMAKE_BUILD_TYPE": "Debug"},
        },
        {
            "name": "dev-win64",
            "binaryDir": "${sourceDir}/build/dev-win64",
            "inherits": ["dev-common", "ci-win64"],
            "cacheVariables": {"CMAKE_BUILD_TYPE": "Debug"},
        },
        {
            "name": "dev-win64-gnu",
            "binaryDir": "${sourceDir}/build/dev-win64-gnu",
            "inherits": ["dev-linux"],
        },
    ],
}

presets = {
    "version": 2,
    "cmakeMinimumRequired": {"major": 3, "minor": 14, "patch": 0},
    "configurePresets": [
        {
            "name": "cmake-pedantic",
            "hidden": True,
            "warnings": {
                "dev": False,
                "deprecated": True,
                "uninitialized": True,
                "unusedCli": True,
                "systemVars": False,
            },
            "errors": {"dev": False, "deprecated": True},
        },
        {
            "name": "dev-mode",
            "hidden": True,
            "generator": "Ninja",
            "inherits": "cmake-pedantic",
            "cacheVariables": {
                "CMAKE_TOOLCHAIN_FILE": "$env{CMAKE_TOOLCHAIN_FILE}",
            },
        },
        {
            "name": "cppcheck",
            "hidden": True,
            "cacheVariables": {"CMAKE_CXX_CPPCHECK": "cppcheck;--inline-suppr"},
        },
        {
            "name": "clang-tidy",
            "hidden": True,
            "cacheVariables": {
                "CMAKE_CXX_CLANG_TIDY": "clang-tidy;--header-filter=^${sourceDir}/"
            },
        },
        {
            "name": "ci-std",
            "description": "This preset makes sure the project actually builds with at least the specified standard",
            "hidden": True,
            "cacheVariables": {
                "CMAKE_CXX_EXTENSIONS": "OFF",
                "CMAKE_CXX_STANDARD": "17",
                "CMAKE_CXX_STANDARD_REQUIRED": "ON",
            },
        },
        {
            "name": "flags-gcc-clang",
            "description": "These flags are supported by both GCC and Clang",
            "hidden": True,
            "cacheVariables": {
                "CMAKE_CXX_FLAGS": "$env{CXXFLAGS} -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wcast-qual -Wformat=2 -Wundef -Werror=float-equal -Wshadow -Wcast-align -Wunused -Wnull-dereference -Wdouble-promotion -Wimplicit-fallthrough -Wextra-semi -Woverloaded-virtual -Wnon-virtual-dtor -Wold-style-cast",
                "CMAKE_EXE_LINKER_FLAGS": "$env{LDFLAGS}",
                "CMAKE_SHARED_LINKER_FLAGS": "$env{LDFLAGS}",
            },
        },
        {
            "name": "flags-msvc",
            "description": "Note that all the flags after /W4 are required for MSVC to conform to the language standard",
            "hidden": True,
            "cacheVariables": {
                "CMAKE_CXX_FLAGS": "$env{CXXFLAGS} $env{CL} /sdl /guard:cf /utf-8 /diagnostics:caret /w14165 /w44242 /w44254 /w44263 /w34265 /w34287 /w44296 /w44365 /w44388 /w44464 /w14545 /w14546 /w14547 /w14549 /w14555 /w34619 /w34640 /w24826 /w14905 /w14906 /w14928 /w45038 /W4 /permissive- /volatile:iso /Zc:inline /Zc:__cplusplus /GR /EHsc /D_CRT_SECURE_NO_WARNINGS=1",
                "CMAKE_EXE_LINKER_FLAGS": "$env{LDFLAGS} /machine:x64 /guard:cf",
                "CMAKE_SHARED_LINKER_FLAGS": "$env{LDFLAGS} /machine:x64 /guard:cf",
            },
        },
        {
            "name": "ci-linux",
            "inherits": ["flags-gcc-clang", "ci-std"],
            "hidden": True,
            "cacheVariables": {"CMAKE_BUILD_TYPE": "Release"},
        },
        {"name": "ci-win64", "inherits": ["flags-msvc", "ci-std"], "hidden": True},
        {
            "name": "coverage-linux",
            "binaryDir": "${sourceDir}/build/coverage",
            "inherits": "ci-linux",
            "hidden": True,
            "cacheVariables": {
                "ENABLE_COVERAGE": "ON",
                "CMAKE_BUILD_TYPE": "Coverage",
                "CMAKE_CXX_FLAGS_COVERAGE": "-Og -g --coverage -fkeep-inline-functions -fkeep-static-functions",
                "CMAKE_EXE_LINKER_FLAGS_COVERAGE": "--coverage",
                "CMAKE_SHARED_LINKER_FLAGS_COVERAGE": "--coverage",
            },
        },
        {
            "name": "ci-coverage",
            "inherits": ["coverage-linux", "dev-mode"],
            "cacheVariables": {"COVERAGE_HTML_COMMAND": ""},
        },
        {
            "name": "ci-sanitize",
            "binaryDir": "${sourceDir}/build/sanitize",
            "inherits": ["ci-linux", "dev-mode"],
            "cacheVariables": {
                "CMAKE_BUILD_TYPE": "Sanitize",
                "CMAKE_CXX_FLAGS_SANITIZE": "-U_FORTIFY_SOURCE -O2 -g -fsanitize=address,undefined -fno-omit-frame-pointer -fno-common",
            },
        },
        {"name": "ci-build", "binaryDir": "${sourceDir}/build", "hidden": True},
        {
            "name": "ci-ubuntu",
            "inherits": ["ci-build", "ci-linux", "clang-tidy", "cppcheck", "dev-mode"],
        },
        {"name": "ci-windows", "inherits": ["ci-build", "ci-win64", "dev-mode"]},
    ],
}

if __name__ == "__main__":
    with open("CMakePresets.json", "r") as f:
        cmake_init_presets = json.load(f)

    dev_mode_cmake_init = cmake_init_presets["configurePresets"][1]
    dev_mode = presets["configurePresets"][1]
    dev_mode_cmake_init["cacheVariables"]["CMAKE_TOOLCHAIN_FILE"] = dev_mode[
        "cacheVariables"
    ]["CMAKE_TOOLCHAIN_FILE"]
    dev_mode["cacheVariables"] = dev_mode_cmake_init["cacheVariables"]

    with open("CMakePresets.json", "w", encoding="utf8") as f:
        json.dump(presets, f, indent=2)

    with open("CMakeUserPresets.json", "w", encoding="utf8") as f:
        json.dump(user_presets, f, indent=2)
