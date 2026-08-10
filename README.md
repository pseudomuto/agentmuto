# agentmuto

Agent Muto. Personal coding agent skills, deep cover in your terminal.

## Install

```text
/plugin marketplace add pseudomuto/agentmuto
/plugin install muto@agentmuto
```

## Update

```text
/plugin update muto@agentmuto
```

There is no auto-update. Updating is always an explicit command.

To get it on every machine automatically, add it to your dotfiles-managed `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "agentmuto": { "source": { "source": "github", "repo": "pseudomuto/agentmuto" } }
  },
  "enabledPlugins": { "muto@agentmuto": true }
}
```

## Skills

| Skill                   | Purpose                                         |
| ----------------------- | ----------------------------------------------- |
| `muto:authoring-skills` | Conventions and release mechanics for this repo |

## Development

See [`skills/authoring-skills/SKILL.md`](skills/authoring-skills/SKILL.md) for this repo's conventions and the process
for adding or releasing a skill.

Requires [mise](https://mise.jdx.dev). All tools are pinned in `mise.toml`.

Run `mise trust` once in a fresh clone, before anything below. Until the config is trusted mise refuses to run at all,
so `mise install` exits with `Config files ... are not trusted` and installs nothing, hooks included.

```bash
mise install          # install pinned tools, and wire up git hooks
mise run validate     # manifests + skill spec conformance (offline)
```

Commits follow [Conventional Commits](https://www.conventionalcommits.org). A `commit-msg` hook rejects anything else,
and releases are cut automatically from the log, so the commit message decides the version.

Note: `mise.toml` pins the `claude` CLI, so inside this repository mise's copy shadows the one on your PATH. That is
deliberate, it makes local runs identical to CI.
