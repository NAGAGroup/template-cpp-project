# DELTA.md — what the `acpp` branch changes, and why

This branch is a **delta on `main`, not a fork.** The layout, the shared
infrastructure, and the doctrine are `main`'s; a small, enumerated set of
things is deliberately different because this branch targets **one**
application type — SYCL via [AdaptiveCpp](https://github.com/AdaptiveCpp/AdaptiveCpp),
consumed as pixi packages from the `naga-labs` channel.

`git merge main` is expected to keep working, and the register below exists so
that a merge conflict is resolved on **evidence rather than instinct**. Every
row is a divergence someone merging `main` will be tempted to "restore".

**Cut point:** `0edb8b4` on `main` (CI green, 12/12, both platforms).

## How to use this file

1. **Every intentional divergence gets a row.** No row, no divergence — if you
   find the branch differing from `main` in a way not listed here, that is a
   drift bug, not a decision, and it should be fixed toward `main`.
2. **A merge conflict resolved in the branch's favour must cite a row ID.**
   If you cannot cite one, `main` wins.
3. **Rows record the WHY, not the diff.** Git already has the diff. What git
   cannot tell a future reader is that the deletion was deliberate and what
   evidence made it so.
4. Rows are append-only; a reversed decision gets its row struck through with
   the reason, never deleted.

## The two amendments that govern everything here

**AM-1 — one compiler toolchain, full stop.** The only compiler on this branch
is `acpp-clang*_<plat>`. No gcc lane, no non-acpp clang, no mingw, no
msvc-as-compiler, and none of their variant packages, environments, presets, or
`variants.yaml` keys. This is not a simplification for its own sake: the `acpp`
package constrains `clang <0.0a0` / `clangxx <0.0a0` / `llvm <0.0a0`, so a
non-acpp compiler cell and an acpp environment are **mutually unsolvable**.
Composition is only ever ACROSS environments, never within one. The nightly
lane stays — same compiler family, different lane. `acpp-clang-cl_win-64`
stays documentation-only: it is an alternative to our pair and constrains it out.

**AM-2 — this branch is deliberately SIMPLER than `main`.** `main` is complex
on purpose: it teaches a wide range of C++ applications and their project
requirements, including testing across compilers. This branch serves one
application type. **Breadth is not inherited just because `main` has it.**
When in doubt, prefer the simpler shape and record the choice under
"Simplifications" below. `main`'s bias-to-inclusion is a property of `main` as
a tutorial surface; it is not a property of this branch.

## Divergence register

Status: `PLANNED` (agreed, not yet landed) → `LANDED` (with commit) →
`REVERSED` (struck, with reason).

| ID | Status | Divergence | Why | On merge from `main` |
|---|---|---|---|---|
| D-01 | **LANDED** | Workspace `channels` becomes the single `naga-labs` channel | The toolchain lives there, and the channel **layers conda-forge** server-side (`info.channel_relations.base = "../../conda-forge"`), so one entry still reaches upstream. Single-channel is a constitutional invariant here, not a convenience. | Keep the branch's channel list. 
| D-02 | **LANDED** | The explicit `c_stdlib` / `c_stdlib_version` pair becomes **load-bearing**, with a CI content assert on the built package | pixi's stdlib derivation is channel-gated (`stdlib_variants.rs` matches the final URL segment against `conda-forge`), so nothing derives the floor here. The explicit pair still works — the backend gates on key *presence*, provenance-agnostic — but it is now the only thing producing `__glibc >=2.28`. Verified empirically at the cut: with the pair, `info/index.json` `depends` carries `__glibc >=2.28,<3.0.a0`; without it, no `__glibc` at all. | Keep. Never delete the pair as "redundant with conda-forge defaults" — there are none. 
| D-03 | **LANDED** | `m2w64_c_stdlib` / `m2w64_c_stdlib_version` keys deleted | Never consulted by the backend (`stdlib_for_language()` maps everything to `c`), and D-06 removes the lane that motivated keeping them. | Do not restore. 
| D-04 | PLANNED | `cxx_compiler` becomes the acpp pair; nightly is a stem swap | AM-1. `pixi-build-cmake` implements `compiler('cxx')` natively as bare stem + `_<target_platform>`; a package never names an activation package. `cxx_compiler_version` is never set — the acpp activation packages ship no version-suffixed names, so a version key renders an unsatisfiable spec. | Keep the branch's compiler axis entirely. |
| D-05 | **LANDED** | clang cells, variant packages, envs and presets deleted | AM-1; and `acpp` constrains non-acpp `clang`/`clangxx`/`llvm` out of any environment it is in. | Do not restore. Stays on `main`. |
| D-06 | **LANDED** | mingw lane deleted: cells, the three `-mingw` source wrappers, the `m2w64_*` variant block and its zip pair | mingw + SYCL is incoherent: every win acpp package requires `vc14_runtime`/`ucrt`, the toolchain is clang-cl-built targeting `x86_64-pc-windows-msvc` with MSVC-mangled import libs, and there is no mingw AdaptiveCpp build. | Do not restore. The mingw teaching — the strongest pixi argument in the template — **stays on `main`**, which is where it belongs. |
| D-07 | **LANDED** | `clang-win` presets (×3) and `cmake/toolchains/linux-clang.cmake` deleted | Fall out of D-05/D-06. | Do not restore. |
| D-08 | PLANNED | The vs2026 pin is promoted from **preference to hard requirement** | Published `acpp-runtime` win metadata requires `vc >=14.5,<15`, `vc14_runtime >=14.51.36247`, `ucrt`; a vs2022-line environment cannot install the toolchain at all. Our activation packages deliberately declare no `vs20XX` dep, so the ENV must supply the MSVC headers/libs/SDK. | Keep the branch's pin. On `main` it is a choice; here it is a constraint. |
| D-09 | PLANNED | `mathkit` → `mathkit-acpp`: header-only **device-callable** kernel helpers; its config must `find_dependency(AdaptiveCpp)` | Consumers compile the kernels, so their build environment needs acpp. The name is C-02-licensed: it is a contract that reaches the consumer's own toolchain. | Keep. |
| D-10 | PLANNED | `enginelib` → `enginelib-acpp`: compiled library owning a `sycl::queue`; `acpp >=25.10.0,<25.11` in **host** deps, nothing acpp in run-deps | The SYCL headers and the AdaptiveCpp CMake config live in `acpp` (host). The runtime reaches consumers through the activation packages' strong run-exports — declaring it in run-deps would duplicate that. | Keep. Do not "fix" the missing acpp run-dep. |
| D-11 | PLANNED | `demo-app` gains device discovery | The application-shaped example for this branch is "find the device, run a step". | Keep. |
| D-12 | PLANNED | stdpar arrives as a **conda activation package** (`ACPP_STDPAR=1` via `activate.d`), not a CMake option | Upstream requires stdpar be enabled for ALL translation units; CMake `INTERFACE` options provably cannot satisfy that — they only reach targets that link the library. This is the microarch pattern generalised: environment-level flavouring for a semantic knob. | Keep. |
| D-13 | PLANNED | Per-target `strictfp` that **counters** acpp's injected `-ffp-contract=fast` | `bin/acpp` injects `-ffp-contract=fast` itself at opt>1, so an absent flag is NOT neutral — a numerics-sensitive target must actively counter it on the compile line. Fast-math stays banned at workspace/env/variant/activation/preset level; numerics is never an environment-level knob. | Keep. |
| D-14 | PLANNED | Publish set becomes `["enginelib-acpp" "mathkit-acpp" "stb"]`, **`--dry-run` only** | Suffixed names because a SYCL/acpp-regime contract is exactly what C-02 licenses a name for. Dry-run because nothing goes public without Jack, and because the channel stays clean while the branch churns. | Keep. Flipping to a real upload is Jack's decision, not a merge's. |
| D-15 | PLANNED | New CI `gpu` job on the `Linux-x64-GPU` runner | `nvidia-smi` → `acpp-info -l` → CPU+CUDA smoke through a real solve. A SYCL template that never touches a device proves nothing. | Keep. |
| D-16 | PLANNED | New CI `canary` job (binary deps only, no lock, daily) | The branch consumes a live channel; a fresh-solve monitor is how channel breakage surfaces before a user finds it. Release leg red, nightly leg warn-only. | Keep. |
| D-17 | PLANNED | New assert scripts: `-march` ordering, fp-contract over `compile_commands.json`, run-export chaining, typo'd-stem guard, bare-activation-dep assert | Each encodes a hazard that is silent by construction: a typo'd compiler stem falls back to the system compiler and still builds; acpp's activation assigns `-march=nocona` and microarch's activation must sort after it; run-export chaining for source-package run deps changed in pixi (#6587) and must never be assumed. | Keep. |
| D-18 | PLANNED | The deletable template docs — `toolchains`, `variants`, `publishing`, `external-deps`, `design-record` — rewritten for the branch | The docs teach the tree they ship with. | Merge carefully — prefer `main`'s wording for anything not on this list. |
| D-21 | **LANDED** | CI runs on pushes to `acpp`, not only `main` | A long-lived divergent branch that CI ignores rots silently: the lock drifts, asserts written for the branch never run, and the first signal is a merge going wrong months later. The publish job runs here too, but its upload step is gated to `main` — build-and-assert on the branch, nothing on the channel (D-14). | Keep both branches in the trigger list. |
| D-20 | **LANDED** | The spdlog build-variant axis moves from `1.14`/`1.15` to `1.15`/`1.16`; feature and env rename `spdlog14` → `spdlog16` | **Forced by D-01, and it is the first real cost of the single-channel constitution.** Our own `fmt` wrapper is published to `naga-labs` at 11.2.0; under strict channel priority a name found in the highest-priority channel is resolved ONLY from that channel, so *no* other fmt version is reachable. spdlog 1.14 requires `fmt <11` and became unsolvable. The documented per-dependency `channel` escape hatch does **not** rescue this: pixi rejects an override naming a channel absent from the workspace `channels` list, and adding one is exactly what the invariant forbids (both the bare name and the layer-base URL were tried, both rejected). The axis teaches "a build-variant over a dependency version"; which two versions is arbitrary, so the pin moved rather than the doctrine. | Keep. Do NOT restore 1.14 — it does not solve here. |
| D-19 | PLANNED | `nightly` environment as a named opt-in, both platforms | Same compiler family, different lane; R7 closed as VALIDATED (9/9 release↔nightly twins on both platforms). Two known non-blocking gaps: the win nightly lane has one published date so far, and `acpp-lldb` is absent from both win lanes (upstream `LLVM_ENABLE_PROJECTS` gap, symmetric across lanes). | Keep. |

## Simplifications (AM-2 record)

Recorded so that a future reader can tell "we chose not to" from "we forgot".

- **The whole compiler axis collapses to one family.** `main` teaches
  cross-compiler testing because that is a real requirement for a wide range of
  C++ projects. Here it is not merely unnecessary, it is unsolvable (AM-1).
- **The mingw regime-closure teaching does not come along.** It is `main`'s
  best material and this branch would have to fabricate a reason to keep it.
- **`fmt` and `stb` wrappers stay, rethemed** rather than expanded: the escape-hatch
  decision tree is still worth teaching, and rethemed examples cost nothing.
- **Coverage gets simpler, not by choice but by luck:** `llvm-cov`,
  `llvm-profdata` and `llvm-profgen` ship inside the `acpp` package, so
  coverage needs no extra dependency and carries no version-skew risk.

## Things that are NOT divergences

Called out because they look like they should be:

- **The microarch axis and all its tiers stay.** They are orthogonal to the
  compiler and just as meaningful under acpp. (Verify the `-march` ordering
  empirically — acpp's activation assigns `-march=nocona` and microarch's
  activation appends; a reorder silently downgrades every binary. D-17.)
- **The `spdlog` version-matrix variant stays** as the dependency-version axis
  carrier.
- **`test-lowest` stays**, and is fully meaningful: it probes what the template
  *declares*. Dependencies floored by a consumed source package's host solve are
  a build-time fact and belong to the variant matrix instead — correct design,
  not a coverage gap.
- **The run-export doctrine, the preset-variant architecture, the
  one-workspace-manifest rule, and "tests are consumer projects"** are all
  inherited verbatim.
