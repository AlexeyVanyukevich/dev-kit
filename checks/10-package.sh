#!/usr/bin/env bash
# The package resolves from a consumer and ships exactly what it means to ship.
set -euo pipefail

fixture="tests/fixture"

# `npm pack` is the only honest answer to "what does a consumer get?" — `files` and
# `.npmignore` interact in ways that are easier to check than to reason about.
packed="$(npm pack --dry-run --json 2>/dev/null | node -e '
  const [pkg] = JSON.parse(require("fs").readFileSync(0, "utf8"))
  console.log(pkg.files.map((f) => f.path).sort().join("\n"))
')"

expect_packed() {
  grep -qx "$1" <<< "$packed" || { echo "  ✗ $1 is not in the package"; return 1; }
}

expect_packed 'package.json'

# A consumer must be able to resolve the package by name. This is what every later module
# rides on, so it is checked once here rather than in each of them.
( cd "$fixture" && npm install --silent --no-audit --no-fund )
resolved="$( cd "$fixture" && node -e '
  console.log(require.resolve("dev-kit/package.json"))
')"
[ -f "$resolved" ] || { echo "  ✗ the package does not resolve from the fixture"; exit 1; }

name="$(node -p "require('$resolved').name")"
[ "$name" = "dev-kit" ] || { echo "  ✗ resolved the wrong package: $name"; exit 1; }

# The kit exists so consumers stop inheriting things. It may never bring a tree with it.
for field in dependencies peerDependencies; do
  count="$(node -p "Object.keys(require('$resolved').$field ?? {}).length")"
  [ "$count" = 0 ] || { echo "  ✗ package.json declares $field"; exit 1; }
done

# A git dependency that has to build breaks on a machine missing a toolchain.
for script in prepare prepublishOnly install postinstall; do
  has="$(node -p "Boolean(require('$resolved').scripts?.$script)")"
  [ "$has" = false ] || { echo "  ✗ package.json declares a $script script"; exit 1; }
done

echo "  ✓ package resolves, ships package.json, brings no dependencies and builds nothing"
