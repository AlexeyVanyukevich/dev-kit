# dev-kit — shared conventions and configuration

Status: **designed**, 2026-09-08. Amended 2026-09-23. Not built.

> **This is a decision record, not a description of the system.**
>
> It states what was decided on 2026-09-08, before any of it was built. It is not revised as
> the code moves on.
>
> Read it to learn **why** something has the shape it does. For **what** the kit provides
> today, read `README.md`.

> **Amendment, 2026-09-23 — the package name and the distribution channel.**
>
> The package is `dev-kit`, unscoped, and a private registry is its preferred channel with git
> as the fallback. This reverses two decisions taken on 2026-09-08 and recorded below: that the
> package keeps a personal scope (§4), and that no registry is involved at all (§3).
>
> Both original arguments are left standing in the text, each followed by what overturned it.
> Nothing here had been built when the amendment was made, so this is still a design being
> settled rather than a system being described — but a reversal is worth more than the decision
> it replaces, and deleting the first argument would leave the second looking obvious.

This is the founding design record of this repository, written before any code on 2026-09-08.

dev-kit is consumed and never consumes: no project here depends on a project that uses it, and
a project that uses it depends on nothing else to do so.

Throughout, **the older project** and **the newer project** are the two applications already
running — the first being where most of these conventions were written down, the second where
they were restated. **The unbuilt project** is a third, designed but not yet written. Their
roles are what matters here; which repository is which is a fact about one machine and would
only date this record.

---

## 1. Purpose

Three repositories share one set of conventions and one set of tooling configuration, and today
each carries its own copy.

The duplication is measurable. `.prettierrc` is byte-identical across the two built projects.
`.gitignore` and `.prettierignore` express the same intent and have drifted apart (22 vs 14
lines, 16 vs 12). The newer project's `CONTRIBUTING.md` opens by saying its conventions are
"the same set as the older one" and then restates them in prose, because there was no other way
to have them. The third has not been built yet and would have restated them a third time.

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

### Never published publicly

**The kit is never published to the public npm registry.** Not "not yet" — this is a
constraint the design relies on rather than a step nobody has got round to. §3 spends the
package's name on the strength of it, so the two have to be read together.

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

One repository. One npm package, `dev-kit`, consumed **from a private registry, or over git,
and never from the public one**:

