---
name: flow-design
description: Stage 1 of the flow workflow — scans the codebase for facts, grills the user until every branch of the idea is decided, compares approaches, and writes a full technical design (architecture, data model, interfaces, failures, tests) to docs/plans. You MUST use this before any creative work — new feature, new component, changed behavior. Use when the user says "brainstorm", "grill me", "let's think this through", "design this", "how should we build this", "architecture", or hands over a vague idea. The only stage of the flow that talks to the user.
version: 1.0.0
---

# Flow / Design: grill until crystal clear, then specify it

**Output:** `docs/plans/<YYYY-MM-DD>-<slug>-design.md`.
**Not in scope:** task breakdown and ordering — that is `flow-plan-implem`.

Questioning and designing are one activity, not two. Grilling surfaces
architectural questions; sketching architecture surfaces unanswered product
questions. Move between them freely — just don't leave either unfinished.

Three rules:

1. **Facts from code, decisions from user.** If grep can answer it, don't ask it.
2. **Always recommend.** Every question ships with your recommended answer and
   the evidence for it. The user accepts, rejects, or modifies.
3. **Batch but never skip.** 3–5 related questions per round. Minor ambiguity
   causes major bugs.

```
 Phase 0          Phase 1              Phase 2         Phase 3
 scan     ──►     grill      ──►     approaches  ──►   specify
 (no questions)   (batched)   ◄──    (pick one)  ◄──   (concrete)
                       ▲                                   │
                       └──── new questions discovered ──────┘
```

## Phase 0 — Codebase scan (before any question)

Explore, in parallel subagents when the codebase is large:

- **Existing patterns** — how does this repo already do similar things?
- **Constraints** — schema, API contracts, auth model, dependencies, build.
- **Closest analogue** — find the most similar existing feature. Read it end to end.
- **Blast radius** — what will this touch, what depends on it?

Post a ≤5-line findings summary with file paths:

> **Codebase context:** auth is JWT via `src/middleware/auth.ts`; Prisma +
> Postgres; closest analogue is `src/modules/roles/` (repository pattern);
> no tests in this module.

These findings pre-answer factual questions and become the *evidence* in your
recommendations. Designing against a stale finding is this stage's most common
failure — verify, don't assume.

## Phase 1 — Grill every branch

The design is a tree. Each answer opens branches. Walk every branch until it
terminates.

```
                    Idea
                   /     \
            Purpose       Scope
           /   |   \      /     \
        Who  What  Why  in-v1   out-of-scope
        /      |            |
   persona  core flow    boundaries
             /  |  \
         happy error edge
```

Track three buckets and re-state them in one line between rounds:
**Decided** / **Open** / **Discovered**.

### Question format

If an **ask-question tool** is available, use it — a structured form beats prose
for this, and it lets the user answer a whole batch at once. Whatever its exact
schema, carry these across:

- **Context up front** — the goal, what you found in the code, and what decision
  is needed. Assume the user has not read your previous message.
- **One question per decision**, each a single choice or free text.
- **Options with a one-line consequence each**, and the recommended one marked.

Otherwise ask in plain text — numbered questions, lettered options,
recommendation marked `*(Recommended)*` with its reason:

```
## Authentication

1. **How should users authenticate?**
   a) JWT + refresh tokens *(Recommended)* — matches existing
      `src/middleware/auth.ts`, no new infrastructure
   b) Session-based — more server state, simpler revocation
   c) OAuth only — least code, vendor dependency
```

Either way the content is identical. The tool is a convenience, not a
requirement — never skip a question because the form is unavailable.

### Coverage checklist

Adapt the order to what the user says, but do not finish until all are covered:

- **Purpose** — what, why, for whom (real personas), what success looks like,
  the happy path start to finish.
- **Scope** — explicitly in v1; explicitly out (YAGNI ruthlessly); hard
  constraints (deadline, stack, perf, compliance); external dependencies.
- **Behavior** — states and transitions, permissions, empty/loading states,
  defaults, copy that matters.
- **Failure** — error states, retries, concurrency and races, 10× scale,
  security (authn, authz, injection, data exposure), migration/backfill.
- **Verification** — how will we know it works? What must be tested?

Push back on vagueness: "we'll figure it out later" → "what specifically? let's
nail it now." Surface conflicts explicitly when two answers disagree.

