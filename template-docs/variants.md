# Variants: presets as the package interface

## The doctrine line

Two orthogonal variant systems exist, and knowing which one an axis
belongs to is the design decision:

- **Preset-variants** — *how this project's own code is configured*
  (linkage, sanitizers, coverage, build type, compiler). Distinct
  package **names** (`enginelib-static`, `enginelib-asan`,
  `enginelib-clang`, `enginelib-mingw`) that consumers knowingly
  choose. Dev-only: none of them publish.
- **[Build-variants](build-variants.md)** — *what the package is built
  against* (dependency versions, toolchain pins). Same package name,
  different build string; environments select via dependency pins.

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
(The `clang-win` preset is the one deliberate exception: selecting a
compiler driver — `CMAKE_C/CXX_COMPILER=clang-cl` — IS configure
machinery, and the preset is exactly where configure detail lives.)

## Two preset layers

1. **Variant presets** (`default`, `static`, `asan`, `clang-win`, …):
   cache variables only — no generator, no binaryDir. Composable with
   the backend.
2. **Dev presets** (`dev`, `dev-asan`, …): inherit a variant preset, add
   Ninja + `build/<preset>` + Debug + `CMAKE_PREFIX_PATH=$env{CONDA_PREFIX}`
   + `<PKG>_DEV_MODE=ON` (warnings-as-errors). Pure developer UX; never
   referenced by manifests.

## The compiler matrix (five cells)

| cell | realization |
|---|---|
| gcc / linux | the default packages (no suffix) |
| msvc (vs2026) / win | the default packages (no suffix) |
| clang / linux | `*-clang` named variants (libstdc++) |
| clang / win | `*-clang` — same name, realized as clang-cl on the VC runtime |
| mingw / win | `*-mingw` named variants — **Windows only** (libstdc++ on win) |

- `clang` is ONE name on both platforms, and the name is grounded TWO
  ways: compiler choice is a knowingly-chosen CONFIGURATION (C-03,
  like asan/static) AND cross-compiler mixing is not guaranteed
  ABI-safe even on a shared runtime. On win, clang-cl targets the same
  VC RUNTIME as MSVC — that NARROWS the regime gap, it does not close
  it: compilers are known to produce ABI-incompatible binaries even
  when the stdlib is the same (mangling corner cases, unwind/EH table
  differences, layout edge cases, cross-TU inline/ODR divergence).
  **Shared VC runtime ≠ safe object mixing** — pick the variant whose
  compiler matches yours; do not treat the two win lanes as
  link-interchangeable.
- `mingw` is a name on ABI-REGIME grounds: a mingw-built lib is not
  link-compatible with MSVC consumers. The lock metadata shows the two
  regimes directly: `enginelib-clang` (win) carries `vc14_runtime`;
  `enginelib-mingw` carries `libstdcxx`/`libgcc`.
