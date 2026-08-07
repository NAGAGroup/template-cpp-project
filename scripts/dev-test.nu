# The dev-loop test flow, no packages involved: build the library
# in-tree, cmake-install it into the dev environment, then configure,
# build and run the tests (a CONSUMER project) against that install.
# Nushell aborts on the first failing external command — no `set -e`
# footguns.
def main [package: string] {
  cd $package
  cmake --preset dev
  cmake --build build/dev
  cmake --install build/dev --prefix $env.CONDA_PREFIX
  cd tests
  cmake --preset dev
  cmake --build build/dev
  ctest --test-dir build/dev --output-on-failure
}
