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

## Microarch note

Never encode `-march` in flags, presets, or toolchain files: the
conda-forge `x86_64-microarch-level` metapackages set it via env
activation with matching `__archspec` install protection. See
[variants.md](variants.md).
