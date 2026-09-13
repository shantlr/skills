# Changelog

All notable changes to the `setup-docs` skill are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com), newest first.

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
