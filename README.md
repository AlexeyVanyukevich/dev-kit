# dev-kit

Shared conventions and tooling configuration for the projects on this machine, in four
sections — `common`, `backend`, `ui`, `testing`. A project loads the sections it needs, and
nothing from the others comes with them.

This is never published to the public npm registry. A package called `dev-kit` on the public
registry is an unrelated project and is not this one.

## Install

From the private registry — the normal way:

```json
"devDependencies": { "dev-kit": "^2.0.0" }
```

with the registry in the consuming project's `.npmrc`:

```
registry=<private registry URL>
```

The package is unscoped, so it cannot be routed by scope the way `@scope:registry=` would
route one. That line redirects the whole project, which is what a registry proxying the public
one upstream is built for.

Over git — the fallback, for a machine that cannot reach the registry:

```json
"devDependencies": { "dev-kit": "github:AlexeyVanyukevich/dev-kit#v2.0.0" }
```

No `.npmrc` is needed for this form, and it installs the same tree at a pinned tag.

## Sections

| Section | For | Brings |
| ------- | --- | ------ |
| `common` | every project | six rules, the TypeScript base, Prettier, the `./run` skeleton, ignore files |
| `backend` | Node services | four rules, the NodeNext tsconfig |
| `ui` | bundled browser applications | one rule, the browser tsconfig |
| `testing` | any project with a test suite | one rule |

**No section loads another.** A backend project with tests writes `common`, `backend` and
`testing` as three lines; nothing arrives that it did not name. A section's rules come as one
line; its configuration — tsconfig, Prettier, `./run`, ignore files — is still taken one piece
at a time, and a project that wants none of it writes none of it.

### A repository with both a backend and a UI

Load `common` and `testing` in the root `CLAUDE.md`, `backend` in the server workspace's
`CLAUDE.md`, and `ui` in the web workspace's. Claude Code reads a subdirectory's `CLAUDE.md`
when it works on files there, so each workspace gets its own section and not the other's.

Loading all four at the root is the obvious move and the wrong one: every session would read
both, and the rules budget assumes no session does.

## The modules

### TypeScript

```json
{ "extends": "dev-kit/backend/tsconfig" }
```

`dev-kit/common/tsconfig` carries the strictness: `strict`, `noUncheckedIndexedAccess`,
`exactOptionalPropertyTypes`, `target: ES2023`. `dev-kit/backend/tsconfig` adds NodeNext
resolution and Node types; `dev-kit/ui/tsconfig` adds the DOM lib, bundler resolution and
`jsx: react-jsx`. A workspace that is neither extends `dev-kit/common/tsconfig` directly.

None of the three sets `outDir`, `rootDir` or `include`. Those describe one project's directory
layout, and a shared base that guesses them is a base every project has to override.

### Prettier

In the consuming project's `package.json`:

```json
{ "prettier": "dev-kit/common/prettier" }
```

`semi: false`, `singleQuote: true`, `printWidth: 100`.

### Rules

One line per section in the consuming project's `CLAUDE.md`, and only the sections that
project needs:

```markdown
@node_modules/dev-kit/common/rules.md
@node_modules/dev-kit/backend/rules.md
@node_modules/dev-kit/ui/rules.md
@node_modules/dev-kit/testing/rules.md
```

| Section | Rule | Covers |
| ------- | ---- | ------ |
| common | `typescript.md` | Compiler strictness, no `any` in hand-written code |
| common | `commits.md` | Conventional Commits, the subject line as the whole message, rebase-only merges |
| common | `documentation.md` | `architecture.md` is authoritative; specs and plans are dated records |
| common | `writing.md` | Refer to projects by role; name something only when the name is load-bearing |
| common | `review.md` | A session ends by showing everything it changed, and what it decided alone |
| common | `backlog.md` | Findings left unfixed go in `docs/backlog.md`, one entry each, deleted by the fix |
| backend | `typescript.md` | NodeNext's `.js` imports, the `typebox` package, the one accepted `any` |
| backend | `http.md` | The one error shape, its codes, `additionalProperties: false`, 4xx translation |
| backend | `layout.md` | `modules/<entity>/` and its four files; `shared/`, `db/` |
| backend | `database-tests.md` | Integration tests against a real PostgreSQL, started by Testcontainers |
| ui | `typescript.md` | Bundler resolution: no extension on relative imports |
| testing | `testing.md` | Tests first, datasets over test bodies, derived facts, where tests live |

