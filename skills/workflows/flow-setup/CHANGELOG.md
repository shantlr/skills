# Changelog

All notable changes to the `flow-setup` skill (formerly `setup-docs`) are
documented here.
Format follows [Keep a Changelog](https://keepachangelog.com), newest first.

## [2.3.0] - 2026-09-20

### Added
- **An update mode.** A project whose scaffold has fallen behind the skill can now
  be brought up to date — new instruction-file sections, an improved
  `build-index.sh`, a template that gained a field — without re-surveying the
  codebase, without a migration proposal, and without touching a single file you
  wrote. Triggers on "update my docs setup", "update the flow setup", "my docs
  scaffold is out of date". A new step 0 decides setup vs update before anything
  else runs.
- **`upgrade-flow.sh`** does the mechanical half. It finds the docs tree by its
  contents (so a `documentation/` tree works), then labels every machine-owned
  file `same` / `differs` / `missing`. Read-only by default; `--apply` writes,
  `--diff` shows. Two tiers: **tooling** (scripts, templates) is overwritten
  because it is the skill's and git holds the old copy, while **prose**
  (`docs/README.md`, the guideline and tasks READMEs) is only ever reported —
  a project may have localised it deliberately.
- **A version stamp** in the docs README's frontmatter (`flow_setup_version`,
  `docs_dir`, `guidelines`, `tasks`), written by `setup-flow.sh` and rewritten by
  `upgrade-flow.sh`. A tree with no stamp — anything set up before this release —
  is diffed from scratch instead of guessed at, so it needs nothing from you.
- **The update re-proposes guidelines the code already obeys**, with a higher bar
  than at setup: existing rules and decision records are read first so nothing
  already settled is re-raised, at most ~5 candidates, three cited occurrences
  each, and nothing is written unless you pick it one by one.

### Changed
- The instruction-file block is now reconciled **section by section** on an
  update: a missing section is appended, and a section you edited is kept as
  yours with the conflict reported — never silently restored to the shipped text.

## [2.2.0] - 2026-09-20

### Added
- **A `## Code comments` section** in the block written to `CLAUDE.md`. The rule
  is that a comment is present tense and must say something neither the code nor
  `docs/` already says. It bans the expensive failure mode specifically: history
  in the file ("this used to…", dates, sprint/wave labels, which agent wrote it),
  `docs/` retold in prose instead of cited in one line, incident transcripts that
  belong in a bug record, `── banner ──` essays and ASCII diagrams inside
  comments, comments correcting other comments, and a docstring on every
  self-evident union arm. Keeps what earns its place — why-not-the-alternative,
  warnings, one-line `@see` pointers, deliberate absences, API contracts. Caps
  file headers at ~3 lines and flags any file that is more comment than code.
  Cuts the tokens every human and agent spends re-reading an unmaintained second
  copy of the docs tree.
- **A `## Tests` section** in the same block. A test earns its place by being able
  to fail for a real reason — branches and boundaries, encoded decisions,
  regressions from a real bug record, public contracts. Not the framework, not
  mock-only tests, not one test per trivial getter, not a case a broader existing
  test already covers. The gate is "what bug would this have caught?"

### Changed
- Step 10 now appends to **`AGENTS.md`** when the project uses that name instead
  of `CLAUDE.md`, and where an existing project rule contradicts the block, the
  project's rule is kept and the conflict reported rather than overridden.

## [2.1.0] - 2026-09-19

### Added
- **`docs/guidelines/` — a rulebook for the conventions a project accumulates.**
  Cross-cutting rules that apply to every feature and therefore cannot live
  under one: *never render data that has silently gone stale*, *a destructive
  action names what it destroys*, *a failed mutation rolls back*. Organised as
  `guidelines/<area>/<topic>.md` with `ui-ux` as the first-class area.
- **Permanent, citable rule IDs.** `ui-ux/data-freshness.md` numbers its rules
  `DATA-FRESHNESS-1`, `-2`, … so a design can bind to a rule and a review can
  cite one. IDs are never renumbered or reused; a retired rule is struck
  through in place. `build-index.sh --check` now fails on a malformed, wrongly
  prefixed or duplicated ID, and on two areas claiming the same topic name.
- `./docs/new-record.sh guideline <area> "<Topic>"` creates a topic file with
  its rule IDs pre-seeded.
- `setup-flow.sh --guidelines` / `--guideline-area <name>` scaffold the tree.
  **Opt-in:** the skill offers it only when the project has a UI, because an
  empty rulebook is a folder people learn to ignore.
- After reading the codebase, the skill now **proposes the rules the project
  already follows** — a convention repeated in three or more places — and
  writes only the ones you confirm.
- `docs/INDEX.md` gained a generated `## Guidelines` section; the `CLAUDE.md`
  block now tells every agent to read the applicable area *before* writing
  code, and to cite rules by ID.

### Changed
- Existing docs trees are unaffected: without a `docs/guidelines/` directory,
  `INDEX.md` is byte-identical to before, so upgrading does not report your
  project as stale.

---

## [2.0.0] - 2026-09-19

