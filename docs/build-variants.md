# pixi build-variants

Build-variants answer "what is this package built **against**": same
package name, different build string, resolved per environment. The live
axis in this repo is enginelib's spdlog version matrix:

```toml
# packages/enginelib/pixi.toml
[workspace.build-variants]
spdlog = ["1.14.*", "1.15.*"]

[feature.spdlog14.dependencies]
enginelib = { path = "." }
spdlog = "1.14.*"          # <- the selector
```

`pixi list -e spdlog14` vs the default env shows two enginelib builds with
different build strings and run-deps (`spdlog >=1.14.1,<1.15` vs
`>=1.15.3,<1.16`).

## How selection ACTUALLY works (measured, not assumed)

An environment picks a variant build **only through run-dependency
conflicts**: the 1.14-built enginelib carries spdlog's `<1.15` run-export,
which conflicts with the env's `1.15.*` pin, forcing the solver onto the
other variant. If no run-dep distinguishes the variants, the solver
happily reuses one build for every env.

Three practical consequences (all verified against pixi 0.76):

1. **Variant keys must be plain-table deps.** Expansion applies only to
   dependencies declared in the plain `[package.*-dependencies]` tables —
   entries under `if(...)` conditions or `target.*` tables don't
   participate.
2. **Non-dependency keys select via CUSTOM PLATFORMS.** `cxx_compiler`
   (and other non-dep keys) can't be picked per env through pins — but a
   custom platform can scope a SINGLE-VALUE variant override, and an env
   bound to that platform gets it deterministically. Live demo — the
   `clang` env delivers a genuinely clang-built enginelib:
   ```toml
   platforms = [{ name = "linux-64-clang", platform = "linux-64" }, ...]

   [workspace.target.linux-64-clang.build-variants]
   cxx_compiler = ["clangxx"]        # conda-forge C++ clang metapackage

   [environments.clang]
   platforms = ["linux-64-clang"]
   ```
   (The Windows default restated in `[workspace.target.win-64.build-variants]`
   is the same mechanism as a plain global override.) Beware metapackage
   naming: `clangxx`, not `clang` — a wrong name can silently fall back
   to the system compiler.
3. **The consuming workspace owns the matrix.** Variant config is NOT
   inherited from a dependency's own workspace — the repo root mirrors
   enginelib's spdlog axis for exactly this reason.

## What we learned (microarch case study) {#what-we-learned}

The obvious design — `x86_64-microarch-level = ["1","3","4"]` as a
variant axis — fails: the conda-forge microarch metapackages are
unix-only noarch, their `>=level` run-export semantics are *correctly*
non-conflicting (a v1 build genuinely runs on a v3 machine), and run
dependencies are not variant-substituted
([pixi#4303](https://github.com/prefix-dev/pixi/issues/4303)) — so
pin-based env selection can't engage. Hence `variants/v{1,3,4}`:
explicit per-level subpackages with pinned levels — deterministic,
`__archspec`-protected, and honest. (Custom-platform-scoped single-value
variants would be the alternative expression once #4303 lands.)

When choosing where a new axis lives: if consumers must knowingly choose
it (ABI, sanitizers) → preset-variant subpackage; if it's a
dependency/toolchain matrix with genuinely conflicting run-deps →
build-variant; if neither → per-pin subpackages like microarch.

Variant sets can also be loaded from files
(`[workspace] build-variants-files`), including conda-forge-style
`conda_build_config.yaml` — handy for mirroring conda-forge's pinning
feedstock.
