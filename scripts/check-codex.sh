#!/usr/bin/env bash
# Verify Codex ingests this repo's Claude Code manifests and delivers the
# skills they point at.
#
# Codex looks for `.agents/plugins/marketplace.json` and
# `.codex-plugin/plugin.json` first, then falls back to the `.claude-plugin`
# manifests already here. That fallback is the only reason one set of manifests
# serves both harnesses, and nothing else checks it: `claude plugin validate`
# proves only that Claude Code is happy, and the release job rewrites both
# manifests with jq on the way to publishing.
#
# Everything runs against a throwaway CODEX_HOME, so this neither reads nor
# writes the caller's real Codex config. It needs no auth and no network, since
# a local marketplace resolves straight off disk.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for cmd in codex jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    printf 'error: %s not found on PATH. Run through mise: mise run validate\n' "$cmd" >&2
    exit 1
  fi
done

plugin="$(jq -r '.name' "$ROOT/.claude-plugin/plugin.json")"
version="$(jq -r '.version' "$ROOT/.claude-plugin/plugin.json")"
marketplace="$(jq -r '.name' "$ROOT/.claude-plugin/marketplace.json")"
plugin_id="$plugin@$marketplace"

# Every shipped skill has to survive the round trip, so collect them from disk
# rather than naming them here. A new skill is covered the moment it exists.
shopt -s nullglob
names=()
for dir in "$ROOT"/skills/*/; do
  names+=("$(basename "$dir")")
done

if [ "${#names[@]}" -eq 0 ]; then
  printf 'error: no skills under %s/skills, nothing to verify\n' "$ROOT" >&2
  exit 1
fi

CODEX_HOME="$(mktemp -d)"
# A neutral working directory. Run this from the repo and Codex would also load
# `.codex/skills`, so a project skill could stand in for a shipped one and mask
# a plugin that delivers nothing.
workdir="$(mktemp -d)"
trap 'rm -rf "$CODEX_HOME" "$workdir"' EXIT
export CODEX_HOME

codex plugin marketplace add "$ROOT" >/dev/null
codex plugin add "$plugin_id" >/dev/null

# Codex takes the version from plugin.json, the same file read above, so this
# comparison cannot catch two manifests disagreeing. What it catches is Codex
# not finding or not parsing plugin.json at all, which leaves the version empty
# and is exactly how the fallback would fail. Disagreement between the marketplace
# entry and plugin.json is already a `claude plugin validate --strict` error.
reported="$(codex plugin list --json | jq -r --arg id "$plugin_id" '
  .installed[] | select(.pluginId == $id) | .version
')"

if [ "$reported" != "$version" ]; then
  printf 'error: codex read no usable version for %s, got "%s" and expected "%s"\n' \
    "$plugin_id" "$reported" "$version" >&2
  exit 1
fi

# Parsing a manifest is not the same as delivering what it points at, so assert
# against the prompt the model actually receives.
prompt="$(cd "$workdir" && codex debug prompt-input)"

status=0
for name in "${names[@]}"; do
  if ! printf '%s' "$prompt" | grep -qF "$plugin:$name"; then
    printf 'error: codex does not surface skill %s:%s\n' "$plugin" "$name" >&2
    status=1
  fi
done

if [ "$status" -eq 0 ]; then
  printf 'ok: codex ingests the manifests and surfaces %d skill(s) at v%s\n' \
    "${#names[@]}" "$version"
fi

exit "$status"
