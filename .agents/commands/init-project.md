# /init-project — turn this template into a real project

You are initializing a NEW project from template-cpp-project. Do not write
any code until you and the developer have fully aligned on the design.
This template was itself built design-first; honor that.

## Phase 1 — Align (interactive; ask, don't assume)

Work through these with the developer, one batch at a time. Offer
recommendations but expect and incorporate corrections:

1. **What is being built?** Purpose, rough architecture, target users.
2. **Package inventory.** Which template packages map to real ones?
   Typical mapping: `mathkit` → your header-only lib (delete if none),
   `enginelib` → your core compiled lib, `demo-app` → your app/CLI
   (delete if library-only). New names for each; CMake namespaces =
   package names.
3. **Standalone vs internal.** Which packages are externally consumable
   (workspace+package root manifest, own version, per-package git tag
   series `<name>-vX.Y.Z`) vs internal-only (package-only manifest)?
4. **Variant matrix.** Which preset-variants does each compiled lib need
   (static? sanitizers? coverage? microarch levels?) — delete unused
   variant dirs + envs; every variant must have a consuming env or a
   documented consumer.
5. **Platforms.** Trim/extend `platforms` in every workspace manifest.
   Note: microarch subpackages and sanitizer/coverage envs are linux-only.
6. **External dependencies.** For each: conda-forge binary → plain dep;
   sane upstream CMake → cmake-backend wrapper in `external/`; broken
   upstream build → rattler-build recipe wrapper. Never FetchContent.
7. **Tooling versions.** Default is leading-edge (CMake ≥4.2, C++23,
   current compilers). Ask explicitly: does their consumer base require
   downgrading? (docs/tooling-versions.md has the framing.)
8. **License + repo details.** MIT is the template default.

Write the agreed design into a short DESIGN.md at the repo root and get
explicit sign-off before Phase 2.

## Phase 2 — Initialize (mechanical)

1. Rename packages: directory names, `[package] name`/workspace `name` in
   every `pixi.toml` (root, packages, variants, tests), CMake
   `project()`/targets/namespaces/Config.cmake.in files, `#include`
   paths, knob prefixes (`ENGINELIB_*` → `<NEWNAME>_*`), preset files,
   test binaries, root workspace dep list + wrapper tasks, CI job paths,
   Doxyfile INPUT paths, .clang-tidy HeaderFilterRegex.
2. Delete unused packages/variants/wrappers and their envs/tasks/CI jobs.
3. Reset versions to 0.1.0 and update the version-sync comments.
4. Rewrite README.md for the real project (keep the support-policy
   boilerplate and the tooling-versions warning, adjusted to Phase-1
   answers).
5. **Overwrite AGENTS.md** with one written for the real project: what it
   is, its architecture, its verification bar, and the template
   doctrine rules that still apply (manifest doctrine, tests-as-consumers,
   zero system tooling, no FetchContent). Do NOT keep the
   template-maintainer content.
6. Delete `.agents/commands/init-project.md` (and its pointer stubs) and
   docs/renaming.md.
7. Regenerate all lockfiles (`pixi install` at root and in each member
   workspace) and run the full verification bar from AGENTS.md.
8. Commit as the project's initial commit; suggest the developer make the
   repo NOT a template repo if it was cloned as one.

Report every rename and deletion you performed.
