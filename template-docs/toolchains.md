# Toolchains

## Who provides the compiler?

- **Package builds**: the pixi-build-cmake backend provisions
  conda-forge compilers automatically (`compilers = ["cxx"]` is the
  default). The version/vendor pins live in **`variants.yaml`**
  ([build-variants.md](build-variants.md)): gcc/gxx 16 on linux,
  **vs2026 on win** — the backend's own default is vs2022, which is
  STALE for GitHub runners; the file is the explicit override, never
  delete it back to the default.
- **Bring your own**: set `compilers = []` in `[package.build.config]`
  and declare the toolchain in `[package.build-dependencies]` (target
  tables for per-platform realizations). Live examples:
  - enginelib's coverage variant brings `clangxx_linux-64` +
    `compiler-rt` (llvm-cov instrumentation needs clang);
  - the clang variants bring `clangxx_linux-64` on linux and
    `vs2026_win-64` + plain `clang` on win, with the `clang-win`
    preset selecting `clang-cl` as the driver (the conda-forge
    `clang_win-64` activation stems exact-pin vs2019/vs2022 and cannot
    be used on a vs2026-only toolset). The backend passes `-GNinja`
    explicitly on the cmake command line, so the VS activation's
    generator env var cannot collide.
  This is the pattern SYCL/CUDA-style custom toolchains build on.
- **Compiler stems**: the mingw variants use a third route —
  `compilers = ["m2w64_cxx"]` renders `${{ compiler('m2w64_cxx') }}`,
  resolved by the `m2w64_cxx_compiler` keys in variants.yaml to the
  new `gxx_win-64` (GCC 14) family. Arbitrary stems pass through to
  the compiler() jinja (verified in backend source); only the variant
  keys make them resolvable.
- **Dev envs**: the dev-package closure delivers the same compilers the
  package build uses — plus dev-only tools from feature deps. Nothing is
  ever taken from the system (zero-system-tooling tenet).

## Toolchain files

Presets carry configure *variants*; toolchain files carry
compiler/platform *machinery* that doesn't belong in either manifests or
variant presets. `cmake/toolchains/linux-clang.cmake` is the in-tree
example for dev-env experimentation:

```sh
cd packages/enginelib
pixi run -e dev cmake --preset dev -DCMAKE_TOOLCHAIN_FILE=$PWD/../../cmake/toolchains/linux-clang.cmake
```

(Requires clang in the dev env — it's already there via the lint
tooling.)

## Compiler-version keys: upstream convention vs the acpp lane

conda-forge's pinning feedstock pairs each compiler with an explicit
version key (`cxx_compiler` + `cxx_compiler_version`, kept in lockstep
via `zip_keys`). This template follows that pair convention in
`variants.yaml` (gcc/gxx 16 zipped; m2w64 gcc/gxx 14 zipped — the
rattler `variants.yaml` form is also the only route to `zip_keys` in
pixi; inline tables don't support it). The SYCL/acpp branch
DELIBERATELY omits `cxx_compiler_version`: the acpp toolchain's
activation packages ship no version-suffixed names, so a version key
would render an unsatisfiable spec. This is a documented divergence,
not an inconsistency — do not "fix" either side to match the other.

## Stdlib floor

`variants.yaml` pins `c_stdlib`/`c_stdlib_version` → glibc **2.28**
(linux). The VALUE is a project decision — deliberately above
conda-forge's 2.17 baseline (SYCL tooling required the bump) — but the
PIN itself is the point: without it the floor is whatever pixi's
platform default happens to be, drift instead of decision. Verified
end-to-end: the pin resolves the matching `sysroot` at build and stamps
the `__glibc` floor into every published package's run requirements.

**⚠ Channel-dependence — why the pin must be EXPLICIT.** pixi can
*derive* the `c_stdlib` pair for you, but only on the literal
`conda-forge` channel (it matches the final segment of the resolved
channel URL). Off conda-forge, derivation is suppressed — and if you
were relying on it, your packages ship with **no `__glibc` floor at
all**: installable on any machine, failing at load time.

The pair itself is **not** channel-dependent. A hand-written variant is
honoured regardless of channel and stamps exactly the value you pinned:
derived entries are inserted with `.or_insert_with`, so an explicit key
always wins, and the backend gates on the *presence* of `c_stdlib`,
which is provenance-agnostic — variant files feed that key set like any
other source.

So the risk is not that the key stops working somewhere. It is that on
conda-forge the pin looks **redundant** — derivation produces a floor
anyway — and the day you move channels, deleting it as dead weight
silently removes the only thing producing one.

**That day has already happened on this branch.** We resolve through a
single `naga-labs` channel, so nothing here derives anything: the pair
in `variants.yaml` is the *only* source of a floor, and row 2 of the
table below is our configuration with the pair removed. This is why
`ci/check-stdlib-floor.nu` reads the floor out of the built artifact
rather than trusting the manifest — it is a failure with no symptom in
a build log, and it reaches users rather than us.

Verified with three builds of the same trivial package (one compiled
translation unit, pixi 0.76.1, pixi-build-cmake 0.4.5), reading
`info/index.json` out of the built `.conda`:

| channel | `c_stdlib` pair | `depends` |
|---|---|---|
| `naga-labs` (not conda-forge) | explicit | `__glibc >=2.28,<3.0.a0` |
| `naga-labs` (not conda-forge) | **absent** | *no `__glibc` entry* |
| `conda-forge` | **absent** | `__glibc >=2.28,<3.0.a0` |

Rows 2 and 3 are the discriminating pair: identical inputs, only the
channel differs, opposite outcomes — that is the channel gate. Row 1
shows the explicit pair working off conda-forge. Rows 1 and 3 produce
an identical `hash_input.json`
(`{"c_stdlib": "sysroot", "c_stdlib_version": "2.28", ...}`) and the
same build string, which is precisely why the pin looks redundant on
conda-forge: derivation happens to reach the same value.

Note what that value was: derivation supplied **2.28**, matching pixi's
own documented default virtual `__glibc`, not conda-forge's 2.17
pinning baseline. So "our pin is above the 2.17 baseline" describes the
conda-forge *pinning convention* we are diverging from; it does not
describe what pixi would have derived. Read a derived floor as
"whatever pixi's default happens to be today" — which is the argument
for pinning it, since a default is not a decision.

Windows skips stdlib derivation regardless of channel — win runtime
metadata (vc14_runtime/ucrt for MSVC and clang; libgcc/libstdcxx/ucrt
for mingw) arrives via the compiler activation's strong run-exports
instead, which is why the m2w64 stdlib keys in variants.yaml are inert
for the backend (kept for rattler recipes).

## Microarch note

Never encode `-march` in flags, presets, or toolchain files: the
conda-forge `x86_64-microarch-level` metapackages set it via env
activation with matching `__archspec` install protection. See
[variants.md](variants.md).
