# Changelog

All notable changes to the `flow-implem` skill.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), newest first.

## [2.0.0] - 2026-09-19

### Changed
- Reads `tasks/<date>-<slug>/plan.md` instead of `docs/plans/<date>-<slug>-plan.md`.

## [1.0.0] - 2026-09-13

### Added
- Initial release. Stage 3 of the flow workflow: executes a plan wave by wave,
  dispatching every file-disjoint task in a wave to concurrent subagents in a
  single message, then verifying at a wave barrier.
- Keeps all git operations in the orchestrator so parallel agents cannot corrupt
  the index; commits one task per commit, staging only that task's owned files.
- Enforces exclusive file ownership, flags agents that wrote outside it, and
  falls back to separate git worktrees when tasks truly must share a file.
- Escalates to instrumentation after two failed fix attempts instead of
  guess-fixing, and loops back to `flow-design` when the design is at fault.
- Independently re-runs each task's verify before committing rather than trusting
  a subagent's report, and requires agents to watch each test fail before
  implementing.
