# skills

Personal collection of [Claude Code Agent Skills](https://docs.claude.com/en/docs/claude-code/skills).

Each skill lives in `skills/<name>/SKILL.md`. See [CLAUDE.md](./CLAUDE.md) for
authoring conventions.

## Skills

<!-- SKILLS:START -->

| Skill | Description |
| --- | --- |
| _none yet_ | Add one with `mkdir -p skills/<name>` and a `SKILL.md`. |

<!-- SKILLS:END -->

## Usage

Symlink a skill into your Claude Code skills directory:

```sh
ln -s "$PWD/skills/<name>" ~/.claude/skills/<name>
```

Or link them all:

```sh
for d in skills/*/; do ln -sfn "$PWD/$d" ~/.claude/skills/"$(basename "$d")"; done
```
