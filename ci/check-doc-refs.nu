# DANGLING-DOC-REFERENCE GUARD.
#
# The template docs directory is TEMPLATE scaffolding: a project generated
# from this template DELETES it (see the renaming/init flow). Anything that
# survives that deletion — manifests, CMakeLists, CI workflows, ci/
# scripts — must therefore never point at it with a RELATIVE path, or the
# generated project ships comments that reference files it does not have.
#
# (This file is itself tracked, so it deliberately never spells the
# directory-with-trailing-slash literal outside the `docdir` variable —
# otherwise the guard would flag its own documentation.)
#
# Rule: outside the template-only surface (the docs directory itself,
# README.md, .agents/), a reference to the docs must either be
#   (a) an ABSOLUTE upstream URL (still resolves after deletion), or
#   (b) INLINED — say the thing instead of pointing at it.
#
# Exempt paths are template-only by construction: README.md is rewritten
# and .agents/ is the template's own agent tooling; both go with the docs.
let docdir = "template-docs"
let allowed = "https://github.com/NAGAGroup/template-cpp-project/blob/main/"
let exempt_files = ["README.md"]
let exempt_dirs = [$"($docdir)/" ".agents/"]

let needle = $"($docdir)/"
let files = (
  git ls-files
  | lines
  | where {|f| ($exempt_dirs | any {|d| $f | str starts-with $d }) == false }
  | where {|f| $f not-in $exempt_files }
)

let hits = (
  $files
  | each {|f|
      let text = (try { open --raw $f | into string } catch { "" })
      if not ($text | str contains $needle) { return [] }
      # Absolute upstream URLs are fine: erase them, then look for what is left.
      $text
      | str replace --all $"($allowed)($needle)" ""
      | lines
      | enumerate
      | where {|l| $l.item | str contains $needle }
      | each {|l| $"($f):($l.index + 1): ($l.item | str trim)" }
    }
  | flatten
)

if ($hits | is-not-empty) {
  print "Relative references to the template docs found in material that OUTLIVES them:"
  $hits | each {|h| print $"  ($h)" }
  error make { msg: $"($hits | length) dangling doc reference\(s\): use the absolute upstream URL \(($allowed)($needle)...\) or inline the point." }
}
print $"doc-reference check OK: ($files | length) tracked files, no relative ($needle) refs outside the template-only surface"
