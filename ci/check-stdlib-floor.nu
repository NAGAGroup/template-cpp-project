# STDLIB-FLOOR CONTENT ASSERT — the real guard behind the `c_stdlib`
# pin in variants.yaml.
#
# WHY THIS EXISTS. pixi's AUTOMATIC stdlib derivation is channel-gated:
# it fires only for the literal `conda-forge` channel. This workspace
# resolves through a single non-conda-forge channel, so nothing derives
# a glibc floor here — the explicit `c_stdlib` / `c_stdlib_version`
# pair is the ONLY thing producing one. That makes the pair
# load-bearing rather than redundant, and makes its silent removal
# catastrophic in a way no build failure would reveal: packages still
# build, still upload, and are installable on machines whose glibc is
# too old, failing at LOAD time in a user's environment.
#
# Verified empirically (2026-08-09, pixi 0.76.1, pixi-build-cmake
# 0.4.5, single naga-labs channel, one compiled TU): WITH the pair,
# `depends` carries `__glibc >=2.28,<3.0.a0`; with the keys removed,
# no `__glibc` entry at all. Same channel, same everything else.
#
# So the assert reads what actually SHIPS — the built artifact's
# info/index.json — not the manifest that was supposed to produce it.
#
# Usage: nu ci/check-stdlib-floor.nu [dist-dir]   (default ./dist)
def main [dist: string = "./dist"] {
  let floor = "2.28"

  if not ($dist | path exists) {
    error make { msg: $"($dist) does not exist — build the packages first, e.g. `pixi publish --to ($dist)`" }
  }

  let pkgs = (glob $"($dist)/**/*.conda")
  if ($pkgs | is-empty) {
    error make { msg: $"no .conda artifacts under ($dist) — nothing to assert, which is itself a failure" }
  }

  mut checked = 0
  mut failures = []

  for pkg in $pkgs {
    let index = (
      ^bsdtar -xOf $pkg "info-*.tar.zst"
      | ^bsdtar -xOf - info/index.json
      | from json
    )
    let name = $"($index.name)-($index.version)-($index.build)"

    # Windows skips stdlib derivation regardless of channel: win runtime
    # metadata (vc14_runtime/ucrt, or libgcc/libstdcxx/ucrt on a GNU
    # lane) arrives through the compiler activation's strong
    # run-exports instead. Nothing to assert there.
    if $index.subdir != "linux-64" {
      print $"  skip ($name) [($index.subdir)]: stdlib derivation is linux-only"
      continue
    }

    let depends = ($index | get -o depends | default [])

    # A package with NO native runtime is not missing a floor — it has
    # nothing to floor. `stb` is the live example: a rattler-build
    # recipe that installs headers and a hand-written CMake config,
    # never invoking a compiler, so no stdlib requirement is emitted
    # and none is wanted. Note that "header-only" is NOT the test —
    # `mathkit` is header-only too, but it builds through
    # pixi-build-cmake, which provisions a compiler and therefore does
    # carry the floor. The discriminator is the COMPILER RUNTIME in
    # depends, and the skip is printed rather than silent, because a
    # compiled package that quietly lost its runtime deps would
    # otherwise slip through this exemption.
    let native = ($depends | any {|d|
      ($d | str starts-with "libgcc") or ($d | str starts-with "libstdcxx")
    })
    if not $native {
      print $"  skip ($name): no compiler-runtime dependency — nothing was compiled, so no stdlib floor is emitted or expected"
      continue
    }

    let glibc = ($depends | where {|d| $d | str starts-with "__glibc" })

    if ($glibc | is-empty) {
      $failures = ($failures | append $"($name): NO __glibc entry in depends — depends = ($depends)")
    } else if not ($glibc | any {|d| $d | str contains $"=($floor)" }) {
      $failures = ($failures | append $"($name): __glibc floor is not ($floor) — got ($glibc)")
    } else {
      print $"  ok ($name): ($glibc | first)"
    }
    $checked = $checked + 1
  }

  if ($failures | is-not-empty) {
    print ""
    print "STDLIB FLOOR MISSING FROM A SHIPPED ARTIFACT:"
    $failures | each {|f| print $"  ($f)" }
    print ""
    print "DIAGNOSTIC — which half broke:"
    diagnose
    error make { msg: $"($failures | length) package\(s\) shipped without the __glibc =($floor) floor" }
  }

  print $"stdlib floor OK: ($checked) linux-64 artifact\(s\) carry __glibc =($floor)"
}

# The pair of questions a bare "no __glibc" cannot distinguish:
#   1. the backend never EMITTED a stdlib requirement (the `c_stdlib`
#      key vanished from the variant set — check variants.yaml), versus
#   2. it emitted one and the resolved sysroot failed to run-export a
#      floor (an upstream/packaging problem, not ours).
# The rendered recipe answers it: `${{ stdlib('c') }}` present means
# the backend did its half.
def diagnose [] {
  let recipes = (glob ".pixi/bld/**/debug/recipe.yaml")
  if ($recipes | is-empty) {
    print "  rendered recipes not found under .pixi/bld/**/debug/ — cannot distinguish"
    print "  'backend never emitted the requirement' from 'sysroot did not run-export'."
    return
  }
  # Many rendered recipes accumulate under .pixi/bld across builds; the
  # VERDICT is what matters, so report counts with one example each
  # rather than a wall of identical lines.
  let verdicts = (
    $recipes
    | each {|r| { recipe: $r, emits: (open --raw $r | into string | str contains "stdlib('c')") } }
  )
  let emitting = ($verdicts | where emits)
  let silent = ($verdicts | where not emits)

  if ($emitting | is-not-empty) {
    print $"  ($emitting | length)/($verdicts | length) rendered recipes DO render stdlib\('c'\) — e.g. ($emitting | first | get recipe)"
    print "    The BACKEND emitted the requirement, so its half is fine: look at what"
    print "    sysroot actually resolved and whether it run-exported a floor."
  }
  if ($silent | is-not-empty) {
    print $"  ($silent | length)/($verdicts | length) rendered recipes do NOT render stdlib\('c'\) — e.g. ($silent | first | get recipe)"
    print "    The `c_stdlib` variant key is missing from the variant set. Check"
    print "    variants.yaml — this one is OUR bug, and the likely cause."
  }
}
