#!/usr/bin/env bash
# Create a docs record from its template, date-prefixed so that concurrent
# authors (parallel agents, separate worktrees) never collide.
#
#   new-record.sh [--root <path>] [--docs-dir <name>] [--date YYYY-MM-DD] \
#                 <decision|bug|plan|feature> <feature|-> <title>
#
#   new-record.sh decision queue "Partial dedupe index"
#     -> docs/features/queue/decisions/2026-09-13-partial-dedupe-index.md
#   new-record.sh plan - "Extract the queue"
#     -> docs/plans/2026-09-13-extract-the-queue.md
#
# Prints the created path on stdout and nothing else, so it can be captured:
#   f=$(new-record.sh decision queue "…")
set -euo pipefail

# Ranges like [a-z] follow the locale's COLLATION order, not ASCII: under
# en_US.UTF-8, bash and sed match 'A' and 'É' inside [a-z]. Without this, the
# slug pipeline below leaks uppercase and accented characters into filenames.
export LC_ALL=C

usage() { awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' "${BASH_SOURCE[0]}"; }

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATE=""
ROOT=""
DOCS_DIR=""

# Two homes: inside the skill (templates in scripts/assets/) or installed into a
# project (docs/new-record.sh, next to docs/templates/). Probe for a known
# template FILE, not a bare directory — `docs/assets/` is a common directory in
# real projects and would otherwise be mistaken for the template home.
#
# Resolved AFTER argument parsing so that `--help` works even when the templates
# are missing.
resolve_home() {
  if [ -f "$SELF_DIR/assets/decision.md" ]; then
    TEMPLATES="$SELF_DIR/assets"
    DEF_ROOT="."; DEF_DOCS_DIR="docs"
  elif [ -f "$SELF_DIR/templates/decision.md" ]; then
    # Installed copy: default to the tree it was installed into, whatever that
    # directory is called. Deriving both halves keeps `--root` from silently
    # reverting a `documentation/` install to `docs/`.
    TEMPLATES="$SELF_DIR/templates"
    DEF_ROOT="$(dirname "$SELF_DIR")"; DEF_DOCS_DIR="$(basename "$SELF_DIR")"
  else
    echo "error: no templates found in $SELF_DIR/{assets,templates}" >&2; exit 2
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --root)     ROOT="${2:?--root needs a path}"; shift 2 ;;
    --docs-dir) DOCS_DIR="${2:?--docs-dir needs a name}"; shift 2 ;;
    --date)     DATE="${2:?--date needs YYYY-MM-DD}"; shift 2 ;;
    -h|--help)  usage; exit 0 ;;
    -*)         echo "unknown flag: $1" >&2; exit 2 ;;
    *)          break ;;
  esac
done

resolve_home
ROOT="${ROOT:-$DEF_ROOT}"
DOCS_DIR="${DOCS_DIR:-$DEF_DOCS_DIR}"

KIND="${1:-}"; FEATURE="${2:-}"
[ -n "$KIND" ] && [ -n "$FEATURE" ] && [ $# -ge 3 ] || {
  echo "usage: new-record.sh <decision|bug|plan|feature> <feature|-> <title>" >&2; exit 2; }
shift 2

# Flags are only honoured before the positionals; catching them after is the
# difference between an error and a record silently titled "... --date 2020-01-01".
# Only the REAL flag names are rejected — a title may legitimately begin with a
# double dash ("--force is deprecated").
for a in "$@"; do
  case "$a" in
    --root|--docs-dir|--date|--help)
      echo "error: flag '$a' must come before the positional arguments" >&2; exit 2 ;;
  esac
done
TITLE="$*"

[ -n "$DATE" ] || DATE="$(date +%F)"
case "$DATE" in
  [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
  *) echo "error: --date must be YYYY-MM-DD" >&2; exit 2 ;;
esac

DOCS="$ROOT/$DOCS_DIR"
[ -d "$DOCS" ] || { echo "error: no $DOCS — run setup-docs.sh first" >&2; exit 2; }

# The feature name becomes a path component, so it is validated for EVERY kind
# that uses it — not just `feature`. Without this, `decision "../../.."` writes
# the record outside the repository.
if [ "$KIND" != "plan" ]; then
  case "$FEATURE" in
    -|"")         echo "error: '$KIND' needs a feature name" >&2; exit 2 ;;
    *[!a-z0-9-]*) echo "error: feature '$FEATURE' must be lowercase kebab-case" >&2; exit 2 ;;
  esac
fi

# "Partial dedupe index!" -> "partial-dedupe-index".
# `tr` and `sed` are line-oriented, so newlines are collapsed FIRST — otherwise
# a multi-line title yields a multi-line filename and breaks `f=$(new-record …)`.
SLUG=$(printf '%s' "$TITLE" \
  | tr '\n\r\t' '   ' \
  | tr '[:upper:]' '[:lower:]' \
  | sed -e 's/[^a-z0-9]\{1,\}/-/g' -e 's/^-//' -e 's/-$//')
[ -n "$SLUG" ] || { echo "error: title produced an empty slug" >&2; exit 2; }
case "$SLUG" in
  *[!a-z0-9-]*) echo "error: internal — slug '$SLUG' is not kebab-case" >&2; exit 2 ;;
esac

