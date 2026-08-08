# Run the instrumented test binary, export an lcov report, and render a
# per-file coverage table — a taste of why nushell for scripting: the
# llvm-cov JSON becomes structured data you can reshape in a pipeline
# instead of scraping text with awk.
def main [] {
  # Everything lands in an ignored directory; stale profiles from
  # earlier runs (or other toolchain versions) are cleared first so
  # llvm-profdata never merges incompatible or leftover data.
  let outdir = "coverage"
  mkdir $outdir
  ls $outdir | where name =~ '\.(profraw|profdata)$' | each {|f| rm $f.name }

  let profraw = ($outdir | path join "enginelib-tests.profraw")
  let profdata = ($outdir | path join "enginelib-tests.profdata")
  let lcov = ($outdir | path join "coverage.info")

  $env.LLVM_PROFILE_FILE = $profraw
  enginelib-tests
  llvm-profdata merge -sparse $profraw -o $profdata

  let bin = (which enginelib-tests | first | get path)
  let lib = ($env.CONDA_PREFIX | path join "lib" "libenginelib.so")
  let cov = [$bin -object $lib $"-instr-profile=($profdata)"]

  llvm-cov export ...$cov -format=lcov | save -f $lcov

  print "Per-file coverage:"
  llvm-cov export ...$cov -summary-only
  | from json
  | get data.0.files
  | each {|f| {
      file: ($f.filename | path basename),
      lines: $"($f.summary.lines.percent | math round --precision 1)%",
      functions: $"($f.summary.functions.percent | math round --precision 1)%",
      regions: $"($f.summary.regions.percent | math round --precision 1)%",
    }}
  | print $in

  print $"lcov report written to ($lcov)"
}
