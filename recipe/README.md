# Conda Package Recipes

This directory contains **rattler-build** recipes for building conda packages of `template-cpp-project` with different toolchains.

## Quick Start

### Prerequisites

Install `rattler-build`:

```bash
pixi global install rattler-build
```

### Build a Package

```bash
# Linux/Windows with Clang (default)
rattler-build build recipe/recipe.yaml

# Linux with GCC
rattler-build build recipe/recipe-gcc.yaml

# Linux with DPC++ (SYCL)
rattler-build build recipe/recipe-dpcpp.yaml

# Windows with MinGW
rattler-build build recipe/recipe-mingw.yaml
```

Output packages are created in the `output/` directory as `.tar.bz2` conda packages.

## Available Recipes

### `recipe.yaml` - Clang (Default)

- **Toolchain**: Clang 18
- **Platform**: Linux, Windows
- **Channels**: conda-forge
- **Use Case**: Cross-platform C++ development
- **Advantages**: Modern compiler, excellent diagnostics, works on both Linux and Windows

### `recipe-gcc.yaml` - GCC

- **Toolchain**: GCC 13.3
- **Platform**: Linux
- **Channels**: conda-forge
- **Use Case**: Standard C++ development on Linux
- **Advantages**: Widely compatible, large community

### `recipe-dpcpp.yaml` - DPC++ (SYCL)

- **Toolchain**: Intel's DPC++ (SYCL)
- **Platform**: Linux only
- **Channels**: conda-forge, NAGAGroup
- **Use Case**: When you need SYCL support for heterogeneous computing
- **Requires**: Intel SYCL SDK from NAGAGroup channel

### `recipe-mingw.yaml` - MinGW

- **Toolchain**: GCC-based MinGW for Windows
- **Platform**: Windows only
- **Channels**: conda-forge
- **Use Case**: GNU development tools on Windows
- **Advantages**: Familiar tools for Linux developers

## Recipe Structure

Each recipe includes:

- **Build Dependencies**:
  - CMake ≥3.24, Ninja, ccache, pkg-config
  - Compiler toolchain (varies by recipe)

- **Host Dependencies**:
  - fmt library (formatting)

- **Runtime Dependencies**:
  - fmt library

- **Build Process**:
  - Sets environment variables (`CC`, `CXX`, etc.)
  - Runs CMake configure with Release mode
  - Builds with CMake
  - Installs to conda environment

- **Tests**:
  - Runs `template-cpp-project_test --version` to verify installation
  - Requires Catch2 test framework

## Customization

To modify a recipe:

1. Edit the YAML file (e.g., `recipe.yaml`)
2. Update compiler versions, flags, or dependencies as needed
3. Run `rattler-build build recipe/recipe.yaml` to test

Common customizations:

**Change CMake flags**:
```yaml
- DCMAKE_CXX_FLAGS="-O3 -march=native"
```

**Add additional dependencies**:
```yaml
requirements:
  build:
    - my-library >=1.0.0
```

**Modify build steps**:
```yaml
build:
  script:
    - cmake -B build -S . ...
    - cmake --build build ...
```

## Integration with CI/CD

Recipes can be automatically built in CI pipelines:

```bash
# Build all recipes
for recipe in recipe/*.yaml; do
  rattler-build build "$recipe"
done
```

## Troubleshooting

### Build fails with missing compiler

Ensure the toolchain's conda channel is accessible:
```bash
# For DPC++, add nagagroup channel
conda config --add channels nagagroup
```

### Linker errors after build

Check that `RPATH` handling is correct in CMake:
```yaml
- -DCMAKE_INSTALL_RPATH="\$ORIGIN;\$ORIGIN/../lib"
```

### Test failures

Verify Catch2 is available in the test environment:
```bash
mamba install -c conda-forge catch2
```

## References

- [Rattler-Build Documentation](https://prefix-dev.github.io/rattler-build/)
- [Conda Recipe Format](https://conda.io/projects/conda-build/en/latest/resources/define-metadata.html)
- [schema_version 1 Specification](https://prefix-dev.github.io/rattler-build/schema/)
