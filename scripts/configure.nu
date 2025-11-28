#!/usr/bin/env nu

# Configure the project using CMake presets
# Usage: nu configure.nu [preset] [extra cmake args...]

def main [
    preset: string = "dev"  # CMake preset to use (default: dev)
    ...rest: string         # Additional CMake arguments
] {
    # Check for cross-compilation (not supported)
    let cross_compile = ($env | get --optional CONDA_BUILD_CROSS_COMPILATION | default "0")
    if $cross_compile == "1" {
        print --stderr "Cross-compilation is not supported at the moment."
        exit 1
    }

    # Get CMAKE_ARGS from environment, filter out build type flags
    let cmake_args = ($env | get --optional CMAKE_ARGS | default "")
        | str replace "-DCMAKE_BUILD_TYPE=Release" ""
        | str replace "-DCMAKE_BUILD_TYPE=Debug" ""
        | str trim

    # Build the cmake command arguments
    mut args = [".", "--preset", $preset]
    
    if ($cmake_args | str length) > 0 {
        # Split cmake_args by spaces and append
        $args = ($args | append ($cmake_args | split row " " | where { |it| ($it | str length) > 0 }))
    }
    
    if ($rest | length) > 0 {
        $args = ($args | append $rest)
    }

    # Run cmake configure
    print $"Running: cmake ($args | str join ' ')"
    run-external "cmake" ...$args

    # Fix compile_commands.json if it exists
    let project_root = ($env | get --optional PROJECT_ROOT | default (pwd))
    let compile_commands = $"($project_root)/build/dev/compile_commands.json"
    
    if ($compile_commands | path exists) {
        let fix_script = $"($project_root)/scripts/fix-compile-commands.nu"
        if ($fix_script | path exists) {
            nu $fix_script $compile_commands
        }
    }
}
