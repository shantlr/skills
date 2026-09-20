# Changelog

All notable changes to the `flow-review` skill.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), newest first.

## [4.0.0] - 2026-09-20

### Changed
- No longer commits its fixes. Fixes are applied in the working tree and
  reported in the conversation; they are committed only if you asked the flow
  to commit.

## [3.0.0] - 2026-09-20

### Removed
- **No more `review.md`.** The review report is now posted in the conversation
  only; nothing is written to the task folder. Fixes still land as their own
  `fix(...)` commits, so the durable record is the diff and the history.

## [2.2.0] - 2026-09-20

### Changed
- **At most 3 subagents are dispatched at a time.** Rounds with more work than
  that now run in sequential batches of 3, ordered by risk, instead of one big
  fan-out. Coverage is unchanged — every lens still runs and every surviving
  finding still gets its own verifier — but a review uses fewer concurrent
  agents, so it is lighter on rate limits and easier to follow.

## [2.1.0] - 2026-09-19

### Added
- **A guideline-conformance pass (round 2b).** Every surface the diff touches is
  checked against every applicable active rule in `docs/guidelines/`. A finding
  must name the rule ID (`violates DATA-FRESHNESS-3`) — one that cannot is not a
  guideline finding. Exceptions listed in the topic file or argued in `design.md`
  are not violations; re-litigating a decided exception is noise.
- Guideline findings go through the same refutation bar as every other finding.
- **Repeat findings become candidate rules.** A mistake found twice in different
  places is the signal a guideline is earned; it is nominated in `review.md`
  under `## Guideline candidates` with the evidence it recurred. Review
  nominates, `flow-doc` writes. Single occurrences are never nominated.
- `review.md` gained `## Guideline violations` and `## Guideline candidates`.

---

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
