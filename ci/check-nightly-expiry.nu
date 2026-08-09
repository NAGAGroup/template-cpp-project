# EXPIRY CHECK for a deliberately temporary state.
#
# This branch compiles on the acpp NIGHTLY lane, which is not the
# design — the ratified lane set makes the RELEASE lane the default.
# The substitution exists for one reason: the release activation
# package carries a strong run-export of
# `acpp-runtime >=25.10.0,<25.11`, and that lower bound matches nothing,
# because published versions look like `25.10.0_llvm20.1.8` and conda
# orders a trailing STRING component BELOW the shorter version. A
# run-export is baked into the artifact, so no manifest of ours can work
# around it: anything BUILT against the release lane fails in its host
# solve.
#
# A temporary state with three explanatory comments rots. One with an
# EXPIRY CHECK does not: this fails the moment the version scheme
# changes, telling us to go back to the release lane rather than
# shipping on nightly forever.
#
# WHY THIS READS REPODATA INSTEAD OF ASKING THE SOLVER: the obvious
# probe — "does `acpp-runtime >=25.10.0,<25.11` resolve yet?" — is
# CONFOUNDED. acpp-runtime constrains `__cuda >=12,<13`, so on a
# machine with a CUDA 13 driver it fails to resolve for a completely
# unrelated reason and the check would report "still broken" forever.
# It would also behave differently on a developer's GPU box than on a
# CI runner with no driver at all. Version strings are the actual thing
# we are waiting on, and reading them needs no solve, no environment
# and no virtual packages.
let url = "https://prefix.dev/jackm97/naga-labs/linux-64/repodata.json.zst"
let tmp = (mktemp -t --suffix .zst)

let dl = (^curl -s -f -L $url -o $tmp | complete)
if $dl.exit_code != 0 {
  rm -f $tmp
  print "could not fetch channel repodata — skipping the expiry check rather than failing CI on a network blip"
  exit 0
}

let raw = (^zstd -d -c $tmp | complete)
rm -f $tmp
if $raw.exit_code != 0 {
  print "could not decompress repodata — skipping the expiry check"
  exit 0
}

let repo = ($raw.stdout | from json)
let versions = (
  [($repo | get -o packages | default {}), ($repo | get -o "packages.conda" | default {})]
  | each {|group| $group | values }
  | flatten
  | where {|r| ($r | get -o name) == "acpp-runtime" }
  | each {|r| $r | get -o version | default "" }
  | uniq
)

if ($versions | is-empty) {
  print "no acpp-runtime records found in repodata — skipping"
  exit 0
}

# The defect is the lane string living in the VERSION. Any published
# version without an underscore has a different scheme — most likely
# the local-version form (`25.10.0+llvm20.1.8`), which sorts as build
# metadata and makes ordinary lower bounds work again.
let fixed = ($versions | where {|v| not ($v | str contains "_") })

if ($fixed | is-not-empty) {
  print $"acpp-runtime now publishes versions WITHOUT a lane suffix: ($fixed | str join ', ')"
  print ""
  print "The release lane's version scheme appears to be fixed, so this branch"
  print "should stop running on nightly. To retire the substitution:"
  print "  1. drop the -nightly infix from c_compiler / cxx_compiler in"
  print "     variants.yaml and from acpp-tools-nightly in the acpp-toolchain feature"
  print "  2. re-check DELTA.md D-04, which describes this as temporary"
  print "  3. delete this check"
  error make { msg: "nightly substitution has EXPIRED — see above" }
}

print $"nightly substitution still required: every published acpp-runtime version carries a lane suffix, e.g. ($versions | first)"
