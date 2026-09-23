#!/usr/bin/env bash
# The library defines what it promises, and load_env_file keeps the documented precedence.
set -euo pipefail

lib="$PWD/sh/lib.sh"
[ -f "$lib" ] || { echo "  ✗ sh/lib.sh does not exist"; exit 1; }

# Sourcing must be inert: no shell options changed, no directory changed, nothing executed.
# A library that runs on load cannot be sourced near the top of someone else's script.
before="$(set +o)"
# shellcheck disable=SC1090
source "$lib"
[ "$(set +o)" = "$before" ] || { echo "  ✗ sourcing lib.sh changed shell options"; exit 1; }

for fn in step ok note die load_env_file need_docker need_node need_deps need_env; do
  declare -F "$fn" >/dev/null || { echo "  ✗ lib.sh does not define $fn"; exit 1; }
done

for var in BOLD DIM RED GREEN YELLOW OFF; do
  [ -n "${!var+set}" ] || { echo "  ✗ lib.sh does not define $var"; exit 1; }
done

# die exits 1 and writes to stderr, so a failure is a failure even when stdout is piped.
( source "$lib"; die "nope" "do this instead" ) >/dev/null 2>&1 &&
  { echo "  ✗ die did not exit non-zero"; exit 1; }

# The precedence rule, which is the reason this is a line-by-line reader rather than `. ./.env`:
# command line beats the file. Sourcing the file would silently invert it.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
printf 'FROM_FILE=file\nOVERRIDDEN=file\n# a comment\n\nWITH_EQUALS=a=b\n' > "$tmp/.env"

result="$(
  cd "$tmp"
  source "$lib"
  OVERRIDDEN=shell
  export OVERRIDDEN
  load_env_file
  echo "$FROM_FILE|$OVERRIDDEN|$WITH_EQUALS"
)"
[ "$result" = "file|shell|a=b" ] || {
  echo "  ✗ load_env_file precedence is wrong: got '$result', wanted 'file|shell|a=b'"
  exit 1
}

# A missing .env is normal on a first run and must not be fatal.
( cd "$tmp" && rm -f .env && source "$lib" && load_env_file ) ||
  { echo "  ✗ load_env_file failed when .env was absent"; exit 1; }

echo "  ✓ lib.sh sources inertly, defines its surface, and keeps env precedence"