case "$KIND" in
  decision) DIR="$DOCS/features/$FEATURE/decisions"; TPL="$TEMPLATES/decision.md" ;;
  bug)      DIR="$DOCS/features/$FEATURE/bugs";      TPL="$TEMPLATES/bug.md" ;;
  plan)     DIR="$DOCS/plans";                       TPL="$TEMPLATES/plan.md" ;;
  feature)  DIR="$DOCS/features/$FEATURE";           TPL="$TEMPLATES/feature.md" ;;
  *) echo "error: kind must be decision|bug|plan|feature" >&2; exit 2 ;;
esac

if [ "$KIND" = "feature" ]; then
  mkdir -p "$DIR/bugs" "$DIR/decisions"
  # Git does not track empty directories; without these, a fresh clone loses
  # bugs/ and decisions/ and the next `new-record.sh bug <f>` fails.
  for sub in bugs decisions; do
    [ -e "$DIR/$sub/.gitkeep" ] || : > "$DIR/$sub/.gitkeep"
  done
  OUT="$DIR/README.md"
else
  if [ "$KIND" != "plan" ]; then
    [ -d "$DIR" ] || { echo "error: unknown feature '$FEATURE' ($DIR missing)" >&2; exit 2; }
  fi
  OUT="$DIR/$DATE-$SLUG.md"
fi

mkdir -p "$DIR"

# Render to a temp file first. Writing straight to $OUT would leave a 0-byte
# corpse behind if rendering failed, and the never-overwrite guard below would
# then block every retry.
TMP="$(mktemp "${TMPDIR:-/tmp}/new-record.XXXXXX")"
CLAIMED=""
# CLAIMED is released too: a `cat` that fails partway (disk full) would
# otherwise leave a 0-byte file that the never-overwrite guard then refuses to
# replace, making the record permanently uncreatable.
trap 'rm -f "$TMP"; [ -n "$CLAIMED" ] && rm -f "$CLAIMED"; true' EXIT

# Drop the template's leading HTML-comment preamble (guidance for the author of
# the record, not content of it), then seed the obvious fields.
#
# Values travel through the environment and are spliced in with index/substr,
# never through a regex replacement: a title containing / $ @ & or \ is data
# here, not syntax.
TITLE="$TITLE" DATE="$DATE" FEATURE="$FEATURE" KIND="$KIND" awk '
  # Replaces EVERY occurrence: a hand-customised template line carrying two
  # YYYY-MM-DD placeholders should not keep the second one.
  function subst(s, old, new,   i, out) {
    if (old == "") return s
    while ((i = index(s, old)) > 0) {
      out = out substr(s, 1, i-1) new
      s = substr(s, i + length(old))
    }
    return out s
  }
  BEGIN { title = ENVIRON["TITLE"]; date = ENVIRON["DATE"]
          feature = ENVIRON["FEATURE"]; kind = ENVIRON["KIND"] }
  NR == 1 && /^<!--/ { skip = 1 }
  skip { if (/-->/) skip = 0; next }
  !seen_body && /^[[:space:]]*$/ { next }          # blank lines left by the preamble
  { seen_body = 1 }
  # Track fenced code blocks so a `# comment` inside one is never mistaken for
  # the record heading.
  /^[[:space:]]*```/ { fence = !fence }
  !done_h && !fence && /^# / {
    done_h = 1
    print (kind == "plan") ? "# " date " — " title : "# " title
    next
  }
  # YAML frontmatter — the keys docs/INDEX.md is built from.
  /^date:[[:space:]]*YYYY-MM-DD/  { print subst($0, "YYYY-MM-DD", date); next }
  /^found:[[:space:]]*YYYY-MM-DD/ { print subst($0, "YYYY-MM-DD", date); next }
  /^feature:[[:space:]]*<feature>/ { print subst($0, "<feature>", feature); next }
  # Body fields, for templates that still carry them.
  /^- \*\*Date:\*\* YYYY-MM-DD/  { print subst($0, "YYYY-MM-DD", date); next }
  /^- \*\*Found:\*\* YYYY-MM-DD/ { print subst($0, "YYYY-MM-DD", date); next }
  /^- \*\*Feature:\*\* <feature>/ { print subst($0, "<feature>", feature); next }
  { print }
  # A template with no top-level heading would silently discard the title.
  END { if (!done_h) exit 3 }
' "$TPL" > "$TMP" || {
  rc=$?
  [ "$rc" -eq 3 ] && echo "error: $TPL has no '# ' heading, so the title has nowhere to go" >&2
  exit 1
}

[ -s "$TMP" ] || { echo "error: rendering $TPL produced an empty record" >&2; exit 1; }

# Claim the path atomically, so two concurrent writers of the same title on the
# same day cannot both believe they created it. noclobber also refuses to follow
# a symlink planted at $OUT.
if [ -e "$OUT" ] || [ -L "$OUT" ]; then
  echo "error: $OUT already exists" >&2; exit 1
fi
# Report the real errno (name too long, permission denied, no space) instead of
# flattening every failure into "already exists".
if ! (set -o noclobber; : > "$OUT"); then
  echo "error: could not create $OUT" >&2; exit 1
fi
CLAIMED="$OUT"

cat "$TMP" > "$OUT"
CLAIMED=""          # the write succeeded; the file is now the user's

printf '%s\n' "$OUT"
