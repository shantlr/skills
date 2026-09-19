<!--
Create with:  ./docs/new-record.sh bug <feature> "<title>"
which writes docs/features/<feature>/bugs/YYYY-MM-DD-kebab-title.md.

The date prefix is deliberate: sequential NNNN numbers require reading the
directory before writing, which races when two agents work in parallel.

The YAML frontmatter is what docs/INDEX.md is built from — keep the keys, fill
the values, re-run ./docs/build-index.sh.

This is a history of what went wrong and why, NOT a ticket tracker. An entry is
earned when the bug was non-obvious, when it reached production/a real user, or
when the fix changed a rule.

No entry for: typos, one-line UI nits, anything caught before merge.

"Root cause" and "Why it wasn't caught" are the two fields that earn their keep.
A symptom-and-fix log tells you nothing you can't get from `git log`.
"Prevention" closes the loop — if a bug can't be prevented structurally, say so
and say why.
-->
---
status: <fixed | open | wontfix>
found: YYYY-MM-DD
feature: <feature>
severity: <high | medium | low>
tags: []
related: []
---

# <what actually went wrong, in one line>

> Found by <who>, doing <what>. Consequence: <the impact, not the adjective>.

## Symptom
What was observed, including the exact error text. Note what looked *fine*,
because that is usually why it survived review.

## Root cause
The actual mechanism, one causal step at a time. If the chain has more than two
links, number them. Also list what this was **not** — the plausible causes that
were checked and disproved. That list is what saves the next person a day.

## Fix
The change, and where.

## Why it wasn't caught
The gap in the tests, fixtures, or types that let it through.

## Prevention
The structural change that makes this whole *class* of bug fail loudly.
If none exists, say that, and say why.
