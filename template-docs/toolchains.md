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

**⚠ Channel-dependence (verified, do not copy this pattern blindly):**
`c_stdlib_version` is a DERIVATION PARAMETER, not a dep-name variant
key — pixi's stdlib derivation triggers on the literal `conda-forge`
channel. On a single-channel workspace layering another channel,
derivation is suppressed, the key is a complete no-op, and — worse —
published packages lose their `__glibc` floor ENTIRELY (installable
anywhere, load-time failure). The constitution-compatible equivalent:
declare `sysroot_linux-64 = "*"` in each compiled package's build-deps
(restores the run-export) and pin workspace-wide BY DEP NAME:
`sysroot_linux-64 = ["2.28"]` as the variant axis. Adding conda-forge
to the channel list is NOT an acceptable fix if your project has a
single-channel invariant. Windows skips stdlib derivation regardless of
channel — win runtime metadata (vc14_runtime/ucrt for MSVC and clang;
libgcc/libstdcxx/ucrt for mingw) arrives via the compiler activation's
strong run-exports instead, which is why the m2w64 stdlib keys in
variants.yaml are inert for the backend (kept for rattler recipes).

## Microarch note

Never encode `-march` in flags, presets, or toolchain files: the
conda-forge `x86_64-microarch-level` metapackages set it via env
activation with matching `__archspec` install protection. See
[variants.md](variants.md).
