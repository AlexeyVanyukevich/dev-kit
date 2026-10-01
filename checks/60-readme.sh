#!/usr/bin/env bash
# Every path the README promises a consumer actually exists.
set -euo pipefail

[ -f README.md ] || { echo "  ✗ README.md does not exist"; exit 1; }

checked=0

# Filesystem paths — rule imports, the shell library, the ignore files. Each never touches npm's
# resolver, so the only promise is that the file is there: strip node_modules/dev-kit/ and look.
while read -r path; do
  rel="${path#node_modules/dev-kit/}"
  [ -f "$rel" ] || { echo "  ✗ README promises $path; $rel does not exist"; exit 1; }
  checked=$((checked + 1))
done < <(grep -o 'node_modules/dev-kit/[^ )`"]*' README.md | sort -u)

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
done < <(grep -o 'dev-kit/\(common\|backend\|ui\)/\(tsconfig\|prettier\)[^ )`"]*' README.md | sort -u)

[ "$checked" -ge 8 ] || { echo "  ✗ only $checked paths checked; the README looks incomplete"; exit 1; }

echo "  ✓ $checked promised paths all resolve"
