---
name: skill-sync
description: Release and update Claude Code Agent Skills in this repo. Use this when the user is done iterating on a skill and wants to publish/release it (bump version, write CHANGELOG entry), or wants to check which installed skills in ~/.claude/skills are outdated or have drifted from the repo, or wants to update/sync/reinstall skills from the repo. Triggers on "release this skill", "bump the skill version", "write the changelog", "which skills are outdated", "check my installed skills", "sync my skills", "update my skills".
version: 1.0.0
---

# Skill Sync

Two jobs, one skill:

- **Release** — a skill in this repo is done being iterated on: bump its semver,
  write its `CHANGELOG.md` entry, update the README row.
- **Update** — compare `~/.claude/skills/*` against this repo, report drift, apply.

```
   RELEASE (author side)              UPDATE (consumer side)
   ─────────────────────              ──────────────────────
   edit SKILL.md                      ~/.claude/skills/foo  v1.0.0
        │  (iterate freely,                    ▲
        │   no version churn)                  │  symlink → always current
        ▼                                      │  copy    → stale, needs sync
   done? → bump version                        │
        → CHANGELOG entry  ────────────────────┘
        → README row                    show changelog since installed version,
        → commit                        then re-copy / re-link
```

## Deciding the bump

| Change | Bump | Example |
| --- | --- | --- |
| `description` / trigger phrases changed, steps reordered, script interface changed | **major** | user's existing invocation now behaves differently |
| New step, new reference doc, new optional capability | **minor** | backwards compatible addition |
| Wording, typos, clarification | **patch** | no observable behavior change |

If nothing observable changed for a *consumer*, do not bump and do not write an entry.

## Release workflow

Run this only when the user says they are **done** iterating — not after every edit.

1. Identify the skill directory: `skills/<name>/`, or `skills/<group>/<name>/` for
   a skill that belongs to a workflow group (e.g. `skills/workflows/flow-design/`).
   Locate it rather than assuming:
   ```sh
   ls -d skills/*/<name> skills/<name> 2>/dev/null
   ```
   Below, `skills/<name>/` means whichever path that returns.
2. Determine what actually changed since the last release:
   ```sh
   git log --oneline -- skills/<name>/
   git diff "$(git log -1 --format=%H -S'version:' -- skills/<name>/SKILL.md)" -- skills/<name>/
   ```
   If that is noisy, just `git diff HEAD~N -- skills/<name>/` over the iteration commits.
3. Pick the bump from the table above. State your reasoning to the user in one line
   and let them override.
4. Update `version:` in `skills/<name>/SKILL.md` frontmatter.
5. Prepend an entry to `skills/<name>/CHANGELOG.md` (create it if missing, using
   `assets/CHANGELOG.template.md`). Use today's date. Write entries from the
   consumer's point of view:
   - Good: `Now also triggers on "ship it" and "cut a release".`
   - Bad: `Refactored step 3 into a table.`
6. Update the skill's row in the root `README.md` if the description changed.
7. Commit everything together:
   `git commit -m "feat(<name>): <summary>"` (or `fix(...)` for a patch).

## Update workflow

1. If the user wants remote changes first, ask before running `git pull`.
2. For each directory in `~/.claude/skills/`:
   - **Symlink into this repo** → already current. Report as `linked`.
   - **Copy** → read `version:` from both `~/.claude/skills/<name>/SKILL.md` and
     `skills/<name>/SKILL.md`. Compare semver.
   - **Not in this repo** → report as `external` (leave it alone; do not delete).
   - **In repo but not installed** → report as `not installed`.
3. Render a table:

   ```
   skill                 installed   repo      status
   ─────────────────────────────────────────────────────
   git-commit            1.0.0       1.2.0     ↑ outdated
   pr-format             →repo       1.0.0     linked
   frontend-design       1.1.0       1.1.0     ok
   work-item-summary     1.0.0       —         external
   ```
4. For each outdated skill, show the `CHANGELOG.md` entries **between** the
   installed version and the repo version, so the user sees what they are getting.
5. Only after confirmation, apply:
   - re-link: `ln -sfn "$REPO/skills/<name>" ~/.claude/skills/<name>`
   - or re-copy: `rm -rf ~/.claude/skills/<name> && cp -R "$REPO/skills/<name>" ~/.claude/skills/<name>`
6. If a copy has local edits that are not in the repo (drift), say so and stop —
   overwriting would lose the user's changes. Offer to port them back into the repo first.

## Helper

`scripts/status.sh` prints the installed-vs-repo comparison as TSV. Run it instead of
hand-globbing:

```sh
./skills/skill-sync/scripts/status.sh
```

## Rules

- Never bump a version without a matching changelog entry, and never write a
  changelog entry without bumping.
- Never delete a skill in `~/.claude/skills` that does not exist in this repo.
- Never overwrite a drifted installed copy without explicit confirmation.
