# skills

Personal repository of Claude Code **Agent Skills**. This repo is the source of truth;
skills are consumed by symlinking or copying them into `~/.claude/skills/`.

## Layout

```
skills/
  <skill-name>/
    SKILL.md            # required — frontmatter + instructions
    CHANGELOG.md        # required once released — see Versioning
    references/         # optional — docs loaded on demand
    scripts/            # optional — executable helpers
    assets/             # optional — templates, images
README.md               # index of all skills
```

- One directory per skill, `kebab-case`, matching the frontmatter `name`.
- Keep the directory name, the `name` field, and the README row in sync.

## SKILL.md format

```markdown
---
name: my-skill
description: What it does AND when to use it. Third person, <1024 chars.
version: 1.0.0
---

# My Skill

## Instructions
1. ...
```

Rules of thumb:

- **`description` is the trigger.** It is the only thing loaded into context until
  the skill fires, so write it as "Use this when the user ...". Include concrete
  trigger phrases the user would actually type.
- **Keep `SKILL.md` under ~500 lines.** Push detail into `references/` and link to it
  so it loads only when needed.
- **Progressive disclosure:** metadata → SKILL.md body → referenced files.
- **Write for an agent, not a human.** Imperative steps, explicit file paths, no
  marketing prose.
- **Prefer scripts over prose** for deterministic work (formatting, validation).

## Adding a skill

1. `mkdir -p skills/<name>` and write `SKILL.md` with `version: 1.0.0`.
2. Add a row to the table in `README.md`.
3. Create `CHANGELOG.md` with an `## [1.0.0] - YYYY-MM-DD` / `### Added` entry.
4. Link it for local use: `ln -s "$PWD/skills/<name>" ~/.claude/skills/<name>`.

The `skill-creator` skill can scaffold and evaluate new skills.

## Versioning & changelog

Skills are consumed by other people and other machines. They need to know *what
changed* before they pull an update — so every skill carries its own version and
changelog.

- `SKILL.md` frontmatter has a **semver** `version` field:
  - **major** — behavior or trigger changed; an existing user's workflow may break
    (description rewritten, steps reordered, a script's interface changed).
  - **minor** — new capability, backwards compatible (new step, new reference doc).
  - **patch** — wording, typos, clarifications; no behavioral change.
- `skills/<name>/CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com),
  newest entry first, using `Added` / `Changed` / `Fixed` / `Removed`.

**Write the entry only once you are done iterating on the skill.** One entry per
finished change — not per commit, not per edit. While a skill is still being
tuned, leave the version alone; bump and write the changelog as the last step,
in the same commit that finishes the work.

Write entries for the *consumer*: "Now also triggers on 'ship it'", not
"refactored step 3". If nothing observable changed, nothing goes in the changelog.

Use the **`skill-sync`** skill to do this — it bumps the version, writes the entry,
and updates the README row. It also checks installed skills in `~/.claude/skills`
against this repo and applies updates.

## Conventions

- Commits follow Conventional Commits (`feat(skills): add <name>`).
- No secrets, no machine-specific absolute paths inside a skill.
- Scripts must be `chmod +x` and start with a shebang.
