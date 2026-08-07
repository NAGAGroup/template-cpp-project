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
3. **Environment doctrine.** Implicit default env = consumer env (never
   declare `[environments.default]`). Dev/test envs use
   `no-default-feature = true`. Dev envs are strictly per-package (a
   shared dev env would build sibling packages). Toolchains live in
   package dep tables; dev-only *tools* (Catch2, clang-tools, formatters)
   live in feature deps. **Zero system tooling.**
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
6. **Run-deps.** Public deps are repeated in `[package.run-dependencies]`
   (THE RULE). `[package.run-exports]` self-export is the intended future
   — blocked by a pixi path-resolution bug (any run-exports table breaks
   sibling path deps from member workspaces). Re-check on pixi upgrades.

## Known upstream limitations this repo works around (re-verify on pixi upgrades)

- run-exports path bug (see rule 6).
- Build-variant expansion applies only to PLAIN package dep tables (not
  `if()`/`target.*`), and env-side variant selection works only through
  run-dep conflicts → microarch is per-level subpackages (`variants/v1|v3|v4`),
  not a variant axis; compiler/stdlib axes are global overrides only.
- `pixi publish` / `pixi-pack` require a self-contained publish set and
  the walker skips nested workspaces → packs/publishes work for LEAF
  packages only (mathkit, wrappers).
- conda-forge microarch metapackages are unix-only noarch → no win-64
  microarch story.

## Verification bar for changes

Run before claiming anything works: `pixi run demo && pixi run test-all`
(root); `pixi run -e test-asan test`, `-e test-coverage coverage`,
`-e dev dev-test`, `-e dev lint` (enginelib); `pixi run -e style
format-check` (root). Windows: the same minus sanitizers/coverage/microarch.

## Divergence checklist (for agents auditing OTHER NAGA repos)

Compare the target repo against: manifest doctrine (rule 3), preset-only
extra-args (rule 2), tests-as-consumers (rule 4), wrapper-not-vendored
externals (rule 1), zero system tooling, committed pixi.lock, support
policy in README. Report divergences; don't silently "fix" a repo that
diverged deliberately — its agent may have reasons; ask it.
