# skills

Personal collection of [Claude Code Agent Skills](https://docs.claude.com/en/docs/claude-code/skills).

Each skill lives in `skills/<name>/SKILL.md`. See [CLAUDE.md](./CLAUDE.md) for
authoring conventions.

## Skills

<!-- SKILLS:START -->

| Skill | Version | Description |
| --- | --- | --- |
| [skill-sync](./skills/skill-sync) | 1.0.0 | Release a finished skill (version bump + changelog) and sync installed skills in `~/.claude/skills` with this repo. |

<!-- SKILLS:END -->

## Versioning

Every skill carries a semver `version` in its `SKILL.md` frontmatter and its own
`skills/<name>/CHANGELOG.md`, so anyone using a skill can see what changed before
updating. Entries are written once iteration on a change is **finished**, not per
commit. See [CLAUDE.md](./CLAUDE.md#versioning--changelog).

Check what you have installed versus this repo:

```sh
./skills/skill-sync/scripts/status.sh
```

## Usage

Symlink a skill into your Claude Code skills directory:

```sh
ln -s "$PWD/skills/<name>" ~/.claude/skills/<name>
```

Or link them all:

```sh
for d in skills/*/; do ln -sfn "$PWD/$d" ~/.claude/skills/"$(basename "$d")"; done
```