- **The mingw lane is the strongest pixi argument in this template.**
  Targeting mingw on Windows is traditionally a NO-GO: binary packages
  for your dependencies don't exist in that regime, so you fall back
  to the old world — `find_package` check first, FetchContent or
  similar second — and end up doing CMake surgery in your own project
  to accommodate dependencies you had to build yourself.
  Understandably, almost nobody bothers. **With pixi source packages
  it is a piece of cake: wrap the upstream once, consume it by name,
  and make ZERO CMake changes to your core packages.** This tree is
  the worked example: the mingw lane consumes `external/spdlog-mingw`
  / `fmt-mingw` / `catch2-mingw` — in-regime rebuilds of the upstream
  releases, each a ~25-line wrapper — while `enginelib`'s CMakeLists
  says `find_package(spdlog CONFIG REQUIRED)` and links
  `spdlog::spdlog` in every regime, never knowing or caring that
  spdlog arrived as an in-regime source build. Only the MANIFEST
  dependency swaps. That invariance is the whole point.

  **The constraint that makes the capability necessary — regime
  closure (learned the hard way; the first mingw CI builds failed,
  each failure a distinct lesson):** the ABI regime requirement
  extends to every NATIVE-CODE dependency, and it reaches further
  than binaries.
  (a) *Link regime:* a mingw object cannot link the channel's
  MSVC-built import libraries (`undefined reference to __imp_…` with
  GNU mangling).
  (b) *Exported-interface regime — the decisive one:* a foreign-regime
  package contaminates you through its EXPORTED CMAKE CONFIG, not
  merely its binaries. The actual conda-forge spdlog win-64 artifact
  ships
  `INTERFACE_COMPILE_OPTIONS "/Zc:__cplusplus;$<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/utf-8>"`
  — note the asymmetry: `/utf-8` properly genex-guarded,
  `/Zc:__cplusplus` UNCONDITIONAL, and it sits on the
  `spdlog_header_only` target too. g++ parses that flag as an input
  file. This is an UPSTREAM bug, not conda-forge packaging
  sloppiness: spdlog's own `CMakeLists.txt` (v1.15.3) sets it inside
  an `if(MSVC)` block — a BUILD-time check that says nothing about
  the CONSUMER's compiler — while the very next lines wrap `/utf-8`
  in a `$<CXX_COMPILER_ID:MSVC>` genex; the fix pattern sits four
  lines below the defect. **Generalizable smell: `if(MSVC)`-guarded
  INTERFACE properties in any C++ package you consume.** So even
  header-only consumption does not escape the regime — you still
  import the config. (Header-only *is* a legitimate lighter technique
  when the dep's config is clean: if a dependency ships a header-only
  mode, that is the cheapest way across a regime boundary. It just
  wasn't available here.)
  (c) *Fetch regime:* the wrappers use TARBALL sources (url + sha256,
  rattler recipes) because a git source dep on upstream Catch2
  hard-fails on Windows' case-insensitive filesystem. The mechanism is
  worth knowing precisely, because it is not what it looks like: pixi's
  refspec for a pinned tag is already TARGETED
  (`+refs/tags/<tag>:refs/remotes/origin/tags/<tag>`), but the fetch
  omits `--no-tags`, so git's default TAG AUTO-FOLLOWING stores every
  tag reachable in the fetched history — and Catch2's history holds a
  case-conflicting pair (`refs/tags/V1.5.0` and `refs/tags/v1.5.0`).
  The `files` ref backend cannot store both, so the fetch dies while
  STORING refs, not while checking anything out; the v3.15.3 tree
  itself is case-clean (verified). Note the shape: a correct targeted
  mechanism undermined by an implicit follow-along default — the same
  shape as the `/Zc` bug above, where a correct build-time guard was
  undermined by an unguarded interface export.

  And the anti-lesson: the tempting one-line workaround — neutralizing
  the imported target's `INTERFACE_COMPILE_OPTIONS` after
  `find_package`, or filtering flags in a preset — goes green just as
  fast and teaches the opposite: CMake surgery in YOUR project to
  accommodate a dependency shipped in the wrong regime, which is
  precisely the old-world coping strategy source packages eliminate.
  A workaround that goes green is worse than staying red another
  cycle. Header-only deps you own (mathkit, stb) are regime-neutral
  and need nothing. The spdlog build-variant axis deliberately does
  not reach the mingw lane — the axis belongs to the channel-binary
  happy path.

  **Scope the law precisely — it is a C++ closure, not a native-code
  closure.** The regime boundary is the C++ ABI (name mangling, std::
  type layouts, exceptions/unwind, import-lib expectations for
  classes), not machine code per se. Pure-C dependencies (zlib-class
  libraries) can generally cross regimes on win-64: both regimes speak
  the platform C ABI and COFF import libs — and, decisively, both
  target the SAME CRT. The lock shows it: the mingw records carry a
  `ucrt` run-export just like the MSVC ones, because the gcc_win-64
  family targets UCRT — so even `malloc`/`free` and `FILE*` crossing
  the boundary is coherent. (This is NOT true of the legacy
  msvcrt-based `m2w64-*` packages — never mix those in.) Without this
  scoping the lesson over-generalizes and someone eventually rebuilds
  zlib-mingw for no reason. The whole story is machine-checked:
  `ci/check-regime-markers.nu` asserts every mingw-lane lock record
  carries `libstdcxx`/`libgcc`/`ucrt` and no foreign-regime C++ dep,
  and every clang-win record carries `vc14_runtime`/`ucrt` and no GNU
  markers — the two regimes stay visibly distinct in metadata, which
  is the C-02 lesson in executable form.
- Header-only packages (mathkit, stb) get NO compiler variants: their
  generated CMake config is byte-identical across compilers (verified) —
  no artifact, no ABI, nothing to name.
- mingw packages also showcase a package limited to one platform: they
  are only ever referenced from `target.win-64` tables and win-only
  envs (`gnu`-on-linux is just gcc — the default package).

## Layout and the env matrix

ONE workspace manifest at the repo root owns every environment, task and
the variant matrix; every package directory is a PACKAGE-ONLY manifest:

```
pixi.toml                  # THE workspace: pool, variants, envs, tasks
variants.yaml              # toolchain/stdlib pins (build-variants file)
packages/enginelib/
├── pixi.toml              # package-only: the DEFAULT package (Release/shared)
├── CMakeLists.txt         # knob mapping lives here
├── CMakePresets.json      # both preset layers
├── variants/{static,relwithdebinfo,asan,tsan,coverage,clang,mingw}/pixi.toml
└── tests/                 # consumer project + its own variants/{clang,mingw,asan,tsan,coverage}
packages/demo-app/
└── variants/{static,clang,mingw}/pixi.toml
```

Every variant exists because an env consumes it: `test-asan` composes
the `asan` flavor feature and consumes `enginelib-tests-asan`, which
depends on `enginelib-asan` — the test binary is built *like the lib it
tests*. Sanitizer/coverage envs are linux-only; `clang` envs span both
platforms; `gnu`/`mingw` test+demo envs are win-only. Sibling
references flow through the root `[workspace.dependencies]` pool
(`{ workspace = true }`), which re-anchors relative paths per consumer —
the single source of truth for every path in the monorepo.

The coverage variant doubles as the **bring-your-own-toolchain**
example: `compilers = []` + explicit clang build-deps
([toolchains.md](toolchains.md)). The clang variants extend the same
mechanics per platform; the mingw variants use the m2w64 compiler-stem
route instead (`compilers = ["m2w64_cxx"]`).

## Where microarch levels live: NOT here

Microarchitecture levels are a **build-variant axis** (same name,
different build strings), not package variants — their compatibility is
fully encoded in dependency metadata, and a bare `enginelib` spec is
always safe. See [build-variants.md](build-variants.md) for the
mechanism, the tier envs (`prod`, `microarch-v0/-v2/-v3/-v4`), and the
**big warning** about pixi not validating archspec yet. (Historical
note: this template once shipped microarch as named subpackages
`enginelib-v1/v3/v4` plus an "adaptive default" routed through platform
ordering — both retired as doctrine violations: names for a
metadata-encodable axis, and platforms used as selection routers
instead of capability gates.)
