#!/usr/bin/env bash
# Every path the README promises a consumer actually exists.
set -euo pipefail

[ -f README.md ] || { echo "  ✗ README.md does not exist"; exit 1; }

checked=0

# Rule imports are filesystem paths; strip the leading @ and the node_modules/<pkg>/ prefix.
while read -r path; do
  rel="${path#@node_modules/dev-kit/}"
  [ -f "$rel" ] || { echo "  ✗ README promises $path; $rel does not exist"; exit 1; }
  checked=$((checked + 1))
done < <(grep -o '@node_modules/dev-kit/[^ )`]*' README.md | sort -u)

# Specifiers that go through module resolution must be in the exports map.
while read -r spec; do
  sub="./${spec#dev-kit/}"
  node -e "
    const map = require('./package.json').exports
    if (!map['$sub']) { console.error('  ✗ README promises $spec, absent from exports'); process.exit(1) }
    const target = map['$sub'].replace(/^\.\//, '')
    if (!require('fs').existsSync(target)) {
      console.error('  ✗ exports maps $sub to ' + target + ', which does not exist')
      process.exit(1)
    }
  "
  checked=$((checked + 1))
done < <(grep -o 'dev-kit/\(tsconfig\|prettier\)[^ )`"]*' README.md | sort -u)

# The one shell path.
grep -q 'node_modules/dev-kit/sh/lib.sh' README.md && {
  [ -f sh/lib.sh ] || { echo "  ✗ README promises sh/lib.sh, which does not exist"; exit 1; }
  checked=$((checked + 1))
}

[ "$checked" -ge 8 ] || { echo "  ✗ only $checked paths checked; the README looks incomplete"; exit 1; }

echo "  ✓ $checked promised paths all resolve"
