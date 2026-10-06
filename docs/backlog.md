# Backlog

What is known to be wrong and not yet fixed, newest first. The rule for this file is the kit's
own [`common/rules/backlog.md`](../common/rules/backlog.md): one entry per finding, deleted by
the commit that fixes it.

## Installing the kit over git needs credentials the moment the repository is private

- Where: `README.md`, "Install", the `github:AlexeyVanyukevich/dev-kit#vX.Y.Z` form; the
  bootstrap line every consumer's `./run` carries
- Found: 2026-10-06, while adding `with_github_token`
- Problem: the git form is fetched by git over HTTPS, which needs no credential while the
  repository is public. Made private, that fetch fails on a fresh clone before `lib.sh` exists,
  so `with_github_token` cannot help, and the token the bootstrap line passes goes to npm's
  registry authentication, not to git. Locally, `gh auth setup-git` lets git use the GitHub
  CLI's login. In GitHub Actions the workflow's token reaches only its own repository, so a
  consumer's workflow would need a token with access to this one and a git `url.insteadOf`
  rewrite that applies it.
- Impact: making the repository private breaks every consumer's first `./run` and its CI with a
  git authentication error that does not mention the kit. Nothing is affected while it is
  public.
