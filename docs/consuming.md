# Consuming these packages

## You use pixi (the happy path)

Add a source dependency. Any member package or variant subpackage is
addressable by `subdirectory`:

```toml
[dependencies]
mathkit   = { git = "https://github.com/NAGAGroup/template-cpp-project", tag = "mathkit-v0.1.0",   subdirectory = "packages/mathkit" }
enginelib = { git = "https://github.com/NAGAGroup/template-cpp-project", tag = "enginelib-v0.1.0", subdirectory = "packages/enginelib" }
# a specific variant:
enginelib-static = { git = "...", tag = "enginelib-v0.1.0", subdirectory = "packages/enginelib/variants/static" }
```

pixi builds the chain (including transitive source deps) in isolation and
installs real conda packages into your env. Then, in CMake:

```cmake
find_package(enginelib CONFIG REQUIRED)
target_link_libraries(my-app PRIVATE enginelib::enginelib)
```

Pin `rev = "<sha>"` during development, `tag = "..."` for releases
([versioning.md](versioning.md)).

## You don't use pixi

Use a **packed environment**: a self-extracting archive containing the
package + its full runtime closure, requiring *nothing* on your machine.

```sh
# producer side (or download the CI "packed-env" artifact):
cd packages/mathkit
pixi exec pixi-pack --create-executable --environment default --platform linux-64 pixi.toml
# consumer side:
./environment.sh          # creates ./env
cmake -B build -DCMAKE_PREFIX_PATH=$PWD/env
```

> **Current limitation:** pixi-pack routes source packages through
> `pixi publish`, which requires a self-contained publish set — and its
> discovery skips nested workspaces. In this repo that means packs work
> for *leaf* packages (mathkit, the wrappers) but not yet for packages
> with cross-member source run-deps (enginelib, demo-app). Upstream
> issue pending; the doctrine is unaffected.

## Run-dependency doctrine (for your own packages)

If your package exposes a dependency publicly — its headers appear in
yours, or your static lib needs it at link time — consumers need it too:
repeat it in `[package.run-dependencies]` (see enginelib's manifest,
"THE RUN-DEPENDENCIES RULE"). Binary conda-forge deps usually handle
this themselves via run-exports (spdlog does). Pixi source packages can
in principle self-export via `[package.run-exports]`; a path-resolution
bug currently prevents it (see AGENTS.md) — re-check on pixi upgrades.

## Support policy

The pixi pipeline above is the only officially supported consumption
path. FetchContent/CPM/`add_subdirectory` may work; issues specific to
them will be closed.
