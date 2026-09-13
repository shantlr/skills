# skills

Personal repository of Claude Code **Agent Skills**. This repo is the source of truth;
skills are consumed by symlinking or copying them into `~/.claude/skills/`.

## Layout

```
skills/
  <skill-name>/
    SKILL.md            # required — frontmatter + instructions
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

1. `mkdir -p skills/<name>` and write `SKILL.md`.
2. Add a row to the table in `README.md`.
3. Link it for local use: `ln -s "$PWD/skills/<name>" ~/.claude/skills/<name>`.

The `skill-creator` skill can scaffold and evaluate new skills.

## Conventions

- Commits follow Conventional Commits (`feat(skills): add <name>`).
- No secrets, no machine-specific absolute paths inside a skill.
- Scripts must be `chmod +x` and start with a shebang.
