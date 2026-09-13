# Changelog

All notable changes to the `flow` skill.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), newest first.

## [1.0.0] - 2026-09-13

### Added
- Initial release. Orchestrates the full feature workflow — design → plan-implem
  → implem → review — passing markdown artifacts through
  `docs/plans/<date>-<slug>-*.md`.
- Runs end to end with no approval gates; stops only for genuine user decisions,
  nearly all of which land in stage 1.
- Resumes a half-finished flow by detecting which artifacts already exist.
