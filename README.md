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

```bash
mise install          # install pinned tools
mise run validate     # manifests + skill spec conformance (offline)
mise run release minor
```

Note: `mise.toml` pins the `claude` CLI, so inside this repository mise's copy shadows the one on your PATH. That is
deliberate, it makes local runs identical to CI.
