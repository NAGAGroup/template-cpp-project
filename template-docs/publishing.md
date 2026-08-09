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
| `external/fmt`, `external/stb` (the wrappers) | the `tests` packages — they exist to verify the install surface |
| | the preset variants (`*-static`, `*-clang`, `*-mingw`, …) — dev-only, consumed as source |

The wrappers *must* be in the set: **a publish must be self-contained**, so
every source dependency of a published package has to opt in too. Pixi fails
the publish rather than leaving a channel referencing packages that were
never uploaded. Wrappers are first-class publishable artifacts — including
`fmt`, whose name collides with conda-forge's on purpose; see footgun 1
for why that is a semantics lesson, not a hazard.

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

1. **Your package can shadow (or be shadowed by) an upstream one — learn
   the actual semantics before deciding whether that is a problem.**
   Channels are often layered — a private channel on top of conda-forge —
   and both directions of surprise are governed by two empirically
   verified rules (this repo's `fmt` wrapper, 11.2.0, on a channel that
   prefers custom packages over conda-forge):
   - *Channel priority is a PREFERENCE, not strict exclusion.* A bare
     `fmt` spec resolves the overlay's 11.2.0; a spec the overlay can't
     satisfy (`fmt >=12`) falls through to upstream and resolves 12.2.0.
     It does not fail.
   - *A preferred lower version CASCADES to dependents.* Preferring our
     fmt 11.2.0 selected spdlog 1.16.0 over 1.17.0, because newer
     spdlog builds pin newer fmt.
   - **⚠ *Fall-through applies to DIRECT specs only.* This is the rule
     the other two hide, and it is the one that bites.** A requirement
     that arrives TRANSITIVELY, for a name your channel provides, is
     *excluded* by strict channel priority rather than falling through
     — even when your candidate cannot satisfy it, which turns a
     preference into a hard solve failure. Measured on a one-package
     workspace, nothing else in it: `fmt <11` alone SOLVES (10.2.1, via
     fall-through); `spdlog >=1.14,<1.15` alone FAILS, because spdlog
     needs `fmt >=11.0.1,<11.1` transitively and the solver reports
     *"excluded because due to strict channel priority"*. Both together
     SOLVE (fmt 11.0.2) — promoting the requirement to a direct spec
     rescues it. The control matters: spdlog 1.14 plus a direct
     `fmt >=11.2`, which cannot admit what spdlog needs, still FAILS.
     So it is the *admission* that rescues the solve, not the presence
     of a direct spec.

   Is the shadow a bug? For the package a consumer deliberately takes,
   usually not: they are getting the COHERENT closure — your library
   was built against your fmt, so receiving your fmt is correct
   semantics, not contamination. ABI is not the issue either;
   activation packages make duplicates ABI-interchangeable.

   **But know the collateral effect, because it is not what the first
   two rules suggest.** Publishing a name does not merely *offer* your
   build — it makes every OTHER version of that name unreachable to
   *transitive* consumers on a single-channel workspace. Two escapes,
   and both have limits worth knowing before you publish:
   - The per-dependency channel override
     (`fmt = { version = "*", channel = "conda-forge" }`) works only
     for a channel **already in the workspace `channels` list**; pixi
     rejects an override naming one that is not, so a consumer honouring
     a single-channel doctrine cannot use it. Verified with both the
     bare name and the layer-base URL.
   - Promoting the requirement to a direct spec works — *except* inside
     a source package's nested host solve, which does not inherit
     environment specs. There the promotion has to live in the package
     manifest, which means a package pinning something it does not use
     to steer what its declared dependency drags in.

   This repo is its own existence proof: our published `fmt` broke our
   own spdlog-1.14 variant cell, and no source packages or run-export
   floors were involved — pure channel priority on a transitive edge.
   Know which outcome you're choosing; that is the whole rule.
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
