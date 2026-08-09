# Design record: ratified constraints

This page is the template's constitutional record. The constraints below
are carried VERBATIM (where quoted) from the ratified design spec
(TEMPLATE-FULL-SPEC.md, Jack Myers, 2026-08). Any amendment must cite
the IDs it touches. Mechanically-checkable constraints are CI-asserted
(`ci/check-publish-set.nu`, `ci/check-lock-tiers.nu`,
`ci/check-spec-forms.nu`, `ci/check-ci-shape.nu`).

- **C-01** No microarch variant naming. (Origin of the constraints
  doctrine: spoken, never written, once violated by `enginelib-v1/v3/v4`.)
- **C-02** BUILD variants (same name, build strings) = any axis, even
  mutually-incompatible builds, where each build's compatibility is FULLY
  ENCODED in dep metadata so the solver enforces coherence and a bare
  spec is always safe. PACKAGE variants (named) = the compatibility
  contract extends beyond env metadata to the CONSUMER'S OWN TOOLCHAIN
  (stdlib/compiler regime), or version ordering makes a bare spec
  unsafe, or a distinct support contract/source. The REASONING is the
  constraint.
- **C-03** "We shouldn't need a platform for clang — clang vs default
  platform compiler should be package variants."
- **C-04** "Build variants should all be consolidated into default
  platforms (linux-64, win-64) so that `pixi publish -p <plat>`
  automatically builds all build variants."
- **C-05** "We can still have platform differentiators, but we should
  use them as intended (pixi docs), not ad hoc workarounds."
- **C-06** "Use variants as intended — different envs with different
  package versions that force resolution to the right variant."
- **C-07** "Use features as intended, shared among environments where it
  makes sense."
- **C-08** "Platforms are for making things FAIL, not succeed, on the
  machine's hardware." Capability gates only, never selection routers.
  Conda spec supports core platforms only — rich platform names never
  touch the channel.
- **C-09 [AMENDED 2026-08-08 PM]** Features — not envs, not deps — carry
  solve strategy; composition overrides the default. Direction (Jack):
  keep pixi's global default (highest); a `solve-lowest` feature
  carrying `solve-strategy = "lowest-direct"` composes into the
  min-version test env. (Supersedes the earlier default-lowest
  formulation.) *Implemented and verified working on 0.76.1, including
  in source-package envs — see the semantics notes in
  [features-and-environments.md](features-and-environments.md).*
- **C-10** Build matrix is UNBOUNDED; TEST matrix is RUNNER-BOUNDED.
  Never assert archspec on an incapable runner to un-skip a tier test.
- **[CLARIFIED 2026-08-09, then AMENDED same day by Jack — cites C-02,
  C-03]** The clang-win cell keeps the `*-clang` NAMED-variant shape
  (one name, both platforms, platform-realized). The name is grounded
  TWO ways: **C-03** (compiler choice = knowingly-chosen
  configuration, like asan/static) AND partly in regime difference —
  the original "grounded in C-03, NOT in ABI-regime distinctness"
  phrasing is retracted. clang-cl's shared VC runtime with vs2026
  NARROWS the regime gap; it does not close it: compilers are known to
  produce ABI-incompatible binaries even on the same stdlib (mangling
  corner cases, unwind/EH table differences, layout edge cases,
  cross-TU inline/ODR divergence), so **shared VC runtime ≠ safe
  object mixing** — the REASONING is the constraint, and a record that
  taught runtime-sharing as mixing-safety would be actively harmful.
  **C-02's bare-spec-safety naming test governs CHANNEL-FACING names
  only** and is not engaged — preset variants are dev-only, never
  published (publish name-set: [enginelib mathkit stb]). If a clang
  variant is ever published, the C-02 test re-engages and this mapping
  must be revisited.
- **Spec forms:** dependency SPECS take real bounds (`">=4.4,<4.5"`);
  variant VALUES are BARE and EXACT (`"4.4"`). No `X.*` anywhere.
  Prefer `pixi add`; if by hand: `">=<v>"`, `">=<maj.min>,<<maj.min+1>"`,
  `"==<maj.min.patch>"`. CARVE-OUT: `"*"` is REQUIRED for
  variant-substitution placeholders; CI checks must distinguish, not
  naive-grep. Build backends are EXACT-pinned (they version
  independently and ARE the behavior surface).
- No multi-line tasks / manifest scripting — nushell scripts.
- `[environments.default]` may be declared when it genuinely composes
  features; the antipattern is only a redundant declaration.
- **Win compiler-cell definition of done (chair requirement, both
  satisfied):** (1) CI's win mirror must actually COMPILE the clang-win
  and mingw cells — satisfied: the win variants/test jobs build
  enginelib-clang, enginelib-tests-clang, enginelib-mingw,
  enginelib-tests-mingw and both demo variants (proven live: these
  exact jobs caught the mingw regime-closure failures before going
  green). (2) There must be a STANDING assertion that the produced
  binaries came from the INTENDED compiler, because the failure mode
  is silent — a lost preset still builds green, just MSVC underneath.
  Satisfied by the REGIME GUARD: compiler-variant presets set
  `*_EXPECT_COMPILER_ID` and every CMakeLists fails configure on
  mismatch, converting the silent hazard into a hard failure on every
  build, local and CI. (The original CMAKE_ARGS-vs-preset hazard was
  separately resolved by evidence: the backend passes no compiler
  `-D`, and the win activation exports no CMAKE_ARGS — the guard
  exists so any future regression of either fact is loud.) The lock's
  regime markers are the complementary metadata evidence: enginelib-
  mingw carries `libstdcxx`/`libgcc`/`ucrt`, enginelib-clang (win)
  carries `vc14_runtime` — the two win regimes visibly distinct,
  asserted implicitly by every solved install.

## A check is worth nothing until it has been observed EXECUTING

Recorded as doctrine because it arrived three separate ways in one
night, each time disguised as a different problem, and each time the
underlying mistake was the same: **confirming that a check is CORRECT
is not confirming that it RUNS.**

1. **A new assert that never ran.** `ci/check-doc-refs.nu` was written,
   its pass and fail paths verified locally, and pushed — onto a branch
   the CI workflow did not trigger on, because the trigger list named
   only `main`. Three commits landed unvalidated. Written up
   afterwards as: *I was watching for the assert to be correct rather
   than for it to run.*
2. **Fail paths never exercised.** Three asserts shipped with failure
   paths that had never been executed. Two died on nushell string
   interpolation instead of reporting the real problem — a
   parenthesised aside inside an interpolated string is a
   SUBEXPRESSION, so the first word of the prose gets run as a command.
   The assert "passed" for months of green runs precisely because
   nothing ever made it fail.
3. **A check deferred to a platform nobody was running.** The win
   compile cell was assumed to be covered long before CI actually
   compiled it; when it did, it found real regime-closure failures
   immediately.

The general rule, and the one worth carrying to other repos:

> **Before trusting a check, observe it execute — and observe it FAIL.**
> A check that has only ever passed is indistinguishable from a check
> that never ran, and both are indistinguishable from a check that
> agrees with you.

The corollary applies to tools as much as to asserts: a command that
silently does nothing looks exactly like a command that confirms you.
`pixi lock` is a no-op once the lock is satisfiable, so a retry loop
that never deletes the lock re-checks one artifact forever; `pixi exec`
reuses cached environments, so repeated arms of an experiment stop
being independent trials. Look for the STATE CHANGE — did the file
change, did the hash roll — or force freshness, or prefer static
evidence like published metadata, which no cache can distort.