**Stop grilling when** every branch terminates and no open decision blocks
another. If you are unsure whether something is resolved, it isn't.

## Phase 2 — Approaches

Propose 2–3. For each: one-paragraph sketch, what it changes, cost, risk, fit
with existing patterns. Then:

| Approach | Fits existing patterns | Effort | Risk | Reversible? |

Lead with your recommendation, justified in terms of *this* codebase. If the
tradeoff is genuine and local precedent doesn't settle it, ask — one question,
options with consequences, recommendation marked. Otherwise decide and move on.

## Phase 3 — Specify it

Cover all of these. ASCII diagram anything with more than two moving parts.

- **Architecture** — components and responsibilities, one line each.

  ```
   Client ──► /api/foo ──► FooService ──► FooRepo ──► Postgres
                  │             │
                  │             └──► events.emit('foo.created')
                  └──► authMiddleware (JWT)
  ```

- **Data flow** — happy path as a numbered sequence; then each failure path.
- **Data model** — entities, fields, types, nullability, indexes, migrations.
  Exact names.
- **Interfaces** — function/endpoint signatures, request/response shapes, error
  codes. Exact enough to implement without inventing, because `flow-plan-implem`
  lands these verbatim as stubs in its first task and every parallel task is
  written against them. A vague seam here serializes the whole implementation.
- **State** — where it lives, who owns it, invalidation.
- **Error handling** — per failure mode: detect, surface, recover, log.
- **Security** — authn, authz per operation, input validation, data exposure.
- **Test strategy** — unit vs integration vs manual, and the specific cases from
  the failure section above that must be covered.
- **Rollout** — flag? migration order? backward compatibility? rollback.

If Phase 3 reveals an undecided question, **go back to Phase 1** and ask it.
Do not fill the gap with an assumption.

**Confirm the two load-bearing sections before writing the rest.** Post
`## Architecture` and `## Interfaces` and ask whether they look right. Every
later stage takes these as literal inputs — `flow-plan-implem` lands your
interfaces verbatim as stubs, and every parallel task is written against them.
Catching a wrong one here costs one message; catching it during implementation
costs a design revision and a plan rewrite.

## Phase 4 — Write and commit

Write `docs/plans/<YYYY-MM-DD>-<slug>-design.md`:

```markdown
# <Title> — Design
Date: YYYY-MM-DD

## Problem
## Users & success criteria
## Codebase findings
| Finding | Evidence (path) |

## Decisions
| # | Decision | Chosen | Why | Rejected alternatives |

## In scope (v1)
## Out of scope
## Constraints & dependencies

## Approach chosen (and rejected)
## Architecture        (diagram)
## Data flow           (happy path + failures)
## Data model / migrations
## Interfaces
## Error handling
## Security
## Test strategy
## Rollout & rollback
## Open risks
```

The `## Decisions` table is the decisions log — every downstream stage checks
itself against it, so record **rejected alternatives** too. Future readers need
the why-not.

Commit as `docs(plans): add <slug> design`, then hand off to `flow-plan-implem`.

## Rules

- **Grill relentlessly** — no question is too small.
- **Facts from code**, never from the user.
- **Every question carries a recommendation with evidence.**
- **Concrete over abstract** — real paths, real type names, real endpoints.
  "A service layer will handle this" is not a design.
- **Reuse beats invention** — every new abstraction needs a sentence on why an
  existing one didn't fit.
- **Design the failures.** Happy-path-only designs get rewritten during implem.
- **Nothing implicit.** Undecided → `## Open risks` *and* you ask about it now.

## Red flags — stop if you think any of these

| Thought | Reality |
| --- | --- |
| "The answer here is obvious, I'll assume it." | If it were obvious it wouldn't be a decision. Ask — it's one line in the next batch. |
| "This branch is basically covered by the last answer." | "Basically" means you are guessing. Walk it to a real terminus. |
| "They said they'd figure it out later." | That is not an answer. Ask what specifically, now. |
| "I'll write 'a service layer handles this' and let implem decide." | Implem is parallel agents with nobody to ask. Vague seams serialize the whole build. |
| "I don't need to check whether that finding is still true." | Designing against a stale scan is this stage's most common failure. Verify. |
| "I'll skip the failure paths, the happy path is the hard part." | Happy-path-only designs get rewritten during implementation. |
