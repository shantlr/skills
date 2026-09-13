#!/usr/bin/env bash
# Compare skills installed in ~/.claude/skills against this repo.
# Output: TSV -> name <TAB> installed <TAB> repo <TAB> status
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
REPO_SKILLS="$REPO_ROOT/skills"
INSTALLED="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

read_version() {
  # first `version:` line inside the leading frontmatter block
  [ -f "$1" ] || { echo "—"; return; }
  awk '
    NR==1 && $0!="---" { exit }
    NR>1 && $0=="---"  { exit }
    /^version:[[:space:]]*/ { sub(/^version:[[:space:]]*/,""); gsub(/["\r]/,""); print; exit }
  ' "$1" | grep . || echo "—"
}

# 1 if $1 < $2 (semver), else 0
semver_lt() {
  [ "$1" = "$2" ] && return 1
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)" = "$1" ]
}

printf 'name\tinstalled\trepo\tstatus\n'

for dir in "$INSTALLED"/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  repo_skill="$REPO_SKILLS/$name"
  repo_ver="$(read_version "$repo_skill/SKILL.md")"

  if [ ! -d "$repo_skill" ]; then
    printf '%s\t%s\t—\texternal\n' "$name" "$(read_version "$dir/SKILL.md")"
    continue
  fi

  # symlink pointing back into this repo -> always current
  if [ -L "${dir%/}" ] && [ "$(cd "$(readlink "${dir%/}")" 2>/dev/null && pwd)" = "$repo_skill" ]; then
    printf '%s\t→repo\t%s\tlinked\n' "$name" "$repo_ver"
    continue
  fi

  inst_ver="$(read_version "$dir/SKILL.md")"
  if [ "$inst_ver" = "$repo_ver" ]; then
    if diff -rq "$repo_skill" "${dir%/}" >/dev/null 2>&1; then
      status="ok"
    else
      status="drifted"   # same version, different content — do NOT overwrite blindly
    fi
  elif semver_lt "$inst_ver" "$repo_ver"; then
    status="outdated"
  else
    status="ahead"
  fi
  printf '%s\t%s\t%s\t%s\n' "$name" "$inst_ver" "$repo_ver" "$status"
done

for dir in "$REPO_SKILLS"/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  [ -e "$INSTALLED/$name" ] && continue
  printf '%s\t—\t%s\tnot installed\n' "$name" "$(read_version "$dir/SKILL.md")"
done