### Changed
- **Renamed `setup-docs` → `flow-setup`, and moved into the `workflows` group**
  alongside the `flow` stages it serves. Re-link it:
  `rm ~/.claude/skills/setup-docs && ln -s "$PWD/skills/workflows/flow-setup" ~/.claude/skills/flow-setup`.
  `scripts/setup-docs.sh` is now `scripts/setup-flow.sh`.
- Triggers on "set up the flow" and "migrate my docs" as well as the previous
  docs phrases. Still user-invoked only — more strictly than before, since it
  now moves files.
- `docs/` is now explicitly the system *as it is now* and `tasks/` is *how it
  got there*, including the promotion path from a finished task into a feature
  README and its decision records.

### Added
- **Scaffolds a `tasks/` folder** next to `docs/` for the one-folder-per-unit-of-work
  layout `tasks/YYYY-MM-DD-<slug>/{design,plan,review}.md` — the structure the
  `flow` skills read and write. It refuses to scaffold into an existing `tasks/`
  that belongs to something else (a task runner, fixtures) and reports it
  instead; `--no-tasks` skips the step entirely.
- **Migration.** Before scaffolding, it surveys the project's actual structure,
  classifies each existing doc by the question it answers, and proposes a
  one-row-per-file table of moves for the user to confirm. Nothing moves
  unconfirmed, nothing is overwritten, and anything it cannot classify is
  reported as left alone rather than guessed at. Dates come from git history
  (`--follow`, oldest commit), so migrating does not backdate the whole corpus
  to the day it ran.
- `INDEX.md` gained a **Tasks** section listing every task folder and which of
  its artifacts exist, replacing the old Plans section.

### Removed
- **`docs/plans/` and the `plan` record kind.** `./docs/new-record.sh plan …`
  now exits with an error and the plan template is gone — a plan is a statement
  about the future, not documentation of the system, so it belongs with its
  task. Existing `docs/plans/` files are left alone; the new migration step
  offers to move them.

### Fixed
- `build-index.sh` no longer word-splits feature directory names containing
  spaces, and percent-encodes task folder names so generated links resolve.
- `build-index.sh` finds the project root by walking up for `.git`/`tasks`
  instead of assuming it is the docs directory's parent. A nested
  `--docs-dir sub/docs` previously reported "no tasks" and then failed
  `--check` forever.
- `new-record.sh` validates the record kind before the feature name, so a
  retired kind reports itself instead of "needs a feature name".

## [1.0.0] - 2026-09-13

### Added

- Initial release. Triggers on "set up docs", "create a docs folder", "scaffold
  docs", "document this project", "add decision records / ADRs / bug records".
- **`ARCHITECTURE.md` is the entry point**, and the skill writes it for real by
  reading your codebase rather than leaving a placeholder — an entry point that
  answers nothing is worse than none.
- **`FEATURE-MAP.md`** answers "which file does X?" It is generated from each
  feature README's `## Key files`, so it cannot drift from its source.
- **`INDEX.md`** lists every decision and bug record, generated from YAML
  frontmatter on the records. Finding a record no longer means browsing folders.
- **`build-index.sh --check`** fails when a generated file is stale, a listed
  key-file path no longer exists, or a feature's key files were never filled in.
  Wire it into CI — it is the only part of the system that notices drift itself.
- Records carry frontmatter (`status`, `date`, `feature`, `tags`, `supersedes`,
  `superseded_by`), so overturning a decision is an edit to two records rather
  than a delete, and the index can show what is still current.
- Scaffolds `docs/` with `README.md` (the index and the rules), `templates/`
  (`feature.md`, `bug.md`, `decision.md`, `plan.md`), one `features/<name>/`
  directory per feature area with `bugs/` and `decisions/`, and `plans/`.
- `scripts/setup-docs.sh` does the scaffolding and is idempotent — it never
  overwrites an existing file, reporting it as `skip` instead.
- Records are named `YYYY-MM-DD-kebab-title.md`, not `0001-`. Sequential numbers
  have to be allocated by reading the directory first, so two agents working in
  parallel worktrees both pick the same one; a date prefix needs no
  coordination, still sorts chronologically, and merges cleanly.
- `docs/new-record.sh` is installed into the project by the scaffolder: it
  stamps the date, slugifies the title, copies the right template, fills in the
  obvious fields, and refuses to overwrite.
- Proposes feature areas by reading the codebase, then confirms them with you
  before creating anything; asks before touching an existing `docs/`.
- Appends a `## Documentation` block to the project's `CLAUDE.md` so the docs
  keep getting updated after the scaffold lands.
- Records-live-under-their-feature layout: decisions and bugs are filed in
  `docs/features/<feature>/`, not in one global pile.
- `--docs-dir <name>` scaffolds into a directory other than `docs/`, rewriting
  the shipped README and templates to point at it.
- Record titles are inert data: a title containing `/ $ & \` or a newline
  becomes a clean ASCII slug and a correct heading, never syntax.
- Feature names are validated for every record kind, so a name like `../..`
  cannot place a record outside the repository.
- A failed render or a failed write leaves nothing behind — no half-written
  record, and no empty file blocking the retry.
- `references/optional-files.md` documents the shape of `DESIGN.md`,
  `ROADMAP.md`, `STATUS.md` and `DECISIONS.md`, which are deliberately *not*
  scaffolded — write them by hand when the project needs them.
