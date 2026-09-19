# Changelog

All notable changes to the `flow` skill.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), newest first.

## [2.1.0] - 2026-09-19

### Added
- `docs/guidelines/` is now a first-class input and output of the pipeline:
  read by stage 1 as design constraints, by stage 3 when building subagent
  prompts, and by stage 4 for conformance — and written only by stage 5. Stages
  1 and 4 nominate candidate rules into their own task artifacts; the standing
  "only stage 5 writes into `docs/`" rule covers `docs/guidelines/` too.

---

## [2.0.0] - 2026-09-19

### Changed
- Artifacts now live in one folder per task, `tasks/<YYYY-MM-DD>-<slug>/`, with
  fixed filenames `design.md`, `plan.md`, `review.md` — replacing the flat
  `docs/plans/<date>-<slug>-<stage>.md` files. No fallback: re-run or move old
  artifacts by hand.
- Resume detection reuses an existing `tasks/*-<slug>/` folder even under an
  older date, instead of minting a new one each day.

### Added
- Stage 5, `flow-doc`: after review, the task is promoted into the project's
  `docs/` tree. Skipped automatically when the repo has no `docs/`.

## [1.0.0] - 2026-09-13

### Added
- Initial release. Orchestrates the full feature workflow — design → plan-implem
  → implem → review — passing markdown artifacts through
  `docs/plans/<date>-<slug>-*.md`.
- Runs end to end with no approval gates; stops only for genuine user decisions,
  nearly all of which land in stage 1.
- Resumes a half-finished flow by detecting which artifacts already exist.
