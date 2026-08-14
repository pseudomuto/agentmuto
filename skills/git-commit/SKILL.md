---
name: git-commit
description: Use when creating or amending a git commit.
allowed-tools: AskUserQuestion Bash(git add *) Bash(git commit *) Bash(git diff *) Bash(git status *)
---

# Git Commit with Conventional Commits

## Overview

Create standardized, semantic git commits using the Conventional Commits specification. Analyze the actual diff to
determine appropriate type, scope, and message.

You can find the spec here: <https://www.conventionalcommits.org/en/v1.0.0>

## Project Conventions Win

The types, scopes, and limits below are defaults. Where a project states its own, follow the project and ignore the
defaults here. Check in this order and stop at the first that answers:

1. `CLAUDE.md` or `AGENTS.md`, which are already in context. Projects often state allowed types and scopes there.
2. A commit linter config such as `committed.toml`, `commitlint.config.*`, or `.gitmessage`, when the above is silent.
3. `git log --oneline -20`, which is read-only and shows what the project actually does.

Expect projects to allow fewer types than the table below, cap the subject at a different length, or restrict scopes to
a fixed list. Their `commit-msg` hook rejects anything that disagrees, so their rules are the ones that matter.

## Conventional Commit Format

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

- The first line of a commit is referenced here as the _subject_.
- While optional in the spec, always include a body (see notes below).

## Commit Types

| Type       | Purpose                        |
| ---------- | ------------------------------ |
| `feat`     | New feature                    |
| `fix`      | Bug fix                        |
| `docs`     | Documentation only             |
| `style`    | Formatting/style (no logic)    |
| `refactor` | Code refactor (no feature/fix) |
| `perf`     | Performance improvement        |
| `test`     | Add/update tests               |
| `build`    | Build system/dependencies      |
| `ci`       | CI/config changes              |
| `chore`    | Maintenance/misc               |
| `revert`   | Revert commit                  |

## Breaking Changes

```text
# Exclamation mark after type/scope
feat!: remove deprecated endpoint

# BREAKING CHANGE footer
feat: allow config to extend other configs

BREAKING CHANGE: `extends` key behavior changed
```

## Workflow

### 1. Analyze Diff

```bash
# If files are staged, use staged diff
git diff --staged

# If nothing staged, use working tree diff
git diff

# Also check status
git status --porcelain
```

### 2. Stage Files (if needed)

If nothing is staged or you want to group changes differently:

```bash
# Stage specific files
git add path/to/file1 path/to/file2

# Stage by pattern
git add *.test.*
git add src/components/*

# Interactive staging
git add -p
```

**Never commit secrets** (.env, .envrc, credentials.json, private keys). If unsure, ask.

### 3. Generate Commit Message

Analyze the diff to determine the subject:

- **Type**: What kind of change is this?
- **Scope**: What area/module is affected?
- **Description**: One-line summary of what changed (present tense, imperative mood)

When a patch/diff contains multiple things, ask before breaking up into multiple commits. The type/scope should focus on
the main purpose of the change.

### 4. Confirm Before Committing (only when it changes the outcome)

Do not confirm routinely, and do not confirm because you feel unsure. Confirm only when one of these observable
conditions holds:

- Two types both fit the diff and they carry different consequences under the repo's conventions.
- The change is breaking, so the subject takes `!` or a `BREAKING CHANGE` footer.
- You are amending, which rewrites a commit that already exists.

When one holds, use `AskUserQuestion` and make the options the competing types, each labelled with its consequence, for
example `feat(skills): cuts a minor release` against `chore(skills): cuts nothing`. Put your recommendation first.

Skip confirmation and commit directly when `AskUserQuestion` is not among your available tools, or when the user already
supplied the subject line. Non-interactive sessions and subagents do not have that tool, so its absence is the signal
that there is nobody to ask.

### 5. Execute Commit

```bash
# Single line
git commit -m "<type>[scope]: <description>"

# Multi-line with body/footer
git commit -m "$(cat <<'EOF'
<type>[scope]: <description>

<body>

<optional footer>
EOF
)"
```

As mentioned above, always include at least a subject and body.

## Best Practices

- Present tense: "add" not "added"
- Imperative mood: "fix bug" not "fixes bug"
- Reference issues: `Fixes #123`, `Refs #456`
- Keep the subject to at most 72 characters so GitHub won't truncate it.
- Always omit co-author or mentioning Claude. This doesn't provide any meaningful info.
- Provide a clear and concise description in the commit body outlining the problem and the proposed solution.
- Assume reviewer is intelligent, well intentioned, and knows the codebase, but potentially lacks context.
- Avoid statistics unless relevant (e.g. code coverage/LoC/number of tests/etc.), fine if committing benchmarks for
  example.
- Avoid describing the actual lines of code (e.g. pkg/internal gains a 'Name' method on line 45).
- Never include details that were fixed in revisions in the same branch, since the reviewer wouldn't have seen the
  original issues.

## Git Safety Protocol

- NEVER update git config
- NEVER run destructive commands (--force, hard reset) without explicit request
- NEVER skip hooks (--no-verify) unless user asks
- NEVER force push to main/master
- If commit fails due to hooks, fix and create NEW commit (don't amend)
- After successful commit, analyze the diff for anything that seems like a token, secret, or otherwise sensitive value
  and let the user know about it.
