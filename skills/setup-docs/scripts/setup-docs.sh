#!/usr/bin/env bash
# Scaffold a project docs/ tree. Idempotent: never overwrites an existing file.
#
#   setup-docs.sh [--root <path>] [--docs-dir <name>] <feature> [<feature> ...]
#
# Example:
#   setup-docs.sh --root . capture queue auth billing
set -euo pipefail

# Ranges like [a-z] follow the locale's COLLATION order, not ASCII: under
# en_US.UTF-8, bash matches 'A', 'B' and 'É' inside [a-z], so the kebab-case
# guard below silently accepts `BAD`. Force byte semantics for globs, sed and tr.
export LC_ALL=C

usage() { awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; }

ASSETS="$(cd "$(dirname "${BASH_SOURCE[0]}")/assets" && pwd)"
ROOT="."
DOCS_DIR="docs"
FEATURES=()

while [ $# -gt 0 ]; do
  case "$1" in
    --root)     ROOT="${2:?--root needs a path}"; shift 2 ;;
    --docs-dir) DOCS_DIR="${2:?--docs-dir needs a name}"; shift 2 ;;
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
for t in feature bug decision plan architecture; do
  copy "$ASSETS/$t.md" "$DOCS/templates/$t.md"
done

# The project owns its helpers; docs/README.md references both by path.
copy "$(dirname "$ASSETS")/new-record.sh"  "$DOCS/new-record.sh"  755
copy "$(dirname "$ASSETS")/build-index.sh" "$DOCS/build-index.sh" 755

mkdir -p "$DOCS/plans"
gitkeep "$DOCS/plans"

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
           "$DOCS"/features/*/README.md; do
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
