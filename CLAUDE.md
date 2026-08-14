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

YAML files use `.yaml`, not `.yml`. The sole exception is `.github/dependabot.yml`, because GitHub reads only that exact
filename.

GitHub Actions are pinned by commit SHA with the version in a trailing comment, never by a mutable tag like `@v7`.
Dependabot updates both parts together.
