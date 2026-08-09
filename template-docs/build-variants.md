# pixi build-variants

Build-variants answer "what is this package built **against**": same
package name, different build string, resolved per environment. **The
doctrine (C-02): an axis is a build-variant whenever each build's
compatibility is fully encoded in dependency metadata (pins,
run-exports, mutexes) so the solver enforces coherence and a bare spec
is always safe. An axis earns a distinct NAME only when the contract
reaches something the solver cannot see** — the consumer's own
toolchain (ABI regime → `enginelib-mingw`), a knowingly chosen
configuration (sanitizers, linkage, compiler → preset-variants,
`enginelib-clang`), or unsafe version ordering. Never encode an axis in
package names when metadata can carry it.

ONE live axis in this repo. Main carries a second — a DEPENDENCY-VERSION
axis over spdlog — which this branch deliberately does not inherit; the
reason is a genuine constraint on when such an axis is safe, so it is
recorded here rather than merely dropped.

## Why there is no dependency-version axis here

A dependency-version axis builds the same package name against two
versions of a dependency and lets run-dep conflicts select between
them. It is the happy path when it works. It is only safe, however,
**where the axis does not cross an ABI boundary in the nested host
solve** — and that is not something you can see from the manifest.

What went wrong here, concretely. Each variant cell resolves its own
dependencies in a NESTED HOST SOLVE that does not inherit the consuming
environment. On win-64 the two published spdlog builds for one of the
cells straddled an fmt ABI: the cell resolved a spdlog built against
fmt 12, so the library in that cell was compiled against `fmt::v12`,
while the consuming environment supplied fmt 11.2. The result was
`LNK1120: unresolved external symbol` at link time — not a solve
failure, a LINK failure, discovered in CI on the one platform where the
builds differed. Linux was immune because both spdlog builds there
agreed on fmt.

Two lessons worth more than the axis was:

1. **A dependency-version axis is only safe where the axis does not
   cross an ABI boundary in the nested host solve.** Check what each
   cell actually resolves, per platform, before adding one.
2. **An environment listing shows the RUNTIME closure; the nested host
   solve is where a build-time disagreement lives.** Reading the env
   view will make a build-time ABI problem look impossible.

The obvious fix — pinning the dependency's dependency to keep the cells
on one ABI — was rejected on package-boundary grounds: it means a
package declaring a pin on something it does not use, purely to steer
what its declared dependency drags in. A project reasons about the deps
it declares; what those drag in is the upstream maintainer's business.

(Spec-form rule, repo-wide: prefer `pixi add` over hand-writing specs;
hand-written specs use `">=x"`, `">=a.b,<a.c"`, or `"==a.b.c"` — never
`"X.*"`, never bare `"*"`… with ONE deliberate carve-out: **a dep that
participates in the build-variant matrix is declared `"*"`** — the
documented variant-substitution placeholder (pixi's variants page:
`python = "*"`, "Used to be 3.12.*"; the axis fills it). Do not "fix"
these — a blanket no-wildcard rule breaks variant expansion.
`ci/check-spec-forms.nu` enforces exactly this distinction, and its
allow-list shrank with the axis: with no variant to substitute, a bare
`"*"` would be an unpinned dep rather than a placeholder. Build
BACKENDS are exact-pinned (`==version`): they version independently of
pixi and are the real behavior surface for source packages — a backend
bump is a deliberate PR, like the pixi floor.)

**Selector-composition law (verified 0.76.1):** pixi INTERSECTS
dependency specs across the features composed into an env. A selector
feature therefore composes onto a base flavor only when it pins
packages the base does NOT declare (the microarch tiers pin the
underscore gate — `prod` never mentions it). Disjoint pins on a dep
both features declare are UNSOLVABLE when composed — such an axis needs
its own complete flavor feature, never a stacked selector.

