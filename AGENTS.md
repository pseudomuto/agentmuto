# agentmuto

## Commits

Conventional Commits, enforced by a `commit-msg` hook and re-checked in CI.

Types: `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `perf`, `test`, `ci`. Scopes (optional): `skills`, `plugin`,
`scripts`, `ci`, `mise`, `readme`, `release`.

Releases are automatic on every push to `main`, with the version inferred from the log, so the type is a release
decision rather than a label:

- Markdown under `skills/` is the product. Changing it is `feat` or `fix`, never `docs`.
- `docs` is for files consumers never install, such as `README.md`.
- Only `feat` and `fix` cut a release. `chore`, `docs`, `ci`, `style`, `refactor`, `perf`, and `test` cut none, so a
  real rewrite of a shipped file must not be typed `refactor`.

`release` is a scope reserved for the CI release commit. Do not use it by hand.

See [committed.toml](committed.toml) for full details.

## Conventions

YAML files use `.yaml`, not `.yml`.

GitHub Actions are pinned by commit SHA with the version in a trailing comment, never by a mutable tag like `@v7`.
Dependabot updates both parts together.

## Two harnesses

Skills here work in both Claude Code and Codex, which agree on the Agent Skills specification and disagree on
everything around it. Three places encode that:

- This file is `AGENTS.md`, not `CLAUDE.md`. Claude Code reads either; Codex reads only `AGENTS.md`.
- `.codex/skills` is a symlink to `.claude/skills`. Each harness finds project skills only under its own directory,
  and neither reads the other's, so one canonical tree plus a symlink is what keeps them from drifting. Add project
  skills to `.claude/skills/` and they appear in both.
- Shipped skills need nothing. Codex reads `.claude-plugin/marketplace.json` and `.claude-plugin/plugin.json` as
  fallbacks when its own `.agents/plugins/` and `.codex-plugin/` manifests are absent, so a single set of manifests
  serves both installers.

Write skill bodies so they degrade rather than break. `git-commit` names `AskUserQuestion` but tells the agent to skip
confirmation when that tool is absent, which is what makes it correct on a harness that has no such tool.
