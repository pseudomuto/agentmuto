---
name: authoring-skills
description: |
  Conventions and validation rules for authoring Agent Skills in the agentmuto repo. Use when adding, editing,
  validating, or releasing a skill, or when writing SKILL.md frontmatter.
---

# Authoring agentmuto Skills

Skills in this repo follow the Agent Skills specification at <https://agentskills.io/specification.md>. That document is
the authority on format; this one covers the parts of it worth knowing up front, plus what is specific to agentmuto.

For general skill-writing craft, use `superpowers:writing-skills`.

## Layout

A skill is a directory under `skills/` containing at minimum a `SKILL.md`:

```text
skills/<name>/
├── SKILL.md      # required: frontmatter plus instructions
├── scripts/      # optional: executable code the agent can run
├── references/   # optional: documentation loaded on demand
└── assets/       # optional: templates, schemas, images
```

Everything except `SKILL.md` is optional, and most skills need none of it.

## Frontmatter

`SKILL.md` opens with YAML frontmatter, then Markdown.

| Field           | Required | Constraints                                                                                                                    |
| --------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `name`          | Yes      | 1-64 chars. Lowercase `a-z`, `0-9`, and `-` only. No leading, trailing, or consecutive hyphens. Must match the directory name. |
| `description`   | Yes      | 1-1024 chars. What the skill does and when to use it.                                                                          |
| `license`       | No       | License name, or a reference to a bundled license file.                                                                        |
| `compatibility` | No       | Max 500 chars. Environment requirements. Most skills do not need it.                                                           |
| `metadata`      | No       | Map of string keys to string values.                                                                                           |
| `allowed-tools` | No       | Space-separated pre-approved tools. Experimental; support varies.                                                              |

Minimal:

```markdown
---
name: skill-name
description: What it does. Use when <triggers>.
---
```

### `name`

The spec requires `name` to match the parent directory. Get it wrong and the skill does not load, so this is the single
easiest thing to break.

Claude Code namespaces plugin skills as `plugin:skill`, so a skill here is invoked as `muto:<directory>`. Do not
prefix directory names with `muto`, that produces `muto:muto-thing`.

Use a verb phrase describing the activity: `authoring-skills`, not `skill-authoring-helper`.

### `description`

The description is the entire basis on which the skill gets selected, and it is loaded at startup for every installed
skill. It is both the trigger and a standing token cost, which pushes the same direction: specific and brief.

Say what the skill does and when to use it, and include the words someone would actually type.

- Good:
  `Extracts text and tables from PDFs, fills forms. Use when working with PDF documents or when the user mentions PDFs.`
- Bad: `Helps with PDFs.`

A skill that never triggers is indistinguishable from one that does not exist, and no validator catches that. Validation
proves a skill is well formed, never that it fires.

## Progressive disclosure

Agents load skills in tiers, so structure for it:

1. **Metadata**, about 100 tokens. `name` and `description`, loaded at startup for every skill.
2. **Instructions**, under 5000 tokens recommended. The whole `SKILL.md` body, loaded once the skill activates.
3. **Resources**, loaded only when needed. Files under `scripts/`, `references/`, and `assets/`.

Keep `SKILL.md` under 500 lines. Move detailed reference material into `references/` and link to it.

Reference other files by relative path from the skill root, one level deep:

```markdown
See [the reference guide](references/REFERENCE.md) for details.
```

Avoid deeply nested reference chains.

## Validation

```bash
mise run validate
```

That runs three things: `claude plugin validate --strict .` for the plugin and marketplace manifests, then
`scripts/check-skills.sh`, which walks every skill and calls `skills-ref validate` and `skills-ref read-properties` on
each.

`skills-ref` is the spec's reference implementation, so conformance is checked against the spec rather than against
hand-rolled parsing. Both subcommands are required, because they miss different things:

| Case                          | `validate` | `read-properties` |
| ----------------------------- | ---------- | ----------------- |
| name does not match directory | fails      | passes            |
| empty or blank `description`  | passes     | fails             |

`validate` covers the naming rules, the 1024-character ceiling, a missing `SKILL.md`, and unterminated frontmatter.
`read-properties` is what enforces the spec's lower bound of one character on `description`.

`claude plugin validate` never reads `SKILL.md` at all, which is why any of this is necessary.

Validation runs in CI on every push to `main` and every pull request targeting `main`. A feature branch pushed elsewhere
gets no CI run until it is opened as a pull request.

## Releasing

Separate and manual:

```bash
mise run release patch    # or minor, or major
```

That bumps both manifests, revalidates, commits, pushes `main`, and pushes a `muto--vX.Y.Z` tag. Consumers pick it up
with `/plugin update muto@agentmuto`.

Pushing `main` is the step that matters. Marketplace caches are git clones tracking `origin/main` and they fetch no
tags, so consumers resolve the version from the branch. A release that is committed locally but never pushed reaches
nobody, even though the tag exists. There is no auto-update, so updating is always an explicit command.

## Adding a skill, end to end

1. `mkdir -p skills/<name>`
2. Write `skills/<name>/SKILL.md` with `name: <name>` matching the directory.
3. `mise run validate`
4. Add a row to the skills table in `README.md`.
5. Commit with a `skills:` scope prefix.
6. Open a pull request; CI runs validation.
7. After merge, `mise run release <patch|minor|major>` to make it installable. The bump type is a judgment call: a new
   skill is typically `minor`, a fix to an existing one `patch`.
