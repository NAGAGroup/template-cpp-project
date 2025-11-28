#!/usr/bin/env nu

# Change the project name throughout the codebase
# Usage: nu change-project-name.nu <new-name>

def main [
    new_name: string  # New project name to replace 'template-cpp-project'
] {
    let old_name = "template-cpp-project"
    
    if ($new_name | str length) == 0 {
        print --stderr "Error: new project name cannot be empty"
        exit 1
    }
    
    print $"Replacing '($old_name)' with '($new_name)' in all project files..."
    
    # Find all files containing the old name using ripgrep
    let files = (run-external --redirect-stdout "rg" "--files-with-matches" $old_name 
        | lines 
        | where { |f| ($f | str length) > 0 })
    
    if ($files | length) == 0 {
        print "No files found containing the old project name."
        exit 0
    }
    
    print $"Found ($files | length) files to update:"
    $files | each { |f| print $"  - ($f)" }
    
    # Process each file
    $files | each { |file|
        let content = (open --raw $file)
        let new_content = ($content | str replace --all $old_name $new_name)
        $new_content | save --force $file
        print $"Updated: ($file)"
    }
    
    print ""
    print $"Done! Project renamed from '($old_name)' to '($new_name)'"
    print ""
    print "Next steps:"
    print "  1. Review the changes with 'git diff'"
    print "  2. Rename any directories if needed"
    print "  3. Update any external references"
}
