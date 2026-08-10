# PIN CHECK for the nightly cadence lane.
#
# This REPLACES ci/check-nightly-expiry.nu, and the reason it replaces
# it rather than extending it is worth stating, because the two checks
# answer opposite questions.
#
# The expiry check existed because the branch was on the nightly lane
# AGAINST ITS WILL. The release activation package carried a strong
# run-export of `acpp-runtime >=25.10.0,<25.11`, and that lower bound
# matched nothing: published versions looked like `25.10.0_llvm20.1.8`,
# and conda orders a trailing string component BELOW the shorter
# version, so every published build sorted under its own floor. A
# run-export is baked into the artifact, so no manifest of ours could
# work around it. The expiry check watched for that defect to be fixed
# and then told us to LEAVE.
#
# The defect IS fixed — the release lane now publishes a pure `25.10.0`
# with the LLVM major in the build string — and the branch has left:
# the base variants table is the release lane. But the nightly lane did
# not go away with the workaround. It came back as something the
# template deliberately TEACHES: a cadence axis, expressed as package
# variants on named platforms. So the question changed from "may we
# stop pinning nightly yet?" to "is the nightly pin we deliberately
# chose still honest?" — and that is what this file asserts.
#
# THREE ARMS. Each catches a failure the other two cannot see.
#
# THE ORDER IS DELIBERATE, and it was chosen after watching the wrong
# order behave badly: the STATIC arm runs first, before anything that
# needs the lock or the network. Editing a cadence table invalidates
# the lock, so a resolution-first ordering reported "could not read the
# resolved contents of env nightly" — true, useless, and three steps
# downstream of the actual mistake — instead of "you did not swap
# cxx_compiler". Cheapest and most precise first.

const NIGHTLY_DATE = "2026.08.10"
const NIGHTLY_ENV = "nightly"
const LLVM_MAJOR = "21"

# The set that must exist, COMPLETE, for the pin to be satisfiable.
# linux and win differ by one name each, and that asymmetry is upstream
# and known: `acpp-lldb-nightly` has no win build (an
# LLVM_ENABLE_PROJECTS gap, symmetric across lanes), and
# `acpp-clang-cl-nightly_win-64` has no linux counterpart by
# definition. Listing them per platform rather than asserting one
# universal set is what keeps this check from failing on a gap that is
# not ours.
const COMMON = [
  "acpp-nightly"
  "acpp-runtime-nightly"
  "acpp-tools-nightly"
  "acpp-llvm-dev-nightly"
  "acpp-compiler-rt-nightly"
  "acpp-runtime-cuda-nightly"
  "acpp-runtime-intel-nightly"
]

def channel-records [subdir: string] {
  let url = $"https://prefix.dev/jackm97/naga-labs/($subdir)/repodata.json.zst"
  let tmp = (mktemp -t --suffix .zst)
  let dl = (^curl -s -f -L $url -o $tmp | complete)
  if $dl.exit_code != 0 {
    rm -f $tmp
    return null
  }
  let raw = (^zstd -d -c $tmp | complete)
  rm -f $tmp
  if $raw.exit_code != 0 { return null }
  let repo = ($raw.stdout | from json)
  (
    [($repo | get -o packages | default {}), ($repo | get -o "packages.conda" | default {})]
    | each {|group| $group | values }
    | flatten
  )
}

# ---------------------------------------------------------------------
# ARM 1 — STEM SWAP, BY COUNT EQUALITY: does the cadence table override
# EVERY stem the base table names?
#
# THIS IS THE ONE THAT CATCHES A SILENT, GREEN FAILURE. Target
# build-variant tables MERGE with the base table rather than replacing
# it. So a stem key present in variants.yaml but absent from a cadence
# table does not error — the cadence cell quietly INHERITS THE RELEASE
# STEM. The result is a MIXED-LANE cell: it builds, it passes, and its
# canary signal is worthless, because part of it was compiled by the
# lane it was supposed to be testing against.
#
# It is asserted by COUNT EQUALITY against the base table's stem key
# set, deliberately, and never as a spot check for the stems we happen
# to have today. A spot check passes when someone adds a third stem key
# and updates only variants.yaml — which is exactly the mistake this
# guards, since that is the edit where the two files drift apart.
# ---------------------------------------------------------------------
print "ARM 1 — stem swap: does every cadence table override every base stem key?"

