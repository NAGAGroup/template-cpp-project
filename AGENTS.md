# AGENTS.md — for agents working on THE TEMPLATE itself

This file explains **this template repository** to coding agents. It is
deliberately NOT an example of the AGENTS.md a project built *from* the
template should have — the `/init-project` command (`.agents/commands/`)
generates that one when a real project is initialized, overwriting this
file.

## What this repo is

The canonical NAGA-ecosystem pixi-build C++ template. Three jobs:
1. Canonical public example of a pixi-build C++ workspace.
2. Internal source of truth: NAGA project agents diff their repos against
   this one to detect divergence from template rules.
3. The README anchor other NAGA repos point consumers at.

## Load-bearing rules (violating any of these is a design regression)

1. **pixi owns cross-project consumption; CMake owns building one
   project.** No FetchContent, no CPM, no submodules, no vendoring — ever.
   External code enters via `external/` wrapper packages (cmake backend if
   upstream CMake is sane, rattler-build recipe otherwise) or conda-forge
   binaries.
2. **Manifests never carry configure detail.** Package manifests pass
   `--preset=<variant>` only (exception: wrappers for upstream projects,
   which have no presets). Variant presets set PROJECT-OWNED knobs
   (`ENGINELIB_SHARED`, …); CMakeLists maps them — because the
   pixi-build-cmake backend's own `-D` flags outrank preset
   cacheVariables.
3. **Environment doctrine.** ONE workspace manifest at the repo root —
   member projects are PACKAGE-ONLY manifests (a monorepo only holds
   projects sharing a variant matrix; anything else is its own repo).
   The default env is CHEAP: tooling + task features, ZERO source
   packages (declaring `[environments.default]` is valid exactly when
   it genuinely composes features; the antipattern is a redundant
   declaration). Library consumption lives in `prod` (= the v1 tier,
   portable by contract); demo-app lives in the `demo` env (an app is
   not a library-consumer surface). Platforms: bare entries for
   everything a normal user touches (bare linux-64 FIRST); rich inline
   entries are CAPABILITY GATES only (microarch tiers, cuda-class) —
   never selection routers, never content-identity hacks. Single-use env
   content is defined INLINE on environments; features carry only SHARED
   content. All non-default envs use `no-default-feature = true`. Dev
   envs are strictly per-package (a shared dev env would build sibling
   packages); their tasks carry the package `cwd`. Toolchains live in
   package dep tables; dev-only *tools* live in feature/env deps.
   **Zero system tooling.** Scripting: one-liners are inline tasks;
   anything multi-step/platform-conditional is a NUSHELL script under
   `scripts/` (nushell dep in the env that runs it) — never bash/bat
   pairs, never Python-for-scripting.
4. **Tests are standalone consumer projects** (`tests/` with its own
   manifests) that `find_package()` the installed lib. Test variants
   mirror the lib variant they test (a sanitized lib gets sanitized
   tests). The dev loop (`pixi run -e dev dev-test`) cmake-installs the
   lib into the dev env and builds tests against it — no packages
   involved.
5. **Layout.** Standalone packages: root manifest = workspace + default
   package + version anchor + own dev/test envs; `variants/` holds
   package-only subpackage manifests (`source.path = "../.."`,
   explicit synced versions). Internal-only projects (demo-app, tests) are
   package-only manifests.
6. **Run-deps, modern form.** Libraries WEAK-EXPORT THEMSELVES
   (`[package.run-exports.weak] name = "X.Y.*"` — version-specced, since
   self-exports publish unversioned otherwise); consumers just host-depend.
   Manual `[package.run-dependencies]` remain only where run-exports
   can't express the need (e.g. stb: private header-only dep exposed
   through the CMake export set of static builds). NOTE: run-exports and
   name-based refs break if member manifests carry their own [workspace]
   — one more reason rule 3/5 are load-bearing.

## Known upstream limitations this repo works around (re-verify on pixi upgrades)

- Nested [workspace] sections in member manifests break name-based
  source refs (run-exports, version-string run-deps) — avoided by the
  single-workspace layout (rule 3/5).
