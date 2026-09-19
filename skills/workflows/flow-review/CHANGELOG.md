# Changelog

All notable changes to the `flow-review` skill.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), newest first.

## [2.0.0] - 2026-09-19

### Changed
- Reads `tasks/<date>-<slug>/{design,plan}.md` and writes
  `tasks/<date>-<slug>/review.md` instead of the flat `docs/plans/` files.

## [1.0.0] - 2026-09-13

### Added
- Initial release. Stage 4 of the flow workflow: three escalating review rounds
  over the working diff — parallel correctness lenses, design/plan conformance,
  then adversarial refutation plus a completeness sweep.
- Fixes what survives and reports every fix with its root cause, plus a
  before/after ASCII diagram.
- Writes `docs/plans/<date>-<slug>-review.md`.
- Verifies each finding with its own independent verifier returning CONFIRMED /
  PLAUSIBLE / REFUTED, dedups findings before that expensive step, carries a
  risk map out of round 1 into round 3, re-reviews its own fixes, and confirms
  every reported fix is actually present on disk.
- Has explicit fix-vs-park criteria and a what-not-to-flag list, so three rounds
  don't triple the noise.
