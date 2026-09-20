#!/usr/bin/env bash
# Bring a project's existing flow scaffold up to date with this skill.
#
#   upgrade-flow.sh [--root <path>] [--docs-dir <name>] [--apply] [--diff]
#
# Compares every MACHINE-OWNED file in the project's docs tree against the copy
# this skill ships, and reports one of: same / differs / missing. Nothing the
# user wrote is ever read for content or touched — ARCHITECTURE.md, feature
# READMEs, records and guideline rules are the project's, not ours.
#
# Without --apply this is a read-only report. Exit code 0 always: "out of date"
# is information, not failure. (Use --check-style parsing of the report, or just
# read it.)
#
# --apply   write the updates:
#             * every `missing` file is created;
#             * every `differs` file in the TOOLING tier is overwritten —
#               scripts and templates are ours, and git holds the old copy;
#             * `differs` in the PROSE tier (docs/README.md, guidelines/
#               README.md) is reported only, never overwritten: a project may
#               have localised it. Reconcile those by hand.
#           The version stamp is rewritten last, so an interrupted run leaves a
#           stamp that is older than the tree, never newer.
# --diff    show a unified diff for every file that differs.
#
# The stamp lives in the docs README's YAML frontmatter:
#
#     ---
#     flow_setup_version: 2.3.0
#     docs_dir: docs
#     guidelines: true
#     ---
#
# An UNSTAMPED tree (scaffolded before stamps existed) is not an error: every
# file is diffed from scratch, which needs no memory of how it was set up.
set -euo pipefail
export LC_ALL=C

usage() { awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$HERE/assets"
VERSION="$(awk -F': *' '/^version:/ {print $2; exit}' "$HERE/../SKILL.md" 2>/dev/null || true)"
[ -n "$VERSION" ] || VERSION="unknown"

ROOT="."
DOCS_DIR=""
APPLY=0
SHOW_DIFF=0

while [ $# -gt 0 ]; do
  case "$1" in
    --root)     ROOT="${2:?--root needs a path}"; shift 2 ;;
    --docs-dir) DOCS_DIR="${2:?--docs-dir needs a name}"; shift 2 ;;
    --apply)    APPLY=1; shift ;;
    --diff)     SHOW_DIFF=1; shift ;;
    -h|--help)  usage; exit 0 ;;
    *)          echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -d "$ROOT" ] || { echo "error: --root '$ROOT' is not a directory" >&2; exit 2; }

# Find the docs tree. A flow docs dir is recognised by its generated read path,
# not by its name — the project may have chosen `documentation/`.
if [ -z "$DOCS_DIR" ]; then
  for cand in docs documentation doc; do
    if [ -f "$ROOT/$cand/build-index.sh" ] || [ -f "$ROOT/$cand/ARCHITECTURE.md" ]; then
      DOCS_DIR="$cand"; break
    fi
  done
fi
if [ -z "$DOCS_DIR" ] || [ ! -d "$ROOT/$DOCS_DIR" ]; then
  echo "error: no flow docs tree found under '$ROOT'." >&2
  echo "       This is a fresh project — run setup-flow.sh, not upgrade-flow.sh." >&2
  exit 2
fi
DOCS="$ROOT/$DOCS_DIR"

# ── The stamp ────────────────────────────────────────────────────────────────
# Read a frontmatter key from the docs README, if it has frontmatter at all.
stamp_get() {
  [ -f "$DOCS/README.md" ] || return 0
  head -1 "$DOCS/README.md" | grep -q '^---$' || return 0
  awk -v k="$1" '
    NR == 1 { next }
    /^---$/ { exit }
    { sub(/^[ \t]+/, ""); if (index($0, k ":") == 1) { sub(/^[^:]*: */, ""); print; exit } }
  ' "$DOCS/README.md"
}

WAS="$(stamp_get flow_setup_version)"
STAMPED=1; [ -n "$WAS" ] || { STAMPED=0; WAS="unstamped"; }

echo "Upgrading $DOCS"
echo "  scaffold version: $WAS  →  skill version: $VERSION"
[ "$STAMPED" -eq 0 ] && echo "  (no stamp — every file diffed from scratch, nothing assumed)"
echo

# ── The two tiers ────────────────────────────────────────────────────────────
# TOOLING: ours outright. Overwritten by --apply.
# PROSE:   ours, but a project may have localised it. Reported only.
TOOLING_SRC=() TOOLING_DST=() TOOLING_MODE=()
add_tooling() { TOOLING_SRC+=("$1"); TOOLING_DST+=("$2"); TOOLING_MODE+=("${3:-}"); }

add_tooling "$HERE/new-record.sh"  "$DOCS/new-record.sh"  755
add_tooling "$HERE/build-index.sh" "$DOCS/build-index.sh" 755
for t in feature bug decision architecture; do
  add_tooling "$ASSETS/$t.md" "$DOCS/templates/$t.md"
done
# The guideline template ships only with the guidelines machinery.
[ -d "$DOCS/guidelines" ] && add_tooling "$ASSETS/guideline.md" "$DOCS/templates/guideline.md"

PROSE_SRC=("$ASSETS/docs-readme.md") PROSE_DST=("$DOCS/README.md")
if [ -d "$DOCS/guidelines" ]; then
  PROSE_SRC+=("$ASSETS/guidelines-readme.md"); PROSE_DST+=("$DOCS/guidelines/README.md")
