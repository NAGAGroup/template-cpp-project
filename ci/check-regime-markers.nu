# Machine-check the ABI-REGIME lesson (C-02 demonstrated, not asserted):
# the two Windows regimes must be VISIBLY DISTINCT in the committed
# lock's metadata, for every package in each lane.
#
#   GNU lane  (mingw cells + in-regime wrappers): depends carry
#             libstdcxx + libgcc + ucrt, and never a foreign-regime
#             channel C++ dep (spdlog/fmt/catch2 — those arrive as
#             *-mingw source rebuilds instead).
#   VC lane   (clang-win cells): depends carry vc14_runtime + ucrt,
#             and never libstdcxx/libgcc.
#
# Note both lanes carry `ucrt`: the gcc_win-64 family targets the SAME
# CRT as MSVC — which is exactly why pure-C deps may cross regimes
# while C++ deps must not (see https://github.com/NAGAGroup/template-cpp-project/blob/main/template-docs/variants.md).
let lock = (open --raw pixi.lock | from yaml)
let srcs = ($lock | get packages | where {|p| ($p | get -o conda_source | default "") != "" })

def win-recs [name: string] {
  $srcs
  | where {|p| $p.conda_source =~ $'^($name)\[' }
  | where {|p| ($p | get -o variants | default {} | get -o target_platform | default "") == "win-64" }
}

def dep-names [rec] {
  $rec | get -o depends | default [] | each {|d| $d | split row " " | first }
}

mut bad = []

let gnu = ["enginelib-mingw" "enginelib-tests-mingw" "demo-app-mingw" "catch2-mingw" "spdlog-mingw" "fmt-mingw"]
for name in $gnu {
  let recs = (win-recs $name)
  if ($recs | is-empty) { $bad = ($bad | append $"($name): no win-64 record in lock") ; continue }
  for r in $recs {
    let deps = (dep-names $r)
    for marker in ["libstdcxx" "libgcc" "ucrt"] {
      if not ($marker in $deps) { $bad = ($bad | append $"($name): missing GNU-regime marker ($marker)") }
    }
    for foreign in ["spdlog" "fmt" "catch2" "vc14_runtime"] {
      if $foreign in $deps { $bad = ($bad | append $"($name): FOREIGN-regime dep ($foreign) in a GNU-lane record") }
    }
  }
}

let vc = ["enginelib-clang" "enginelib-tests-clang" "demo-app-clang"]
for name in $vc {
  let recs = (win-recs $name)
  if ($recs | is-empty) { $bad = ($bad | append $"($name): no win-64 record in lock") ; continue }
  for r in $recs {
    let deps = (dep-names $r)
    for marker in ["vc14_runtime" "ucrt"] {
      if not ($marker in $deps) { $bad = ($bad | append $"($name): missing VC-regime marker ($marker)") }
    }
    for foreign in ["libstdcxx" "libgcc"] {
      if $foreign in $deps { $bad = ($bad | append $"($name): GNU marker ($foreign) in a VC-lane record") }
    }
  }
}

if ($bad | is-not-empty) {
  for b in $bad { print $"regime marker violation: ($b)" }
  error make { msg: "lock regime markers violated — a package's metadata no longer proves which ABI regime built it (C-02 lesson: the two win regimes must stay visibly distinct in the lock)" }
}
print "regime markers OK: GNU lane carries libstdcxx/libgcc/ucrt with no foreign C++ deps; VC lane carries vc14_runtime/ucrt"
