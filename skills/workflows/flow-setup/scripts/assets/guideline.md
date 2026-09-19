<!--
Template for a guideline topic — a cross-cutting rule set that applies to work
everywhere, not to one feature. Create it with:

    ./docs/new-record.sh guideline ui-ux "Data freshness"

Keep one topic per file and 3–10 rules per topic. Every rule:
  - has a stable ID: <TOPIC>-<n>, numbered in creation order, NEVER renumbered
  - is one imperative sentence you could hold a diff against
  - says *because* — a rule with no reason gets argued with and then ignored
  - is earned: it came up in real work at least once. Do not invent rules.

A retired rule keeps its ID and its place; mark it `~~struck~~` with a line
saying what replaced it. Renumbering breaks every citation in every review.
-->
---
area: <area>
topic: <topic>
status: active
tags: []
---

# <Title>

**Applies to:** <the situation that makes these rules relevant — be concrete, so
a reader can tell in one second whether this file is about their diff.>

## Rules

### <TOPIC>-1 — <the rule, as an imperative sentence>

<One or two lines of detail: what it looks like to follow this.>

**Because:** <what goes wrong when you don't.>
**Source:** <tasks/YYYY-MM-DD-slug/ or the bug record that earned it, if any.>

### <TOPIC>-2 — <the next rule>

**Because:** <…>

## Exceptions

<Where these rules deliberately do not apply, and what to do instead. Delete
this section if there are none — an empty "None." is noise.>