# Stem keys are the compiler-name keys: the ones whose values are
# toolchain package stems. Other variant keys (c_stdlib, cmake) are not
# lane-specific and must NOT be swapped.
const STEM_KEYS = ["c_compiler", "cxx_compiler"]

# `open` parses by extension, so no explicit `from yaml`/`from toml`.
let base = (open variants.yaml)
let base_stems = ($STEM_KEYS | where {|k| ($base | get -o $k) != null })

if ($base_stems | is-empty) {
  error make { msg: "variants.yaml declares no compiler stem keys at all — that cannot be right" }
}
print $"  base table declares ($base_stems | length) stem key\(s\): ($base_stems | str join ', ')"

let manifest = (open pixi.toml)
let targets = ($manifest | get -o workspace.target | default {})
let cadence_platforms = ($targets | columns | where {|c| $c =~ 'nightly' })

if ($cadence_platforms | is-empty) {
  error make { msg: "no cadence target tables found in pixi.toml — the nightly lane has no stem swap at all" }
}

for plat in $cadence_platforms {
  let tbl = ($targets | get $plat | get -o build-variants | default {})
  let swapped = ($base_stems | where {|k| ($tbl | get -o $k) != null })

  # COUNT EQUALITY — the assertion, stated as such.
  if ($swapped | length) != ($base_stems | length) {
    let missing = ($base_stems | where {|k| not ($k in $swapped) })
    print ""
    print $"  ($plat): swaps ($swapped | length) of ($base_stems | length) stem keys"
    print $"  NOT SWAPPED: ($missing | str join ', ')"
    print ""
    print "  A stem key that a cadence table does not override does NOT error."
    print "  It INHERITS THE RELEASE STEM, and the cell builds green as a"
    print "  MIXED-LANE build whose canary signal means nothing. Add the"
    print $"  missing key\(s\) to [workspace.target.($plat).build-variants]."
    error make { msg: $"cadence table ($plat) does not swap every stem key" }
  }

  # Count equality alone would be satisfied by a table that overrides
  # the right NUMBER of keys with release-lane values, so each value
  # must also actually carry the cadence suffix.
  for k in $base_stems {
    let vals = ($tbl | get $k)
    let bad = ($vals | where {|v| not ($v | str ends-with "-nightly") })
    if ($bad | is-not-empty) {
      error make { msg: $"($plat).($k) carries non-nightly stem\(s\): ($bad | str join ', ')" }
    }
  }
  print $"  ($plat): all ($swapped | length) stem key\(s\) swapped to nightly stems"
}

# ---------------------------------------------------------------------
# ARM 2 — REPODATA: is the pinned set still present and complete?
#
# WHY THIS READS REPODATA INSTEAD OF ASKING THE SOLVER. This rationale
# is inherited VERBATIM from the check this file replaces, because it
# is still exactly true and it is the kind of thing that gets
# "simplified" back into a bug: the obvious probe — just try to solve
# the pin — is CONFOUNDED. `acpp-runtime` constrains `__cuda >=12,<13`,
# so on a machine with a CUDA 13 driver it fails to resolve for a
# completely unrelated reason and the check would report a problem that
# does not exist. It would also behave differently on a developer's GPU
# box than on a CI runner with no driver at all. Package names and
# versions are the actual thing we are asserting on, and reading them
# needs no solve, no environment and no virtual packages.
#
# An exact pin turns channel retention into OUR problem: the moment a
# retention policy prunes the pinned date, the branch stops building
# with a solver error that names a version and explains nothing. This
# arm makes that failure legible in advance.
# ---------------------------------------------------------------------
print ""
print $"ARM 2 — repodata: is the ($NIGHTLY_DATE) nightly set still complete?"

mut arm1_failures = []
mut arm1_skipped = false