```
package.json          name and exports map — the whole public surface
rules/                markdown, imported by a consuming project's CLAUDE.md
  typescript.md  http.md  layout.md  testing.md
  commits.md  documentation.md  writing.md
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

The obvious reading of "split as much as possible" is a package per concern — `dev-tsconfig`,
`dev-prettier-config`. That shape is foreclosed by the git fallback: a git dependency installs
a **repository**, so several independent packages inside one repository cannot be depended on
separately over git at all. Only the registry channel could carry them, and a module that
exists on one channel and not the other is a module that breaks the moment a machine falls
back.

One package with subpath exports gives the same granularity. A project that wants only the
Prettier configuration references only `dev-kit/prettier`; nothing else is loaded, extended,
or imported. The unit of choice is the export, not the package.

### No public registry

**Decided 2026-09-08.** `"dev-kit": "github:AlexeyVanyukevich/dev-kit#v1"` installs on any
machine that can reach the remote, needs no npm account, no publish step and no release
process, and pins to a git ref. For one author and three consumers, a registry would add
ceremony and buy nothing.

**Amended 2026-09-23.** A private registry is the preferred channel; the git specifier stays
as the documented fallback. What the original argument missed is that "registry" was treated
as one thing. A *public* registry would indeed buy nothing — it would cost an account, a
publish step, a release process, and it would put three private projects' shared conventions
on the open internet. A *private* one costs a service that is already worth running for other
reasons and buys back the thing git specifiers cannot express: real semver ranges, so a
consumer can say `^1.0.0` and take patch fixes without editing a ref.

Both channels install the same package. A consumer that can reach the registry writes a
version range and an `.npmrc` line; a consumer that cannot — a fresh machine, a CI runner
outside the network — writes the git specifier and gets the same tree at a pinned tag. Neither
is a migration away from the other.

The public registry is not a third option, and §1 says why that is a constraint rather than an
omission.

---

## 4. The consumption contract

Every line below is independent and optional. A project writes only the ones it wants.

| Module | How a project takes it |
| ------ | ---------------------- |
| the package | `"devDependencies": { "dev-kit": "^1.0.0" }`, plus `registry=` in `.npmrc` |
| the package, over git | `"devDependencies": { "dev-kit": "github:AlexeyVanyukevich/dev-kit#v1" }`, no `.npmrc` |
| TypeScript | `"extends": "dev-kit/tsconfig/node"` in `tsconfig.json` |
| Prettier | `"prettier": "dev-kit/prettier"` in `package.json` |
| a rule | `@node_modules/dev-kit/rules/typescript.md` in `CLAUDE.md` |
| the run skeleton | `source node_modules/dev-kit/sh/lib.sh` in `./run` |
| ignore files | copied once — see below |

The first two rows are the same module through two channels; a project writes one of them.
Every row below them is identical either way, which is the property that makes the fallback a
fallback rather than a fork.

Four of the seven use a mechanism the tool already has. That is deliberate: an installer script
that copied files around would have to be written, documented, kept working, and given an
update command, and every one of those is a thing that can rot.

### The `.npmrc` line is the cost of an unscoped name

A scoped package can be routed to a private registry by its scope alone —
`@scope:registry=…` — leaving every other dependency on the public registry. An unscoped name
has no such hook: npm routes by scope or not at all, so a consumer of `dev-kit` sets
`registry=` for the whole project and every install it makes flows through the private
registry.

This is a smaller cost than it reads as, because a private registry worth running proxies the
public one upstream, which is the arrangement such a registry is built for. It is recorded
because it is the one place where the name below has a price, and the price is paid by every
consumer rather than by this repository.

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
import path — `@node_modules/@scope/dev-kit/rules/typescript.md` — which is unusual enough to
be worth a probe rather than an assumption. A throwaway fixture with two sentinel strings, one
behind a scoped path and one behind an unscoped path, was read back correctly in a print-mode
session. Both resolve. The amendment below takes the unscoped path, so the probe now decides
nothing; it is kept because it is the reason nobody has to re-run it if a scope ever returns.

### The package name

**Decided 2026-09-08.** The package keeps a personal scope, `@vanyukevich/dev-kit`. Dropping
it was considered under the rule in `rules/writing.md` — an unscoped `dev-kit` would remove a
personal name from every specifier — and rejected because the same name is unavoidable in
`github:<account>/dev-kit`, which npm needs verbatim to clone: dropping the scope would
shorten the import while leaving the install line unchanged. A name a tool requires is
load-bearing, which is exactly the exception that rule carves out.

**Amended 2026-09-23. The package is `dev-kit`, unscoped.** The argument above depended on
the git specifier being the only way in. Once a private registry is the preferred channel,
the install line is `"dev-kit": "^1.0.0"` and carries no URL, so the account name is no longer
unavoidable — it survives only in the fallback row of §4's table. The exception in
`rules/writing.md` stops applying the moment the name stops being required, and what is left
is a personal name in every import path of three projects, which is what that rule exists to
remove.

**The name is taken on the public registry, and that is accepted.** `dev-kit` resolves there
to an abandoned Angular 2 package, last published at `1.0.0-beta2`. The consequence is
specific: a machine that runs `npm install dev-kit` *by name* against a registry that is not
the private one installs a stranger's package instead of failing. That is a worse failure than
a 404, and it is accepted for two reasons. The situation requires a consumer with no `.npmrc`
and no git specifier, which no project here has; and the alternative does not actually fix it.

There is one accidental benefit, noted but not relied upon: because the name belongs to
somebody else upstream, an unthinking `npm publish` against the public registry cannot
succeed. It fails with a 403 rather than putting these conventions on the open internet. A
stranger's ownership is not an access control and the build plan configures the registry
explicitly regardless, but the accident runs in the safe direction.

A scope only protects a name if it is owned, and owning one means claiming it publicly — which
§1 rules out. An *unclaimed* scope such as `@kit` reads as safe today and expires the moment
somebody else claims it, at which point the same silent-wrong-package failure returns, later
and harder to spot. A guarantee that can be revoked by a stranger is not a guarantee, and
paying for it in every specifier is paying twice.

**The signal to revisit** is a consumer outside this author's control — a contractor's laptop,
a shared runner, anything where the `.npmrc` is not guaranteed. At that point buy the name
properly by claiming a scope, and change `package.json`, the `.npmrc` line and the `extends`
strings. Nothing else in the kit depends on the name.

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

The scenarios themselves stay in each project: one `run` is 511 lines and the other 358,
because they start different things; only the frame is common.

---

## 5. What the rules contain, and what stays behind

The rules are **extracted**, not copied. The older project's `docs/conventions.md` is titled
"Engine-wide conventions" and is exactly that: a mix of portable rules and engine domain
knowledge.

| Source section | Destination |
| -------------- | ----------- |
| API conventions — error shape, `additionalProperties: false` | `rules/http.md` |
| Technology stack | `rules/typescript.md`, `rules/testing.md` |
| Code layout | `rules/layout.md` |
| Testing conventions | `rules/testing.md` |
| Vocabulary, Time and date, Concurrency, Deliberate limitations | **stay in the older project** |

From the newer project's `CONTRIBUTING.md`: the TypeScript compiler settings and the NodeNext
`.js` import rule join `rules/typescript.md`; Conventional Commits and the commit-splitting
guidance become `rules/commits.md`; the spec / plan / `architecture.md` discipline becomes
`rules/documentation.md`.

### One rule is written, not extracted

`rules/writing.md` has no source document. It states that a document refers to other projects,
people and accounts by their **role** rather than their name, and names something only when the
name is load-bearing — a package that must be installed, a file that must be opened, a command
that must run.

It was stated twice before it was written down. The unbuilt project's design record was edited
on 2026-09-05 to replace four named sibling applications with "the reference application", and
on 2026-09-08 the first draft of this spec was rejected for the same reason. A preference
corrected twice is a convention nobody had written down, which is exactly what this repository
is for.

The rule governs names, not dates: this record is dated throughout on purpose, because a
decision record is a statement about a moment.

Each file stays small and single-topic, because declining a rule should be deleting a line
rather than editing a paragraph.

### Consolidating one rule settled a conflict that was invisible

`rules/commits.md` had to state whether a commit message may carry a body and a
`Co-Authored-By` trailer. The newer project's `CONTRIBUTING.md` forbids both — "The
subject line is the whole message" — while the agent harness used to write these
projects requires the trailer. The two cannot both hold, and the conflict went unnoticed
while each project answered it separately.

**The subject line is the whole message. No body, no footers, no `Co-Authored-By` trailer.**
The existing rule wins, and it now binds every consumer including the agents: reasoning that
outlives a commit belongs in `docs/architecture.md` or a spec, where someone will find it, and
a change that seems to need a paragraph is a change that wants splitting.

This is the argument for the kit in miniature. The rule was stated in one project, restated in
another, and quietly contradicted in a third; nobody could see the disagreement because no
file held both halves. One shared rule made it a decision instead of a drift.

---

## 6. Versioning

One version number, in `package.json`, expressed twice: a registry consumer writes a semver
range, a git consumer pins the tag cut from the same commit. Every release is both published
and tagged, or the two channels drift and the fallback stops being equivalent.

**Decided 2026-09-08, and still standing.** A project pins `#v1` and updating is a ref bump in
one project at a time. The unbuilt project can move to `#v2` while the newer one stays on
`#v1`, which matters because a convention change that is right for a new project is not
automatically worth a sweep through an old one. Deliberate updates are the point, not a
limitation: a shared configuration that changes underneath a project without being asked is
how a shared configuration becomes something people stop trusting.

