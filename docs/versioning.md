# Versioning

## Two manifest types, two version stories

- **Standalone-consumable packages** (mathkit, enginelib): root manifest =
  `[workspace]` + `[package]`; the version there is the anchor. Each has
  its **own tag series**: `mathkit-v0.1.0`, `enginelib-v0.1.0`. Tags
  exist for *external* consumers only — inside the monorepo, members
  consume each other by relative path, always at HEAD.
- **Internal-only packages** (demo-app, tests, variant subpackages):
  package-only manifests. Pixi requires a `version` field for external
  resolution, so variant subpackages carry one — **kept in sync with
  their root package** (the release checklist below owns that).

## Release flow (tag-then-re-pin)

1. Bump the package version in its root manifest **and every
   `variants/*/pixi.toml`** (grep for the old version).
2. Commit; tag `enginelib-vX.Y.Z`; push tag.
3. Consumers bump: `tag = "enginelib-vX.Y.Z"` → `pixi update enginelib`.

During development, external consumers pin `rev = "<sha>"` instead and
bump the sha — the pin bump *is* the integration step.

## Wrapper pins

Wrapper packages pin **upstream's** ref (fmt: upstream tag `11.2.0`;
stb: a commit sha, dated version `2026.8.6`). Bumping upstream = change
the pin, adjust the wrapper's `version`, `pixi update`.
