#!/usr/bin/env nu

# Patch RPATHs of installed ELF binaries to remove conda prefix paths
# This is Linux-only and requires patchelf
# Usage: nu patch-rpaths.nu

def main [] {
    # This script only works on Linux
    if (sys host | get name) != "Linux" {
        print "This script only runs on Linux (ELF binaries)."
        exit 0
    }
    
    let install_prefix = ($env | get --optional INSTALL_PREFIX | default "")
    let project_root = ($env | get --optional PROJECT_ROOT | default (pwd))
    let prefix = ($env | get --optional PREFIX | default "")
    let build_prefix = ($env | get --optional BUILD_PREFIX | default $prefix)
    
    if ($install_prefix | str length) == 0 {
        print --stderr "Error: INSTALL_PREFIX environment variable not set"
        exit 1
    }
    
    print "Removing conda prefix from RPATHs using patchelf..."
    
    let cache_dir = $"($project_root)/.cache/patch-rpaths"
    let enable_sudo_file = $"($cache_dir)/enable_sudo"
    
    # Find all regular files under install prefix
    let files = (glob $"($install_prefix)/**/*" | where { |f| ($f | path type) == "file" })
    
    for file in $files {
        process_binary $file $prefix $build_prefix $cache_dir $enable_sudo_file
    }
    
    print "Done."
    
    # Cleanup cache
    if ($cache_dir | path exists) {
        rm -rf $cache_dir
    }
}

# Process a single binary file
def process_binary [
    binary: string
    prefix: string
    build_prefix: string
    cache_dir: string
    enable_sudo_file: string
] {
    # Check if it's an ELF file
    let file_type = (run-external --redirect-stdout "file" $binary)
    if not ($file_type | str contains "ELF") {
        return
    }
    
    # Get current RPATH
    let current_rpath = try {
        run-external --redirect-stdout "patchelf" "--print-rpath" $binary | str trim
    } catch {
        ""
    }
    
    if ($current_rpath | str length) == 0 {
        return
    }
    
    # Remove PREFIX/lib from RPATH
    let new_rpath = $current_rpath
        | str replace --all $"($prefix)/lib" ""
        | str replace --all "::" ":"
        | str trim --char ":"
    
    # If empty, default to $ORIGIN
    let final_rpath = if ($new_rpath | str length) == 0 {
        "$ORIGIN"
    } else {
        $new_rpath
    }
    
    print -n $"  Updating RPATH for ($binary)..."
    
    let patchelf_cmd = $"($build_prefix)/bin/patchelf"
    
    # Check if we should use sudo
    let use_sudo = ($enable_sudo_file | path exists)
    
    let result = if $use_sudo {
        try {
            run-external "sudo" $patchelf_cmd "--set-rpath" $final_rpath $binary
            true
        } catch {
            false
        }
    } else {
        try {
            run-external $patchelf_cmd "--set-rpath" $final_rpath $binary
            true
        } catch {
            false
        }
    }
    
    if $result {
        print "Done."
    } else {
        print "Permission denied."
        
        # Interactive sudo prompt
        let choice = (input "Do you want to retry with sudo? [y/N] ")
        if ($choice | str downcase | str starts-with "y") {
            mkdir $cache_dir
            touch $enable_sudo_file
            
            let sudo_result = try {
                run-external "sudo" $patchelf_cmd "--set-rpath" $final_rpath $binary
                true
            } catch {
                false
            }
            
            if $sudo_result {
                print $"Successfully updated RPATH for ($binary) with sudo."
            } else {
                print $"Failed to update RPATH for ($binary) even with sudo."
            }
        } else {
            print $"Skipping ($binary)."
        }
    }
}
