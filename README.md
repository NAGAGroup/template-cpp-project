# template-cpp-project

A production-shaped **pixi-build C++ project template**: one workspace,
several packages, every consumption path proven in CI — and an argument, in
repo form, that [pixi](https://pixi.prefix.dev) is the C++ project manager
that has been missing.

**pixi owns cross-project consumption; CMake owns building one project.**
Everything else in this repo follows from that sentence.

## What you get

| | |
|---|---|
| `pixi.toml` | THE workspace — every environment, task, and the variant matrix (members are package-only manifests) |
| `packages/mathkit` | header-only library (weak self-export teaching case) |
| `packages/enginelib` | compiled library — the variant teacher: preset-variants (`static`, `asan`, `tsan`, `coverage`, `relwithdebinfo`), pixi build-variants (spdlog version matrix + microarch levels under ONE name) |
| `packages/demo-app` | application consuming the libraries (internal-only, package-only manifest) |
| `external/fmt` | wrapper package building upstream fmt from a git tag (pixi-build-cmake) |
| `external/stb` | wrapper via the **rattler-build escape hatch** — upstream has no build system; the recipe installs headers + a hand-written CMake config |
| `tests/` under each lib | tests as standalone **consumer projects** that `find_package()` the installed library |
| `.github/workflows` | pixi-first CI: consume, test, sanitizers, llvm-cov coverage, variants, style, pixi-pack |

## Quickstart

This is a GitHub **template repository** — click **“Use this template”** on
the repo page (or `gh repo create my-project --template NAGAGroup/template-cpp-project`),
then run the `/init-project` agent command or follow
`template-docs/renaming.md`.

To just try it ([install pixi](https://pixi.prefix.dev), nothing else —
no compiler, no cmake, no system anything):

```sh
pixi run -e demo demo               # build the app chain, run it (try `demo 20`)
pixi run test-all                   # every test env for this platform
pixi run -e test-asan test          # sanitized variant, tests built to match
pixi run coverage                   # llvm-cov report (resolves without -e: one env owns it)
pixi run -e dev-enginelib dev-test  # the in-tree dev loop (no packages involved)
pixi run check-microarch            # what your CPU supports (do this before v2/v3/v4)
pixi run publish-local              # every package into an indexed local channel
```

## The ideas, in one screen

1. **Environments are the interface; features are the unit of
   composition.** One root workspace; the default env is CHEAP (tooling
   + style tasks, zero source packages); `prod` is the recommended
   consumer env, portable by contract (the v1 microarch tier);
   optimized tiers are explicit opt-in envs (run
   `pixi run check-microarch` first — see
   template-docs/build-variants.md). Test envs compose flavor features
   and consume test packages. Dev envs materialize a package's build
   closure *without building it* — day-to-day work is plain CMake
   presets inside that env.
2. **A package variant is a CMake preset.** Pixi manifests pass only
   `--preset=<name>`; presets carry *project-owned knobs* which
   CMakeLists maps to real CMake variables. Non-pixi users get the same
   variants via plain `cmake --preset`.
3. **Tests are consumer projects.** They `find_package()` the installed
   library, because testing your install surface is testing what your
   users actually get.
4. **External code is wrapped, never vendored.** conda-forge binary if it
   exists → cmake-backend wrapper if upstream CMake is sane →
   rattler-build recipe if it isn't. **FetchContent/CPM: never.**
5. **Zero system tooling.** Compilers, clangd, formatters, doxygen —
   even the scripting runtime — all from pixi envs. Every developer,
   every CI job, identical tooling. Scripts are **nushell** (`scripts/`):
   one cross-platform script set, structured-data pipelines instead of
   awk-scraping (see the coverage table `scripts/coverage.nu` prints).

Template deep dives live in [`template-docs/`](template-docs/) — prose
about the TEMPLATE, self-contained so instantiated projects delete the
directory in one step: [why pixi](template-docs/why-pixi.md) ·
[features & environments](template-docs/features-and-environments.md) ·
[consuming these packages](template-docs/consuming.md) ·
[variants](template-docs/variants.md) ·
[build-variants](template-docs/build-variants.md) ·
[external deps](template-docs/external-deps.md) ·
[versioning](template-docs/versioning.md) ·
[toolchains](template-docs/toolchains.md) ·
[dev workflow](template-docs/dev-workflow.md) ·
[publishing](template-docs/publishing.md) ·
[tooling versions](template-docs/tooling-versions.md) ·
[design record](template-docs/design-record.md)

[`docs/`](docs/index.md), by contrast, documents the DUMMY PROJECT the
way a real derived project documents its code — it is the example you
rewrite, not prose you delete.

## Opinionated tooling versions — read this

This template runs **leading-edge tooling** (CMake ≥ 4.2, current gcc and
clang/LLVM, C++23) because the conda ecosystem makes that *possible* — the
entire point is escaping distro-frozen toolchains. It is a deliberately
nuclear choice, and it may be wrong **for you**: if your project must be
consumable by codebases with long histories and slow toolchain migrations,
**downgrade to your minimum viable versions before you lock out your
primary userbase.** We fully encourage that divergence; we just don't
officially support issues specific to downgraded tooling. See
[template-docs/tooling-versions.md](template-docs/tooling-versions.md).

## Support policy

The **pixi pipeline is the only officially supported way to build and
consume these packages** (source deps for pixi users; `pixi-pack`
environments + `find_package` for everyone else). Raw
`add_subdirectory`, FetchContent, or CPM may happen to work; issues
specific to those paths will be closed. This policy text is boilerplate —
copy it into your own README.

## License

MIT — see [LICENSE](LICENSE).
