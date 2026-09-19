# Changelog

All notable changes to the `flow-doc` skill.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), newest first.

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
