# Variants: presets as the package interface

## The doctrine line

Two orthogonal variant systems exist, and knowing which one an axis
belongs to is the design decision:

- **Preset-variants** — *how this project's own code is configured*
  (linkage, sanitizers, coverage, build type). Distinct package **names**
  (`enginelib-static`, `enginelib-asan`) that consumers knowingly choose.
- **[Build-variants](build-variants.md)** — *what the package is built
  against* (dependency versions, toolchain). Same package name, different
  build string; environments select via dependency pins.

## A package variant IS a CMake preset

Every variant subpackage manifest says only:

```toml
[package.build.config]
extra-args = ["--preset=asan"]
```

No `-D` soup in manifests — the preset file is the single source of truth,
and non-pixi users get the identical variant via `cmake --preset asan`.

**Project-owned knobs, not raw CMake variables.** The pixi-build-cmake
backend passes its own `-D` flags (`BUILD_SHARED_LIBS=ON`,
`CMAKE_BUILD_TYPE=Release`, …) which outrank preset cacheVariables. So
variant presets set knobs the project owns (`ENGINELIB_SHARED`,
`ENGINELIB_SANITIZER`, `ENGINELIB_BUILD_TYPE`, …) and CMakeLists maps
them with plain `set()` — which always wins. See enginelib/CMakeLists.txt.

## Two preset layers

1. **Variant presets** (`default`, `static`, `asan`, …): cache variables
   only — no generator, no binaryDir. Composable with the backend.
2. **Dev presets** (`dev`, `dev-asan`, …): inherit a variant preset, add
   Ninja + `build/<preset>` + Debug + `CMAKE_PREFIX_PATH=$env{CONDA_PREFIX}`
   + `<PKG>_DEV_MODE=ON` (warnings-as-errors). Pure developer UX; never
   referenced by manifests.

## Layout and the env matrix

ONE workspace manifest at the repo root owns every environment, task and
the variant matrix; every package directory is a PACKAGE-ONLY manifest:

```
pixi.toml                  # THE workspace: pool, variants, envs, tasks
packages/enginelib/
├── pixi.toml              # package-only: the DEFAULT package (Release/shared)
├── CMakeLists.txt         # knob mapping lives here
├── CMakePresets.json      # both preset layers
├── variants/{static,relwithdebinfo,asan,tsan,coverage,clang}/pixi.toml
└── tests/                 # consumer project + its own variants/
```

Every variant exists because an env consumes it: `test-asan` consumes
`enginelib-tests-asan` which depends on `enginelib-asan` — the test binary
is built *like the lib it tests*. Sanitizer/coverage/clang envs are
linux-only (platform-scoped inline envs). Sibling references flow through
the root `[workspace.dependencies]` pool (`{ workspace = true }`), which
re-anchors relative paths per consumer — the single source of truth for
every path in the monorepo.

The coverage variant doubles as the **bring-your-own-toolchain** example:
`compilers = []` + explicit clang build-deps
([toolchains.md](toolchains.md)). The clang variant applies the same
mechanics as a NAMED compiler variant: compiler choice is a
consumer-toolchain contract (stdlib/ABI regime) the solver cannot see,
so it earns a name consumers knowingly choose — the same doctrine test
asan and static pass.

## Where microarch levels live: NOT here

Microarchitecture levels are a **build-variant axis** (same name,
different build strings), not package variants — their compatibility is
fully encoded in dependency metadata, and a bare `enginelib` spec is
always safe. See [build-variants.md](build-variants.md) for the
mechanism, the tier envs (default/v0/v3/v4), and the **big warning**
about pixi not validating archspec yet. (Historical note: this template
once shipped microarch as named subpackages `enginelib-v1/v3/v4` plus an
"adaptive default" routed through platform ordering — both retired as
doctrine violations: names for a metadata-encodable axis, and platforms
used as selection routers instead of capability gates.)
