---
name: flow-review
description: Stage 4 of the flow workflow — reviews the working diff against the flow design and plan artifacts in escalating multi-agent rounds, fixes what survives refutation, and reports each fix with its root cause. Use when tasks/<date>-<slug>/design.md or plan.md exists for the current change, or right after flow-implem finishes, or when the user asks to double-check the work, sanity-check it, or says "did I miss anything" before opening a PR. For reviewing a diff with no flow artifacts behind it, use review-code instead.
version: 2.1.0
---

# Flow / Review: three escalating rounds, then fix

**Input:** the working diff (uncommitted + branch vs base) and, when present,
`tasks/<date>-<slug>/{design,plan}.md`.
**Output:** fixes applied, plus `tasks/<date>-<slug>/review.md`.

Working around a rule below while telling yourself you are honoring its intent
is still a violation.

## Instructions

### 0. Establish the diff

```sh
git status --short
git diff                                        # uncommitted
git diff "$(git merge-base HEAD main)"...HEAD   # branch vs base (or master)
```

Review only these changes and their direct call sites. Pre-existing issues get
noted, not fixed.

- **Empty diff → say so and stop.** Do not fall back to auditing the repository.
- **No base branch** → review the uncommitted changes only, and say that was
  the scope.

### 1. Round 1 — Correctness (parallel readers)

Fan out one reader per dimension over the diff, all in a single message. Each
returns findings with file:line, a concrete failure scenario, and a severity.

| Lens | Looks for |
| --- | --- |
| Logic | off-by-one, inverted conditions, wrong operator, missing early return |
| State & async | races, unawaited promises, stale closures, leaks, ordering |
| Boundaries | null/undefined, empty collections, zero, overflow, unicode |
| Errors | swallowed exceptions, wrong error type, unreachable recovery |
| Data & security | injection, missing authz, unvalidated input, leaked secrets/PII |

