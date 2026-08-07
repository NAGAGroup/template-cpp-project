# Tooling versions: leading edge, deliberately

This template pins **leading (not bleeding) edge tooling**: CMake ≥ 4.2
(including `cmake_minimum_required`), current gcc and clang/LLVM, C++23.

## Why

The conda ecosystem's superpower for C++ is that tooling stops being the
distro's decision. For years, "portable" C++ projects meant LTS-Ubuntu (or
worse, RHEL) toolchains: ancient CMake exactly when CMake was improving
fastest, compilers years behind the standard. Every tool here comes from
conda-forge, pinned in a lockfile, identical on every machine — so the
only reason left to use old tooling is *your consumers*, not your distro.

## The warning (read before adopting)

This choice is **nuclear and it may be wrong for you.** It assumes an
ideal world; we know the real one isn't. If your project should be
consumed by projects with long development histories — where migrating
toolchains or C++ standards is genuinely expensive — then adopting our
pins will lock out your primary userbase before your project even starts.
**Downgrade to your minimum viable versions.** Grep for `4.2`,
`cxx_std_23`, and the dep pins in `pixi.toml` files; lower them; done.

We *encourage* that divergence explicitly. The deal: downgrading is
endorsed, but issues reproducible only on downgraded tooling are outside
the support envelope.

Related opt-ins with the same flavor:

- The `v3`/`v4` microarch subpackages assume modern CPUs; the default
  packages stay portable (x86-64 baseline) so nothing breaks out of the
  box. (We'd have liked the default env pinned to v3 on linux; current
  pixi + conda-forge mechanics made portable-by-default the honest
  choice — see [build-variants.md](build-variants.md).)
- fmt/stb wrapper pins track recent upstream; bump or freeze per your
  needs ([versioning.md](versioning.md)).