fi
if [ -d "$ROOT/tasks" ]; then
  PROSE_SRC+=("$ASSETS/tasks-readme.md"); PROSE_DST+=("$ROOT/tasks/README.md")
fi

# body_of <file> — the file minus a leading YAML frontmatter block, if any. The
# stamp is ours to write, so it must never read as a local edit.
body_of() {
  awk 'NR == 1 && $0 == "---" { fm = 1; next }
       fm && $0 == "---"      { fm = 0; next }
       !fm                    { print }' "$1"
}

same_as_asset() {
  local src="$1" dst="$2"
  [ -f "$dst" ] || return 1
  diff -q <(body_of "$dst") "$src" >/dev/null 2>&1
}

CHANGED=0 NEEDS_HAND=0

report() {  # report <label> <src> <dst> <tier>
  local src="$1" dst="$2" tier="$3" rel
  # Assigned separately: the nested quotes of ${dst#"$ROOT"/} do not survive a
  # multi-variable `local` declaration, and the path silently comes out empty.
  rel="${dst#"$ROOT"/}"
  if [ ! -f "$dst" ]; then
    echo "  missing  $rel"
    CHANGED=$((CHANGED + 1))
    if [ "$APPLY" -eq 1 ]; then
      mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"
      echo "           → created"
    fi
    return
  fi
  if same_as_asset "$src" "$dst"; then
    echo "  same     $rel"
    return
  fi
  CHANGED=$((CHANGED + 1))
  if [ "$tier" = tooling ]; then
    echo "  differs  $rel"
    [ "$SHOW_DIFF" -eq 1 ] && diff -u "$dst" "$src" | sed 's/^/           /' || true
    if [ "$APPLY" -eq 1 ]; then
      cp "$src" "$dst"
      echo "           → updated (git holds the previous copy)"
    fi
  else
    NEEDS_HAND=$((NEEDS_HAND + 1))
    echo "  DIFFERS  $rel  — prose, not overwritten. Reconcile by hand."
    [ "$SHOW_DIFF" -eq 1 ] && diff -u <(body_of "$dst") "$src" | sed 's/^/           /' || true
  fi
}

echo "Tooling (yours to run, ours to maintain)"
i=0
while [ $i -lt ${#TOOLING_DST[@]} ]; do
  report "${TOOLING_SRC[$i]}" "${TOOLING_DST[$i]}" tooling
  m="${TOOLING_MODE[$i]}"
  [ -n "$m" ] && [ -f "${TOOLING_DST[$i]}" ] && chmod "$m" "${TOOLING_DST[$i]}"
  i=$((i + 1))
done

echo
echo "Prose (reported only — a project may have localised it)"
i=0
while [ $i -lt ${#PROSE_DST[@]} ]; do
  report "${PROSE_SRC[$i]}" "${PROSE_DST[$i]}" prose
  i=$((i + 1))
done

# ── Capabilities the project never opted into ────────────────────────────────
echo
echo "Optional machinery"
if [ -d "$DOCS/guidelines" ]; then
  echo "  present  $DOCS_DIR/guidelines/  ($(find "$DOCS/guidelines" -name '*.md' -not -name README.md 2>/dev/null | wc -l | tr -d ' ') rule topic(s))"
else
  echo "  absent   $DOCS_DIR/guidelines/  — house rules that apply to every feature."
  echo "           Add with: setup-flow.sh --guidelines (adds an EMPTY tree; a rule"
  echo "           is earned from real work, never generated)."
fi
if [ -d "$ROOT/tasks" ]; then
  echo "  present  tasks/"
else
  echo "  absent   tasks/  — where each unit of work keeps design/plan/review."
fi

# ── Restamp, last ────────────────────────────────────────────────────────────
if [ "$APPLY" -eq 1 ] && [ -f "$DOCS/README.md" ]; then
  guidelines=false; [ -d "$DOCS/guidelines" ] && guidelines=true
  tasks=false;      [ -d "$ROOT/tasks" ]      && tasks=true
  tmp="$DOCS/README.md.stamp.$$"
  {
    echo "---"
    echo "flow_setup_version: $VERSION"
    echo "docs_dir: $DOCS_DIR"
    echo "guidelines: $guidelines"
    echo "tasks: $tasks"
    echo "---"
    body_of "$DOCS/README.md"
  } > "$tmp" && mv "$tmp" "$DOCS/README.md"
  echo
  echo "  stamped  $DOCS_DIR/README.md → flow_setup_version: $VERSION"
fi

echo
if [ "$APPLY" -eq 1 ]; then
  echo "Applied. $CHANGED file(s) were out of date."
  [ "$NEEDS_HAND" -gt 0 ] && echo "$NEEDS_HAND prose file(s) still need a hand — see DIFFERS above."
  echo "Next: reconcile the CLAUDE.md / AGENTS.md block, then run"
  echo "      $DOCS_DIR/build-index.sh --check"
elif [ "$CHANGED" -eq 0 ]; then
  echo "Up to date. Nothing to do."
else
  echo "$CHANGED file(s) out of date. Re-run with --apply to write them, --diff to see them."
fi
exit 0
