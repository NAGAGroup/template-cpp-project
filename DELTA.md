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
| D-04 | **LANDED** (nightly substitution — temporary) | `c_compiler`/`cxx_compiler` become the acpp pair; no `*_compiler_version` keys and no `zip_keys`; vs2026 demoted from compiler to build-environment SDK | AM-1. `pixi-build-cmake` implements `compiler('cxx')` as `<stem>_<target_platform>`, so ONE stem serves both platforms. **The stems carry a `-nightly` infix, which is NOT the design.** The ratified lane set makes release the default; nothing can currently be BUILT against it, because `acpp-clangxx_linux-64`'s strong run-export is `acpp-runtime >=25.10.0,<25.11` and that lower bound matches nothing — published versions look like `25.10.0_llvm20.1.8`, and conda orders a trailing string component BELOW the shorter version, so every build sorts under its own floor. A run-export is baked into the artifact, so no consumer manifest can override it. The nightly lane's run-export is EXACT (`acpp-runtime-nightly ==2026.8.9_llvm21.1.8`) and therefore immune. Verified end to end: the template locks, the prod env builds enginelib and mathkit from source, and `hash_input.json` records `cxx_compiler: acpp-clangxx-nightly` — so the toolchain really drove the compile rather than silently falling back to a host compiler. | Keep the acpp pair. **Drop the `-nightly` infix from both stems the day ACPP republishes the release lane** — that is the only part of this row that is temporary.  **TWO GAPS BLOCK IT, both found by CI in a clean environment after it passed locally — which is itself the lesson: a local build reuses caches a clean checkout does not have.** (1) LINUX SANITIZERS: linking dies on `cannot find lib/clang/21/lib/x86_64-conda-linux-gnu/libclang_rt.asan_static.a` — the acpp toolchain does not ship compiler-rt's sanitizer runtimes, so the asan/tsan variants cannot build. Plain builds are fine; this is specific to the sanitizer surface. Needs ACPP, or a ruling to drop sanitizers on the branch. (2) WINDOWS SDK: `lld-link: could not open 'kernel32.lib'` — the predicted D-08 gap, exactly as documented and not yet implemented: the activation packages declare no `vs20XX`, so every compiled package needs `vs2026_win-64` in its build-dependencies on win. That one is OURS and is mechanical.  **THE SPEC FORM, FOR WHEN IT UNBLOCKS — both halves matter.** A lower bound must carry the full lane string (`>=25.10.0` and `>=25.10` match nothing). And the obvious ceiling is ILLUSORY: `<25.11` and `<25.11.0` both ADMIT a future `25.11.0_llvmNN`, because the same trailing-string rule that sinks the floor also sinks the next release below the bound. `<25.11.0a0` — the conda pre-release idiom — actually holds. Verified by direct version comparison and in the solver. So: `acpp = ">=25.10.0_llvm20.1.8,<25.11.0a0"`. **This applies even after ACPP republishes**, unless they move to a local-version segment (`25.10.0+llvm20.1.8`), which would sort as build metadata and make the whole problem go away. Forward movement is preserved either way: an llvm bump and a patch bump both stay above the floor. |
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
| D-22 | **LANDED** | Windows falls through to the base `test-all` task; main's `[target.win-64.tasks.test-all]` is gone | AM-1 deleted the win-only gnu env that table existed for. An empty target table would be worse than none. Called out in the manifest because "the table disappeared" and "the tests stopped running" look identical from a green CI leg. | Take main's table only if a win-specific test env exists again. |
| D-23 | **LANDED** | The spdlog DEPENDENCY-VERSION build-variant axis is dropped entirely: the `[workspace.build-variants]` entry, the flavor feature, its env, the CI env-list entries, and the `"*"` placeholder carve-out in `ci/check-spec-forms.nu`. enginelib's spdlog spec becomes an ordinary pinned dep. | **A dependency-version axis is only safe where the axis does not cross an ABI boundary in the NESTED HOST SOLVE.** Each variant cell resolves its own deps in a nested solve that does not inherit the consuming env. On win-64 the two published spdlog builds for one cell straddled an fmt ABI: the cell resolved a spdlog built against fmt 12, so the library was compiled against `fmt::v12` while the consuming env supplied fmt 11.2 — `LNK1120` at LINK time, not a solve failure, and invisible on linux where both builds agreed on fmt. The obvious fix (pin the dependency's dependency so both cells share one ABI) was rejected on PACKAGE-BOUNDARY grounds: it means a package declaring a pin on something it does not use, purely to steer what its declared dependency drags in. AM-2 then decides the rest — the microarch axis still teaches build-variants, and the constraint is better teaching than the axis was. | Do not restore. If you want it back, first check what each cell resolves PER PLATFORM in its nested host solve. |
| D-24 | **LANDED** (temporary) | `ci/check-lock-tiers.nu` is re-scoped: it asserts each tier env resolves its own microarch GATE package, not that its enginelib was BUILT at that level. Main keeps the stronger assert. | **A temporary scope reduction, not a design change — and no teaching text was touched, because the design is not what is in question.** A tier env pins the metapackage at its level; a build made at a LOWER level carries only an OPEN floor, which such a pin still admits, so selection is ADMISSIBLE rather than FORCED and a v4 env can legitimately receive a v1 binary. Measured over 10 fresh solves, deleting the lock each time since `pixi lock` is a no-op once satisfiable: v2 correct 5/10, v3 3/10, v4 1/10, independently — about 1-in-60 jointly. A fresh clone of MAIN fails main's own assert, so its tier-correct lock is a historical artifact preserved by lock satisfiability rather than something re-derivable. The gate-package property, by contrast, has held in every fresh lock examined. | **Pending Jack's ruling on force-vs-rescope.** If selection is made forced — most likely a gate package of ours exporting an exact pin, since conda-forge's metapackages only offer open floors — restore main's assert and delete this row. |
| D-25 | **LANDED** | The `tooling` feature splits three ways: shared non-clang tools; `tooling-upstream-clang` (clang-format + clang-tools) for the cheap default env; `acpp-toolchain` (acpp-tools-nightly + the compiler activation) for the dev envs. | Forced by the toolchain, and each measurement changed the design, so the sequence is worth keeping: `acpp` constrains clang/clangxx/llvm out, so the upstream COMPILER cannot share an env with it (clang-format and clang-tools alone were fine against `acpp`); removing upstream `clang` then breaks clang-tidy with `'stddef.h' file not found`, because `clang` supplies the builtin-header resource dir; and `acpp-tools` in turn constrains `clang-format` out, so the two families cannot be mixed at all. Net: an env takes upstream's clang tools or the toolchain's, never both — which is the right shape anyway, since analysing with a different clang than you build with yields diagnostics that do not match your binaries. The dev envs also needed the compiler ACTIVATION named explicitly: they drive CMake directly rather than through the backend, and main got a compiler implicitly from the `clang` package AM-1 deletes. | Keep the split. The cheap default env must stay upstream-only and source-package free; that property was the whole reason to measure rather than assume.  **The measurements below are settled and should not be re-derived** — they answer the toolchain question that was outstanding with ACPP, and they hold regardless of when D-04 lands. Only the manifest changes were reverted, and solely because they were bundled with D-04. |
| D-26 | **LANDED** (capability gap — restore when available) | The asan and tsan variant packages, features, envs, presets and CI entries are deleted. Coverage stays. | **NOT an AM-2 simplification and must not be read as one — the capability does not exist in this toolchain.** AdaptiveCpp ships no compiler-rt sanitizer runtimes: its clang resource dir holds `clang_rt.crtbegin.o`, `clang_rt.crtend.o`, `libclang_rt.builtins.a` and `libclang_rt.ctx_profile.a` and nothing else, so linking dies on `cannot find lib/clang/21/lib/x86_64-conda-linux-gnu/libclang_rt.asan_static.a`. **Plain builds are unaffected** — `builtins` is present, which is exactly why only the sanitizer surface fails. conda-forge cannot patch it either: a matching-major `compiler-rt` does not coexist with acpp, and a mismatched one populates the wrong `lib/clang/<N>`. Depends on **ACPP item (B)**. ⚠ **FLAGGED FOR JACK:** this touches his sanitizers-CPU-only ruling (#4). Deleting something physically unavailable is not overriding him, but he should see it named rather than discover it as an absence. | **RESTORE when ACPP ships compiler-rt sanitizer runtimes.** Same obligation shape as D-23's re-measure: this is a gap being recorded, not a decision being made. |
| D-27 | **LANDED** | `ci/check-nightly-expiry.nu` — an expiry check for the D-04 nightly substitution, wired into the variants job. | A temporary state with three explanatory comments rots; one with an expiry check does not. It fails the moment the release lane's version scheme changes, telling us to go back rather than shipping on nightly forever. **It reads repodata rather than asking the solver, deliberately:** the obvious probe ("does `acpp-runtime >=25.10.0,<25.11` resolve yet?") is CONFOUNDED by the `__cuda >=12,<13` constraint — on a CUDA-13 developer box it fails for an unrelated reason and would report "still broken" forever, while behaving differently on a driverless CI runner. Version strings are the thing we are actually waiting on and need no solve. Both paths exercised before shipping. | Delete this check together with the substitution. |
| D-28 | **LANDED** (toolchain gap workaround) | The static variant declares `binutils_linux-64` as a linux build-dependency. | AdaptiveCpp's activation exports the conda-forge archiver names but the toolchain does not SHIP them: an installed acpp env contains no archiver at all, so a static archive dies with exit 127 and `x86_64-conda-linux-gnu-ar: not found`. Shared libraries are unaffected — they go through the compiler driver — which is why only the static flavor failed. Declaring an archiver is a legitimate BUILD TOOL declaration, not a package reaching into its dependency's business. Third toolchain gap of the night, reported to ACPP alongside the run-export and the missing sanitizer runtimes. | Delete when the activation stops exporting names it does not provide, or the toolchain ships them. |
| D-21 | **LANDED** | CI runs on pushes to `acpp`, not only `main` | A long-lived divergent branch that CI ignores rots silently: the lock drifts, asserts written for the branch never run, and the first signal is a merge going wrong months later. The publish job runs here too, but its upload step is gated to `main` — build-and-assert on the branch, nothing on the channel (D-14). | Keep both branches in the trigger list. |
| D-20 | ~~REVERSED~~ | ~~The spdlog axis moves from `1.14`/`1.15` to `1.15`/`1.16`~~ | Superseded by **D-23**, which drops the axis outright. Kept struck rather than deleted because its history is the useful part: the row's FIRST justification ("our published `fmt` claims the name, so no other version is reachable") was **false** and was retracted after the chair falsified it — a direct `fmt <11` resolves to 10.2.1 through the layer. The corrected justification (fall-through applies to DIRECT specs but not to purely TRANSITIVE requirements) was sound, and is now recorded under D-23 where it belongs. | n/a — see D-23. |
| D-19 | PLANNED | `nightly` environment as a named opt-in, both platforms | Same compiler family, different lane; R7 closed as VALIDATED (9/9 release↔nightly twins on both platforms). Two known non-blocking gaps: the win nightly lane has one published date so far, and `acpp-lldb` is absent from both win lanes (upstream `LLVM_ENABLE_PROJECTS` gap, symmetric across lanes). | Keep. |

## Merging `main` into this branch

The DoD direction is `main` into `acpp`. Probed at `c36ef7b` against
`main@b9f305d`: **two conflicts** — the `toolchains` doc and
`variants.yaml` — both squarely covered by D-02 and D-18, and — the
part that matters — **none of the AM-1 deletions came back**. No clang
or mingw file, no `check-regime-markers.nu`, no `linux-clang.cmake`.
That holds while `main` does not modify a path this branch deleted; the
day it does, git will ask, and the answer is the D-05/D-06/D-07 rows.

Note that a pull request from `acpp` to `main` tests the OPPOSITE merge
— merging this branch into main would delete main's clang and mingw
lanes. A result there, green or red, says nothing about the merge we
actually intend to perform. Re-run the probe instead.

## Simplifications (AM-2 record)

Recorded so that a future reader can tell "we chose not to" from "we forgot".

- **The dependency-version build-variant axis does not come along** (D-23), and the reason generalises past this repo: such an axis is only safe where it does not cross an ABI boundary in the nested host solve, which is not visible from the manifest and shows up as a LINK error on one platform. A second sentence earned the same night and worth keeping next to it: **an environment listing shows the RUNTIME closure — the nested host solve is where a build-time disagreement lives.** Reading the env view makes a build-time ABI problem look impossible.
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