**What the registry changes, 2026-09-23.** A range such as `^1.0.0` does let patch and minor
releases arrive without being asked, which is the thing the paragraph above argues against.
The two are reconciled by what a version number is allowed to mean here: a convention change
that a project might reasonably decline is a **major** version, however small the diff. Fixing
a typo in a rule is a patch; changing what the rule requires is a major. Majors are what the
paragraph above is protecting, and a range never crosses one.

A project that wants none of this writes an exact version or the git tag and takes nothing it
did not ask for.

---

## 7. What was deliberately left out

**A Claude Code plugin.** Deferred, not rejected. The kit carries no skills, agents, slash
commands or hooks today, and a marketplace exists to distribute exactly those. When there is a
first one, `plugins/` and `.claude-plugin/marketplace.json` drop in beside `package.json`
without restructuring anything, and a consuming project adds `extraKnownMarketplaces` to its
`.claude/settings.json`. Building the manifest before there is anything to put in it would be
scaffolding for its own sake.

**`docker-compose.yml`.** 101 lines in the older project, 19 in the newer. What they share
is the idea of a Postgres service, which is not worth a module.

**A project generator.** §2.

**ESLint and CI workflows.** Neither project has them today. A shared configuration for a tool
nobody uses is a guess about the future.

---

## 8. Consequences for the three existing projects

The unbuilt project has, by definition, not been built. Its implementation plan has a first
task that hand-writes `tsconfig.base.json`, `.prettierrc`, the `run` script and a
`CONTRIBUTING.md` restating conventions. Most of that becomes taking the dependency. **That
plan needs revising once this repository exists** — a separate decision, recorded here so it
is not forgotten.

Both built projects are running, and neither is migrated as part of building this. They
adopt modules one at a time, when something in one of them is being changed anyway. The
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
   the tag is what §6's pin refers to — until it exists no project can depend on this. The
   registry channel is documented in the same step but need not be exercised until a registry
   exists; §6 requires only that a release which *is* published is tagged from the same commit.

The first consumer is whichever project is touched next. If that is the unbuilt one, step 4 is
followed by revising its Slice 1 plan per §8.
