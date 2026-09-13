# Changelog

All notable changes to the `flow-design` skill.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), newest first.

## [1.0.0] - 2026-09-13

### Added
- Initial release. Stage 1 of the flow workflow and its only interactive stage:
  codebase scan, batched grilling (3–5 questions, each with a recommended
  answer), approach comparison, then a concrete specification — architecture,
  data flow, data model, interfaces, error handling, security, tests, rollout.
- Writes `docs/plans/<date>-<slug>-design.md`, including a decisions log that
  records rejected alternatives; downstream stages check themselves against it.
- Grilling and designing are one stage on purpose: specifying reveals unanswered
  questions, so the skill loops back and asks rather than assuming. Task
  breakdown is deliberately left to `flow-plan-implem`.
- Confirms the architecture and interface sections with the user before writing
  the rest of the document, since downstream stages consume them literally.
