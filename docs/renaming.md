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
   matching envs, tests variants, and CI steps.
5. **Set versions** to 0.1.0 everywhere (root manifests AND variant
   manifests — they must stay in sync).
6. **Rewrite README.md** (keep the support-policy + tooling-versions
   boilerplate). **Overwrite AGENTS.md** with one about *your* project.
7. Reconsider [tooling versions](tooling-versions.md) for your userbase.
8. Delete `.agents/commands/init-project.md`, its pointer stubs, and this
   file.
9. `pixi install` at root and in each member workspace (regenerates
   locks); run the verification bar from AGENTS.md; commit.