for spec in [
  { subdir: "linux-64", extra: ["acpp-clang-nightly_linux-64", "acpp-clangxx-nightly_linux-64", "acpp-lldb-nightly"] }
  { subdir: "win-64", extra: ["acpp-clang-nightly_win-64", "acpp-clangxx-nightly_win-64", "acpp-clang-cl-nightly_win-64"] }
] {
  let records = (channel-records $spec.subdir)
  if $records == null {
    print $"  ($spec.subdir): could not fetch repodata — skipping this platform rather than failing CI on a network blip"
    $arm1_skipped = true
    continue
  }
  let expected = ($COMMON | append $spec.extra)
  let present = (
    $records
    | where {|r| ($r | get -o version) == $NIGHTLY_DATE }
    | each {|r| $r | get -o name }
    | uniq
  )
  let missing = ($expected | where {|n| not ($n in $present) })
  if ($missing | is-not-empty) {
    $arm1_failures = ($arm1_failures | append $"($spec.subdir): MISSING ($missing | str join ', ')")
  } else {
    print $"  ($spec.subdir): all ($expected | length) pinned names present at ($NIGHTLY_DATE)"
  }
}

if ($arm1_failures | is-not-empty) {
  print ""
  print ($arm1_failures | str join "\n")
  print ""
  print $"The pinned nightly set ($NIGHTLY_DATE) is no longer complete on the channel."
  print "The pin cannot resolve. Either restore the set, or move the pin to a"
  print "complete newer date in BOTH places it appears:"
  print "  - [feature.acpp-toolchain-nightly.dependencies] in pixi.toml"
  print "  - NIGHTLY_DATE in this file"
  error make { msg: "pinned nightly set incomplete on the channel" }
}

# ---------------------------------------------------------------------
# ARM 3 — RESOLUTION: does the nightly env actually resolve to the pin?
#
# Arm 1 proves the artifacts EXIST. It cannot prove we get them. A
# manifest can pin a date and still resolve somewhere else entirely if
# a feature stops being composed into the env, if the env's platform
# list drifts off the cadence platforms, or if someone adds a second
# spec that narrows the result. This arm reads what the environment
# ACTUALLY RESOLVED, which is the only statement that survives all of
# those.
# ---------------------------------------------------------------------
print ""
print $"ARM 3 — resolution: does env `($NIGHTLY_ENV)` resolve to the pin?"

let listed = (^pixi list -e $NIGHTLY_ENV --json | complete)
if $listed.exit_code != 0 {
  print $listed.stderr
  error make { msg: $"could not read the resolved contents of env `($NIGHTLY_ENV)`" }
}

let pkgs = ($listed.stdout | from json)
let tools = ($pkgs | where {|p| ($p | get -o name) == "acpp-tools-nightly" })
if ($tools | is-empty) {
  error make { msg: $"env `($NIGHTLY_ENV)` does not contain acpp-tools-nightly at all — the cadence feature is not reaching it" }
}
let tools_version = ($tools | first | get -o version)
if $tools_version != $NIGHTLY_DATE {
  error make { msg: $"env `($NIGHTLY_ENV)` resolved acpp-tools-nightly ($tools_version), but the pin says ($NIGHTLY_DATE)" }
}
print $"  acpp-tools-nightly ($tools_version) — matches the pin"

let llvm = ($pkgs | where {|p| ($p | get -o name) == "acpp-llvm" })
if ($llvm | is-empty) {
  error make { msg: $"env `($NIGHTLY_ENV)` does not contain acpp-llvm — the lane mutex is not being applied" }
}
let llvm_version = ($llvm | first | get -o version)
if $llvm_version != $LLVM_MAJOR {
  error make { msg: $"env `($NIGHTLY_ENV)` resolved acpp-llvm ($llvm_version), but the pin says ($LLVM_MAJOR)" }
}
print $"  acpp-llvm ($llvm_version) — matches the pin"

# A RELEASE-lane package inside the nightly env would mean the two
# families are being mixed, which their own metadata is supposed to
# make impossible. If it ever happens, the exclusion has regressed
# upstream and we want to hear about it here rather than from a
# mysterious link error.
let leaked = (
  $pkgs
  | each {|p| $p | get -o name }
  | where {|n| $n in ["acpp" "acpp-runtime" "acpp-tools" "acpp-lldb" "acpp-llvm-dev" "acpp-compiler-rt"] }
)
if ($leaked | is-not-empty) {
  error make { msg: $"RELEASE-lane packages present in the nightly env: ($leaked | str join ', ') — the cadence families are mixing" }
}
print "  no release-lane packages in the nightly env — the families are separate"

print ""
if $arm1_skipped {
  print "nightly pin check OK (one or more repodata fetches were skipped — see above)"
} else {
  print $"nightly pin check OK: ($NIGHTLY_DATE) complete on both platforms, env resolves to it, every stem swapped"
}
