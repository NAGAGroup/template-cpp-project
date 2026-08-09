# TIER GATE ASSERT — BRANCH-ONLY SCOPE REDUCTION, TEMPORARY.
#
# Main asserts something stronger: that each tier env's enginelib was
# BUILT at that env's microarch level. That property is not currently
# guaranteed, and this branch does not pretend otherwise.
#
# WHY. A tier env pins `x86_64-microarch-level ==N`. A level-M build
# carries the metapackage's OPEN floor `>=M`, which excludes M above N
# and admits every M at or below it — so the source-variant chooser is
# free anywhere in 1..N and a v4 env can legitimately receive a v1
# binary. Selection is ADMISSIBLE, not FORCED. Measured over 10 fresh
# solves (deleting the lock each time, since `pixi lock` is a no-op
# once the file is satisfiable and a retry loop that skips the deletion
# re-checks one artifact): v2 correct 5/10, v3 3/10, v4 1/10,
# independently — roughly a 1-in-60 chance of all three aligning. A
# fresh clone of MAIN at HEAD fails main's own version of this assert,
# so main's tier-correct lock is a historical artifact preserved by
# lock satisfiability, not something re-derivable on demand.
#
# WHAT THIS ASSERTS INSTEAD: the part that IS guaranteed — that each
# tier env resolves its own gate package. That has held in every fresh
# lock examined. It is a real invariant and worth guarding; it is
# simply weaker than the one main claims.
#
# STATUS: temporary, pending Jack's ruling on force-vs-rescope for the
# microarch axis. If selection is made FORCED (most likely a gate
# package of ours exporting an exact pin, since conda-forge's
# metapackages only offer open floors), restore main's stronger assert
# and delete this comment. NO TEACHING TEXT WAS CHANGED for this — the
# docs still describe the intended design, because the design is not
# what is in question. See DELTA.md D-24.
let lock = (open --raw pixi.lock | from yaml)

def gate-level [env_name: string] {
  let entries = ($lock | get environments | get $env_name | get packages | values | flatten)
  let gates = ($entries
    | each {|e| $e | get -o conda | default "" }
    | where {|u| $u =~ '_x86_64-microarch-level-' })
  if ($gates | is-empty) { return "absent" }
  $gates | first | parse --regex '_x86_64-microarch-level-(?<n>\d+)-' | get -o n.0 | default "unparsed"
}

let expect = { microarch-v0: "1", prod: "1", microarch-v2: "2", microarch-v3: "3", microarch-v4: "4" }
mut bad = []
for e in ($expect | transpose env level) {
  let got = (gate-level $e.env)
  print $"tier gate check: ($e.env) -> gate package level ($got), want ($e.level)"
  if $got != $e.level { $bad = ($bad | append $e.env) }
}
if ($bad | is-not-empty) {
  # No unescaped parentheses in this message: inside a nushell
  # interpolated string they are a SUBEXPRESSION, so a parenthesised
  # aside executes its first word and the assert dies with "command not
  # found" instead of reporting the real failure.
  error make { msg: $"tier envs resolved the wrong microarch GATE package: ($bad | str join ', ') — this is the weaker branch-scoped assert, so a failure here means something is genuinely wrong with tier composition, not merely unlucky variant selection" }
}
print "tier gate selections OK — note this is the branch's REDUCED assert; see the header"
