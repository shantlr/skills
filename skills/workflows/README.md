# workflows

Skills that compose into one end-to-end feature workflow. Each stage is a standalone
skill; **`flow`** is the orchestrator that runs them in order.

```
                       ┌──────────┐
   "flow: add X"  ───► │   flow   │  orchestrator — runs stages, no approval gates
                       └────┬─────┘
                            │
   ┌────────────────┬───────┴───────┬──────────────┐
   ▼                ▼               ▼              ▼
 design    ──►  plan-implem  ──►  implem   ──►   review
   ⇄ user
   │                │               │              │
   ▼                ▼               ▼              ▼
 *-design.md     *-plan.md     code + commits   *-review.md
   │                                                 │
   └────────── docs/plans/YYYY-MM-DD-<slug>-*.md ────┘
               every stage reads the previous artifact
```

Stage 1 is the only one that talks to the user — grilling and designing are one
activity, so they live in one skill. Stages 2–4 run on the artifacts.

| Stage | Skill | Reads | Writes |
| --- | --- | --- | --- |
| 1 | [`flow-design`](./flow-design) | codebase + user | `…-design.md` |
| 2 | [`flow-plan-implem`](./flow-plan-implem) | design | `…-plan.md` |
| 3 | [`flow-implem`](./flow-implem) | plan | code, commits, plan checkboxes |
| 4 | [`flow-review`](./flow-review) | design + plan + diff | `…-review.md`, fixes |

Each stage can be invoked on its own (`/flow-plan-implem`) to redo or resume one
step.