## The axis that remains: microarch — open floors, capability gates

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
| `prod` | bare `linux-64` | `_x86_64-microarch-level = "==1"` | **Recommended consumer env.** Portable-by-contract (v1: any x86-64 CPU from the last ~15 years). The pin uniquely excludes the optimized builds. |
| `microarch-v0` | bare `linux-64` | none | Nuclear-conservative fallback, **not recommended** — resolves the level-1 build anyway (higher floors can't solve on a bare platform). |
| `microarch-v2/-v3/-v4` | gate entry | `_x86_64-microarch-level = "==N"` | Opt-in optimized tiers (v2: SSE4/POPCNT, ~every x86-64 CPU since 2009; v3: AVX2-era; v4: AVX-512). Solve-time gated; NOT install/run-enforced yet (warning above). |

Every tier has an env on purpose: environments show capability, not
just CI need — the template is a tutorial surface, and composition
(shared `header-only` + `prod` surface + per-tier selector feature) is
what makes the full set cheap.

Microarch levels have no minor versions — pin `==N`, never `N.*`.

**Manifest composition is load-bearing (C-07 with teeth):** the tier
envs differ ONLY by their selector, so the common deps live in the
shared `header-only` + `prod` features and each tier feature carries
only its pin. An env that carries a selector but not the selected
package silently selects nothing — share features across envs that
share deps.

A tier ENV must bind to its gate platform entry (`platforms =
["linux-64-vN"]`): an env solves for **every** platform in its list,
and the bare entry cannot solve a `>=2` runtime pin (bare entries solve
with pixi's documented default virtuals — `archspec=x86_64` — not the
host's detected CPU). Gate entries are pixi's own recommended mechanism
for declaring archspec/CUDA-class constraints; they parameterize solves
and gate capability — they are **never selection routers** (the old
"adaptive default" via platform ordering is retired: entry ranking
never disqualifies by archspec, so it mis-adapts).

Known open item (upstream-shaped, guarded in CI): pixi's
**source-variant selection is nondeterministic** when several variants
satisfy an env — the microarch floors are open by design, so the
v2/v3/v4 IN-WORKSPACE solves can land on a lower level on any fresh
`pixi lock` (observed: identical solves rolling different levels; a pin
that excludes UNIQUELY, like prod's `==1`, selects deterministically on
every roll — the unreliability lives exactly where ties exist). The
committed lock is the deterministic artifact: `ci/check-lock-tiers.nu`
asserts every run that the lock's tier envs carry their own level, so a
bad re-lock cannot land — after any `pixi lock`, re-run it and re-lock
until green. BINARY consumers of the published packages select
correctly with the same recipe (verified) and are unaffected.
(conda-forge's own auto-highest prioritisation relies on per-level
build-number offsets the cmake backend doesn't emit — so conda users,
like pixi users, select their tier explicitly.)

## Non-dependency keys: the toolchain pinning file

Compiler and stdlib pins are variant keys without a manifest dep spec —
they live in `./variants.yaml` (`[workspace] build-variants-files`,
rattler-build variant syntax; the name `conda_build_config.yaml` would
invoke the conda-build parser instead). There: gcc/gxx 16 on linux,
**vs2026 on win** (the backend's vs2022 default is stale — the file is
the explicit override; never delete it back), the glibc 2.28 floor with
its rationale, cmake 4.4, `zip_keys` lockstep pairs, and the m2w64
(mingw) compiler lane. See [toolchains.md](toolchains.md).

Non-dep keys canNOT be selected per env through pins — and a compiler
axis shouldn't be: compiler choice is either a knowingly-chosen
configuration (`enginelib-clang` — one name, realized per platform) or
a different ABI regime entirely (`enginelib-mingw` on Windows), so it's
a NAMED package variant either way. Beware metapackage naming:
`clangxx_linux-64`, not `clang`, on linux — a wrong name can silently
fall back to the system compiler.

## Mechanics worth knowing (verified)

1. Variant expansion works in plain AND `target.*`/`if()` dependency
   tables on equal footing (enginelib's microarch dep is target-scoped
   to linux and expands fine).
2. The consuming workspace owns the matrix: variant config is NOT
   inherited from a dependency's own workspace — the repo root carries
   the axes for exactly this reason.
3. `zip_keys` works in the rattler `variants.yaml` form (verified: a
   two-key zip yields 2 builds, not 4); inline
   `[workspace.build-variants]` does not support it.
4. A variant key binds a backend's IMPLICITLY-injected tool by name
   (`cmake`, `ninja`) with no explicit build-dep declared — backends
   inject those specs unpinned, and unpinned specs are variant-bindable.
5. The publish NAME-SET is the compliance surface for the naming
   doctrine: CI asserts it every run (`ci/check-publish-set.nu`).
   Output counts grow with the matrix; names must not.
