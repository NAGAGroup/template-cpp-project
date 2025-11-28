#!/usr/bin/env nu

# Build the project using CMake
# Usage: nu build.nu [preset] [extra cmake build args...]

def main [
    preset: string = "dev"  # CMake preset/build directory name (default: dev)
    ...rest: string         # Additional CMake build arguments
] {
    let build_dir = $"build/($preset)"
    
    mut args = ["--build", $build_dir]
    
    if ($rest | length) > 0 {
        $args = ($args | append $rest)
    }

    print $"Running: cmake ($args | str join ' ')"
    run-external "cmake" ...$args
}
