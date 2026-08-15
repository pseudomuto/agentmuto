#!/usr/bin/env bash
# Validate every skill under skills/ against the Agent Skills specification
# (https://agentskills.io/specification.md).
#
# `claude plugin validate` does not read SKILL.md at all, so something has to.
# That something is skills-ref, the spec's reference implementation, rather
# than hand-rolled YAML parsing.
#
# Both subcommands are needed. They are complementary, verified against
# fixtures:
#
#   case                        validate   read-properties
#   name/directory mismatch     fails      passes
#   empty or blank description  passes     fails
#
# `validate` covers naming rules, the 1024-character description ceiling, a
# missing SKILL.md, and unterminated frontmatter. `read-properties` is what
# enforces the spec's lower bound of one character on description. Running
# only one of them leaves a real gap.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="${1:-$ROOT/skills}"

status=0

if ! command -v skills-ref >/dev/null 2>&1; then
  printf 'error: skills-ref not found on PATH. Run through mise: mise run validate\n' >&2
  exit 1
fi

# A skill tree can be a symlink, which is how `.codex/skills` points Codex at
# `.claude/skills`. A broken link there passes both checks below without ever
# being reported: `-d` is false for a dangling symlink, so the tree takes the
# "no skills directory" exit, and the `*/` glob matches directories only, so a
# dangling entry inside a tree matches nothing and leaves `status` at 0. Either
# way validation claims success having validated nothing. Reject broken links
# explicitly instead.
if [ -L "$SKILLS_DIR" ] && [ ! -e "$SKILLS_DIR" ]; then
  printf 'error: dangling symlink: %s\n' "$SKILLS_DIR" >&2
  exit 1
fi

if [ ! -d "$SKILLS_DIR" ]; then
  printf 'ok: no skills directory at %s\n' "$SKILLS_DIR"
  exit 0
fi

shopt -s nullglob
for entry in "$SKILLS_DIR"/*; do
  if [ -L "$entry" ] && [ ! -e "$entry" ]; then
    printf 'error: dangling symlink: %s\n' "$entry" >&2
    status=1
  fi
done

for dir in "$SKILLS_DIR"/*/; do
  skills-ref validate "$dir" || status=1
  skills-ref read-properties "$dir" >/dev/null || status=1
done

if [ "$status" -eq 0 ]; then
  printf 'ok: all skills valid\n'
fi

exit "$status"
