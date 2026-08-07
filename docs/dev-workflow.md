# Developer workflow

Day-to-day work happens **inside a package's dev env** with plain CMake
presets — pixi provides the environment, CMake does the building, no
packages are built in the loop.

```sh
cd packages/enginelib
pixi run -e dev configure      # cmake --preset dev (+ compile_commands symlink)
pixi run -e dev build
pixi run -e dev dev-test       # see below
pixi run -e dev lint           # run-clang-tidy over the dev build
pixi run -e dev cmake --preset dev-asan   # any variant, ad hoc
pixi shell -e dev              # or just live in the env
```

The dev env is the package's **dependency closure without building the
package** (`[feature.dev.dev]` + `no-default-feature = true`): the same
compilers, cmake, ninja and dependency headers/configs the hermetic
package build uses (`ls .pixi/envs/dev/include/`), plus dev-only tools
(Catch2, clang-tools) from feature deps. Dev envs are strictly
per-package — a combined env would have to *build* sibling packages.

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

## Formatting & docs

Repo-wide, from the root workspace: `pixi run -e style format`,
`format-check`, `docs` (Doxygen → `docs/api/`).
