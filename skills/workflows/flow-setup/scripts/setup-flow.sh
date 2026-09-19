#!/usr/bin/env bash
# Scaffold a project docs/ tree. Idempotent: never overwrites an existing file.
#
#   setup-flow.sh [--root <path>] [--docs-dir <name>] [--no-tasks]
#                 [--guidelines] [--guideline-area <name>]
#                 <feature> [<feature> ...]
#
# Example:
#   setup-flow.sh --root . --guidelines capture queue auth billing
#
# Creates <root>/<docs-dir>/ and, unless --no-tasks, <root>/tasks/ — the two
# trees the `flow` skills read and write. tasks/ is always a sibling of the
# project root, never nested inside the docs directory.
#
# --no-tasks  skip the tasks/ scaffold. Use when the project already has a
#             tasks/ directory meaning something else (a task runner, fixtures);
#             the script refuses to scaffold into a foreign one either way.
#
# --guidelines        create docs/guidelines/ — cross-cutting rules that apply
#                     to every feature (UI/UX behaviour, API shape, data).
#                     Defaults to the `ui-ux` area. OFF by default: a project
#                     with no interface and no house conventions does not need
#                     an empty rulebook.
# --guideline-area X  add area X (repeatable); implies --guidelines.
set -euo pipefail

# Ranges like [a-z] follow the locale's COLLATION order, not ASCII: under
# en_US.UTF-8, bash matches 'A', 'B' and 'É' inside [a-z], so the kebab-case
# guard below silently accepts `BAD`. Force byte semantics for globs, sed and tr.
export LC_ALL=C

usage() { awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; }

ASSETS="$(cd "$(dirname "${BASH_SOURCE[0]}")/assets" && pwd)"
ROOT="."
DOCS_DIR="docs"
NO_TASKS=0
GUIDELINES=0
AREAS=()
FEATURES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --root)     ROOT="${2:?--root needs a path}"; shift 2 ;;
    --docs-dir) DOCS_DIR="${2:?--docs-dir needs a name}"; shift 2 ;;
    --no-tasks) NO_TASKS=1; shift ;;
    --guidelines) GUIDELINES=1; shift ;;
    --guideline-area)
      GUIDELINES=1; AREAS+=("${2:?--guideline-area needs a name}"); shift 2 ;;
    -h|--help)  usage; exit 0 ;;
    -*)         echo "unknown flag: $1" >&2; exit 2 ;;
    *)          FEATURES+=("$1"); shift ;;
  esac
done

if [ ${#FEATURES[@]} -eq 0 ]; then
  echo "error: name at least one feature (e.g. capture queue auth)" >&2
  exit 2
fi
[ -d "$ROOT" ] || { echo "error: --root '$ROOT' is not a directory" >&2; exit 2; }

# Validate every feature BEFORE creating anything: a bad name in position three
# must not leave a half-built tree behind.
for f in "${FEATURES[@]}"; do
  case "$f" in
    "")           echo "error: feature name cannot be empty" >&2; exit 2 ;;
    *[!a-z0-9-]*) echo "error: feature '$f' must be lowercase kebab-case" >&2; exit 2 ;;
  esac
done

