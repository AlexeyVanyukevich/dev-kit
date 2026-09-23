#!/usr/bin/env bash
# Every rule is reachable at the promised path, and the set stays small enough to be followed.
set -euo pipefail

cd tests/fixture
npm install --silent --no-audit --no-fund

# Every import in the fixture's CLAUDE.md must resolve to a real file. This is what catches a
# rename: the import syntax fails silently, leaving a project quietly missing a convention.
total=0
imports=0
while read -r path; do
  [ -f "$path" ] || { echo "  ✗ CLAUDE.md imports $path, which does not exist"; exit 1; }
  lines="$(wc -l < "$path")"
  # Per-file budget. A rule nobody finishes reading is a rule nobody follows.
  [ "$lines" -le 60 ] || { echo "  ✗ $path is $lines lines; the limit is 60"; exit 1; }
  total=$((total + lines))
  imports=$((imports + 1))
done < <(grep -o '^@node_modules/[^ ]*\.md' CLAUDE.md | sed 's/^@//')

[ "$imports" = 8 ] || { echo "  ✗ expected 8 rule imports, found $imports"; exit 1; }

# The whole-set budget encodes spec §4's decision: past roughly 200 lines, adherence suffers
# and the path-scopable rules should move to .claude/rules/. Crossing it is a design signal,
# not a formatting nit, so it fails the build rather than warning.
[ "$total" -le 200 ] || {
  echo "  ✗ the rules total $total lines. Past 200 they belong in .claude/rules/ with"
  echo "    paths: frontmatter so they load only for matching files — see spec §4."
  exit 1
}

# The end-to-end proof: a real session reads a rule back. Skipped where the CLI is absent,
# because a check that cannot run everywhere must not be the only thing standing behind a claim
# — the path assertions above hold on their own.
if [ -z "${DEVKIT_SKIP_SESSION_CHECK:-}" ] && command -v claude >/dev/null 2>&1; then
  answer="$(claude -p 'Which package does the TypeScript rule in your instructions say to use for schemas? Answer with the package name and nothing else.' 2>&1 || true)"
  grep -q 'typebox' <<< "$answer" || {
    echo "  ✗ a session did not read the imported rule back. Got: $answer"
    exit 1
  }
  echo "  ✓ a real session read an imported rule back"
else
  echo "  · session check skipped (no claude CLI, or DEVKIT_SKIP_SESSION_CHECK set)"
fi

echo "  ✓ $imports rules reachable, $total lines total, all within budget"
