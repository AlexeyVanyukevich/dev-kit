# dev-kit — common, backend, ui and testing sections

Status: **designed**, 2026-10-01. Not built.

> **This is a decision record, not a description of the system.**
>
> It states what was decided on 2026-10-01, before any of it was built. It is not revised as
> the code moves on.
>
> Read it to learn **why** the kit is divided the way it is. For **what** the kit provides
> today, read `README.md`.

---

## 1. Goal

**A project loads only the rules and configuration it needs.** Today the kit is one flat set:
a project writes one `CLAUDE.md` line per rule, and a UI project that takes `typescript.md`
reads about Kysely and TypeBox, while one that takes `testing.md` is told to run its tests
against PostgreSQL.

The kit is divided into four **sections** — `common`, `backend`, `ui`, `testing` — and each
is loaded on its own, with one line per section.

The test applied to every line of content: *would a project that loads this section ever not
want this?* If yes, the line is in the wrong section.

## 2. Decisions

| Question | Decision |
| -------- | -------- |
| Separate packages, or one? | **One package, `dev-kit`**, with four top-level directories |
| How is a section loaded? | **One line per section** — an index file that imports its rules |
| Does a section bring `common` with it? | **No.** Every section is loaded explicitly |
| Old paths kept as aliases? | **No.** This is 2.0.0; the README carries a migration table |

### One package still

The 2026-09-08 design (§3, "One package, not several") rejected a package per concern because
a git specifier installs a whole repository and cannot name a subdirectory, so separate
packages would exist on the registry channel and not on the git fallback. That argument still
holds, and nothing here weakens it. What changes is the unit of choice: it was the individual
export, and it is now the section. Individual rule files remain importable, because they are
files, but the documented contract is the section.

### Strictly separate sections

`backend/rules.md` does not import `common/rules.md`. Loading `backend` alone gets backend
rules alone. A section that pulled `common` in would make "only what is needed" depend on
the kit author's guess about what every backend needs; the consuming project is the one that
knows.

The one internal reference is `backend/tsconfig.json` and `ui/tsconfig.json` extending
`../common/tsconfig.json`. That is a TypeScript `extends` inside the package, invisible to the
consumer, and the alternative — restating the strictness options in two places — is the very
thing the base exists to prevent. It loads a compiler option set, not a rule.

## 3. Layout

```
common/                  every project
  rules.md               index
  rules/
    commits.md           unchanged
    documentation.md     unchanged
    writing.md           unchanged
    review.md            unchanged
    backlog.md           unchanged
    typescript.md        strictness, no `any`, extend a base rather than restating it
  tsconfig.json          was tsconfig/base.json
  prettier.json          was prettier/index.json
  lib.sh                 was sh/lib.sh
  ignore/
    gitignore            unchanged
    prettierignore       unchanged

backend/                 Node services
  rules.md               index
  rules/
    typescript.md        NodeNext `.js` imports; `typebox`; the `Kysely<any>` exception
    http.md              unchanged
    layout.md            modules/<entity>/, shared/, db/ — without where tests live
    database-tests.md    integration tests against real PostgreSQL via Testcontainers
  tsconfig.json          was tsconfig/node.json; extends ../common/tsconfig.json

ui/                      bundled browser applications
  rules.md               index
  rules/
    typescript.md        bundler resolution: no `.js` extension on relative imports
  tsconfig.json          was tsconfig/web.json; extends ../common/tsconfig.json

testing/                 any project with a test suite
  rules.md               index
  rules/
    testing.md           tests first, datasets, derived facts, injected clock and network,
                         and where tests live
```

The old top-level `rules/`, `tsconfig/`, `prettier/`, `sh/` and `ignore/` are removed.

An index is a heading and one relative import per rule in its own `rules/`:

```markdown
# Backend

@rules/typescript.md
@rules/http.md
@rules/layout.md
@rules/database-tests.md
```

**Verified before this design was accepted.** A relative import inside an imported file
resolves against that file's directory, including under `node_modules`. A probe with
`CLAUDE.md` → `@node_modules/kit/sec/rules.md` → `@rules/word.md` had a print-mode session
read the innermost file's content back on 2026-10-01.

## 4. Where today's content goes

Five rules move unchanged into `common/rules/`. The other four are divided:

**`typescript.md`** splits three ways.

- `common`: the strictness flags, the instruction to extend a section's tsconfig rather than
  restate them, and "no `any` in hand-written code".
- `backend`: the `NodeNext` `.js` extension rule and its example; `typebox`, not
  `@sinclair/typebox`, with `@fastify/type-provider-typebox`; the `Kysely<any>` migration
  signature as the one place `any` appears.
- `ui`: bundler resolution takes no extension on relative imports.
- The warning that copying an import between a NodeNext and a bundler workspace breaks the
  build goes in **both** `backend` and `ui`, one sentence each. A mistake made in either
  direction lands in the workspace receiving the import, and a project loading one section
  must still be warned.

**`testing.md`** loses its PostgreSQL paragraph to `backend/rules/database-tests.md`. "A real
database, not a mock" is a decision about how a backend is tested against its persistence; a
UI project loading `testing` should never read it. Everything else stays.

