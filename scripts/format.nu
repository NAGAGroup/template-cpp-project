# Format (or verify) every C++ source in the repo, in parallel — file
# discovery via the env's git, formatting fanned out with par-each
# (functional, no xargs quoting hazards, same behavior on every OS).
def main [--check] {
  let files = (git ls-files *.cpp *.hpp | lines)
  if $check {
    $files | par-each {|f| clang-format --dry-run --Werror $f } | ignore
    print $"($files | length) files formatted correctly"
  } else {
    $files | par-each {|f| clang-format -i $f } | ignore
    print $"formatted ($files | length) files"
  }
}