- Env-side variant selection works via run-dep conflicts; run-deps are
  not variant-substituted (pixi#4303, re-verified 0.76.1) → the
  microarch axis is HOST-consumed (host tables variant-expand; the
  runtime gate reaches run-deps via the flag-setter's strong
  run-export). HOST placement (not build) is load-bearing — from
  build-deps the strong export contaminates the package's own host
  solve and binds building to the build machine.
- pixi does not MATCH archspec at install/run (deliberate, pixi#3281;
  feature request #5285): microarch tier envs are solve-time gated
  only — a weaker machine installs/runs them silently (SIGILL later).
  Advisory `check-microarch` task + docs warning stand in until
  upstream lands; the gates then enforce with zero changes here.
- pixi's SOURCE-variant selection is NONDETERMINISTIC when several
  variants satisfy an env (microarch floors are open by design): fresh
  `pixi lock` runs can land tier envs on the wrong level. The committed
  lock is the deterministic artifact; `ci/check-lock-tiers.nu` asserts
  its tier selections every run — after re-locking, run it and re-lock
  until green. Binary consumers select correctly (verified) and are
  unaffected.
- Spec-form rule (Jack): prefer `pixi add`; hand-written specs use
  `">=x"` / `">=a.b,<a.c"` / `"==a.b.c"` — never `"X.*"`, never bare
  `"*"` EXCEPT variant-substitution placeholders (deps in the
  build-variant matrix are declared `"*"` — documented mechanism; CI
  enforces the distinction via ci/check-spec-forms.nu). Microarch
  levels have no minor versions: pin `==N`. Build backends are
  exact-pinned (`==version`, R11); bumping one is a deliberate PR.
- Manifest composition rule: share features across envs that share
  deps (tier envs = shared `header-only`+`prod` surface +
  selector-only tier features); a feature needing different solve
  semantics carries its own `solve-strategy` (verified 0.76.1 incl.
  source-package envs; governs regardless of list position). Read
  lowest-direct results semantically: transitives are never lowered,
  and chosen source variants' run-dep floors bound direct deps —
  lowest-SATISFYING, not lowest-in-spec. Selectors compose only when
  they pin packages the base
  flavor does NOT declare — pixi INTERSECTS specs across features, so
  disjoint pins on a declared dep are a separate FLAVOR feature
  (spdlog14), never a stacked selector.
- Capability-demonstration doctrine (Jack): environments aren't just
  what CI needs — they show capability. The template is a tutorial
  surface, a compilation of possibilities, NOT a hard requirement set;
  users discard what they don't need. Default answer for an orphaned
  demonstrable item is GIVE IT AN ENV, not prune. (Deletions justified
  by CORRECTNESS still stand.)
- `--locked`/`--frozen` are developer-side tools for already-installed
  envs; virtual packages legitimately differ across hosts (and their
  satisfiability re-solve is also buggy — repro:
  `CONDA_OVERRIDE_CUDA= pixi install --locked`). CI and consumers use
  DEFAULT resolution semantics; the committed lock still drives it.
- (historical: pre-0.75) publishing was per-package (--path semantics)
  and packs were limited to leaf envs. Since pixi 0.75 (#6526),
  `pixi publish` walks the workspace (gitignore-aware, nested
  workspaces skipped) for packages opting in with `publish = true` and
  builds/uploads the full chain in dependency order — verified on
  0.76.1: a root `pixi publish --dry-run` discovers all 4 publish
  packages / 5 outputs.
- conda-forge microarch metapackages are unix-only noarch → no win-64
  microarch story.

## Verification bar for changes

Run before claiming anything works (all from the repo root):
`pixi run demo && pixi run test-all`; `pixi run -e test-coverage
coverage`; `pixi run -e dev-enginelib dev-test` and `lint`;
`pixi run -e dev-mathkit dev-test`; `pixi run format-check` (default
env); `pixi run check-microarch`; `pixi install -e prod -e clang -e gnu -e
microarch-v0 -e microarch-v2 -e microarch-v3 -e static -e reldbg -e
spdlog14 -e demo-static -e demo-clang`;
`pixi exec --spec nushell nu ci/check-publish-set.nu`;
`pixi exec --spec nushell nu ci/check-lock-tiers.nu`;
`pixi exec --spec nushell nu ci/check-ci-shape.nu`;
`pixi exec --spec nushell nu ci/check-regime-markers.nu`. Windows: the same
minus sanitizers/coverage/microarch envs, plus the win-only gnu lane
(`test-gnu-windows`, `demo-gnu-windows`) — clang envs run on BOTH
platforms (clang-cl realization on win).

## Divergence checklist (for agents auditing OTHER NAGA repos)

Compare the target repo against: manifest doctrine (rule 3), preset-only
extra-args (rule 2), tests-as-consumers (rule 4), wrapper-not-vendored
externals (rule 1), zero system tooling, committed pixi.lock, support
policy in README. Report divergences; don't silently "fix" a repo that
diverged deliberately — its agent may have reasons; ask it.
