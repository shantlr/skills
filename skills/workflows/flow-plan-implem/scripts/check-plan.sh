#!/usr/bin/env bash
# Validate a flow implementation plan before dispatching it.
#
#   check-plan.sh docs/plans/2026-09-13-add-oauth-plan.md
#
# Checks:
#   - every task declares Wave, Owns and Verify
#   - no file is owned by two tasks in the same wave  (would collide at runtime)
#   - no file is owned by two tasks at all            (warning: serialises waves)
#   - reports wave widths, so you can see how parallel the plan actually is
#
# Exit: 0 ok (warnings allowed), 1 errors found, 2 bad usage.
set -uo pipefail

plan="${1:-}"
[ -n "$plan" ] || { echo "usage: check-plan.sh <plan.md>" >&2; exit 2; }
[ -f "$plan" ] || { echo "check-plan: no such file: $plan" >&2; exit 2; }

errors=0
warnings=0

# Parse tasks into "<task-id>|<wave>|<has_verify>|<owned files...>" lines.
# A task starts at a checklist line:  - [ ] **T3 — title**
parsed="$(awk '
  function flush() {
    if (id != "") printf "%s|%s|%s|%s\n", id, wave, verify, owns
    id=""; wave=""; verify="0"; owns=""
  }
  /^[[:space:]]*-[[:space:]]*\[[ xX]\][[:space:]]*\*\*/ {
    flush()
    line=$0
    sub(/^[^*]*\*\*/, "", line); sub(/\*\*.*$/, "", line)
    id=line
    sub(/[[:space:]]*[—-].*$/, "", id)
    gsub(/[[:space:]]/, "", id)
    next
  }
  id != "" && /^[[:space:]]*-[[:space:]]*Wave:/  { w=$0; sub(/^.*Wave:[[:space:]]*/,"",w); gsub(/[^0-9]/,"",w); wave=w; next }
  id != "" && /^[[:space:]]*-[[:space:]]*Verify:/ { verify="1"; next }
  id != "" && /^[[:space:]]*-[[:space:]]*Owns:/ {
    o=$0; sub(/^.*Owns:[[:space:]]*/, "", o)
    n=split(o, parts, ",")
    for (i=1; i<=n; i++) {
      f=parts[i]
      gsub(/`/, "", f)                       # strip code ticks
      gsub(/\([^)]*\)/, "", f)               # strip "(new)" / "(edit)"
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", f)
      if (f != "") owns = owns (owns=="" ? "" : " ") f
    }
    next
  }
  END { flush() }
' "$plan")"

[ -n "$parsed" ] || { echo "check-plan: no tasks found — expected lines like '- [ ] **T1 — title**'" >&2; exit 1; }

ntasks="$(printf '%s\n' "$parsed" | grep -c .)"
echo "check-plan: $plan — $ntasks task(s)"
echo

# --- per-task required fields -------------------------------------------------
while IFS='|' read -r id wave verify owns; do
  [ -n "$id" ] || continue
  [ -n "$wave" ] || { echo "ERROR  $id: no 'Wave:' declared"; errors=$((errors+1)); }
  [ -n "$owns" ] || { echo "ERROR  $id: no 'Owns:' declared — cannot be scheduled safely"; errors=$((errors+1)); }
  [ "$verify" = "1" ] || { echo "ERROR  $id: no 'Verify:' command"; errors=$((errors+1)); }
done <<EOF
$parsed
EOF

# --- ownership collisions -----------------------------------------------------
owner_rows="$(
  while IFS='|' read -r id wave verify owns; do
    [ -n "$id" ] && [ -n "$owns" ] || continue
    for f in $owns; do printf '%s\t%s\t%s\n' "$f" "${wave:-?}" "$id"; done
  done <<EOF
$parsed
EOF
)"

# same file, same wave -> hard error
while IFS= read -r dup; do
  [ -n "$dup" ] || continue
  f="${dup%%	*}"; rest="${dup#*	}"; w="${rest%%	*}"
  who="$(printf '%s\n' "$owner_rows" | awk -F'\t' -v f="$f" -v w="$w" '$1==f && $2==w {printf "%s ", $3}')"
  echo "ERROR  $f owned by multiple tasks in wave $w: $who"
  errors=$((errors+1))
done <<EOF
$(printf '%s\n' "$owner_rows" | awk -F'\t' '{print $1"\t"$2}' | sort | uniq -d)
EOF

# same file, different waves -> warning (forces serialisation)
while IFS= read -r f; do
  [ -n "$f" ] || continue
  who="$(printf '%s\n' "$owner_rows" | awk -F'\t' -v f="$f" '$1==f {printf "%s(w%s) ", $3, $2}')"
  printf 'WARN   %s owned across waves: %s— consider one owner\n' "$f" "$who"
  warnings=$((warnings+1))
done <<EOF
$(printf '%s\n' "$owner_rows" | awk -F'\t' '{print $1"\t"$2}' | sort -u | awk -F'\t' '{c[$1]++} END {for (f in c) if (c[f]>1) print f}')
EOF

# --- wave widths --------------------------------------------------------------
echo
echo "wave  tasks  ids"
printf '%s\n' "$parsed" | awk -F'|' '$2!="" {w[$2]++; ids[$2]=ids[$2]" "$1} END {n=asorti(w,s); for(i=1;i<=n;i++) printf "%-5s %-6s%s\n", s[i], w[s[i]], ids[s[i]]}' 2>/dev/null \
  || printf '%s\n' "$parsed" | awk -F'|' '$2!="" {w[$2]++; ids[$2]=ids[$2]" "$1} END {for (k in w) printf "%-5s %-6s%s\n", k, w[k], ids[k]}' | sort -n

widest="$(printf '%s\n' "$parsed" | awk -F'|' '$2!="" {w[$2]++} END {m=0; for (k in w) if (w[k]>m) m=w[k]; print m}')"
nwaves="$(printf '%s\n' "$parsed" | awk -F'|' '$2!="" {w[$2]=1} END {print length(w)}')"
echo
echo "waves: $nwaves   widest: $widest task(s)"
[ "${nwaves:-0}" -gt 0 ] && [ "${widest:-0}" -le 1 ] &&
  echo "WARN   every wave has one task — this plan is fully serial; look for a missing contracts task" &&
  warnings=$((warnings+1))

echo
if [ "$errors" -gt 0 ]; then
  echo "FAIL   $errors error(s), $warnings warning(s)"
  exit 1
fi
echo "OK     0 errors, $warnings warning(s)"
