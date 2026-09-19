# skills

Personal collection of [Claude Code Agent Skills](https://docs.claude.com/en/docs/claude-code/skills).

Each skill lives in `skills/<name>/SKILL.md`. See [CLAUDE.md](./CLAUDE.md) for
authoring conventions.

## Skills

<!-- SKILLS:START -->

| Skill | Version | Description |
| --- | --- | --- |
| [skill-sync](./skills/skill-sync) | 1.0.0 | Release a finished skill (version bump + changelog) and sync installed skills in `~/.claude/skills` with this repo. |
| [flow](./skills/workflows/flow) | 2.1.0 | Runs the full feature workflow end to end — design, plan, implement, review, document — handing off artifacts in `tasks/<date>-<slug>/`. |
| [flow-design](./skills/workflows/flow-design) | 2.1.0 | Stage 1 — scans the codebase, grills the user until nothing is ambiguous, then writes the technical design. The only interactive stage. |
| [flow-plan-implem](./skills/workflows/flow-plan-implem) | 2.0.0 | Stage 2 — converts a design into a maximally parallel plan: contracts first, then waves of file-disjoint tasks. Ships `check-plan.sh`. |
| [flow-implem](./skills/workflows/flow-implem) | 2.1.0 | Stage 3 — executes the plan wave by wave, dispatching file-disjoint tasks to concurrent subagents, one commit per task. |
| [flow-review](./skills/workflows/flow-review) | 2.1.0 | Stage 4 — three escalating multi-agent review rounds over the working diff, fixes findings, reports root causes. |
| [flow-doc](./skills/workflows/flow-doc) | 1.1.0 | Stage 5 — promotes the finished task into the project's `docs/` tree: feature one-pager plus a decision record per rejected alternative. Promotes earned rules into `docs/guidelines/`. |
| [flow-setup](./skills/workflows/flow-setup) | 2.1.0 | Scaffolds the `docs/` + `tasks/` trees the flow lives in, including the `docs/guidelines/` rulebook, and migrates an existing project onto that layout. User-invoked only. |

<!-- SKILLS:END -->

Skills that compose into a single workflow live in a group directory —
`skills/workflows/` — one level deep. See [skills/workflows](./skills/workflows)
for how the `flow` stages fit together.

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
for d in skills/*/ skills/*/*/; do
  [ -f "$d/SKILL.md" ] || continue   # skips group dirs like skills/workflows/
  ln -sfn "$PWD/${d%/}" ~/.claude/skills/"$(basename "$d")"
done
```
