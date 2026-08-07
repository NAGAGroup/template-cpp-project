# Pixi field notes

Distilled notes from a full read of the pixi documentation (2026-08,
pixi 0.76.1) plus empirical findings from building this template. Kept in
the repo because understanding pixi deeply IS this template's subject
matter. Some items describe preview behavior that will change.

- lock_file: --frozen (install from lock, ignore manifest sync) vs --locked (fail if out of sync); PIXI_FROZEN/PIXI_LOCKED env vars; DOCTRINE: these are niche developer-side guards — CI/consumers should use default resolution semantics (virtual packages differ across hosts); satisfiability = envs+channels+packages matchspec-match lock (even timestamp/subdir); library-vs-app lock committing considerations; pixi-diff tooling.
- backends: "equal footing" — if()/target/plain deps ALL only shape the build env resolve, never the recipe → variant expansion works in conditional+target tables (my earlier misdiagnosis: selection-by-conflict was the failing part for microarch, NOT expansion). Generated recipe + variants.yaml debuggable at .pixi/build/work/<pkg>--<hash>/debug/ (rebuild with raw rattler-build). PIXI_BUILD_BACKEND_OVERRIDE(_ALL) for backend dev.
- manifest ref: TOML 1.1; requires-pixi (USE IT); exclude-newer (supply-chain); solve-strategy lowest/lowest-direct (min-version testing); [constraints]; channel-priority; rich platforms reference (friendly keys incl cuda={driver,arch}); [package] field inheritance {workspace=true}; [package.build] extras: flags/build-number/build-string-prefix/secrets; run-exports 5 buckets + publish semantics (self-export unversioned; path specs dropped in binaries; conditional if() subtables OK); extra-dependencies/extras; run-deps `when` field.
- specs: MatchSpec build/build-number/channel/sha256/license/file-name; repodata v3 extras+flags on deps (CEP42/44, flags match [package.build].flags — FUTURE variant selector); `when` conditional deps (matchspec incl __virtuals, all/any combinators); local .conda path deps.
- tasks: env-pinned depends-on ({task,environment,args}); default-environment; MiniJinja + pixi.* vars (is_win!); inputs/outputs caching; args w/ choices; multiline=; semantics + set -e; deno builtins cross-platform (cp/mv/rm/mkdir); _hidden tasks; task alias shorthand [{task=..}].
- envs: inline env content ([environments.X.dependencies/tasks/platforms...]); solve-groups; feature channels w/ priority; env-task shadowing; platforms intersection rule.
- platforms: wildcard target selectors [target."cuda-*".tasks] (workspace/feature only, NOT package); pixi workspace platform add --auto-detect; pixi info shows "Minimum platform"; archspec names validated vs bundled db (underscores); CONDA_OVERRIDE_* env vars incl CONDA_OVERRIDE_ARCHSPEC (CI lever!); win has NO default virtual floors.
- env internals: activation shell = bash/cmd; shell-hook; conda-meta/pixi metadata + lock hash; pixi clean [-e]; reflink dedup; PIXI_CACHE_DIR.
- setup-pixi v0.10.0: working-directory input (monorepo fix for our CI!), environments:, frozen/locked, cache-write, activate-environment, global-environments, custom shell wrapper, post-cleanup.
- publish/prefix.dev: trusted publishing OIDC (no secrets), --generate-attestation (sigstore); pixi upload; docker multi-stage shell-hook pattern; s3/gcs channels + rattler-index.
- inline package defs on source deps (no manifest needed upstream! alternative wrapper style); rattler-build backend: NO run-exports (use recipe), no binary deps in manifest, custom variant keys → env vars + jinja; incremental builds need OUT-of-root build dir; recipe search order; experimental flag.
- compilers: {lang}_compiler(_version) variants; win family target ok ([workspace.target.win.build-variants]); [package.build.target.<plat>.config] compilers per-platform.
- cross-compilation: pixi publish --target-platform; multi-output recipes; pin_subpackage; noarch stubs pattern.
