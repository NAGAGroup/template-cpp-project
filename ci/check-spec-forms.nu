# Spec-form guard (Jack's rule of record): hand-written specs use
# ">=x", ">=a.b,<a.c", or "==a.b.c" — never bare "*"... EXCEPT the one
# sanctioned use: a dep participating in the [workspace.build-variants]
# matrix is declared "*" (the variant-substitution placeholder, per
# pixi's own variants docs). This check distinguishes the two instead
# of a naive grep.
# spdlog leaves this list with its axis (D-23): with no variant to
# substitute, a bare "*" for it would be an unpinned dep, not a
# placeholder — exactly what this check exists to catch.
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
