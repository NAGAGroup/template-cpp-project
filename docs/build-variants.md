# pixi build-variants

Build-variants answer "what is this package built **against**": same
package name, different build string, resolved per environment. **The
doctrine (C-02): an axis is a build-variant whenever each build's
compatibility is fully encoded in dependency metadata (pins,
run-exports, mutexes) so the solver enforces coherence and a bare spec
is always safe. An axis earns a distinct NAME only when the contract
reaches something the solver cannot see** — the consumer's own
toolchain (compiler/stdlib regime → `enginelib-clang`), a knowingly
chosen configuration (sanitizers, linkage → preset-variants), or unsafe
version ordering. Never encode an axis in package names when metadata
can carry it.

Two live axes in this repo, one per selection style:

## Axis 1: spdlog — the happy path (tight ceilings)

```toml
[workspace.build-variants]
spdlog = ["1.14.*", "1.15.*"]

[environments.spdlog14]
dependencies = { enginelib = { workspace = true }, spdlog = "1.14.*" }  # <- selector
```

An environment picks a variant build **through run-dependency
conflicts**: the 1.14-built enginelib carries spdlog's `<1.15`
run-export, which conflicts with a `1.15.*` pin, forcing the solver onto
the other variant. Tight run-export ceilings ⇒ pins select uniquely.
If no run-dep distinguishes the variants, the solver happily reuses one
build for every env — which is exactly the microarch situation below.

## Axis 2: microarch — open floors, capability gates

`x86_64-microarch-level` (conda-forge) is a variant-substituted **host**
dep on enginelib (linux-only, target-scoped — the packages are unix-only
noarch). Mechanism, all verified on pixi 0.76.1:

- The flag-setter's activation appends the level's `-march` **last** on
  the compile line (wins over the compiler activation's default); we
  never hand-edit CXXFLAGS.
- Its **strong run-export** stamps `_x86_64-microarch-level >=N` (the
  runtime gate) into each build's run-deps. We never declare the
  underscore package in a manifest — it arrives via run-exports.
- **Host placement is load-bearing**: from build-deps, the strong
  export would also land in the package's own host env and bind
  *building* to the build machine's capability (conda-forge's own
  "can only build ≤ your runner's level" wall). From host-deps the gate
  reaches run-deps only: any machine builds the full matrix, and one
  `pixi publish -p linux-64` produces every level.
- The floors are deliberately **open** (`>=N` — a v3 CPU runs a v1
  build; conda-forge's README keeps them open for CI testability), so
  env pins on the flag-setter cannot select a variant. Tier envs pin
  the UNDERSCORE runtime package instead, and bind to a capability-gate
  platform entry so the pin can solve (see below).

### ⚠ BIG WARNING: pixi does not validate archspec yet

**As of pixi 0.76.1 a machine below a tier's level can `pixi install`
and `pixi run` that tier env with zero diagnostics and crash later as
SIGILL.** This is a known, deliberately-unimplemented feature, not a
bug: virtual-package validation ignores build-string matchers — and
`__archspec` is build-string-only — per the maintainers
([pixi#3281](https://github.com/prefix-dev/pixi/pull/3281): "we don't
match archspecs yet, we should ignore them");
[pixi#5285](https://github.com/prefix-dev/pixi/issues/5285) is the open
feature request (add your voice there; don't open new issues).

Run **`pixi run check-microarch`** (advisory task in the default env —
the one env every machine can install) BEFORE using a tier env.

**This project is pre-wired**: tier platforms declare archspec honestly
and every optimized build carries its underscore gate in run-deps — the
day pixi's validator matches archspec, the tier envs start refusing
incompatible machines with **zero changes here** (already-installed
envs need one reinstall; the validator reads stored metadata).

### The tier envs

| Env | Platform | Selector | Meaning |
|-----|----------|----------|---------|
| default | bare `linux-64` | `_x86_64-microarch-level = "1.*"` | **Recommended.** Portable-by-contract (v1: any x86-64 CPU from the last ~15 years). The pin uniquely excludes the optimized builds. |
| v0 | bare `linux-64` | none | Nuclear-conservative fallback, **not recommended** — resolves the level-1 build anyway (higher floors can't solve on a bare platform). |
| v3 / v4 | gate entry | `_x86_64-microarch-level = "3.*"/"4.*"` | Opt-in optimized tiers. Solve-time gated; NOT install/run-enforced yet (warning above). |

A tier feature MUST carry `platforms = ["<its gate entry>"]`: an env
solves for **every** platform in its list, and the bare entry cannot
solve a `>=2` runtime pin (bare entries solve with pixi's documented
default virtuals — `archspec=x86_64` — not the host's detected CPU).
Gate entries are pixi's own recommended mechanism for declaring
archspec/CUDA-class constraints; they parameterize solves and gate
capability — they are **never selection routers** (the old "adaptive
default" via platform ordering is retired: entry ranking never
disqualifies by archspec, so it mis-adapts).

Known open item: pixi-build-cmake cannot express per-variant build
numbers, so conda-forge's build-number prioritisation (+100·(level−1))
is not applied; among multiple CPU-compatible optimized builds the
solver's choice is a tie (tracked; the rattler-build backend is the
escape hatch if it bites).

## Non-dependency keys

`cxx_compiler` and other non-dep keys can be overridden globally (the
`[workspace.target.win-64.build-variants]` vs2022 demo restates the
Windows default). They can NOT be selected per env through pins — and a
compiler axis shouldn't be: compiler choice is a consumer-toolchain
contract the solver cannot see, so it's a NAMED package variant
(`variants/clang` → `enginelib-clang`), knowingly chosen like
asan/static. Beware metapackage naming: `clangxx_linux-64`, not
`clang` — a wrong name can silently fall back to the system compiler.

## Mechanics worth knowing (verified)

1. Variant expansion works in plain AND `target.*`/`if()` dependency
   tables on equal footing (enginelib's microarch dep is target-scoped
   to linux and expands fine).
2. The consuming workspace owns the matrix: variant config is NOT
   inherited from a dependency's own workspace — the repo root carries
   the axes for exactly this reason.
3. Variant sets can be loaded from files (`[workspace]
   build-variants-files`), including conda-forge-style
   `conda_build_config.yaml`.
4. The publish NAME-SET is the compliance surface for the naming
   doctrine: CI asserts it every run (`ci/check-publish-set.nu`).
   Output counts grow with the matrix; names must not.
