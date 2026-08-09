# Toolchains

## Who provides the compiler?

- **Package builds**: the pixi-build-cmake backend provisions conda-forge
  compilers automatically (`compilers = ["cxx"]` is the default; vs2022
  on Windows — overridable via `[workspace.build-variants]`, see
  [build-variants.md](build-variants.md)).
- **Bring your own**: set `compilers = []` in `[package.build.config]`
  and declare the toolchain in `[package.build-dependencies]`. Live
  example: enginelib's coverage variant
  (`variants/coverage/pixi.toml`) brings `clangxx_linux-64` +
  `compiler-rt` because llvm-cov instrumentation needs clang. This is
  the pattern SYCL/CUDA-style custom toolchains build on.
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
upstream via `zip_keys`). When this template grows explicit compiler
variants it follows that pair convention. The SYCL/acpp branch
DELIBERATELY omits `cxx_compiler_version`: the acpp toolchain's
activation packages ship no version-suffixed names, so a version key
would render an unsatisfiable spec. This is a documented divergence,
not an inconsistency — do not "fix" either side to match the other.
(pixi note: `zip_keys` itself is not supported in `pixi.toml` — only in
`recipe.yaml` via the rattler-build backend — so lockstep pairs are
expressed as single-valued axes per flavor instead.)

## Stdlib floor

The workspace pins `c_stdlib_version = ["2.17"]` (linux) in
`[workspace.target.linux-64.build-variants]` — conda-forge's
redistributability baseline. Without it, pixi derives the floor from
its platform default (glibc 2.28) and published packages silently
demand a newer glibc than the ecosystem's own floor: the
"built according to the build machine" failure mode. Verified: the pin
resolves `sysroot 2.17.*` at build and stamps `__glibc >=2.17` into
run-deps.

**⚠ Channel-dependence (verified, do not copy this pattern blindly):**
`c_stdlib_version` is a DERIVATION PARAMETER, not a dep-name variant
key — pixi's stdlib derivation triggers on the literal `conda-forge`
channel. On a single-channel workspace layering another channel (the
NAGA constitution: one `naga-labs` channel), derivation is suppressed,
the key is a complete no-op, and — worse — published packages lose
their `__glibc` floor ENTIRELY (installable anywhere, load-time
failure). The constitution-compatible equivalent: declare
`sysroot_linux-64 = "*"` in each compiled package's build-deps
(restores the run-export) and pin workspace-wide BY DEP NAME:
`sysroot_linux-64 = ["2.17"]` as the variant axis. Adding conda-forge
to the channel list is NOT an acceptable fix (violates the
single-channel invariant). Windows skips stdlib derivation regardless
of channel — explicit stdlib deps are needed there either way.

## Microarch note

Never encode `-march` in flags, presets, or toolchain files: the
conda-forge `x86_64-microarch-level` metapackages set it via env
activation with matching `__archspec` install protection. See
[variants.md](variants.md).
