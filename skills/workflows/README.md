# workflows

Skills that compose into one end-to-end feature workflow. Each stage is a standalone
skill; **`flow`** is the orchestrator that runs them in order.

```
                       ┌──────────┐
   "flow: add X"  ───► │   flow   │  orchestrator — runs stages, no approval gates
                       └────┬─────┘
                            │
   ┌────────────┬───────────┼───────────┬────────────┐
   ▼            ▼           ▼           ▼            ▼
 design ──► plan-implem ──► implem ──► review ──►   doc
   ⇄ user
   │            │           │           │            │
   ▼            ▼           ▼           ▼            ▼
design.md    plan.md   code+commits  review.md    docs/…
   │                                      │            │
   └──── tasks/YYYY-MM-DD-<slug>/ ────────┘            │
         every stage reads the previous artifact       │
                                                       ▼
                                     docs/features/<f>/README.md + decisions/
```

**House rules.** `docs/guidelines/<area>/<topic>.md` holds the cross-cutting rules
the project has settled on — how stale data is handled, what a destructive action
confirms — each with a permanent ID (`DATA-FRESHNESS-3`). Stage 1 treats them as
design constraints, stage 3 pastes them into subagent prompts, stage 4 reports
violations by ID, and stage 5 is the only stage that writes a new one.

**Two homes.** `tasks/<date>-<slug>/` holds the record of *this piece of work*
(design, plan, review) and is committed as history. `docs/` holds the record of
*the system as it is now*. Stage 5 is the only bridge between them: no stage
before it writes anything under `docs/` (stage 3 writes code, of course — the
rule is about which *documentation* tree a stage may touch).

Stage 1 is the only one that talks to the user — grilling and designing are one
activity, so they live in one skill. Stages 2–5 run on the artifacts.

| Stage | Skill | Reads | Writes |
| --- | --- | --- | --- |
| 1 | [`flow-design`](./flow-design) | codebase + user | `tasks/<date>-<slug>/design.md` |
| 2 | [`flow-plan-implem`](./flow-plan-implem) | design | `…/plan.md` |
| 3 | [`flow-implem`](./flow-implem) | plan | code, commits, plan checkboxes |
| 4 | [`flow-review`](./flow-review) | design + plan + diff | `…/review.md`, fixes |
| 5 | [`flow-doc`](./flow-doc) | all three + diff | `docs/features/<f>/…`, `docs/guidelines/…` |

Each stage can be invoked on its own (`/flow-plan-implem`) to redo or resume one
step.

## Setting the folders up — [`flow-setup`](./flow-setup)

Not a stage: it runs **once per project**, before any flow, and only when the
user explicitly asks for it.

```
   existing repo ──► flow-setup ──► docs/  + tasks/  ──► ready for `flow`
                         │
                         └─ surveys what's already there and proposes a
                            file-by-file migration onto the layout
```

It scaffolds `docs/` (ARCHITECTURE.md, per-feature one-pagers, decision and bug
records, the `guidelines/` rulebook, generated FEATURE-MAP.md / INDEX.md) and
`tasks/`, and folds any existing docs, plans or ADR pile into them — one
confirmed row at a time.

Stage 5 deliberately does **not** call it: `flow-doc` skips itself when a
project has no `docs/` tree rather than scaffolding one behind the user's back.
