# dev-kit

Shared conventions and tooling configuration for the projects on this machine. A project takes
the pieces it wants, one module at a time, and nothing else comes with them.

This is never published to the public npm registry. A package called `dev-kit` on the public
registry is an unrelated project and is not this one.

## Install

From the private registry — the normal way:

```json
"devDependencies": { "dev-kit": "^1.0.0" }
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
"devDependencies": { "dev-kit": "github:AlexeyVanyukevich/dev-kit#v1.0.0" }
```

No `.npmrc` is needed for this form, and it installs the same tree at a pinned tag.

## The modules

Every module below is **independent and optional**. Take one line or all six. A project that
takes only `rules/commits.md` and nothing else is using this correctly, and nothing will warn
it otherwise.

### TypeScript

```json
{ "extends": "dev-kit/tsconfig/node" }
```

`dev-kit/tsconfig/base` carries the strictness: `strict`, `noUncheckedIndexedAccess`,
`exactOptionalPropertyTypes`, `target: ES2023`. `dev-kit/tsconfig/node` adds NodeNext
resolution and Node types; `dev-kit/tsconfig/web` adds the DOM lib, bundler resolution and
`jsx: react-jsx`.

None of the three sets `outDir`, `rootDir` or `include`. Those describe one project's directory
layout, and a shared base that guesses them is a base every project has to override.

### Prettier

In the consuming project's `package.json`:

```json
{ "prettier": "dev-kit/prettier" }
```

`semi: false`, `singleQuote: true`, `printWidth: 100`.

### Rules

One line per rule in the consuming project's `CLAUDE.md`, and only the rules that project
wants:

```markdown
@node_modules/dev-kit/rules/typescript.md
@node_modules/dev-kit/rules/http.md
@node_modules/dev-kit/rules/layout.md
@node_modules/dev-kit/rules/testing.md
@node_modules/dev-kit/rules/commits.md
@node_modules/dev-kit/rules/documentation.md
@node_modules/dev-kit/rules/writing.md
```

| Rule | Covers |
| ---- | ------ |
| `typescript.md` | Compiler strictness, no `any`, NodeNext's `.js` imports, the `typebox` package |
| `http.md` | The one error shape, its codes, `additionalProperties: false`, 4xx translation |
| `layout.md` | `modules/<entity>/` and its four files; `shared/`, `db/`, where tests live |
| `testing.md` | Tests first, real Postgres over mocks, datasets over test bodies, derived facts |
| `commits.md` | Conventional Commits, and the subject line being the whole message |
| `documentation.md` | `architecture.md` is authoritative; specs and plans are dated records |
| `writing.md` | Refer to projects by role; name something only when the name is load-bearing |

These are **filesystem paths, not module specifiers**. They never touch npm's resolver, which
is why they appear in no `exports` map and why adding a rule needs no `package.json` change.

### The `./run` skeleton

```bash
source node_modules/dev-kit/sh/lib.sh
```

Defines `step`, `ok`, `note`, `die`, `load_env_file`, `need_docker`, `need_node`, `need_deps`
and `need_env`, plus the colour variables. Sourcing is inert: no shell options set, no
directory changed, nothing run.

**`./run` is what installs dependencies, so it cannot source out of `node_modules` before that
directory exists.** Keep a short bootstrap *above* the `source` line:

```bash
[ -d node_modules ] || npm install
source node_modules/dev-kit/sh/lib.sh
```

`need_node` reads `DEVKIT_NODE_MIN` (default `24`) and `DEVKIT_NODE_HINT`. `need_env` returns
non-zero when it created `.env`, so a caller can print its own notes only on the first run.

The scenarios stay in each project. Only the frame is shared.

### Ignore files

```bash
cp node_modules/dev-kit/ignore/gitignore .gitignore
cp node_modules/dev-kit/ignore/prettierignore .prettierignore
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
