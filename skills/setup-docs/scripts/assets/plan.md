<!--
Create with:  ./docs/new-record.sh plan - "<title>"
which writes docs/plans/YYYY-MM-DD-kebab-title.md.

A plan is written BEFORE the work and is not edited after it starts — if the
plan turns out wrong, that is a finding, and it goes in the Outcome section at
the bottom. A silently-rewritten plan teaches nobody anything.

Tasks are the unit. A good task is file-disjoint from its siblings, so two of
them can run at the same time without conflict.
-->

# YYYY-MM-DD — <title>

- **Goal:** the one sentence that says when this is done
- **Exit criterion:** the observable thing that proves it — something you run,
  not something you read
- **Touches:** the directories this work is allowed to modify

## Context
What exists today and why it is not enough. Link the decisions that constrain
the approach.

## Tasks

Group tasks into waves. Everything inside a wave is file-disjoint and can run
concurrently; a wave starts only when the previous one is complete.

### Wave 1 — <what this wave establishes>

- [ ] **1A** <task> — `path/to/file.ts`
- [ ] **1B** <task> — `path/to/other.ts`

### Wave 2 — <what this wave establishes>

- [ ] **2A** <task> — `path/...`

## Risks
What could make this plan wrong, and the cheapest way to find out early.

## Outcome
<!-- Filled in after the work lands. Keep the plan above untouched. -->
What actually happened, what the plan got wrong, and what that implies for the
next one.
