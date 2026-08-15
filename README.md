# agentmuto

My coding agent skills, packaged so I can install them on any machine. They install in both Claude Code and Codex from
the same manifests. Public because that is the easiest way to distribute them, not because they are advice.

## Skills

| Skill              | Use it when                       |
| ------------------ | --------------------------------- |
| `muto:git-commit`  | Creating or amending a git commit |

One so far. `agents/`, `commands/`, and `hooks/` are empty placeholders for whenever there is something to put in
them.

## Install

Claude Code:

```text
/plugin marketplace add pseudomuto/agentmuto
/plugin install muto@agentmuto
```

To get it on every machine instead of one, declare it in dotfiles-managed `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "agentmuto": { "source": { "source": "github", "repo": "pseudomuto/agentmuto" } }
  },
  "enabledPlugins": { "muto@agentmuto": true }
}
```

Codex:

```bash
codex plugin marketplace add pseudomuto/agentmuto
codex plugin add muto@agentmuto
```

Codex needs nothing else from this repo. It looks for its own `.agents/plugins/marketplace.json` and
`.codex-plugin/plugin.json` first, then falls back to the `.claude-plugin/` manifests that are already here, so both
installers read one set of files. Skills keep the same `muto:` prefix on either side.

## Update

```text
/plugin update muto@agentmuto
```

```bash
codex plugin marketplace upgrade agentmuto
```

Claude Code has no auto-update for plugins, so pulling a new version is always this explicit command. The Codex
equivalent refreshes the marketplace snapshot it cloned.

Publishing a new version is the opposite, entirely automatic. Every push to `main` whose commits imply a version bump
rewrites the manifests, commits, and tags. Marketplace caches are clones tracking `origin/main` and fetch no tags, so
the branch is what consumers actually resolve against and the tag is only a record.

## Development

See [`.claude/skills/authoring-skills/SKILL.md`](.claude/skills/authoring-skills/SKILL.md) for this repo's conventions
and the process for adding or releasing a skill. It is a project skill rather than a shipped one, so it loads
automatically when you work in this repo and is not part of the plugin.

Requires [mise](https://mise.jdx.dev). All tools are pinned in `mise.toml`.

Run `mise trust` once in a fresh clone, before anything below. Until the config is trusted mise refuses to run at all,
so `mise install` exits with `Config files ... are not trusted` and installs nothing, hooks included.

```bash
mise install          # install pinned tools, and wire up git hooks
mise run lint         # markdownlint + manifests + skill spec conformance
mise run format       # fix what markdownlint can fix on its own
```

Commits follow [Conventional Commits](https://www.conventionalcommits.org), because the commit type is what decides
the next version. Two hooks come from `mise install`: `commit-msg` rejects anything that does not parse, and
`pre-push` runs `mise run lint`, the same gate CI runs. The pre-push hook skips itself when `CI` is set so it never
fires on the release job's own push.

Both are worth having rather than leaving to CI, because the release job waits on validation. A stray over-long line
in a markdown file is enough to hold up a release.

Note: `mise.toml` pins the `claude` CLI, so inside this repository mise's copy shadows the one on your PATH. That is
deliberate, it makes local runs identical to CI.
