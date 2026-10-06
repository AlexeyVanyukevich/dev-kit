# Sourced by a project's ./run, never executed:
#
#   source node_modules/dev-kit/common/lib.sh
#
# Sourcing is inert. No shell options are set, no directory is changed and nothing runs — the
# caller owns `set -euo pipefail` and its own `cd`, and a library that took either would
# surprise whoever sources it halfway down a script.

# ── output ───────────────────────────────────────────────────────────────────

if [ -t 1 ]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; OFF=$'\033[0m'
else
  BOLD=''; DIM=''; RED=''; GREEN=''; YELLOW=''; OFF=''
fi

step() { printf '%s→ %s%s\n' "$BOLD" "$1" "$OFF"; }
ok()   { printf '%s✓ %s%s\n' "$GREEN" "$1" "$OFF"; }
note() { printf '%s  %s%s\n' "$DIM" "$1" "$OFF"; }

# Fail with an instruction, not just a symptom. The second argument is what to do about it.
die() {
  printf '%s✗ %s%s\n' "$RED" "$1" "$OFF" >&2
  [ $# -gt 1 ] && printf '%s  %s%s\n' "$YELLOW" "$2" "$OFF" >&2
  exit 1
}

# ── environment ──────────────────────────────────────────────────────────────

# `.env` is the local counterpart of what compose already substitutes for the Docker stack.
#
# Read line by line rather than sourced, so the conventional precedence holds: command line,
# then the file, then the script's own defaults. `. ./.env` assigns unconditionally and would
# let the file override an explicit `PORT=4100 ./run dev`.
#
# The grammar is plain `KEY=value`, matching what compose itself reads: no quoting, no
# expansion, `#` starts a comment. A value may contain `=`; only the first one splits.
load_env_file() {
  [ -f .env ] || return 0
  local line key
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in '' | \#*) continue ;; esac
    key=${line%%=*}
    [ -n "${!key:-}" ] && continue
    export "$key=${line#*=}"
  done < .env
}

# ── preflight ────────────────────────────────────────────────────────────────

need_docker() {
  command -v docker >/dev/null 2>&1 ||
    die "Docker is not installed." "Install Docker Desktop, then run this again."
  docker info >/dev/null 2>&1 ||
    die "Docker is installed but not running." "Start Docker Desktop and wait for it to report ready."
}

# The floor is a variable because it is the one thing that differs between projects today, and
# a project that needs a newer Node should say so rather than fork this function.
need_node() {
  local min="${DEVKIT_NODE_MIN:-24}"
  local hint="${DEVKIT_NODE_HINT:-Install Node ${min} or newer.}"
  command -v node >/dev/null 2>&1 || die "Node is not installed." "$hint"
  local major
  major="$(node -p 'process.versions.node.split(".")[0]')"
  if [ "$major" -lt "$min" ]; then
    printf '%s! Node %s is older than the required %s.%s\n' "$YELLOW" "$(node -v)" "$min" "$OFF" >&2
    note "nvm use   (or install Node ${min}) — continuing anyway"
  fi
}

# GitHub Packages wants a token even to install. CI provides one as GITHUB_TOKEN; a developer's
# comes from the GitHub CLI's login, which keeps it in the system's credential store. Either way
# it is handed to the one command that needs it and never exported into the caller's session.
with_github_token() {
  local token="${GITHUB_TOKEN:-}"
  if [ -z "$token" ]; then
    command -v gh >/dev/null 2>&1 ||
      die "Installing needs a GitHub token, and the GitHub CLI is not installed." \
        "Install it from https://cli.github.com, then: gh auth login && gh auth refresh -s read:packages"
    token="$(gh auth token 2>/dev/null)" && [ -n "$token" ] ||
      die "Installing needs a GitHub token, and the GitHub CLI is not signed in." \
        "gh auth login && gh auth refresh -s read:packages"
  fi
  GITHUB_TOKEN="$token" "$@"
}

# A project whose .npmrc reads ${GITHUB_TOKEN} installs from GitHub Packages and gets a token.
# One that does not never needs the GitHub CLI.
need_deps() {
  [ -d node_modules ] && return 0
  step "Installing dependencies"
  if grep -qs 'GITHUB_TOKEN' .npmrc; then
    with_github_token npm install
  else
    npm install
  fi
}

# Copies the template and says so. Whatever else the project wants to tell the reader about the
# new file — which port it points at, which secret is still blank — is the caller's to `note`,
# because only the caller knows.
need_env() {
  if [ ! -f .env ]; then
    step "Creating .env from .env.example"
    cp .env.example .env
    return 1
  fi
  return 0
}
