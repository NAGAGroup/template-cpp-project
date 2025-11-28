# Building Conda Packages

This directory contains the recipe and variant configurations for building conda packages using **rattler-build**.

## Structure

```
recipe/
├── recipe.yaml              # Unified recipe (uses ${{ compiler() }})
├── variants.yaml            # Default variants (Clang) - used by pixi-build
├── variants-linux-clang.yaml
├── variants-linux-gcc.yaml
├── variants-win-clang.yaml
└── variants-win-msvc.yaml
```

## Building with pixi-build

The simplest way to build is using pixi, which automatically uses `variants.yaml` (Clang):

```bash
pixi build
```

## Building with rattler-build

For more control over the toolchain, use rattler-build directly with a specific variant file:

```bash
# Install rattler-build (if not already installed)
pixi global install rattler-build

# Linux + Clang (default)
rattler-build build -r recipe/recipe.yaml --variant-config recipe/variants-linux-clang.yaml

# Linux + GCC
rattler-build build -r recipe/recipe.yaml --variant-config recipe/variants-linux-gcc.yaml

# Windows + Clang
rattler-build build -r recipe/recipe.yaml --variant-config recipe/variants-win-clang.yaml

# Windows + MSVC
rattler-build build -r recipe/recipe.yaml --variant-config recipe/variants-win-msvc.yaml
```

## Output

Built packages are placed in the `output/` directory as `.conda` packages.

## Toolchain Variants

| Variant File | Platform | Compiler | Version |
|--------------|----------|----------|---------|
| `variants.yaml` | Cross-platform | Clang | 18 |
| `variants-linux-clang.yaml` | Linux | Clang | 18 |
| `variants-linux-gcc.yaml` | Linux | GCC | 13 |
| `variants-win-clang.yaml` | Windows | Clang | 18 |
| `variants-win-msvc.yaml` | Windows | MSVC | 2022 |

## How It Works

The unified `recipe.yaml` uses the `${{ compiler('c') }}` and `${{ compiler('cxx') }}` Jinja functions, which are resolved based on the variant configuration:

- `c_compiler: clang` → resolves to `clang_linux-64` or `clang_win-64`
- `cxx_compiler: clangxx` → resolves to `clangxx_linux-64` or `clangxx_win-64`
- `c_compiler: gcc` → resolves to `gcc_linux-64`
- `c_compiler: vs2022` → resolves to `vs2022_win-64`

This approach eliminates recipe duplication while supporting multiple toolchains.
