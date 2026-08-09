# Publishing packages

`pixi publish` walks the workspace, builds every package that opted in with
`publish = true` — in dependency order, across the whole variant matrix —
and uploads the results to a channel.

```sh
pixi publish --dry-run --to https://prefix.dev/<channel>   # see the set, build nothing
pixi publish --to ./local-channel                          # indexed local channel (great for testing)
pixi publish --to https://prefix.dev/<channel>             # the real thing (see footgun 6!)
```

Other destinations work the same way: `https://anaconda.org/<owner>`,
`s3://bucket/channel`, `quetz://…`, `artifactory://…`.

## What this template publishes

| Published | Not published |
|---|---|
| `mathkit`, `enginelib` (the libraries) | `demo-app` — a channel is for libraries other projects consume, not demo binaries |
| `external/stb` (wrapper: a source dep of published enginelib) | `external/fmt` — the NO-COLLISION rule (see footgun 1: fmt exists on conda-forge; publishing it shadows upstream) |
| | the `tests` packages — they exist to verify the install surface |
| | the preset variants (`*-static`, `*-clang`, `*-mingw`, …) — dev-only, consumed as source |

Wrapper membership follows from **self-containment**: every source
dependency of a published package must opt in too (pixi fails the
publish rather than leaving a channel referencing packages that were
never uploaded). stb is in because published enginelib depends on it;
fmt is out because only the unpublished demo-app consumes it — which
is exactly what lets the no-collision rule apply to it.

Note the dry-run output lists `enginelib` **eight times** — the full
build-variant matrix (4 microarch levels × 2 spdlog lineages) under ONE
name. The whole matrix publishes. Use `pixi publish --variant
spdlog=1.15` to publish one slice (handy for splitting CI across jobs).
The publish NAME-SET is the naming-doctrine compliance surface —
`ci/check-publish-set.nu` asserts it every run.

## Authentication

**In CI: trusted publishing (OIDC) — no stored secrets.** The channel is
configured to trust a specific repository *and workflow file*; the job then
requests a short-lived token at run time:

```yaml
permissions:
  contents: read
  id-token: write        # this is what makes OIDC work
steps:
  - run: pixi publish --to ./dist   # then upload, see footgun 6
```

Channel side (once): in the channel's settings, add a trusted publisher with
your org/user, repo name, and the workflow filename (optionally an
environment). Nothing is stored in the repo.

**Locally, or outside GitHub Actions:** log in once and pixi keeps the
credential in your OS keychain —

```sh
pixi auth login prefix.dev              # browser/device-code flow
pixi auth login prefix.dev --token …    # or an API key
```

or set `PREFIX_API_KEY` (`ANACONDA_API_KEY`, `CLOUDSMITH_API_KEY`, … for
other hosts). Prefer trusted publishing where it's available: a leaked
long-lived token is worth more to an attacker than anything else in your repo.

For supply-chain provenance, add `--generate-attestation` (prefix.dev):
consumers can then verify with `gh attestation verify` or `cosign`.

## Footguns worth knowing before you publish

Publishing puts your names into a namespace you share with everyone else on
that channel. None of these are hypothetical disasters — they're just things
to decide **deliberately** rather than discover later.

1. **Your package can shadow (or be shadowed by) an upstream one — and a
   channel-priority flip turns "can" into "does", retroactively.**
   Channels are often layered — a private channel on top of conda-forge.
   A layered channel merges into ONE namespace: with overlay-first
   priority, any name you publish that also exists upstream wins for
   EVERY consumer of the channel, even at a LOWER version. This repo
   lived it: a teaching wrapper published `fmt` 11.2.0, harmless under
   conda-forge-first ordering — then the channel flipped to
   overlay-first and every consumer silently downgraded from upstream's
   12.2.0. The safe rule is absolute, not version-hygiene: **never
   publish a name the upstream channel ships** (this repo's
   `ci/check-publish-set.nu` asserts it per name). ABI is not the
   issue — activation packages make duplicates ABI-interchangeable —
   the issue is version resolution across a merged namespace.
2. **Strong run-exports travel with what you build.** A compiler activation
   package that declares a strong run-export stamps that dependency onto
   *every* package built with it. Publish such a package and your consumers
   inherit that runtime too. Check what your artifacts actually require
   (`pixi list`, or read the built package's `depends`) before publishing.
3. **Re-publishing the same version is a no-op.** `pixi publish` skips
   packages that already exist at the target (`--no-skip-existing` to
   override). If your CI publishes on every push, a real change with an
   unchanged version silently doesn't ship. Bump versions deliberately —
   see [versioning.md](versioning.md).
4. **Published is published.** Yanking is not deletion, and someone may
   already depend on what you shipped. Decide up front whether a package is
   a product or an example.
5. **Names are the cheapest thing to get wrong.** If a repo publishes
   variants of the same idea (this template's `acpp` branch publishes
   SYCL-flavored siblings), suffix them rather than letting two different
   things fight over one name.
6. **`--to` mis-parses user-scoped channel URLs.** pixi (as of 0.76.1) takes
   only the *last* path segment of the `--to` URL as the channel name, so
   `--to https://prefix.dev/<user>/<channel>` uploads to `<channel>` — a
   channel that isn't yours — and fails with an opaque `HTTP 403: Not
   authorized` (your trusted-publishing setup is fine; the token went to the
   wrong door). Single-segment channels are unaffected. Workaround: build
   into a local channel first (`pixi publish --to ./dist`), then upload with
   `pixi upload prefix -c <user>/<channel> ./dist/**/*.conda`, which takes
   the channel name verbatim through the same backend (OIDC and
   `--generate-attestation` included). This is what this template's CI does.

Test the whole flow against `--to ./local-channel` first: it produces a real
indexed channel you can add to another workspace's `channels` and install
from, with no account, no upload, and no cleanup.
