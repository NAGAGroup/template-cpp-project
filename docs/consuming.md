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

> **Current limitation:** pixi-pack publishes source packages one at a
> time (`--path` semantics), which forbids source run-deps — so packs
> work for leaf envs (see the `header-only` env) but not yet for envs
> with cross-package chains. Workspace-level `pixi publish` handles the
> full chain fine: `pixi run publish-local` builds every opted-in
> package (all variant builds included) into an indexed local channel
> that any conda tool can consume. Upstream issue pending for the pack
> path.

## Run-dependency doctrine (for your own packages)

If your package exposes a dependency publicly — its headers appear in
yours, or your static lib needs it at link time — consumers need it too.
The modern form: the dependency **weak-exports itself**
(`[package.run-exports.weak] mathkit = "0.1.*"`), so host-depending on
it is all a consumer writes (mathkit and enginelib both do this; binary
conda-forge deps like spdlog do it out of the box). Version-spec the
self-export — unversioned self-exports publish without a constraint.
Manual `[package.run-dependencies]` remain for cases run-exports can't
express (enginelib's stb: a private header-only dep that static
consumers still link through the export set). CAUTION: run-exports (and
any name-based source reference) break if member manifests carry their
own [workspace] — keep the single-workspace layout.

## Support policy

The pixi pipeline above is the only officially supported consumption
path. FetchContent/CPM/`add_subdirectory` may work; issues specific to
them will be closed.
