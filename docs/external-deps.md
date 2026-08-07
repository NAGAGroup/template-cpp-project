# External dependencies: the decision tree

```
Does conda-forge ship it?            -> use the binary        (spdlog)
Upstream has sane modern CMake?      -> cmake-backend wrapper (external/fmt)
Upstream build is broken/absent?     -> rattler-build wrapper (external/stb)
FetchContent / CPM / vendoring?      -> NEVER
```

## 1. conda-forge binary (always prefer this)

`spdlog = "*"` in enginelib's host-deps. Binary packages carry their own
run-exports, so runtime propagation is automatic. Wrapping something that
conda-forge already ships is extra maintenance for nothing (fmt is
wrapped here purely for teaching).

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

## Propagation rules for wrapper deps

Same as any dep: public in your headers → repeat in run-deps; private +
shared-linked → runtime closure handles it (fmt in demo-app carries a
manual run-dep until pixi's run-exports bug is fixed); private +
header-only compiled in (stb in enginelib) → nothing propagates at all.
