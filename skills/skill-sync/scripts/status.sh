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

# Enumerate repo skills as "name<TAB>path". A directory directly under skills/
# is either a skill (has SKILL.md) or a group of skills (e.g. workflows/).
repo_skills() {
  for dir in "$REPO_SKILLS"/*/; do
    [ -d "$dir" ] || continue
    if [ -f "$dir/SKILL.md" ]; then
      printf '%s\t%s\n' "$(basename "$dir")" "${dir%/}"
    else
      for sub in "$dir"*/; do
        [ -f "$sub/SKILL.md" ] || continue
        printf '%s\t%s\n' "$(basename "$sub")" "${sub%/}"
      done
    fi
  done
}

repo_skill_path() {
  repo_skills | awk -F'\t' -v n="$1" '$1==n { print $2; exit }'
}

printf 'name\tinstalled\trepo\tstatus\n'

for dir in "$INSTALLED"/*/; do
  [ -d "$dir" ] || continue
  name="$(basename "$dir")"
  repo_skill="$(repo_skill_path "$name")"
  repo_ver="$(read_version "$repo_skill/SKILL.md")"

  if [ -z "$repo_skill" ] || [ ! -d "$repo_skill" ]; then
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

while IFS=$'\t' read -r name dir; do
  [ -n "$name" ] || continue
  [ -e "$INSTALLED/$name" ] && continue
  printf '%s\t—\t%s\tnot installed\n' "$name" "$(read_version "$dir/SKILL.md")"
done < <(repo_skills)
