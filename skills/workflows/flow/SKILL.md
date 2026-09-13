---
name: flow
description: Runs the full feature workflow end to end — design (scan, grill, specify), then plan, implement and review — handing off markdown artifacts between stages. Use this when the user asks to "flow" something, says "run the flow", "full flow", "take this from idea to PR", "do the whole workflow", or describes a feature and wants it built properly rather than quick-and-dirty. Also use to resume a half-finished flow from its artifacts in docs/plans/.
version: 1.0.0
---

# Flow: idea → design → plan → implement → review

## Overview

`flow` is an orchestrator. It does no work itself — it runs four stage skills in
order and carries artifacts between them.

```
   design    ──►   plan-implem   ──►   implem   ──►   review
     ⇄ user
  scan, grill,     contracts +        waves of      verify, fix,
  specify          waves of           parallel      report
                   disjoint tasks     agents
  ─────────────    ───────────────────────────────────────────
  interactive      autonomous
```

Stage 1 is the only one that talks to the user. Everything after it runs on the
artifacts.

**Run end to end without approval gates.** Do not stop after a stage to ask
"shall I continue?". Stop *only* when you hit something you genuinely cannot
decide from the codebase — a product decision, a tradeoff with no clear winner,
a missing credential. Then ask (batched, with a recommendation) and keep going.

## Instructions

1. **Pick the slug.** Derive a kebab-case topic slug from the request
   (`add-oauth-login`). Get today's date once: `date +%F`. All artifacts live at
   `docs/plans/<YYYY-MM-DD>-<slug>-<stage>.md`.

2. **Detect resume point.** `ls docs/plans/ | grep <slug>`. Start at the first
   stage whose artifact is missing (or whose plan has unchecked tasks). Say in one
   line where you are starting and why. Never redo a completed stage unless the
   user asked.

3. **Run each stage by invoking its skill**, in order, passing the slug and date:

   | Stage | Skill | Skip when |
   | --- | --- | --- |
   | 1 | `flow-design` | `…-design.md` exists |
   | 2 | `flow-plan-implem` | `…-plan.md` exists |
   | 3 | `flow-implem` | all plan tasks checked |
   | 4 | `flow-review` | never — always review |

4. **Between stages, do a 3-line handoff.** State: artifact written, the single
   most important decision in it, and what the next stage will do with it. No
   approval question.

5. **Loop back when a stage invalidates an earlier one.** If implem discovers the
   design is wrong, do not patch around it: re-enter `flow-design` for the
   affected part, update the artifact (append a `## Revision — <date>` section,
   never silently rewrite history), regenerate the affected plan tasks, continue.

6. **Report at the end.** One summary containing:
   - ASCII diagram of what was built
   - Table of artifacts written (path + one-line contents)
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
  (`docs(plans): add <slug> design`), so the flow is resumable from a clean tree.
- **Never skip review.**
- **Report root causes, not just fixes.**
