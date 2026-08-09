# Turning the template into your project (manual checklist)

Prefer the agent flow: run **`/init-project`** (canonical prompt in
`.agents/commands/init-project.md`) — it walks the design alignment first
and then performs everything below. This page is the manual fallback.

1. **Create your repo** from the template: GitHub → **Use this template**
   → *Create a new repository* (or
   `gh repo create my-project --template NAGAGroup/template-cpp-project`).
2. **Decide your package inventory** (delete what you don't need):
   mathkit → your header-only lib · enginelib → your compiled lib ·
   demo-app → your app · external/* → your real wrapped deps.
3. **Rename** (repo-wide, case-sensitive; `git grep -l mathkit` etc.):
   - directory names under `packages/`
   - `name` fields in every `pixi.toml` (workspace + package + variants + tests)
   - path deps in root `pixi.toml` + wrapper tasks + CI paths
   - CMake: `project()`, targets, `ALIAS`/namespace, `*Config.cmake.in`
     filenames and contents, install destinations
   - include dirs + `#include` paths, header guards
   - knob prefixes (`ENGINELIB_*`, `MATHKIT_*`, `*_DEV_MODE`)
   - `.clang-tidy` HeaderFilterRegex, `Doxyfile` INPUT
4. **Trim the variant matrix** to what you'll actually consume; delete the
   matching envs, tests variants, and CI steps. (The full feature/env
   inventory is a tutorial surface — most projects keep a fraction.)
5. **Set versions** to 0.1.0 everywhere (root manifests AND variant
   manifests — they must stay in sync).
6. **Rewrite README.md** (keep the support-policy + tooling-versions
   boilerplate). **Overwrite AGENTS.md** with one about *your* project.
   **Rewrite `docs/`** — it documents the dummy project exactly as your
   docs will document yours; replace its contents, keep its shape.
7. Reconsider [tooling versions](tooling-versions.md) for your userbase.
8. **Delete the entire `template-docs/` directory** — every page in it
   (including this one) teaches the TEMPLATE, not your project. It is
   self-contained precisely so this step is one `rm -r`. Also delete
   `.agents/commands/init-project.md` and its pointer stubs.
9. `pixi install` at the root (regenerates the lock); run the
   verification bar from AGENTS.md; commit.
