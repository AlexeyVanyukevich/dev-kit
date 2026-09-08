# dev-kit — shared conventions and configuration

Status: **designed**, 2026-09-08. Not built.

> **This is a decision record, not a description of the system.**
>
> It states what was decided on 2026-09-08, before any of it was built. It is not revised as
> the code moves on.
>
> Read it to learn **why** something has the shape it does. For **what** the kit provides
> today, read `README.md`.

This is the founding design record of this repository, written before any code on 2026-09-08.

dev-kit is consumed and never consumes: no project here depends on a project that uses it, and
a project that uses it depends on nothing else to do so.

---

## 1. Purpose

Three repositories — `booking-engine`, `cabins-admin`, `vigil` — share one set of conventions
and one set of tooling configuration, and today each carries its own copy.

The duplication is measurable. `.prettierrc` is byte-identical across the two built projects.
`.gitignore` and `.prettierignore` express the same intent and have drifted apart (22 vs 14
lines, 16 vs 12). `cabins-admin/CONTRIBUTING.md` opens by saying its conventions are "the same
set as `../booking-engine`" and then restates them in prose, because there was no other way to
have them. The third project has not been built yet and would have restated them a third time.

dev-kit holds one copy of each shared thing and lets a project take the pieces it wants.

### The driving case

A convention changes. It is edited in one file, and every project that opted into that file
gets it on its next dependency bump — rather than being corrected in three places by whoever
remembers all three.

### In scope

- Markdown convention rules, consumed by a project's `CLAUDE.md`
- TypeScript configuration bases
- Prettier configuration
- The `./run` script's skeleton, without its scenarios
- `.gitignore` and `.prettierignore` starting points

### Not in scope

A project generator; `docker-compose.yml`; the `./run` scenarios; ESLint; CI workflow
definitions; a Claude Code plugin.

Each is addressed in §7. None is precluded by anything below.

---

## 2. Why a repository rather than the alternatives

Three other shapes were considered.

**User-level configuration** — `~/.claude/CLAUDE.md`, `~/.claude/rules/` — reaches every
project on one machine with no repository at all. Rejected because it reaches every project
whether or not the project wants it, cannot be pinned or versioned, is invisible to anyone
reading the repository, and does not exist on a second machine or in CI.

**Symlinks from a local checkout.** `.claude/rules/` supports symlinks natively, so this is
cheaper than it sounds, and edits propagate the instant they are saved. Rejected because a
fresh clone and a CI runner both get dangling links, which was decided against when the reach
of the kit was settled: it must work on any machine, not only this one.

**A template repository that stamps out new projects.** Rejected as the wrong shape rather
than a bad idea: a template is a one-time copy, and a one-time copy is what produced the
present drift. The kit has to be something a project keeps depending on, not something it is
born from.

The cost accepted: a project must run `npm install` before its tooling configuration resolves,
and updating is a deliberate act rather than an automatic one. §6 argues the second is a
feature.

---

## 3. Shape

One repository. One npm package, `@vanyukevich/dev-kit`, consumed **over git and never from a
registry**:

```
package.json          name and exports map — the whole public surface
rules/                markdown, imported by a consuming project's CLAUDE.md
  typescript.md  http.md  layout.md  testing.md  commits.md  documentation.md
tsconfig/
  base.json           strict, noUncheckedIndexedAccess, exactOptionalPropertyTypes, ES2023
  node.json           extends base — NodeNext, types: node
  web.json            extends base — bundler resolution, DOM, jsx, verbatimModuleSyntax
prettier/index.json
sh/lib.sh             the ./run skeleton
ignore/
  gitignore  prettierignore
```

### One package, not several

The obvious reading of "split as much as possible" is a package per concern —
`@vanyukevich/tsconfig`, `@vanyukevich/prettier-config`. That shape is foreclosed by consuming
over git: a git dependency installs a **repository**, so several independent packages inside
one repository cannot be depended on separately without publishing them separately, which is
the registry this design is avoiding.

One package with subpath exports gives the same granularity. A project that wants only the
Prettier configuration references only `@vanyukevich/dev-kit/prettier`; nothing else is
loaded, extended, or imported. The unit of choice is the export, not the package.

