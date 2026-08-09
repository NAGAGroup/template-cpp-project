# Standing doctrine-compliance check, two layers:
#
# 1. C-01/C-02: the publish NAME-SET is the surface where naming
#    violations appear first — variant axes must grow build strings,
#    never names. Names must match EXACTLY; drift fails. (Counts grow
#    with the variant matrix by design; names must not.)
#
# 2. NO-COLLISION constraint: no published name may exist on
#    conda-forge. MECHANISM: a layered channel merges into ONE
#    namespace, so with overlay-first channel priority any name we
#    publish that also exists upstream WINS for every consumer of the
#    channel — even at a LOWER version. (Live incident 2026-08-09: our
#    teaching wrapper's fmt 11.2.0 silently downgraded conda-forge's
#    fmt 12.2.0 for every naga-labs consumer the moment the channel
#    flipped priority.) The rule is therefore absolute, not a
#    version-hygiene guideline.
let expected = ["enginelib" "mathkit" "stb"]

let out = (pixi publish --dry-run --to ./ci-dry-channel | complete)
if $out.exit_code != 0 {
  print $out.stdout
  print $out.stderr
  error make { msg: "publish --dry-run failed" }
}
let actual = ($out.stdout ++ $out.stderr
  | lines
  | parse --regex '^\s+- (?<name>\S+) v\d'
  | get name | uniq | sort)

if $actual != ($expected | sort) {
  error make { msg: $"publish name-set drift: ($actual) != ($expected | sort). If a NEW name was added: names are forever on a channel — check the no-collision rule below before widening the expected set." }
}

# Layer 2: every published name must be ABSENT from conda-forge.
mut collisions = []
for name in $actual {
  let hit = (pixi search -c conda-forge $name | complete)
  if $hit.exit_code == 0 {
    $collisions = ($collisions | append $name)
  }
}
if ($collisions | is-not-empty) {
  error make { msg: $"COLLISION: ($collisions | str join ', ') exist(s) on conda-forge. Publishing a conda-forge name silently OVERRIDES upstream for every consumer of this channel under overlay-first priority — even at a lower version (this exact failure shipped once: our fmt 11.2.0 shadowed upstream 12.2.0). Rename the package or drop it from the publish set." }
}
print $"publish name-set OK: ($actual | str join ', ') — no conda-forge collisions"
