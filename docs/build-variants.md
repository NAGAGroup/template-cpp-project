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
2. **Non-dependency keys have no env-side selector.** `cxx_compiler` (and
   custom keys like a stdlib switch) can't be picked per env; multi-value
   entries resolve arbitrarily. Use them as single-value **global
   overrides** instead — this workspace restates the Windows default
   explicitly as the live demo:
   ```toml
   [workspace.target.win-64.build-variants]
   cxx_compiler = ["vs2022"]     # swap to change the toolchain workspace-wide
   ```
3. **The consuming workspace owns the matrix.** Variant config is NOT
   inherited from a dependency's own workspace — the repo root mirrors
   enginelib's spdlog axis for exactly this reason.

## What we learned (microarch case study) {#what-we-learned}

The obvious design — `x86_64-microarch-level = ["1","3","4"]` as a
variant axis — fails twice: the conda-forge microarch metapackages are
unix-only noarch (can't sit in plain tables of a win-supporting package,
see #1), and their `>=level` run-export semantics are *correctly*
non-conflicting (a v1 build genuinely runs on a v3 machine), so env
selection can't work (see the conflict rule). Hence
`variants/v{1,3,4}`: explicit per-level subpackages with pinned levels —
deterministic, `__archspec`-protected, and honest.

When choosing where a new axis lives: if consumers must knowingly choose
it (ABI, sanitizers) → preset-variant subpackage; if it's a
dependency/toolchain matrix with genuinely conflicting run-deps →
build-variant; if neither → per-pin subpackages like microarch.

Variant sets can also be loaded from files
(`[workspace] build-variants-files`), including conda-forge-style
`conda_build_config.yaml` — handy for mirroring conda-forge's pinning
feedstock.