### No registry

`"@vanyukevich/dev-kit": "github:AlexeyVanyukevich/dev-kit#v1"` installs on any machine that
can reach GitHub, needs no npm account, no publish step and no release process, and pins to a
git ref. For one author and three consumers, a registry would add ceremony and buy nothing.

---

## 4. The consumption contract

Every line below is independent and optional. A project writes only the ones it wants.

| Module | How a project takes it |
| ------ | ---------------------- |
| the package | `"devDependencies": { "@vanyukevich/dev-kit": "github:AlexeyVanyukevich/dev-kit#v1" }` |
| TypeScript | `"extends": "@vanyukevich/dev-kit/tsconfig/node"` in `tsconfig.json` |
| Prettier | `"prettier": "@vanyukevich/dev-kit/prettier"` in `package.json` |
| a rule | `@node_modules/@vanyukevich/dev-kit/rules/typescript.md` in `CLAUDE.md` |
| the run skeleton | `source node_modules/@vanyukevich/dev-kit/sh/lib.sh` in `./run` |
| ignore files | copied once — see below |

Four of the six use a mechanism the tool already has. That is deliberate: an installer script
that copied files around would have to be written, documented, kept working, and given an
update command, and every one of those is a thing that can rot.

### Rules travel through npm because they cannot travel through a plugin

A Claude Code plugin would be the natural home for shared Claude configuration, and it was the
first thing tried. It does not work: the documented plugin layout provides `skills/`,
`agents/`, `commands/`, `hooks/`, `.mcp.json` and `settings.json`, and **no `rules/`**. A
plugin cannot ship convention rules.

Since the rules had to travel some other way, and the package already travels, they travel in
the package and a project's `CLAUDE.md` imports the files it wants. `node_modules` resolves
inside the working directory, so these are not "external" imports and raise no approval
dialog.

**Verified before this design was accepted.** A scoped package puts an `@` in the middle of an
import path — `@node_modules/@vanyukevich/dev-kit/rules/typescript.md` — which is unusual
enough to be worth a probe rather than an assumption. A throwaway fixture with two sentinel
strings, one behind a scoped path and one behind an unscoped path, was read back correctly in
a print-mode session. Both resolve. The package keeps its scope.

### Rules are imported, not linked into `.claude/rules/`

Linking them into `.claude/rules/` instead would allow `paths:` frontmatter, so a TypeScript
rule would stay out of context until Claude touched a `.ts` file. That is a real advantage and
it was declined for now: the rule set is small enough that always-on costs little, and linking
adds a setup script, dangling links after `rm -rf node_modules`, and a broken state on a fresh
clone.

The signal to revisit is size. If the imported rules approach 200 lines in total — the point
at which adherence is documented to suffer — move the path-scopable ones to `.claude/rules/`.
**Nothing in the package changes when that happens**; only how projects consume it. That is
the property that makes deferring safe.

### Ignore files are copied, and the copy is admitted

Neither `.gitignore` nor `.prettierignore` has an import, extends, or include mechanism. The
kit ships starting points and a project copies one. This is the one place the duplication
being solved elsewhere is accepted rather than fixed, because fixing it would mean generating
those files, and a generated `.gitignore` is worse than a copied one. They change rarely.

### `./run` bootstraps before it sources

`./run` is what runs `npm install`, so it cannot source a file out of `node_modules` before
that file exists. Each project's `./run` therefore keeps a short inline bootstrap — test for
`node_modules`, install if absent — and sources `sh/lib.sh` after it. Everything below the
bootstrap is shared: the colour handling, `step` / `ok` / `note` / `die`, `need_docker`,
`need_node`, `load_env_file`, and the `check` scenario.

The scenarios themselves stay in each project. `booking-engine`'s `run` is 511 lines and
`cabins-admin`'s is 358 because they start different things; only the frame is common.

---

## 5. What the rules contain, and what stays behind

The rules are **extracted**, not copied. `booking-engine/docs/conventions.md` is titled
"Engine-wide conventions" and is exactly that: a mix of portable rules and engine domain
knowledge.

