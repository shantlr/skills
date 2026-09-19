---
name: flow-plan-implem
description: Stage 2 of the flow workflow — converts a finished design document into a maximally parallel implementation plan: a contracts-first task, then waves of file-disjoint tasks that subagents can run concurrently, each with exact owned files, tests and a verify command. Use when a design artifact exists (tasks/*/design.md) and the user asks to plan the implementation, break it into tasks, or "parallelize this work". For a multi-step plan with no preceding design document, use superpowers-writing-plans instead.
version: 2.0.0
---

# Flow / Plan-Implem: a wide, executable checklist

**Input:** `tasks/<date>-<slug>/design.md`.
**Output:** `tasks/<date>-<slug>/plan.md` — a checklist agents can execute
**in parallel** without re-reading the design.

Plan for width. A plan is good when many tasks can run at once; a chain of ten
sequential tasks is a planning failure, not a fact about the work. Two things
buy width: **contracts landed first**, and **exclusive file ownership**.

## Instructions

### 1. Enumerate the work from the design

Walk the design section by section and list every change it implies: migrations,
types, modules, endpoints, UI, wiring, config, tests, docs. Nothing in the design
may be left unclaimed by a task — verify this in the coverage table at the end.

### 2. Land the contracts first (T0)

The single biggest unlock for parallelism: one small serial task that writes
**every shared boundary** the design specifies, with real signatures and
stub bodies (`throw new Error('not implemented')`).

```
 T0 contracts: types, interfaces, function signatures, error codes,
               empty modules, migration file, route stubs
      │
      └─► after T0 everything typechecks, so every later task can be
          written and verified against the contract instead of waiting
          for the implementation underneath it
```

Include in T0: shared types/DTOs, interface declarations, public function
signatures, error enums, the migration, and any new file's skeleton. Exclude:
all logic. T0 should be minutes of work and must typecheck when done.

Without T0 you get `types → repo → service → endpoint → UI`, a five-deep chain.
With T0 those four implementations become one wave.

### 3. Slice by file ownership, not by layer

One task = one coherent change that compiles, passes its tests, and can be
committed on its own. Then add the parallelism constraint:

> **Every task declares `Owns` — the files it is the only task allowed to write.
> Two tasks in the same wave must have disjoint `Owns` sets.**

- If a task's description needs the word "and" twice, split it.
- If a task can't be verified, it isn't a task — it's a step inside one.
- Smaller tasks make wider waves. Prefer 20–60 minutes each over 90.
- Reading a file others own is fine (`Reads`). Writing it is not.

**Shared-file conflict magnets** — barrel/`index` files, DI registries, route
tables, config, i18n bundles, lockfiles, generated code. Never let two tasks
edit one. Either:
- give all edits to that file to a single **wiring task** at the end of the wave, or
- have T0 pre-register the entries so no later task touches the file at all.

The second is better. Prefer it.

### 4. Group into waves

```
 WAVE 0 ── T0 contracts                                   (serial, 1 task)
              │
 WAVE 1 ── T1 repo ∥ T2 validation ∥ T3 service ∥ T4 UI   (4 agents, disjoint)
              │
 WAVE 2 ── T5 endpoint ∥ T6 e2e tests                     (2 agents)
              │
 WAVE 3 ── T7 wiring + docs                               (serial)
```

A wave is a set of tasks with all dependencies satisfied and pairwise-disjoint
`Owns`. Put a task in the earliest wave it can legally run in.

Then state the **critical path** (longest dependency chain) and, for anything
forced serial, one line on why. If the critical path is most of the tasks,
go back to step 2 — usually a missing contract in T0.

### 5. Write each task in this shape

```markdown
- [ ] **T3 — FooService.create**
  - Wave: 1
  - Depends on: T0
  - Owns: `src/modules/foo/foo.service.ts`, `src/modules/foo/foo.service.test.ts`
  - Reads: `src/modules/foo/foo.types.ts`, `src/modules/roles/roles.service.ts`
  - Do: implement `create` against the `FooRepo` interface from T0, following
    the pattern in `src/modules/roles/roles.service.ts`.
  - Tests: happy path, duplicate name, missing owner.
  - Verify: `npm test -- foo.service`
  - Done when: tests green, no `any`, no calls outside the T0 interfaces.
```

`Verify` must be a command scoped to this task's files — never the full suite
(that runs once per wave barrier) and never "looks right".

**Scope it to tests, not to typechecking.** Most toolchains (`tsc`, `go build`,
`cargo check`) type-check the whole program, so a "scoped" typecheck does not
exist: an agent running one will see transient errors from siblings still
mid-edit. Put the task's test command in `Verify`, and leave whole-program
typechecking to the wave barrier. If the project has no test runner, say so in
**Preflight** and use the narrowest real check available (lint on the owned
files, a build, a smoke command) — never a vague one.

### 6. Add the scaffolding sections

- **Preflight** — exact commands for install / migrate / typecheck / test / lint,
  discovered from `package.json` or equivalent. Implem uses these verbatim.
- **Wave table** — wave → tasks → max concurrency.
- **File ownership check** — one row per file, listing the task that owns it.
  A file with two owners in the same wave is a planning bug; fix it before writing.
- **Do not parallelize** — call out work that must stay serial even when
  file-disjoint: database migrations, code generation, dependency installs
  (lockfile), repo-wide formatters, anything binding a fixed port.
- **Risk list** — the two or three tasks most likely to go wrong, and the
  fallback for each.
- **Out of scope** — copied forward from the design so implem doesn't drift.
- **Coverage check** — table mapping each design section to the tasks covering it.
- **Discovered** — an empty `## Discovered` heading. `flow-implem` appends
  pre-existing bugs and out-of-scope findings here instead of fixing them.

### 7. Validate, write, commit

Check `Owns` disjointness mechanically rather than by eye:

```sh
~/.claude/skills/flow-plan-implem/scripts/check-plan.sh tasks/<date>-<slug>/plan.md
```

It reports any file owned by two tasks in the same wave, any task missing
`Owns`/`Wave`/`Verify`, and the width of each wave.

**STOP. Do not commit the plan or hand off until this reports zero errors.**
A plan that fails the check will collide at runtime, and two agents will lose
their work to each other.

Commit as `docs(tasks): add <slug> implementation plan`, then hand off to
`flow-implem`.

## Revision mode

`flow-implem` re-enters this skill when the design changed mid-implementation.
Some tasks are already checked and **committed**, so the plan is append-only
from here:

1. **Never renumber or delete an existing task.** Commit messages and checkboxes
   already reference those numbers.
2. Tasks that are checked and still valid: leave untouched.
3. Tasks that are checked but now **wrong**: leave them checked, and add a new
   task that supersedes them — `T9 — supersedes T4: …`, with a `Why` line
   pointing at the design's `## Revision` section. Implem will not re-run T4.
4. Tasks that are unchecked and now wrong: edit them in place. Nothing depends
   on their old text yet.
5. New tasks go in new waves appended after the current one, with their own
   `Owns` sets — re-run `check-plan.sh`, since a new task can collide with an
   unchecked existing one.
6. Add a `## Revisions` section to the plan: date, what changed in the design,
   which tasks were added or superseded.

## Rules

- **Plan for width.** Report the wave count and critical path; a long chain
  needs justifying.
- **Contracts before logic.** T0 exists in every plan.
- **`Owns` is exclusive**, and disjoint within a wave. This is what makes
  parallel agents safe.
- **Exact file paths** — no "the relevant component".
- **Every task independently verifiable** with a scoped command.
- **Tests live inside their task**, not in a task at the end.
- **No task invents design.** If a task would need a decision, the design is
  incomplete — go back to `flow-design`.
- **Keep each task readable in one screen.**

## Red flags — stop if you think any of these

| Thought | Reality |
| --- | --- |
| "I'll let these two tasks both own the barrel file, just this once." | That is the collision the whole scheme exists to prevent. Give it to T0 or one wiring task. |
| "The chain is long, but that's just how this feature is." | Almost always a missing contract in T0. Try again before accepting it. |
| "This task is hard to verify, I'll write 'verify manually'." | Then it isn't a task yet. Find a command, or split until you can. |
| "I'll note the file paths roughly, implem can figure it out." | A parallel agent has no one to ask. Exact paths or it collides. |
| "This task needs a decision, I'll pick the obvious one." | The design is incomplete. Go back to `flow-design` — planning is not the place to decide. |
| "check-plan.sh only reported warnings, close enough." | Warnings are fine. Errors are not. Read which you have. |
