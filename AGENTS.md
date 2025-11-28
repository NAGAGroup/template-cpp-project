# Agent Guidelines for template-cpp-project

## Environment Setup

This project uses **pixi** for dependency management. Activate the development environment:
```bash
pixi shell -e dev    # Activates dev environment (includes dpcpp, clang tools, test deps)
pixi shell -e test   # Activates test-only environment
pixi shell -e user   # User environment for end consumers
```

## Quick Commands

**Configure & Build (Dev Mode):**
```bash
pixi run configure              # Run cmake configure (calls scripts/configure.sh)
pixi run build                  # Build project (depends-on configure)
ctest --preset=dev              # Run all tests
pixi run -e test install        # Build & install from test environment
```

**Run Single Test:**
```bash
ctest --preset=dev -R template-cpp-project_test -V
```

**Format & Lint:**
```bash
cmake --build --preset=dev -t format-fix      # Fix formatting with clang-format
cmake --build --preset=dev -t spell-fix       # Fix spelling errors
cmake --build --preset=dev -t clang-tidy      # Run clang-tidy linter
```

**Project Management:**
```bash
pixi run -e project-mgmt change-project-name  # Rename project (interactive)
```

## Code Style Guidelines

**Formatting:** Enforced via `.clang-format` (Chromium-based with 2-space indents, 80-char limit).

**Naming Conventions:**
- Classes/Structs: `lower_case` (e.g., `exported_class`)
- Functions/Methods: `lower_case` (e.g., `my_function()`)
- Private Members: `m_lower_case` prefix (e.g., `m_name`)
- Constants: `UPPER_CASE` for macros, `lower_case` for const variables
- Template Parameters: `CamelCase` (e.g., `typename T`)

**Imports & Headers:**
1. Standard library first: `<algorithm>`, `<string>`, etc.
2. Library headers next: `<fmt/core.h>`
3. Project headers last: `"template-cpp-project/..."`
4. Separate groups with blank lines (enforced by clang-format)

**Type Safety:**
- Use `auto` with explicit casts when needed
- Prefer `std::string` over raw char arrays
- Use `const` liberally (enforced by clang-tidy)
- Trailing return types preferred: `auto func() -> int`

**Error Handling:**
- Exceptions encouraged (C++ standard exceptions)
- Constructor failures via exceptions
- No void returns for error conditions; use exceptions or optional
- clang-tidy enforces Modern C++ practices (C++17+)

**Code Quality:**
- Enable `template-cpp-project_DEVELOPER_MODE` for development
- All code must pass clang-tidy checks (`.clang-tidy` config enforced)
- Use `catch_discover_tests()` for new test files (Catch2 framework)
- Private members use `m_` prefix; protected members also use `m_` prefix

## Build System Details

- **CMake 3.24+** required (managed by pixi)
- **Presets:** Use `CMakeUserPresets.json` for local dev config (Git-ignored)
- **Generator:** Ninja on Linux, MSVC on Windows
- **C++ Standard:** C++17 minimum
- **Package Manager:** pixi (Python-based, cross-platform)
- **Toolchains:** dpcpp (default dev), clang, gcc, MSVC (selectable via features)
- **Tests:** Catch2 framework; add test executables to `test/CMakeLists.txt`
- **Docs:** Doxygen + m.css; build with `-t docs` target
- **Dependencies:** fmt (formatting library), catch2 (testing)

## Development Workflow

1. Activate environment: `pixi shell -e dev`
2. Create `CMakeUserPresets.json` with `dev` preset inheriting `dev-mode` + platform preset
3. Run: `pixi run configure && pixi run build`
4. Edit code following style guidelines (run `format-fix` after)
5. Test: `ctest --preset=dev` or single test via `-R` filter
6. Lint: clang-tidy runs automatically; check via build output
7. Commit: ensure `format-check` passes (part of CI workflow)

## Building Conda Packages with pixi-build (Rattler-Build)

This project includes recipes for building conda packages using **rattler-build** and the **pixi-build-rattler-build** backend. This approach allows custom toolchains (like DPC++) that aren't available in conda-forge's default compiler packages.

### Available Recipes

The `recipe/` directory contains recipes for different toolchains:

| Recipe | Toolchain | Platform | Channel |
|--------|-----------|----------|---------|
| `recipe.yaml` | DPC++ (Intel SYCL) | Linux | conda-forge, nagagroup |
| `recipe-gcc.yaml` | GCC 13.3 | Linux | conda-forge |
| `recipe-clang.yaml` | Clang 18 | Linux, Windows | conda-forge |
| `recipe-mingw.yaml` | MinGW GCC | Windows | conda-forge |

### Building Packages

#### Install rattler-build

```bash
pixi global install rattler-build
```

#### Build with specific toolchain

```bash
# Build with DPC++ (Linux only, requires nagagroup channel)
rattler-build build recipe/recipe.yaml

# Build with GCC (Linux)
rattler-build build recipe/recipe-gcc.yaml

# Build with Clang (multi-platform)
rattler-build build recipe/recipe-clang.yaml

# Build with MinGW (Windows)
rattler-build build recipe/recipe-mingw.yaml
```

#### Output

Built packages are placed in `output/` directory as `.tar.bz2` conda packages.

### Recipe Features

All recipes include:
- **CMake configuration** with C++17 standard
- **Developer mode** enabled (`template-cpp-project_DEVELOPER_MODE=ON`)
- **Install targets** with proper RPATH handling
- **Test discovery** with Catch2 framework
- **Platform-specific handling** for Linux/Windows

### Why rattler-build?

The `pixi-build-rattler-build` backend is chosen because:

1. **Custom Toolchains**: Supports DPC++ and other non-standard compilers
2. **Flexibility**: Direct conda recipe control without abstraction
3. **Multi-Platform**: Single recipe format for Windows, Linux, macOS
4. **Mature**: rattler-build is production-ready, actively maintained

### Development vs. Packaging

- **Development**: Continue using `pixi shell -e dev` + CMake for fast iteration
- **Packaging**: Use rattler-build recipes for creating distributable conda packages
- **CI/CD**: Recipes can be integrated into CI pipelines for automated package builds

### Future Integration

As `pixi-build` matures and stabilizes the API, full integration into `pixi.toml` is planned:

```toml
# Future (when pixi-build API stabilizes):
[workspace]
preview = ["pixi-build"]

[package]
build = { backend = "pixi-build-rattler-build" }
```

For now, recipes remain standalone and can be built independently with `rattler-build`.
