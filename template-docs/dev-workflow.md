# Developer workflow

Day-to-day work happens **inside a package's dev env** with plain CMake
presets — pixi provides the environment, CMake does the building, no
packages are built in the loop.

```sh
# everything from the repo root — tasks carry the package cwd
pixi run -e dev-enginelib configure   # cmake --preset dev (+ compile_commands link)
pixi run -e dev-enginelib build
pixi run -e dev-enginelib dev-test    # see below
pixi run -e dev-enginelib lint        # run-clang-tidy over the dev build
pixi run -e dev-enginelib lint fix    # args-with-choices: mode = check|fix
pixi shell -e dev-enginelib           # or live in the env (cd packages/enginelib)
```

The dev env is the package's **dependency closure without building the
package** (`[feature.dev-<pkg>.dev]` + `no-default-feature = true`): the
same compilers, cmake, ninja and dependency headers/configs the hermetic
package build uses (`ls .pixi/envs/dev-enginelib/include/`), plus
dev-only tools from the shared `tooling` feature. The dev feature lists
the package AND its tests package as dev packages — their closures
deliver catch2 and everything the tests build needs, so no test-dep is
ever declared directly. Dev envs are strictly per-package — a combined
env would have to *build* sibling packages.

## The dev test loop

Tests are consumer projects, so the dev loop makes the package findable
without involving pixi packaging:

```
dev-test = build lib → cmake --install into $CONDA_PREFIX → configure+build
           tests/ against it (CMAKE_PREFIX_PATH=$env{CONDA_PREFIX}) → ctest
```

Iterate at CMake speed; the packaged path (`pixi run -e test test`) stays
the CI/consumer-fidelity check. Installed artifacts carry
`INSTALL_RPATH=$ORIGIN` so the loader never falls back to system
libraries.

## Editor/LSP

`configure` symlinks `compile_commands.json` at the package root; clangd
(from the env, not the system) picks it up. Warnings-as-errors are on in
dev presets (`<PKG>_DEV_MODE`) and off in package builds.

## Scripting doctrine: nushell

One-liners stay inline pixi tasks (deno_task_shell is already
cross-platform, and MiniJinja `{% if pixi.is_win %}` covers one-line
platform conditionals — see the `open-docs` task). Anything multi-step
becomes a **nushell script** under `scripts/` — one script for every
OS, no bash/bat pairs, and no Python-for-scripting (overkill). Nushell
comes from the env like every other tool (zero-system-tooling), aborts
on the first failing external command, and treats command output as
structured data: `scripts/coverage.nu` turns llvm-cov's JSON into a
per-file coverage table in four pipeline steps, and `scripts/format.nu`
fans clang-format out with `par-each`.

## Formatting & docs

Repo-wide, from the root workspace (the tasks ride the CHEAP default
env — tooling only, zero source packages): `pixi run format`,
`format-check`, `docs` (Doxygen → `docs/api/`, cached on
inputs/outputs), `open-docs`.
