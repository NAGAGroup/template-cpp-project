# Configure a package's in-tree dev build and refresh the clangd
# compile_commands link (copy on Windows — no symlink permissions needed).
#
# Scripting doctrine: one-liners stay inline pixi tasks; anything
# multi-step or platform-conditional is a nushell script. One script, all
# platforms — nushell comes from the env (zero-system-tooling tenet).
def main [package: string] {
  cd $package
  cmake --preset dev
  if $nu.os-info.name == "windows" {
    cp build/dev/compile_commands.json compile_commands.json
  } else {
    ln -sf build/dev/compile_commands.json compile_commands.json
  }
}
