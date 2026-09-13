# Changelog

All notable changes to the `flow-plan-implem` skill.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), newest first.

## [1.0.0] - 2026-09-13

### Added
- Initial release. Stage 2 of the flow workflow: slices a design into small,
  independently verifiable tasks with exact files, tests, dependencies and a
  scoped verify command each.
- Plans for parallelism: a contracts-first `T0` task lands every shared type and
  signature as a stub so downstream tasks stop queuing behind each other, tasks
  declare an exclusive `Owns` file set, and tasks are grouped into waves of
  pairwise-disjoint tasks that can run concurrently.
- Emits a file-ownership table, a wave table, the critical path, and an explicit
  "do not parallelize" list (migrations, codegen, installs, repo-wide formatters).
- Ships `scripts/check-plan.sh`, which validates a plan mechanically: files owned
  by two tasks in the same wave, tasks missing `Wave`/`Owns`/`Verify`, and how
  wide each wave actually is.
- Has a revision mode for when the design changes mid-implementation: the plan
  becomes append-only, superseding tasks rather than renumbering committed ones.
- Writes `docs/plans/<date>-<slug>-plan.md` as an executable checklist.