| Source section | Destination |
| -------------- | ----------- |
| API conventions — error shape, `additionalProperties: false` | `rules/http.md` |
| Technology stack | `rules/typescript.md`, `rules/testing.md` |
| Code layout | `rules/layout.md` |
| Testing conventions | `rules/testing.md` |
| Vocabulary, Time and date, Concurrency, Deliberate limitations | **stay in booking-engine** |

From `cabins-admin/CONTRIBUTING.md`: the TypeScript compiler settings and the NodeNext `.js`
import rule join `rules/typescript.md`; Conventional Commits and the commit-splitting guidance
become `rules/commits.md`; the spec / plan / `architecture.md` discipline becomes
`rules/documentation.md`.

Each file stays small and single-topic, because declining a rule should be deleting a line
rather than editing a paragraph.

### One rule carries an unresolved question

`rules/commits.md` must state whether a commit message may carry a body and a
`Co-Authored-By` trailer. `cabins-admin/CONTRIBUTING.md` forbids both — "The subject line is
the whole message" — while the agent harness used to write these projects requires the
trailer. The two cannot both hold, and until now the conflict was invisible because each
project answered it separately.

Consolidating the rule is what surfaced it. The answer belongs in `rules/commits.md` and is
the owner's to give; it is recorded here as open rather than decided silently.

---

## 6. Versioning

Git tags, and a project pins one: `#v1`. Updating is a ref bump in one project at a time.

`vigil` can move to `#v2` while `cabins-admin` stays on `#v1`, which matters because a
convention change that is right for a new project is not automatically worth a sweep through
an old one. Deliberate updates are the point, not a limitation: a shared configuration that
changes underneath a project without being asked is how a shared configuration becomes
something people stop trusting.

---

## 7. What was deliberately left out

**A Claude Code plugin.** Deferred, not rejected. The kit carries no skills, agents, slash
commands or hooks today, and a marketplace exists to distribute exactly those. When there is a
first one, `plugins/` and `.claude-plugin/marketplace.json` drop in beside `package.json`
without restructuring anything, and a consuming project adds `extraKnownMarketplaces` to its
`.claude/settings.json`. Building the manifest before there is anything to put in it would be
scaffolding for its own sake.

**`docker-compose.yml`.** 101 lines in `booking-engine`, 19 in `cabins-admin`. What they share
is the idea of a Postgres service, which is not worth a module.

**A project generator.** §2.

**ESLint and CI workflows.** Neither project has them today. A shared configuration for a tool
nobody uses is a guess about the future.

---

## 8. Consequences for the three existing projects

`vigil` has not been built. Its implementation plan
(`vigil/docs/superpowers/plans/2026-09-07-vigil-slice-1-errors-end-to-end.md`) has a first
task that hand-writes `tsconfig.base.json`, `.prettierrc`, the `run` script and a
`CONTRIBUTING.md` restating conventions. Most of that becomes taking the dependency. **That
plan needs revising once this repository exists** — a separate decision, recorded here so it
is not forgotten.

`cabins-admin` and `booking-engine` are running and are not migrated as part of building this.
They adopt modules one at a time, when something in one of them is being changed anyway. The
kit is designed to make partial adoption normal: a project that takes only `rules/commits.md`
and nothing else is using it correctly.

---

## 9. Build order

Small enough for one plan, in four steps, each independently checkable:

1. **The package.** `package.json` with the exports map, `tsconfig/`, `prettier/`,
   `ignore/`. Checkable by a scratch project that extends the tsconfig and formats a file.
2. **The rules.** Extraction per §5, including the answer to §5's commit-message question.
   Checkable by a print-mode session that reads a sentence back out of an imported rule.
3. **`sh/lib.sh`.** Extracted from the two existing `run` scripts, with the bootstrap pattern
   documented. Checkable by pointing one existing project's `./run` at it.
4. **`README.md`, then tag `v1`.** The consumption contract from §4 is the whole interface, and
   the tag is what §6's pin refers to — until it exists no project can depend on this.

The first consumer is whichever project is touched next. If that is `vigil`, step 4 is
followed by revising its Slice 1 plan per §8.
