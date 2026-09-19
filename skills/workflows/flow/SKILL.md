---
name: flow
description: Runs the full feature workflow end to end — design (scan, grill, specify), then plan, implement, review and document — handing off markdown artifacts in a per-task folder under tasks/. Use this when the user asks to "flow" something, says "run the flow", "full flow", "take this from idea to PR", "do the whole workflow", or describes a feature and wants it built properly rather than quick-and-dirty. Also use to resume a half-finished flow from its artifacts in tasks/YYYY-MM-DD-<slug>/.
version: 2.1.0
---

# Flow: idea → design → plan → implement → review → document

## Overview

`flow` is an orchestrator. It does no work itself — it runs five stage skills in
order and carries artifacts between them.

```
   design    ──►  plan-implem  ──►  implem   ──►  review   ──►   doc
     ⇄ user
  scan, grill,    contracts +      waves of      verify,      promote to
  specify         waves of         parallel      fix,         docs/
                  disjoint tasks   agents        report
  ─────────────   ─────────────────────────────────────────────────────
  interactive     autonomous

  tasks/<date>-<slug>/          ← working artifacts, live with the task
    design.md  plan.md  review.md
                    │
                    └──► docs/  ← what survives the task (stage 5)
                           features/  decisions/
                           guidelines/<area>/<topic>.md
                             ▲ read by 1 (constraints), 3 (dispatch prompts),
                               4 (conformance) — written only by 5
```

**Two homes, on purpose.** `tasks/<date>-<slug>/` is the record of *this piece
of work* — what was decided, what was built, what review found. `docs/` is the
record of *the system as it is now*. Stage 5 is the bridge; without it the
knowledge stays buried in a dated folder nobody re-reads.

Stage 1 is the only one that talks to the user. Everything after it runs on the
artifacts.

**Run end to end without approval gates.** Do not stop after a stage to ask
"shall I continue?". Stop *only* when you hit something you genuinely cannot
decide from the codebase — a product decision, a tradeoff with no clear winner,
a missing credential. Then ask (batched, with a recommendation) and keep going.

## Instructions

1. **Pick the task folder.** Derive a kebab-case topic slug from the request
   (`add-oauth-login`). Get today's date once: `date +%F`. The task directory is
   `tasks/<YYYY-MM-DD>-<slug>/`; every stage artifact is a fixed filename inside
   it — `design.md`, `plan.md`, `review.md`. Create it with `mkdir -p` at the
   start and pass the path to every stage.

   ```
   tasks/2026-09-19-add-oauth-login/
     design.md    ← stage 1
     plan.md      ← stage 2   (stage 3 ticks its checkboxes)
     review.md    ← stage 4
   ```

   A stage may drop extra scratch files in the folder (`notes.md`, a scratch
   diagram) — only the three above are contracts between stages.

2. **Detect resume point.** `ls -d tasks/*-<slug>/ 2>/dev/null` — reuse the
   existing folder if one is found, even under an older date; only mint a new
   dated folder when there is none. Then `ls tasks/<date>-<slug>/` and start at
   the first stage whose artifact is missing (or whose plan has unchecked tasks).
   Say in one line where you are starting and why. Never redo a completed stage
   unless the user asked.

3. **Run each stage by invoking its skill**, in order, passing the task folder
   path and the slug:

   | Stage | Skill | Skip when |
   | --- | --- | --- |
   | 1 | `flow-design` | `design.md` exists |
   | 2 | `flow-plan-implem` | `plan.md` exists |
   | 3 | `flow-implem` | all plan tasks checked |
   | 4 | `flow-review` | never — always review |
   | 5 | `flow-doc` | repo has neither a `docs/features/` nor a `docs/guidelines/` tree |

4. **Between stages, do a 3-line handoff.** State: artifact written, the single
   most important decision in it, and what the next stage will do with it. No
   approval question.

5. **Loop back when a stage invalidates an earlier one.** If implem discovers the
   design is wrong, do not patch around it: re-enter `flow-design` for the
   affected part, update the artifact (append a `## Revision — <date>` section,
   never silently rewrite history), regenerate the affected plan tasks, continue.

6. **Report at the end.** One summary containing:
   - ASCII diagram of what was built
   - Table of artifacts written — the task folder's files *and* the `docs/`
     pages stage 5 created or updated (path + one-line contents)
   - Table of fixes from review: symptom → **root cause** → fix
   - Anything deliberately left out of scope

## When to stop and ask

Ask — batched 3–5 questions, each with a recommended answer, via an
ask-question tool if one is available — only for:

- Product/UX decisions the codebase cannot answer
- Two viable designs with a real tradeoff and no local precedent
- Destructive or irreversible actions (data migration, deleting a table, force push)
- Missing access, secrets, or an external dependency

Never ask for: anything greppable, naming you can infer from convention,
permission to proceed to the next stage.

Expect nearly all of this during stage 1. If stage 3 or 4 is asking a lot of
questions, the design was incomplete — fix the design artifact, don't keep
asking inline.

## Rules

- **One stage's output is the next stage's only input.** If a stage needs
  something not in the previous artifact, that artifact was incomplete — go fix
  it there, not inline.
- **Artifacts are committed.** Commit each artifact as it is written
  (`docs(tasks): add <slug> design`), so the flow is resumable from a clean
  tree. The `tasks/` tree is history — never gitignored, never deleted when the
  work ships.
- **Never skip review.**
- **`tasks/` is the work, `docs/` is the system.** Stages 1–4 write their
  artifacts only into the task folder (stage 3 also writes code, naturally).
  Only stage 5 may write into `docs/` — **including `docs/guidelines/`**.
  Stages 1 and 4 read the rules and *nominate* new ones into their own
  artifact; neither creates nor edits a topic file.
- **Report root causes, not just fixes.**
