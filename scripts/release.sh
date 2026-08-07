#!/usr/bin/env bash
# Cut a release: bump both manifests, validate, commit, tag, push.
#
# The bump type is an explicit argument rather than inferred from commit
# messages, because this repo does not use conventional commits.
#
# -E (errtrace) is required, not optional: the ERR trap below guards
# write_version, which is a shell function, and bash does not propagate
# an ERR trap into a function's failures unless errtrace is set. Verified
# empirically: without -E, a failing command inside a function does not
# trigger the trap even though set -e still exits the script.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# claude plugin tag creates {name}--v{version}. svu cannot read those tags
# with its default 'v' prefix, it errors with "invalid semantic version".
TAG_PREFIX="muto--v"
PLUGIN=".claude-plugin/plugin.json"
MARKETPLACE=".claude-plugin/marketplace.json"

bump="${1:-}"
case "$bump" in
  patch | minor | major) ;;
  *)
    printf 'usage: %s <patch|minor|major>\n' "$(basename "$0")" >&2
    exit 2
    ;;
esac

if [ -n "$(git status --porcelain)" ]; then
  printf 'error: working tree is dirty, commit or stash first\n' >&2
  exit 1
fi

branch="$(git branch --show-current)"
if [ "$branch" != "main" ]; then
  printf 'error: releases are cut from main, currently on %s\n' "$branch" >&2
  exit 1
fi

if ! git remote get-url origin >/dev/null 2>&1; then
  printf 'error: no origin remote. Create the repository first: gh repo create pseudomuto/agentmuto --public --source=. --remote=origin\n' >&2
  exit 1
fi

raw="$(svu "$bump" --tag.prefix "$TAG_PREFIX")"
version="${raw#"$TAG_PREFIX"}"

if [ -z "$version" ] || [ "$version" = "$raw" ]; then
  printf 'error: could not derive a version from svu output %s\n' "$raw" >&2
  exit 1
fi

printf 'releasing %s\n' "$version"

write_version() {
  local file="$1" path="$2" tmp
  tmp="$(mktemp)"
  jq --arg v "$version" "$path = \$v" "$file" > "$tmp"
  mv "$tmp" "$file"
}

# If anything fails between the first write and the commit, the manifests
# would otherwise be left half-bumped and uncommitted. The next run's
# dirty-tree guard would catch that, but its message does not say the dirt
# is a half-finished release, so restore the manifests here instead.
#
# Must restore from HEAD, not just "git checkout -- <file>". Once git add
# has run, the index already holds the bumped content, so a plain checkout
# restores from that index and is a no-op. "git checkout HEAD -- <file>"
# resets both the index and the working tree, which is what covers a
# failure at git add or git commit, e.g. a gpg signing failure.
restore_manifests() {
  printf 'error: release aborted, manifests restored\n' >&2
  git checkout HEAD -- "$PLUGIN" "$MARKETPLACE"
}

trap restore_manifests ERR

write_version "$PLUGIN" '.version'
write_version "$MARKETPLACE" '.plugins[0].version'

# Fail before the commit if either write produced something invalid.
claude plugin validate --strict .
./scripts/check-skills.sh

git add "$PLUGIN" "$MARKETPLACE"
git commit -m "release: v$version"

# Once the bump is committed, restoring the working tree accomplishes
# nothing, and a later push or tag failure should not print a misleading
# "manifests restored" message. Disarming the trap entirely would leave a
# push or tag failure to print raw git output with no indication that a
# release commit now sits unpublished on main, so replace it instead of
# dropping it: state the real situation and how to recover from it.
trap 'printf "error: %s is committed locally but not published. Recover with: git push origin main && claude plugin tag --push -m \"Release %%s\"\n" "$version" >&2' ERR

# claude plugin tag only pushes the tag, never the branch. Marketplace
# caches track origin/main, not tags, so the tag must never point at a
# commit the remote does not have yet, or the release stays invisible to
# consumers even though the tag exists.
git push origin main

# Revalidates that the manifests agree, then tags and pushes.
claude plugin tag --push -m "Release %s"

printf 'released %s\n' "$version"