Each reader **also returns a risk map**: up to 3 places it could not fully
reason about, and why (unfamiliar pattern, indirection it couldn't follow,
behavior depending on config it couldn't see). Carry this forward — it is what
makes round 3 more than a repeat of round 1.

Then **dedup before going further.** Five lenses hitting one line produce five
findings; collapse them into the one with the most concrete failure scenario.
Verification is the expensive step — don't spend it on duplicates.

### 2. Round 2 — Conformance

Two passes: **2a** against this task's design/plan, **2b** against the project's
standing rulebook. Findings from both enter round 3 like any other finding.

#### 2a. Against the design and plan

Only if a design/plan exists. Check the diff against them:

- Every design section implemented? Anything silently skipped?
- Any behavior that contradicts a row in the design's `## Decisions` table?
- Tests the plan required — present, and actually asserting?
- Dead code, leftover scaffolding, `TODO`, debug logs, commented-out blocks?
- Repo conventions: naming, error handling, layering, no unplanned new deps.

#### 2b. Against `docs/guidelines/`

**No `docs/guidelines/` tree → skip this pass silently.** Do not scaffold one;
`flow-setup` is user-invoked only.

Read `docs/guidelines/README.md`, then select the topic files the diff touches:

```
diff touches                 →  load
─────────────────────────────────────────────────
any UI / component / screen  →  the whole ui-ux/ area
endpoint, client, contract   →  api/<topic>.md
schema, query, cache, fetch  →  data/<topic>.md
test files, test helpers     →  testing/<topic>.md
```

Areas are coarse on purpose: a UI change is checked against *every* `ui-ux/`
topic, not just the one that sounds related. The rule you skipped because it
"didn't apply" is the one that was violated.

Then, **for every surface the diff touches, walk every applicable rule** and
report each violation as a finding:

| Gate | Effect |
| --- | --- |
| Rule's `status` is not `active` | Not enforced. Ignore it. |
| Matches the topic's `## Exceptions` | Not a violation. |
| `design.md` argued this exact exception | Not a violation — already decided. |
| Otherwise, surface breaks the rule | Finding. |

Check the exceptions and the design **before** reporting, not after. Re-opening
an exception the design already argued is the loudest kind of review noise: the
user decided it once, in the stage built for deciding it.

A guideline finding **cites the rule ID and the specific line or behavior**:

- ✓ `ProductCard.tsx:42 — violates DATA-FRESHNESS-3: renders cached price with
  no staleness indicator.`
- ✗ "the loading states here feel inconsistent" — that names no rule. It is not
  a guideline finding; send it to round 1's correctness lenses or drop it.

**No rule ID, no guideline finding.** The whole value of the pass is that every
claim is traceable to a line someone already agreed to.

### 3. Round 3 — Adversarial

**One independent verifier per surviving finding**, dispatched concurrently.
Each must return exactly one verdict:

```
Decide whether this claimed finding is real. Your job is to refute it if you can.

Finding: <summary>   Claimed scenario: <scenario>   At: <file>:<line>
<the relevant code and diff>

Return exactly one verdict:
- CONFIRMED — name the inputs or state that trigger it and the wrong output or
  crash that results. Quote the offending line.
- PLAUSIBLE — the mechanism is real but the trigger is uncertain (timing,
  environment, config). State what would confirm it.
- REFUTED — factually wrong, or already guarded elsewhere. Quote the line that
  proves it.

If unsure, lean REFUTED. A false positive costs the user more than a nitpick.
```

For a **guideline finding**, the verifier is handed the rule's full text and the
topic's `## Exceptions`, and refutes on any of: the code does satisfy the rule;
the rule does not govern this surface; the case is a listed exception; the rule
is not `active`. CONFIRMED must quote both the offending line and the rule's
`**Because:**` — a rule whose failure mode cannot be shown here is a rule that
does not apply.

Then spend the **round 1 risk map**: send a reader at each spot a round-1 lens
flagged as not-fully-understood. Also ask what the first two rounds never looked
at — a changed-but-unreviewed file, a config flag, a migration's down path, a
caller outside the diff.

### 4. Fix, or park

**Fix** when all hold:

- Verdict is CONFIRMED, or PLAUSIBLE where the fix only prevents a failure
  (adding a guard).
- Exactly one reasonable intended behavior, derivable from code, types, tests,
  adjacent call sites, the design doc, or CLAUDE.md.
- Contained: inside the change's blast radius; no public API, schema, wire
  format or config-default change; no new dependency.
- It does not weaken, skip, or delete a test to make something pass.
- It does not reverse something clearly done on purpose.

**Park and ask** when any hold: two or more defensible behaviors and the code
picks neither; a product or policy decision (copy, timeouts, retry counts,
limits); the fix changes a public contract, schema, or serialized format; the
finding is "this approach is wrong" (that's a rewrite); every fix trades against
something else and the weighting is the user's call.

Parking is for ambiguity, not permission — a confirmed bug with one obvious fix
gets fixed, not asked about. Parking never blocks the round: note it, keep
going, ask at the end.

While fixing:

- Highest severity first. Run typecheck + tests after each fix.
- A fix that fails twice → **stop guessing, add logging and find the real
  cause.** State one hypothesis per attempt.
- Commit fixes separately: `fix(<scope>): <what>`.

**Nominate guideline candidates as you fix.** When a confirmed finding is of a
kind you have *already seen* — the same class of mistake in another feature in
this diff, a rule you had to explain twice, or a matching `docs/bugs/` record —
the repetition is the evidence that a rule is earned. Nominate it (step 5). One
occurrence is not a pattern: that is a decision record, not a guideline. A
rulebook padded with rules nobody needed is a rulebook nobody reads.

You only nominate. `flow-doc` (stage 5) decides and writes the rule.

Then **review your own fixes.** The least-reviewed code in any change is the
code the reviewer added. Re-read only the diff your fixes introduced, looking
for behavior deltas beyond the bug and interactions between two fixes.

### 5. Report

Before writing the table, `git diff` and confirm **every row's change is
actually present on disk**. A claimed fix that isn't in the working tree is this
skill's worst possible failure.

Write `tasks/<date>-<slug>/review.md` and post the same content:

```markdown
# <Title> — Review
Date: YYYY-MM-DD

## Fixes
| # | Severity | Symptom | Root cause | Fix | File |

## Before / after
<ASCII diagram of the corrected flow, when the shape changed>

## Guideline violations
| Rule | File:line | What breaks it | Fixed / parked |

## Guideline candidates
| Proposed rule (imperative) | Area | Evidence it recurred |

## Refuted findings
| Claim | Why it was not a bug |

## Parked — needs your decision
| Finding | The two behaviors | Recommendation |

## Not fixed (noted only)
| Issue | Why deferred |

## Verification
Commands run and their results.
```

Omit both guideline sections entirely when there is no `docs/guidelines/` tree
or nothing to say. In `## Guideline candidates`, the rule is one imperative
sentence in the voice of the rulebook ("Always show a staleness timestamp beside
cached figures"), and the evidence names the two-or-more places it came up
(`this diff: ProductCard.tsx, CartSummary.tsx` / `docs/bugs/2026-04-02-*.md`).
Never nominate a rule whose evidence column holds one item.

Root cause is *why the bug existed*, not the symptom and not the patch:

- ✗ symptom: "null deref on `user.email`"
- ✗ patch restated: "added an optional chain"
- ✓ root cause: "the OAuth path constructs `User` without `email`, the type
  marks it required, and no caller guards it"

## What not to flag

Three rounds multiply noise threefold unless you hold the line. Do not report:

- Pre-existing issues in untouched code, unless the change makes them newly
  reachable.
- Anything the typechecker, linter, or compiler already catches.
- Style preferences not written in a CLAUDE.md that governs the file.
- Missing tests for code with no test infrastructure around it.
- Changes that are clearly deliberate — read the commit message and comments
  before calling something a mistake.
- Hypotheticals with no concrete trigger, unless you can name the scale at
  which it breaks.

## Rules

- **Three rounds, always** — cheap rounds first, adversarial last.
- **A finding needs a failure scenario** or it is discarded.
- **Refute before fixing**, one verifier per finding — guideline findings
  included.
- **Every guideline finding names a rule ID.** No ID, not a guideline finding.
- **Nominate a guideline only on a repeat.** One occurrence is a decision record.
- **Root cause in every report row.**
- **Two failed fix attempts → instrument, don't guess.**
- **Don't widen scope** — note pre-existing issues, fix the diff.
- **Tests must pass before you claim done.** Never state a result you have not
  just run and read — "should pass" is not a result.

## Red flags — stop if you think any of these

| Thought | Reality |
| --- | --- |
| "This finding is probably fine, I'll mark it refuted." | REFUTED needs a quoted line that proves it. No quote, no refutation. |
| "The diff is small, I'll skip round 3." | Small diffs are where single-verifier confidence is most misplaced. Run it. |
| "I'll downgrade this to a style note so I don't have to fix it." | Severity is not a fix strategy. Fix it or park it explicitly. |
| "I'll fix this one ambiguous thing, the user probably wants it." | That's a park. Two defensible behaviors means you ask. |
| "Tests should pass now." | Run them. Read the output. Then say so. |
| "I already reviewed carefully, no need to re-read my own fixes." | Reviewer-written code is the least reviewed code in the change. |
| "This clearly breaks the spirit of the ui-ux rules." | Name the rule ID or it's not a guideline finding. Spirit isn't citable. |
| "Only a couple of ui-ux topics look relevant, I'll check those." | A UI change is checked against the whole area. The skipped topic is the violated one. |
| "The design argued against this rule, so the design is wrong." | Already decided in stage 1. Not your call in stage 4. |
| "Good rule — I'll nominate it from this one instance." | One instance is a decision record. Unearned rules kill the rulebook. |
| "There's no docs/guidelines/, I'll create one." | Skip the pass. `flow-setup` is user-invoked only. |
