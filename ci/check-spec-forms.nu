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

# ---- THE SECOND CARVE-OUT: exact-integer MUTEX pins -----------------
#
# Jack's spec-form rule says hand-written specs look like ">=x",
# ">=a.b,<a.c" or "==a.b.c". The documented three forms were never
# exhaustive, and pretending otherwise pushed us toward writing a
# WRONG spec to satisfy a check — so the honest carve-out is named
# here instead.
#
# A MUTEX or metapackage that is versioned by a single integer can
# only be pinned by that integer. Writing "==21.0.0" against a package
# whose published versions are literally `20` and `21` does not match
# anything; writing a range defeats the point of a mutex.
#
#   x86_64-microarch-level / _x86_64-microarch-level — levels 1-4.
#     Microarch levels have no minor versions; "==3.0.0" matches
#     nothing and "3.*" is banned outright.
#
#   acpp-llvm — the AdaptiveCpp lane mutex, versioned MAJOR-ONLY
#     (`20`, `21` — there is no `21.1.0`). It is also the ONE
#     unsuffixed name in that toolchain's interface: a mechanical
#     `-nightly` append produces a package that does not exist. Note
#     `acpp-llvm-dev` is a DIFFERENT package and never the pinning
#     handle.
#
# ⚠ NOT IN THIS LIST, DELIBERATELY: `acpp-tools-nightly = "==2026.08.10"`.
# It does not need to be — a pure date IS the canonical `==a.b.c`
# form, so it passes this check on its own merits. It is mentioned
# only so nobody "corrects" it into a range to match the nightly
# lane's other specs: that pin is exact ON PURPOSE, because the
# nightly lane changed version schemes and the OLD scheme
# (`2026.08.09_llvm21.1.8`) sorts BELOW the new one at the same date,
# which makes any range across that boundary admit artifacts nobody
# intended. See [feature.acpp-toolchain-nightly] in the root manifest.
let allowed_exact_integer_pins = [
  "x86_64-microarch-level"
  "_x86_64-microarch-level"
  "acpp-llvm"
]

let manifests = (glob **/pixi.toml | where {|p| $p !~ 'scratch|\.pixi' })
mut bad = []
mut bad_exact = []
for m in $manifests {
  let numbered = (open --raw $m | lines | enumerate)

  let hits = ($numbered | where {|l| $l.item =~ '=\s*"\*"' })
  for h in $hits {
    let key = ($h.item | parse --regex '^\s*"?(?<k>[A-Za-z0-9_-]+)"?\s*=' | get -o k.0 | default "?")
    if not ($key in $allowed_placeholder_keys) {
      $bad = ($bad | append $"($m):($h.index + 1): ($h.item | str trim)")
    }
  }

  # Exact pins: allowed when they are canonical "==a.b.c", or when the
  # name is a declared integer-versioned mutex. Comment lines are
  # skipped — this file is full of specs quoted in prose.
  let exact = ($numbered | where {|l| ($l.item !~ '^\s*#') and ($l.item =~ '=\s*"==') })
  for h in $exact {
    let parsed = ($h.item | parse --regex '^\s*"?(?<k>[A-Za-z0-9_.-]+)"?\s*=\s*"==(?<v>[^"]+)"')
    if ($parsed | is-empty) { continue }
    let key = ($parsed | get k.0)
    let ver = ($parsed | get v.0)
    let canonical = ($ver =~ '^[0-9]+\.[0-9]+\.[0-9]+$')
    if (not $canonical) and (not ($key in $allowed_exact_integer_pins)) {
      $bad_exact = ($bad_exact | append $"($m):($h.index + 1): ($h.item | str trim)")
    }
  }
}
if ($bad | is-not-empty) {
  print ($bad | str join "\n")
  error make { msg: "bare \"*\" specs outside the variant-placeholder carve-out — pin them (>=a.b,<a.c) or add the key to the build-variant matrix" }
}
if ($bad_exact | is-not-empty) {
  print ($bad_exact | str join "\n")
  error make { msg: "non-canonical exact pins outside the mutex carve-out — use \"==a.b.c\", or a range, or add the name to allowed_exact_integer_pins and say why" }
}
print $"spec-form check OK: placeholders (($allowed_placeholder_keys | str join ', ')); integer mutex pins (($allowed_exact_integer_pins | str join ', '))"
