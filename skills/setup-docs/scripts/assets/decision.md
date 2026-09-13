<!--
Create with:  ./docs/new-record.sh decision <feature> "<title>"
which writes docs/features/<feature>/decisions/YYYY-MM-DD-kebab-title.md.

The date prefix is deliberate: sequential NNNN numbers require reading the
directory before writing, which races when two agents work in parallel.

The YAML frontmatter is what docs/INDEX.md is built from — keep the keys, fill
the values, re-run ./docs/build-index.sh. `tags` is how you find this record
later; spend five seconds on it.

One page — the value is in having written it, not in its length.

Write one whenever a REAL ALTERNATIVE WAS REJECTED. If there was only ever one
way to do it, there is no decision to record.

Records are append-only. When one is overturned, set `status: superseded` and
`superseded_by: YYYY-MM-DD-<slug>` here, and `supersedes:` on the new record.
Never rename, never delete.

"Why" and "Consequences" are the fields that earn their keep. A decision
without its rejected alternative is just documentation of the current code.
-->
---
status: accepted
date: YYYY-MM-DD
feature: <feature>
decided_by: <user | design review | implementation>
tags: []
supersedes:
superseded_by:
---

# <the decision, as a statement, not a topic>

## Context
What situation forced a choice. Name the alternatives that were actually on
the table — this is the part that stops the decision being relitigated.

## Decision
One or two sentences. The thing that was decided, in the imperative.

## Why
Why the chosen option beat the rejected ones. Reference constraints, not taste.

## Consequences
What this now costs or forecloses, including the things it makes harder.
A decision with no listed downside was not a decision.
