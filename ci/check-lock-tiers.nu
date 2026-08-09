# Guard against pixi's nondeterministic SOURCE-variant selection: when
# several variants satisfy an env (microarch floors are open by design),
# fresh `pixi lock` runs pick arbitrarily. The committed lock is the
# deterministic artifact — assert its tier envs actually carry their own
# level, so a bad re-lock can never land silently. (Binary consumers of
# the published packages are unaffected; this guards the in-workspace
# source path only.)
#
# ⚠ MEASURED, 2026-08-09 — READ BEFORE YOU "JUST RE-RUN IT". A tier
# env pins `x86_64-microarch-level ==N`, and a level-M build carries
# the metapackage's OPEN floor `>=M`. That excludes M greater than N
# and admits every M at or below it, so the chooser is free within
# 1..N and the tier env can legitimately end up with a lower-level
# binary than its name promises. Over 10 fresh solves (the lock
# DELETED each time — note that `pixi lock` is a no-op once the file is
# satisfiable, so a retry loop that does not delete it re-checks one
# artifact and proves nothing): v2 landed correct 5/10, v3 3/10, v4
# 1/10, independently. All three aligning is a ~1-in-60 event, and a
# fresh clone of main at the same commit fails this assert too. So the
# committed tier-correct lock is a historical artifact preserved by
# lock satisfiability, NOT something re-derivable on demand.
#
# This assert therefore currently measures LUCK. Fixing it means making
# selection forced rather than admissible — an exact-pinned marker that
# only the matching build satisfies — which conda-forge's open-floor
# metapackages do not provide on their own. Until that lands, treat a
# red result here as "the microarch teaching is not currently true of
# this lock", not as "re-roll until green".
let lock = (open --raw pixi.lock | from yaml)

def enginelib-level [env_name: string] {
  let entries = ($lock | get environments | get $env_name | get packages | values | flatten)
  let srcs = ($entries
    | each {|e| $e | get -o conda_source }
    | compact
    | where {|s| $s =~ '^enginelib\[' })
  if ($srcs | is-empty) { return "absent" }
  let hash = ($srcs | first | parse --regex 'enginelib\[(?<h>\w+)\]' | get h.0)
  let pkg = ($lock | get packages
    | where {|p| ($p | get -o conda_source | default "") =~ $'^enginelib\[($hash)\]' }
    | first)
  $pkg | get variants | get -o x86_64_microarch_level | default "none"
}

let expect = { microarch-v0: "1", prod: "1", microarch-v2: "2", microarch-v3: "3", microarch-v4: "4" }
mut bad = []
for e in ($expect | transpose env level) {
  let got = (enginelib-level $e.env)
  print $"lock tier check: ($e.env) -> enginelib microarch level ($got), want ($e.level)"
  if $got != $e.level { $bad = ($bad | append $e.env) }
}
if ($bad | is-not-empty) {
  # NOTE — no UNESCAPED PARENTHESES in this message. Inside a nushell
  # interpolated string `(...)` is a SUBEXPRESSION, so a parenthesised
  # aside in prose gets executed: the first word becomes a command and
  # the assert dies with "command not found" instead of reporting the
  # real failure. (I first blamed backticks and "fixed" those; the
  # second CI run proved the parens were the culprit all along. Escape
  # them, or write the aside without them.)
  error make { msg: $"committed lock has wrong tier selection for: ($bad | str join ', ') — see the header of this file before re-running pixi lock: tier selection is admissible, not forced, so re-rolling is not a fix" }
}
print "lock tier selections OK"
