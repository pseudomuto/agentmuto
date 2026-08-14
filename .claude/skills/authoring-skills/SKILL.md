---
name: authoring-skills
description: >-
  Use when adding, editing, validating, or releasing a skill in the agentmuto repo, or when writing SKILL.md
  frontmatter.
---

# Authoring agentmuto Skills

Skills in this repo follow the Agent Skills specification at <https://agentskills.io/specification.md>. That document is
the authority on format; this one covers the parts of it worth knowing up front, plus what is specific to agentmuto.

For general skill-writing craft, use `superpowers:writing-skills`.

## Layout

A skill is a directory containing at minimum a `SKILL.md`:

```text
<name>/
├── SKILL.md      # required: frontmatter plus instructions
├── scripts/      # optional: executable code the agent can run
├── references/   # optional: documentation loaded on demand
└── assets/       # optional: templates, schemas, images
```

Everything except `SKILL.md` is optional, and most skills need none of it.

### Which directory

| Location          | Loads when                         | Use for                                        |
| ----------------- | ---------------------------------- | ---------------------------------------------- |
| `skills/`         | the plugin is installed, anywhere  | anything consumers should get                  |
| `.claude/skills/` | the working directory is this repo | tooling only useful while working on this repo |

A skill that talks about `mise run validate`, this repo's layout, or its release process cannot do anything useful on
a consumer's machine, so it belongs in `.claude/skills/` and costs them nothing. This skill lives there for exactly
that reason. Everything else goes in `skills/`.

Both trees are validated, and project skills are invoked by bare name with no plugin prefix.

## Frontmatter

`SKILL.md` opens with YAML frontmatter, then Markdown.

| Field           | Required | Constraints                                                                                                                    |
| --------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `name`          | Yes      | 1-64 chars. Lowercase `a-z`, `0-9`, and `-` only. No leading, trailing, or consecutive hyphens. Must match the directory name. |
| `description`   | Yes      | 1-1024 chars. When to use the skill.                                                                                           |
| `license`       | No       | License name, or a reference to a bundled license file.                                                                        |
| `compatibility` | No       | Max 500 chars. Environment requirements. Most skills do not need it.                                                           |
| `metadata`      | No       | Map of string keys to string values.                                                                                           |
| `allowed-tools` | No       | Space-separated tools the skill needs. See below.                                                                              |

Minimal:

```markdown
---
name: skill-name
description: Use when <triggers>.
---
```

### `name`

The spec requires `name` to match the parent directory. Get it wrong and the skill does not load, so this is the single
easiest thing to break.

Claude Code namespaces plugin skills as `plugin:skill`, so a skill under `skills/` is invoked as `muto:<directory>`. Do
not prefix directory names with `muto`, that produces `muto:muto-thing`. Skills under `.claude/skills/` get no prefix
and are invoked by directory name alone.

Use a verb phrase describing the activity: `authoring-skills`, not `skill-authoring-helper`.

### `description`

The description is the entire basis on which the skill gets selected, and it is loaded at startup for every installed
skill. It is both the trigger and a standing token cost, which pushes the same direction: specific and brief.

Say when to use it, and include the words someone would actually type.

- Good: `Use when working with PDF documents or when the user mentions PDFs.`
- Bad: `Helps with PDFs.`

A skill that never triggers is indistinguishable from one that does not exist, and no validator catches that. Validation
proves a skill is well formed, never that it fires.

### `allowed-tools`

Declare the tools the skill needs. Bash entries take permission-rule syntax with a trailing wildcard, and the
space-separated form is the one Claude Code's own permission dialog writes:

```text
allowed-tools: AskUserQuestion Bash(git add *) Bash(git commit *)
```

Declaring anything here makes invoking the skill permission-gated. The agent prompts once with `Execute skill: <name>`
before the body loads, which is the trade: an explicit tool contract costs one prompt per invocation.

Plan for the consequence. A non-interactive run has nobody to answer that prompt, so the invocation is denied and the
skill never loads at all. A skill that has to work headless, in CI or inside a subagent, must leave this field out.

Two things temper what the grants buy. Read-only commands never prompt anyway, including the read-only forms of `git`,
so listing them only documents intent. And a rule matches the command as written, so `git -C <path> status`, or two
commands joined with `&&`, still prompts despite `Bash(git status *)`.

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

That runs `claude plugin validate --strict .` for the plugin and marketplace manifests, then `scripts/check-skills.sh`
once per skill tree, `skills/` and `.claude/skills/`. The script walks every skill in the directory it is given and
calls `skills-ref validate` and `skills-ref read-properties` on each. It takes the directory as its first argument and
defaults to `skills/`, so a new tree needs its own line in the `validate` task or it goes unchecked.

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

Automatic. Every push to `main` runs CI, and if the commit log since the last tag implies a new version, CI bumps both
manifests, commits, pushes, and tags `muto--vX.Y.Z`.

The version comes from the commit messages, so the message is the release decision:

| Commit                                                     | Effect     |
| ---------------------------------------------------------- | ---------- |
| `fix(skills): ...`                                         | patch      |
| `feat(skills): ...`                                        | minor      |
| `feat(skills)!: ...`                                       | major      |
| `chore`, `docs`, `ci`, `style`, `refactor`, `perf`, `test` | no release |

That last row is the complete set of types that publish nothing, and it is the one to watch. Only `feat` and `fix` cut a
release, so `refactor(skills): ...` ships to nobody however much it changes. Markdown under `skills/` is the product,
not documentation, so a rewrite of a `SKILL.md` body is `feat` or `fix`. Reserve `docs` for files consumers never
install, like `README.md`.

Pushing `main` is the step that publishes. Marketplace caches are git clones tracking `origin/main` and they fetch no
tags, so consumers resolve the version from the branch and the tag is only a record. There is no auto-update, so
consumers still update with an explicit `/plugin update muto@agentmuto`.

## Adding a skill, end to end

1. Decide where it goes. `skills/` if consumers should get it, `.claude/skills/` if it only makes sense in this repo.
2. `mkdir -p <dir>/<name>`
3. Write `<dir>/<name>/SKILL.md` with `name: <name>` matching the directory.
4. `mise run validate`
5. For a shipped skill, add a row to the skills table in `README.md`. Project skills are not installable, so they do
   not belong in that table.
6. Commit with a conventional message. A shipped skill is `feat(skills): add <name>` or `fix(skills): ...` because it
   is the product. A project skill ships to nobody, so it takes a type that cuts no release, usually `chore(skills)`.
7. Open a pull request; CI validates the manifests, the skill frontmatter, and every commit message.
