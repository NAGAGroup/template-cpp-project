#!/usr/bin/env nu

# Install the project using CMake
# Usage: nu install.nu [preset]

def main [
    preset: string = "dev"  # CMake preset/build directory name (default: dev)
] {
    let build_dir = $"build/($preset)"
    let project_root = ($env | get --optional PROJECT_ROOT | default (pwd))
    let install_prefix = ($env | get --optional INSTALL_PREFIX | default $"($project_root)/.pixi/envs/dev")

    # Run cmake install
    print $"Running: cmake --install ($build_dir)"
    run-external "cmake" "--install" $build_dir

    # Copy additional files from files/ directory if it exists
    let files_dir = $"($project_root)/files"
    if ($files_dir | path exists) {
        print $"Copying files from ($files_dir) to ($install_prefix)"
        
        # Get all files recursively and copy them
        ls $files_dir | each { |entry|
            let src = $entry.name
            let relative = ($src | str replace $"($files_dir)/" "")
            let dest = $"($install_prefix)/($relative)"
            
            if $entry.type == "dir" {
                # For directories, use glob to copy contents
                glob $"($src)/**/*" | where { |f| ($f | path type) == "file" } | each { |f|
                    let rel_path = ($f | str replace $"($files_dir)/" "")
                    let dest_file = $"($install_prefix)/($rel_path)"
                    let dest_dir = ($dest_file | path dirname)
                    
                    mkdir $dest_dir
                    cp $f $dest_file
                }
            } else {
                cp $src $dest
            }
        }
    }
}
