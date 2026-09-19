# Changelog

All notable changes to the `flow-design` skill.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), newest first.

## [2.1.0] - 2026-09-19

### Added
- **Active guidelines now bind the design.** Stage 1 loads the topics in
  `docs/guidelines/` that apply to the change (any UI work loads all of
  `ui-ux/`) and treats each active rule as a constraint. Contradicting one is
  allowed but must be written down as an argued exception — never silently.
- **Grilling got shorter.** A question a guideline already answers is not asked;
  the design cites the rule ID and moves on.
- `design.md` gained `## Guidelines applied` (each applicable rule and how it is
  satisfied or excepted) and `## Guideline candidates` — rules the conversation
  settled that are clearly not specific to this feature. Stage 1 only nominates;
  `flow-doc` writes them.
- No `docs/guidelines/` tree → the whole thing is skipped silently. It is never
  scaffolded here.

---

## [2.0.0] - 2026-09-19

### Changed
- Writes `tasks/<YYYY-MM-DD>-<slug>/design.md` instead of
  `docs/plans/<date>-<slug>-design.md`. Creates the task folder if the `flow`
  orchestrator hasn't.

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
