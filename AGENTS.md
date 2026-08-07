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
   Implicit default env = the adaptive library-consumer env (never
   declare `[environments.default]`); demo-app lives in the `app` env
   (portable chain can't coexist with microarch builds). Single-use env
   content is defined INLINE on environments; features carry only SHARED
   content. All non-default envs use `no-default-feature = true`. Dev
   envs are strictly per-package (a shared dev env would build sibling
   packages); their tasks carry the package `cwd`. Toolchains live in
   package dep tables; dev-only *tools* live in feature/env deps.
   **Zero system tooling.**
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
- Env-side variant selection works via run-dep conflicts OR custom-
  platform-scoped single-value variants; run-deps are not
  variant-substituted (pixi#4303) → microarch is per-level subpackages.
- `--locked` verification re-solves source workspaces unreliably across
  hosts/clones (repro: `CONDA_OVERRIDE_CUDA= pixi install --locked`) →
  CI uses `frozen`.
- pixi-pack publishes source packages per-package (--path semantics, no
  source run-deps) → packs limited to leaf envs; workspace
  `pixi publish` (publish-local task) handles full chains fine.
- conda-forge microarch metapackages are unix-only noarch → no win-64
  microarch story.

## Verification bar for changes

Run before claiming anything works (all from the repo root):
`pixi run demo && pixi run test-all`; `pixi run -e test-coverage
coverage`; `pixi run -e dev-enginelib dev-test` and `lint`;
`pixi run -e dev-mathkit dev-test`; `pixi run -e style format-check`;
`pixi install -e clang -e v3 -e spdlog14`; `pixi publish --dry-run --to
./local-channel`. Windows: the same minus sanitizers/coverage/microarch/
clang envs.

## Divergence checklist (for agents auditing OTHER NAGA repos)

Compare the target repo against: manifest doctrine (rule 3), preset-only
extra-args (rule 2), tests-as-consumers (rule 4), wrapper-not-vendored
externals (rule 1), zero system tooling, committed pixi.lock, support
policy in README. Report divergences; don't silently "fix" a repo that
diverged deliberately — its agent may have reasons; ask it.
