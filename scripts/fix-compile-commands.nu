#!/usr/bin/env nu

# Fix compile_commands.json by removing problematic compiler flags
# Usage: nu fix-compile-commands.nu <compile_commands.json>
#
# Reads FILTER_COMPILE_COMMANDS_FLAGS env var (comma-separated list of flags to remove)
# Each flag and its argument (up to the next -flag) will be removed

def main [
    compile_commands: path  # Path to compile_commands.json file
] {
    if not ($compile_commands | path exists) {
        print $"File not found: ($compile_commands)"
        exit 0
    }

    # Get flags to filter from environment
    let filter_flags = ($env | get --optional FILTER_COMPILE_COMMANDS_FLAGS | default "")
        | split row ","
        | where { |f| ($f | str trim | str length) > 0 }

    if ($filter_flags | length) == 0 {
        # No flags to filter, nothing to do
        exit 0
    }

    # Read the file
    let content = open --raw $compile_commands

    # Process each line, removing flagged content
    let fixed_content = $content
        | lines
        | each { |line|
            mut result = $line
            for flag in $filter_flags {
                # Keep removing the flag until it's gone (handles multiple occurrences)
                while ($result | str contains $flag) {
                    let begin = ($result | str index-of $flag)
                    if $begin == -1 {
                        break
                    }
                    
                    # Find the end: next " -" after the flag, or end of relevant content
                    let after_flag = ($result | str substring $begin..)
                    let end_offset = ($after_flag | str index-of " -")
                    
                    if $end_offset != -1 and $end_offset > 0 {
                        # Found next flag, remove up to it
                        let end = $begin + $end_offset + 1
                        $result = ($result | str substring ..($begin) | append ($result | str substring $end..) | str join "")
                    } else {
                        # No next flag found, remove to end of the flag+arg
                        # Find the next space after the flag value
                        let space_after = ($after_flag | str substring ($flag | str length)..) | str index-of " "
                        if $space_after != -1 {
                            let end = $begin + ($flag | str length) + $space_after
                            $result = ($result | str substring ..($begin) | append ($result | str substring $end..) | str join "")
                        } else {
                            # Just remove the flag itself
                            $result = ($result | str replace $flag "")
                        }
                    }
                }
            }
            $result
        }
        | str join "\n"

    # Write back
    $fixed_content | save --force $compile_commands
}
