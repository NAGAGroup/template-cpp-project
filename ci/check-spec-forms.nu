# Spec-form guard (Jack's rule of record): hand-written specs use
# ">=x", ">=a.b,<a.c", or "==a.b.c" — never bare "*"... EXCEPT the one
# sanctioned use: a dep participating in the [workspace.build-variants]
# matrix is declared "*" (the variant-substitution placeholder, per
# pixi's own variants docs). This check distinguishes the two instead
# of a naive grep.
#
# ⚠ THE ALLOW-LIST IS MICROARCH-ONLY, AND THAT IS NOT AN OVERSIGHT.
# A name belongs here ONLY while it has a live axis in
# [workspace.build-variants]. spdlog left this list together with
# its axis (D-23), because the moment there is no variant to
# substitute, a bare "*" stops being a placeholder and becomes an
# UNPINNED DEPENDENCY — the exact thing this check exists to catch.
#
# This is not hypothetical: removing spdlog from the list
# immediately caught FIVE manifests still carrying `spdlog = "*"`,
# in the same hour the axis was removed. If you are about to widen
# this list to make a failure go away, you are almost certainly
# looking at that failure — pin the spec instead, or add the name
# to the variant matrix and mean it.
let allowed_placeholder_keys = ["x86_64-microarch-level"]

let manifests = (glob **/pixi.toml | where {|p| $p !~ 'scratch|\.pixi' })
mut bad = []
for m in $manifests {
  let hits = (open --raw $m | lines | enumerate
    | where {|l| $l.item =~ '=\s*"\*"' })
  for h in $hits {
    let key = ($h.item | parse --regex '^\s*"?(?<k>[A-Za-z0-9_-]+)"?\s*=' | get -o k.0 | default "?")
    if not ($key in $allowed_placeholder_keys) {
      $bad = ($bad | append $"($m):($h.index + 1): ($h.item | str trim)")
    }
  }
}
if ($bad | is-not-empty) {
  print ($bad | str join "\n")
  error make { msg: "bare \"*\" specs outside the variant-placeholder carve-out — pin them (>=a.b,<a.c) or add the key to the build-variant matrix" }
}
print $"spec-form check OK: only variant placeholders use \"*\" (($allowed_placeholder_keys | str join ', '))"
