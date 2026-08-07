# Why pixi

C++ has never had a package manager that owns the *whole* problem:
toolchain provisioning, dependency building, environment reproducibility,
and cross-project consumption. The community's answers each solve a
slice — vcpkg/Conan solve packages but not toolchains or environments;
FetchContent/CPM solve nothing except "I can paste a URL into CMake",
while making your configure step a package manager with no lockfile, no
cache policy, no isolation, and no story for consumers who don't build
your tree.

pixi (with pixi-build) closes the loop using the conda ecosystem:

- **Environments as the unit of truth.** A `pixi.toml` declares envs;
  `pixi.lock` pins every package in them, byte-for-byte, per platform.
  `pixi run` puts every command inside one. Nothing depends on what your
  distro shipped — including the compiler (see
  [tooling-versions.md](tooling-versions.md)).
- **Projects are packages.** A `[package]` section + a build backend turn
  a CMake project into a real conda package, built hermetically. Source
  dependencies — yours by path/git, third-party via
  [wrapper packages](external-deps.md) — are built in isolation and
  *installed*, so consumers use `find_package()` against a real install
  surface, not your source tree's internals.
- **One mental model from laptop to CI to users.** The same envs run the
  [dev loop](dev-workflow.md), the CI matrix, and the
  [consumer paths](consuming.md) (source deps for pixi users, packed
  environments for everyone else).

What CMake keeps: building one project well — targets, presets,
install/export rules. What CMake loses: pretending to be a package
manager. That division of labor is this template's core doctrine.

This template is the living demonstration: three interdependent packages,
a full variant matrix, two wrapper styles for external code, tests that
consume like users do, and a CI that never touches a system toolchain.
