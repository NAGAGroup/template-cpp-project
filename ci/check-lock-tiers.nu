# Guard against pixi's nondeterministic SOURCE-variant selection: when
# several variants satisfy an env (microarch floors are open by design),
# fresh `pixi lock` runs pick arbitrarily. The committed lock is the
# deterministic artifact — assert its tier envs actually carry their own
# level, so a bad re-lock can never land silently. (Binary consumers of
# the published packages are unaffected; this guards the in-workspace
# source path only.)
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

let expect = { v0: "1", v2: "2", v3: "3", v4: "4" }
mut bad = []
for e in ($expect | transpose env level) {
  let got = (enginelib-level $e.env)
  print $"lock tier check: ($e.env) -> enginelib microarch level ($got), want ($e.level)"
  if $got != $e.level { $bad = ($bad | append $e.env) }
}
if ($bad | is-not-empty) {
  error make { msg: $"committed lock has wrong tier selection for: ($bad | str join ', ') — re-run `pixi lock` until tiers select their own level (nondeterministic source-variant selection)" }
}
print "lock tier selections OK"