A section's `rules.md` is a heading and one `@rules/<rule>.md` line per file in its `rules/`.
No section imports another, so a project gets exactly the sections it names.

**The kit must be installed as a real directory** — from the registry or over git, as above.
`npm link` and a `file:` dependency install a symlink, and Claude Code does not follow an
index's imports through a symlink that leads out of the project: the session reads the section
headings and none of the rules.

These are **filesystem paths, not module specifiers**. They never touch npm's resolver, which
is why they appear in no `exports` map and why adding a rule needs no `package.json` change.

### The `./run` skeleton

```bash
source node_modules/dev-kit/common/lib.sh
```

Defines `step`, `ok`, `note`, `die`, `load_env_file`, `need_docker`, `need_node`, `need_deps`
and `need_env`, plus the colour variables. Sourcing is inert: no shell options set, no
directory changed, nothing run.

**`./run` is what installs dependencies, so it cannot source out of `node_modules` before the
kit is there.** Keep a short bootstrap *above* the `source` line, and test for the file rather
than the directory: a checkout installed before it took the kit has `node_modules` without it.

```bash
[ -f node_modules/dev-kit/common/lib.sh ] || npm install
source node_modules/dev-kit/common/lib.sh
```

`need_node` reads `DEVKIT_NODE_MIN` (default `24`) and `DEVKIT_NODE_HINT`. `need_env` returns
non-zero when it created `.env`, so a caller can print its own notes only on the first run.
**Under `set -e` a bare `need_env` therefore ends the script on exactly that run** — call it as
`need_env || note "…"`.

The scenarios stay in each project. Only the frame is shared.

### Ignore files

```bash
cp node_modules/dev-kit/common/ignore/gitignore .gitignore
cp node_modules/dev-kit/common/ignore/prettierignore .prettierignore
```

These are **copied, not referenced** — neither format has an import or extends mechanism. They
are starting points a project appends its own entries to, and they change rarely.

## Verification

```bash
./check            # every check, in order
./check 20         # just the one whose name matches
```

`./check` is the only verification command. There is no test framework: each `checks/*.sh`
proves one module's contract by running the tool a consumer would actually run — `tsc` against
the fixture, `prettier` against a deliberately unformatted file — from `tests/fixture/`, a real
consumer project that installs this package by relative path.

## Adding a module

Write the check first. It is the only test this repository has, and a module that ships without
one is a promise nobody is keeping.

A rule goes in the `rules/` of the section whose every project needs it, with its import in
that section's `rules.md`. `./check 40` fails until both exist, and fails if the section's
session load passes 225 lines.

## Migrating from 1.x

Every path changed in 2.0.0. Replace each 1.x line with its 2.0 counterpart:

| 1.x | 2.0 |
| --- | --- |
| `@node_modules/dev-kit/rules/commits.md`, `documentation.md`, `writing.md`, `review.md`, `backlog.md` | `@node_modules/dev-kit/common/rules.md` |
| `@node_modules/dev-kit/rules/typescript.md` | `common/rules.md`, plus `backend/rules.md` or `ui/rules.md` |
| `@node_modules/dev-kit/rules/http.md`, `layout.md` | `@node_modules/dev-kit/backend/rules.md` |
| `@node_modules/dev-kit/rules/testing.md` | `@node_modules/dev-kit/testing/rules.md`, plus `backend/rules.md` for the PostgreSQL rule |
| `dev-kit/tsconfig/base` | `dev-kit/common/tsconfig` |
| `dev-kit/tsconfig/node` | `dev-kit/backend/tsconfig` |
| `dev-kit/tsconfig/web` | `dev-kit/ui/tsconfig` |
| `dev-kit/prettier` | `dev-kit/common/prettier` |
| `node_modules/dev-kit/sh/lib.sh` | `node_modules/dev-kit/common/lib.sh` — in the bootstrap line too |
| `node_modules/dev-kit/ignore/…` | `node_modules/dev-kit/common/ignore/…` |

A project that imported only some of the 1.x rules now gets the whole section. The rule files
are still files at `<section>/rules/<rule>.md` and can be imported one at a time, but that is
outside the documented contract and nothing checks it.
