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
- **NO-COLLISION constraint [ratified 2026-08-09 after a live
  regression]:** no published name may exist on conda-forge. The
  MECHANISM is the constraint, not the rule: a layered channel merges
  into ONE namespace, so with overlay-first channel priority any name
  we publish that also exists upstream WINS for every consumer of the
  channel — even at a LOWER version. (Incident: the teaching wrapper's
  published fmt 11.2.0 silently downgraded conda-forge's fmt 12.2.0
  for every naga-labs consumer the moment the channel flipped to
  overlay-first priority.) That is why this is absolute rather than a
  version-hygiene guideline. Enforced by `ci/check-publish-set.nu`
  (name-set + per-name conda-forge absence probe).
- No multi-line tasks / manifest scripting — nushell scripts.
- `[environments.default]` may be declared when it genuinely composes
  features; the antipattern is only a redundant declaration.