**`layout.md`** loses its final sentence — `tests/{unit,integration}/`, browser journeys in
`tests/ui/` — to `testing.md`. The rest describes backend modules and stays in `backend`.

**`http.md`** moves to `backend` unchanged.

The ignore files and `lib.sh` stay whole in `common`. Ignore files are copied once and then
edited by the project, so a `playwright-report` line in a backend's `.prettierignore` is free
to delete and costs nothing to leave. An unused shell function costs nothing either. Dividing
them would cost every consumer a concatenation step and buy nothing.

## 5. The consumption contract

| Module | How a project takes it |
| ------ | ---------------------- |
| a section's rules | `@node_modules/dev-kit/<section>/rules.md` in `CLAUDE.md` |
| TypeScript, Node | `"extends": "dev-kit/backend/tsconfig"` |
| TypeScript, browser | `"extends": "dev-kit/ui/tsconfig"` |
| TypeScript, neither | `"extends": "dev-kit/common/tsconfig"` |
| Prettier | `"prettier": "dev-kit/common/prettier"` in `package.json` |
| the run skeleton | `source node_modules/dev-kit/common/lib.sh` in `./run` |
| ignore files | `cp node_modules/dev-kit/common/ignore/gitignore .gitignore` (and `prettierignore`) |

The package's `exports`:

```json
{
  "./package.json": "./package.json",
  "./common/tsconfig": "./common/tsconfig.json",
  "./common/prettier": "./common/prettier.json",
  "./backend/tsconfig": "./backend/tsconfig.json",
  "./ui/tsconfig": "./ui/tsconfig.json"
}
```

and `files` is `["common", "backend", "ui", "testing"]`.

### A repository with both a backend and a UI

It loads `common` and `testing` in its root `CLAUDE.md`, `backend` in the server workspace's
`CLAUDE.md`, and `ui` in the web workspace's. Claude Code reads a subdirectory's `CLAUDE.md`
when it works on files there, so each workspace gets its own section and neither gets the
other's. The README documents this, because loading all four at the root is the obvious move
and the wrong one.

## 6. The rule budget

The 2026-09-08 design capped the whole rule set at 200 lines, later 225, because adherence
falls once a session reads much more than that. Its stated remedy for crossing the cap was to
make rules load only where they apply. Sections are that remedy, so the budget is now measured
on **what one session loads**, not on everything the kit ships:

- every rule file: at most 60 lines, as before;
- `common` + `testing` + `backend`: at most 225 lines;
- `common` + `testing` + `ui`: at most 225 lines.

Index files are not counted; they hold import lines, not prose. The sum of all four sections
is not capped, because §5 says no session should load all four.

## 7. Verification

`./check` stays the only verification command, and the fixture stays a real consumer.

- **10-package.** `npm pack` ships `package.json` and the four directories. The rest is unchanged:
  the package resolves, declares no dependencies and runs no build scripts.
- **20-tsconfig.** The fixture's three tsconfigs extend `dev-kit/backend/tsconfig` (clean and
  probe) and `dev-kit/ui/tsconfig` (DOM). Same assertions: TS2322 and TS2375 still bite, the
  DOM lib is real only under `ui`. `dev-kit/common/tsconfig` is also resolved and compiled,
  because it is now a documented specifier.
- **30-prettier.** `"prettier": "dev-kit/common/prettier"`; ignore files read from
  `common/ignore/`.
- **40-rules.** Rewritten. The fixture's `CLAUDE.md` imports the four indexes — a harness
  proving every index resolves, not the pattern §5 recommends. The check proves, for each
  section:
  - its index exists and every import in it resolves to a file;
  - **its index imports exactly the files in its own `rules/`** — no file left out, so nothing
    shipped is unreachable, and nothing from another section, so the sections stay separate;
  - every rule file is within 60 lines;
  - and both §6 combinations are within 225.

  The session check asks for the TypeBox package name, which now lives two imports deep in
  `backend`. That proves nested imports through a real install.
- **50-lib.** Sources `common/lib.sh`; otherwise unchanged.
- **60-readme.** Its patterns follow the new paths: `@node_modules/dev-kit/<section>/…`,
  `dev-kit/(common|backend|ui)/(tsconfig|prettier)`, and `common/lib.sh`.

## 8. Release

**2.0.0.** Every import, `extends`, `prettier` key and `source` line a consumer has written
changes, so this is a major version. The README gains a table from every 1.x path to its 2.0
replacement. The release commit, tag and publish follow the existing `chore: release X.Y.Z`
practice and are done when the branch merges, not as part of building it.

## 9. Not in scope

- New rules for the UI or for UI testing. `ui` ships thin — a tsconfig and a few lines — and
  grows when there is a convention worth writing down, not to fill the section.
- Path-scoped `.claude/rules/` with `paths:` frontmatter. Sections achieve the same narrowing
  through a mechanism the consumer controls, without the kit guessing file globs.
- Compatibility aliases for 1.x paths.
