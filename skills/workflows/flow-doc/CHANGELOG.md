# Changelog

All notable changes to the `flow-doc` skill.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), newest first.

## [1.1.0] - 2026-09-19

### Added
- **Stage 5 now writes guidelines** — the only stage that does. It reads the
  `## Guideline candidates` nominated by `flow-design` and `flow-review`,
  applies the earned bar (the situation came up twice, or a fix changed how we
  do a whole class of thing — not a one-off, which stays a decision record), and
  either appends the next rule to an existing topic or creates a new one.
- Rules are written with a `**Because:**` (the failure mode) and a `**Source:**`
  (the task folder or bug record that earned them). IDs are append-only: never
  renumbered, never reused; superseding strikes the old rule through in place.
- Candidates deliberately *not* promoted are reported with the reason, so an
  unearned rule is a visible decision rather than a silent one.
- Skips silently when there is no `docs/guidelines/` tree — the never-scaffold
  rule now covers it explicitly.

---

## [1.0.0] - 2026-09-19

### Added
- Initial release. Stage 5 of the flow workflow: promotes a finished task in
  `tasks/<date>-<slug>/` into the project's durable `docs/` tree — updates the
  feature one-pager (including `## Key files`), writes one decision record per
  rejected alternative from the design's decisions table, and promotes only
  pre-existing, instructive bugs from the review.
- Skips itself when the repo has no `docs/` tree rather than scaffolding one;
  scaffolding stays with the user-invoked `flow-setup`.
- Rebuilds `FEATURE-MAP.md` / `INDEX.md` via `./docs/build-index.sh`, which also
  catches feature READMEs pointing at files that have moved.
