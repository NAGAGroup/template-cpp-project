# Assert the CI workflow's own shape (§8 rules that are mechanically
# checkable):
# 1. setup-pixi TRAP: the action defaults to --locked when a lock file
#    exists — every setup-pixi step that INSTALLS (has `environments:`)
#    must set `locked: false` explicitly (CI uses pixi's DEFAULT
#    resolution semantics; virtual packages differ across hosts).
# 2. `--frozen` / `--locked` are BANNED in CI run commands.
# 3. `CONDA_OVERRIDE_*` never appears (install-time mocking is never
#    test evidence).
let ci = (open --raw .github/workflows/ci.yml)

# --- rule 1: each setup-pixi `with:` block with environments: carries locked: false
let blocks = ($ci | split row "uses: prefix-dev/setup-pixi" | skip 1)
mut bad_blocks = 0
for b in $blocks {
  # the `with:` block ends at the first `- name:` / `- uses:` after it
  let block = ($b | split row "- name:" | first)
  if ($block | str contains "environments:") and (not ($block | str contains "locked: false")) {
    print "setup-pixi block installs environments without `locked: false`:"
    print ($block | str substring 0..300)
    $bad_blocks = $bad_blocks + 1
  }
}
if $bad_blocks != 0 {
  error make { msg: $"($bad_blocks) setup-pixi block\(s\) missing explicit locked: false (the action defaults to --locked)" }
}

# --- rules 2+3: banned strings in the workflow
for banned in ["--frozen" "--locked" "CONDA_OVERRIDE_"] {
  let hits = ($ci | lines | enumerate | where {|l| ($l.item | str contains $banned) and (not ($l.item | str trim | str starts-with "#")) })
  if ($hits | is-not-empty) {
    for h in $hits { print $"line ($h.index + 1): ($h.item | str trim)" }
    error make { msg: $"banned string ($banned) appears in ci.yml outside comments" }
  }
}

print "CI shape OK: locked: false explicit on installing setup-pixi steps; no --frozen/--locked/CONDA_OVERRIDE_ in commands"
