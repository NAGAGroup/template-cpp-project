# External dependencies: the decision tree

```
Does conda-forge ship it?            -> use the binary        (spdlog)
Upstream has sane modern CMake?      -> cmake-backend wrapper (external/fmt)
Upstream build is broken/absent?     -> rattler-build wrapper (external/stb)
FetchContent / CPM / vendoring?      -> NEVER
```

## 1. conda-forge binary (always prefer this)

`spdlog = "*"` in enginelib's host-deps (the `"*"` is the
variant-substitution placeholder — spdlog is a build-variant axis).
Binary packages carry their own run-exports, so runtime propagation is
automatic. Wrapping something that conda-forge already ships is extra
maintenance for nothing (fmt is wrapped here purely for teaching).

## 2. cmake-backend wrapper (`external/fmt`)

A directory containing ONE `pixi.toml`: `[package.build.source]` points at
upstream's git with a **tag pin you control**, the backend drives
configure/build/install hermetically. ~15 lines wraps any well-behaved
CMake project. Wrappers are the one place raw `-D` flags belong in
`extra-args` — upstream has no presets to call.

Note the resolver effect: a source dep named `fmt` overrides the channel
binary for the whole workspace — spdlog's own fmt requirement resolves
against the wrapper build (which is why the wrapper pins a
conda-forge-compatible tag).

## 3. rattler-build escape hatch (`external/stb`)

For upstream like stb — or boost before 1.79's usable CMake config — no
CMake backend can help. `recipe.yaml` next to the manifest owns
everything: source pin (a commit sha; stb has no releases), build script,
install layout, and a **hand-written `stbConfig.cmake`** so downstream
still gets a first-class `find_package(stb)` + `stb::stb` target. The
escape hatch is total: whatever upstream's build looks like, the result
is a normal conda package, and nothing ever forces you back to
FetchContent.

## ⚠ Editing a recipe does not invalidate its lock record

pixi's source-package identifier hash excludes recipe CONTENT, so
changing `recipe.yaml` alone leaves the old metadata in `pixi.lock` —
your change looks like it had no effect (we once concluded a pixi
feature was broken from exactly this artifact). This silently pins ALL
recipe-level metadata (run_exports, requirements, everything), and the
sharp edge is that the backend DECLARES the recipe file as a metadata
input — lock satisfiability just doesn't consult that declaration on
recipe-only edits (upstream candidate). Force re-resolution with
`pixi update <package>`; it re-queries the backend and rolls the
record hash. Targeted updates reject the whole command if any named
package is only a transitive dep, so name a direct one.

## Propagation rules for wrapper deps

Same as any dep: public in your headers → the dep weak-exports itself
and host-depending suffices (fmt and the in-tree libraries all do
this); private + shared-linked → the runtime closure handles it;
private + header-only compiled in (stb in enginelib) → nothing
propagates at all, except where the CMake export set still resolves it
(stb keeps a manual run-dep for static consumers).