# Same treatment for guideline areas — they are path components too. Default the
# list only after validation, so `--guidelines` alone still yields `ui-ux`.
# `${AREAS[@]}` on an empty array is an unbound-variable error under `set -u` in
# bash 3.2 (still the /bin/bash on macOS), hence the length guard.
if [ "$GUIDELINES" -eq 1 ] && [ ${#AREAS[@]} -eq 0 ]; then AREAS=("ui-ux"); fi
if [ ${#AREAS[@]} -gt 0 ]; then
  for a in "${AREAS[@]}"; do
    case "$a" in
      "")           echo "error: guideline area cannot be empty" >&2; exit 2 ;;
      *[!a-z0-9-]*) echo "error: area '$a' must be lowercase kebab-case" >&2; exit 2 ;;
    esac
  done
fi

DOCS="$ROOT/$DOCS_DIR"

# copy <src> <dst> [mode] — never clobbers.
# `-e` alone resolves symlinks, so a DANGLING symlink at $2 reads as absent and
# `cp` would follow it and write outside the repo; `-L` catches that.
copy() {
  if [ -e "$2" ] || [ -L "$2" ]; then
    echo "  skip   ${2#"$ROOT"/}"
  else
    mkdir -p "$(dirname "$2")"
    cp "$1" "$2"
    # chmod only on the create path: on `skip` it would follow a planted
    # symlink and change the mode of whatever it points at.
    [ -n "${3:-}" ] && chmod "$3" "$2"
    echo "  create ${2#"$ROOT"/}"
  fi
}

# gitkeep <dir> — same dangling-symlink care, since git needs the empty dirs.
gitkeep() {
  [ -e "$1/.gitkeep" ] || [ -L "$1/.gitkeep" ] || {
    : > "$1/.gitkeep"; echo "  create ${1#"$ROOT"/}/.gitkeep"
  }
}

echo "Scaffolding $DOCS"

copy "$ASSETS/docs-readme.md" "$DOCS/README.md"
copy "$ASSETS/architecture.md" "$DOCS/ARCHITECTURE.md"
for t in feature bug decision architecture; do
  copy "$ASSETS/$t.md" "$DOCS/templates/$t.md"
done

# Cross-cutting rules: docs/guidelines/<area>/<topic>.md. Opt-in — see the
# --guidelines flag. The template ships with it, not with the base scaffold, so
# a project that declined guidelines has no dangling template inviting them.
if [ "$GUIDELINES" -eq 1 ]; then
  copy "$ASSETS/guidelines-readme.md" "$DOCS/guidelines/README.md"
  copy "$ASSETS/guideline.md"         "$DOCS/templates/guideline.md"
  for a in "${AREAS[@]}"; do
    mkdir -p "$DOCS/guidelines/$a"
    gitkeep "$DOCS/guidelines/$a"
  done
fi

# The project owns its helpers; docs/README.md references both by path.
copy "$(dirname "$ASSETS")/new-record.sh"  "$DOCS/new-record.sh"  755
copy "$(dirname "$ASSETS")/build-index.sh" "$DOCS/build-index.sh" 755

# Units of work live OUTSIDE docs/, in tasks/<YYYY-MM-DD>-<slug>/ — see the
# `flow` skills. docs/ holds the system as it is now; tasks/ holds how it got
# there. Scaffolded at the project ROOT, never inside the docs directory, even
# when --docs-dir is nested.
#
# `tasks/` is a popular directory name (gulp/grunt task runners, Ansible roles,
# Celery modules, fixtures). Writing a README about design documents into one of
# those is confusing at best, so an existing tasks/ is only accepted when it is
# EMPTY or already ours — recognised by a task folder or by the README this
# script installs. Anything else is reported and left untouched.
if [ "$NO_TASKS" -eq 1 ]; then
  echo "  skip tasks/ (--no-tasks)"
elif [ ! -e "$ROOT/tasks" ]; then
  mkdir -p "$ROOT/tasks"
  copy "$ASSETS/tasks-readme.md" "$ROOT/tasks/README.md"
elif [ ! -d "$ROOT/tasks" ]; then
  echo "  SKIP tasks/: '$ROOT/tasks' exists and is not a directory — left untouched" >&2
else
  # Ours if it holds a YYYY-MM-DD-<slug> folder, or our README.
  ours=0
  [ -f "$ROOT/tasks/README.md" ] && grep -q 'design\.md' "$ROOT/tasks/README.md" 2>/dev/null && ours=1
  for d in "$ROOT"/tasks/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*/; do
    [ -d "$d" ] && ours=1
    break
  done
  # An empty tasks/ belongs to nobody; adopting it is safe.
  [ -z "$(ls -A "$ROOT/tasks" 2>/dev/null)" ] && ours=1

  if [ "$ours" -eq 1 ]; then
    copy "$ASSETS/tasks-readme.md" "$ROOT/tasks/README.md"
  else
    echo "  SKIP tasks/: '$ROOT/tasks' already exists and does not look like a flow" >&2
    echo "       tasks folder. Left completely untouched — move it, or pass" >&2
    echo "       --no-tasks and keep task artifacts elsewhere." >&2
  fi
fi

for f in "${FEATURES[@]}"; do
  mkdir -p "$DOCS/features/$f/bugs" "$DOCS/features/$f/decisions"
  copy "$ASSETS/feature.md" "$DOCS/features/$f/README.md"
  for sub in bugs decisions; do
    gitkeep "$DOCS/features/$f/$sub"
  done
done

# The shipped markdown hard-codes `docs/`. If the tree was scaffolded somewhere
# else, rewrite those references or every path the new docs advertise is wrong.
if [ "$DOCS_DIR" != "docs" ]; then
  for m in "$DOCS/README.md" "$DOCS/ARCHITECTURE.md" "$DOCS"/templates/*.md \
           "$DOCS"/guidelines/README.md "$DOCS"/features/*/README.md; do
    [ -f "$m" ] || continue
    tmp="$m.retarget.$$"
    sed -e "s|\./docs/|./$DOCS_DIR/|g" -e "s|(\./docs)|(./$DOCS_DIR)|g" \
        -e "s|\`docs/|\`$DOCS_DIR/|g" -e "s|^docs/|$DOCS_DIR/|" "$m" > "$tmp" && mv "$tmp" "$m"
  done
  echo "  retarget docs/ -> $DOCS_DIR/ in README and templates"
fi

# Generate the read path so FEATURE-MAP.md and INDEX.md exist from minute one.
"$DOCS/build-index.sh" --root "$ROOT" --docs-dir "$DOCS_DIR" >/dev/null 2>&1 || true

echo
echo "Done. ${#FEATURES[@]} feature(s): ${FEATURES[*]}"
echo "Next: fill in $DOCS_DIR/ARCHITECTURE.md and each feature's '## Key files',"
echo "      then run $DOCS_DIR/build-index.sh to regenerate the map and index."
