# tasks/

One directory per unit of work: `tasks/YYYY-MM-DD-<kebab-slug>/`.

```
tasks/
└── 2026-09-19-extract-the-queue/
    ├── design.md    what we decided to build, and why — written BEFORE the work
    ├── plan.md      the executable task breakdown; checkboxes get ticked
    └── review.md    what review found after the work landed, with root causes
```

This folder is **how the system got here**. `docs/` is **what the system is
now**. Both are committed; neither replaces the other.

```
   tasks/<date>-<slug>/  ──── the durable parts ────►  docs/
   dated, append-only                                  present tense, edited
   "what did we do in Sept?"                           "how does this work?"
```

## Writing path

| I am… | Write |
| --- | --- |
| starting a piece of work | `tasks/<today>-<slug>/design.md` |
| breaking it into tasks | `…/plan.md` |
| reviewing what landed | `…/review.md` |
| finished, and it changed the system | `docs/features/<f>/README.md` + a decision record |

The `flow` skills write all four for you: `flow-design` → `flow-plan-implem` →
`flow-implem` → `flow-review` → `flow-doc`.

## Rules

- **A design is not edited after the work starts.** If it turns out wrong, that
  is a finding — append a `## Revision — <date>` section, never rewrite history.
  A silently-corrected design teaches nobody anything.
- **Never delete a task folder when the work ships.** It is the record.
- **Nothing here is the source of truth about current behaviour.** Six-month-old
  task folders describe a system that has moved on; `docs/` does not.
- **The last step of a task is promoting it into `docs/`.** A task folder that
  never produced a docs change either changed nothing, or lost its knowledge.
