# Features & environments: the composition model

**A FEATURE is the unit of composition; an ENV is only a composition.**
An env's inline content is exactly its DELTA from shared features.
DEP-features are separate from TASK-features: tools are defined once,
tasks are defined once, and environments assemble them.

## The default env is CHEAP

`default` = `tooling` + `style-tasks`. Zero source packages, ever —
formatting or docs generation must never force a source build.
Declaring `[environments.default]` is valid exactly when it genuinely
composes features (the antipattern is only a redundant declaration).
Library consumption lives in `prod`.

## Flavor features

Source consumption is FLAVOR-scoped and COMPLETE: each flavor feature
carries a coherent surface at its flavor (the variant package + the
spdlog lineage pin). Mixing flavors — a default mathkit with a static
enginelib — is incoherent, so envs compose `header-only` + exactly ONE
flavor + orthogonal task/selector features.

| feature | contents |
|---|---|
| `header-only` | mathkit — composed into every consumer/test env |
| `prod` | enginelib + spdlog (the default toolchain per platform) |
| `static` / `reldbg` / `clang` | the matching variant + spdlog |
| `asan` / `tsan` / `coverage` | linux-only variants + spdlog (+ sanitizer activation env vars; coverage also carries llvm-tools) |
| `gnu` | target-table showcase: linux → enginelib, win → enginelib-mingw |
| `spdlog14` | enginelib + the 1.14 spdlog pin (a FLAVOR, see below) |

## Selectors and the intersection law

Selector features (`microarch-v2/-v3/-v4`) compose onto the shared
surface because they pin a package the base flavor does NOT declare
(the underscore runtime gate). **Pixi INTERSECTS dependency specs
across composed features** (verified 0.76.1): disjoint pins on a
declared dep are unsolvable, which is why `spdlog14` is a complete
flavor feature rather than a selector stacked on `prod`.

## Solve strategy is a feature concern

`solve-lowest` carries `solve-strategy = "lowest-direct"` and composes
into `test-lowest` (C-09; verified 0.76.1, including in
source-package envs, regardless of the feature's list position). Two
semantic rules shape what you see — misread them and the env looks
broken when it is exactly right: (1) lowest-**direct** never lowers
TRANSITIVE deps (catch2 arrives via the tests packages' host-deps and
stays highest); (2) the chosen source variant's run-dep can FLOOR a
direct dep (the 1.15-built enginelib carries `spdlog >=1.15.3`, so
test-lowest's spdlog is 1.15.3 — the lowest *satisfying* version, and
coincidentally also the highest in range: a degenerate observable).
Min-version testing composes with run-export floors; it does not
bypass them. An unconstrained direct dep resolves genuinely lowest.

Why floors happen at all: a consumed source package's HOST deps are
resolved in a NESTED solve that does not inherit the env's strategy,
and their run-exports are baked into the source record as floors — the
env solve then applies lowest-direct faithfully to an already-floored
candidate set. Spotting it in a lock: a **doubled spec on a source
record** (the raw spec plus a tighter pin) is the fingerprint of a
run-export floor. So state the guarantee precisely: `test-lowest`
lowers every UNFLOORED direct dep and cannot lower floored ones.

## Task features

`style-tasks` (format/format-check/docs/open-docs → default env),
`test-tasks` (the `test` runner → every test env), `demo-tasks` (the
`demo` runner with its args showcase → every demo env). Env-inline
task OVERRIDES carry per-env deltas (e.g. sanitizer test envs override
`test` to run only the instrumented binary) — inline env content
shadows composed feature content, which is the precedence lesson.

## The environment inventory

- **default** — tooling + style tasks (cheap; carries `check-microarch`).
- **Consumers**: `prod` (recommended; = the v1 tier), `microarch-v0`
  (teaching entry, not recommended), `microarch-v2/-v3/-v4` (gate-bound
  tiers), `static`, `reldbg`, `clang`, `gnu`, `spdlog14`,
  `header-only` (doubles as the pixi-pack demo).
- **Tests**: `test`, `test-clang`, `test-gnu-windows` (win-only — the
  env-platform-limiting showcase), `test-asan`, `test-tsan`,
  `test-coverage` (linux-only), `test-lowest`. The test matrix is
  deliberately NOT the whole variant matrix (no test-static: the static
  consumer env stays, but prod + clang + gnu-windows + sanitizers is
  the meaningful test surface).
- **Demos**: `demo`, `demo-static`, `demo-clang`, `demo-gnu-windows`
  (win-only). `demo` is ambiguous by design across these envs — the
  task-resolution lesson: `pixi run demo` fails with the env list,
  `pixi run -e demo demo` runs. Contrast `pixi run coverage`, which
  resolves bare because exactly one env carries it.
- **Dev**: `dev-mathkit`, `dev-enginelib`, `dev-demo-app` — strictly
  per-package (see [dev-workflow.md](dev-workflow.md)); each composes
  its dev feature + `tooling`.

Environments show capability, not just CI need: the template is a
tutorial surface — a compilation of possibilities, not a hard
requirement set. Users discard what they don't need.
