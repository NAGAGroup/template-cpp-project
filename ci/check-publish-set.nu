# Standing doctrine-compliance check (C-01/C-02): the publish NAME-SET is
# the surface where naming violations appear first — variant axes must
# grow build strings, never names. Names must match EXACTLY; drift fails.
# (Counts grow with the variant matrix by design; names must not.)
let expected = ["enginelib" "fmt" "mathkit" "stb"]

let out = (pixi publish --dry-run --to ./ci-dry-channel | complete)
if $out.exit_code != 0 {
  print $out.stdout
  print $out.stderr
  error make { msg: "publish --dry-run failed" }
}
let actual = ($out.stdout ++ $out.stderr
  | lines
  | parse --regex '^\s+- (?<name>\S+) v\d'
  | get name | uniq | sort)

if $actual != ($expected | sort) {
  error make { msg: $"publish name-set drift: ($actual) != ($expected | sort)" }
}
print $"publish name-set OK: ($actual | str join ', ')"
