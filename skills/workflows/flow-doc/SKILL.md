---
name: flow-doc
description: Stage 5 of the flow workflow — promotes a finished task's artifacts into the project's durable docs/ tree, updating the feature one-pager and writing a decision record for each real alternative that was rejected. Use right after flow-review finishes, or when the user says "document this", "write it up in docs", "update the docs for this change", or asks what a shipped change should leave behind. Only updates an existing docs/ tree; it never scaffolds one.
version: 1.0.0
---

# Flow / Doc: promote the task into the docs

**Input:** `tasks/<date>-<slug>/{design,plan,review}.md` and the shipped diff.
**Output:** updated `docs/features/<feature>/README.md`, plus one decision
record per rejected alternative. Nothing is written outside `docs/`.

The task folder answers *"what did we do in September?"*. The docs answer
*"how does this system work, and why is it like that?"*. This stage moves the
second kind of knowledge across — everything else stays in `tasks/`.

```
 tasks/<date>-<slug>/
   design.md   ── Decisions table ──────► docs/features/<f>/decisions/<date>-<slug>.md
   design.md   ── Architecture, flow ──┐
   plan.md     ── owned files ─────────┼─► docs/features/<f>/README.md  (+ ## Key files)
   review.md   ── root causes ─────────┘        └─ a shipped bug worth remembering
                                                   ──► docs/features/<f>/bugs/<date>-<slug>.md
   (dates, task breakdown, wave structure, refuted findings)  ──► stays put ✗
```

## Instructions

### 1. Preflight — is there a docs tree?

```sh
ls -d docs/features 2>/dev/null
```

- **No `docs/` tree** → stop. Say in one line: *"no `docs/` tree — skipping
  stage 5; run `flow-setup` if you want one"* and finish. **Do not scaffold
  one.** `flow-setup` is explicitly user-invoked only; creating a dozen files
  nobody asked for is not this skill's call.
- **Tree exists** → read `docs/README.md` and one existing feature README and
  decision record. Match their conventions over the ones below when they differ.

### 2. Pick the feature area

Map the change onto an existing directory under `docs/features/` — compare the
plan's owned files against each feature README's `## Key files`. Prefer an
existing feature; a new one is only justified when the change introduces a
capability no current README can host. If two features are touched, update both
READMEs and file the decision under the one that owns the mechanism.

### 3. Update the feature one-pager

Edit `docs/features/<feature>/README.md` — **edit, do not append a changelog
section.** It describes the system in the present tense as it is *now*; a
reader must not have to reconstruct the current state from a pile of dated
entries.

- Rewrite the mechanism paragraph if the change altered how it works.
- Add deliberate-but-surprising behaviour to **Edge cases**, each linking its
  decision record.
- Update **## Key files** to the 3–7 files you would open first *today*,
  including new ones from the plan's `Owns` sets, dropping any that are no
  longer the way in.
- Keep the prose under ~25 lines. If it grew past that, the extra belongs in a
  decision record.

### 4. Write the decision records

Read the design's `## Decisions` table. **One record per row that names a real
rejected alternative.** A row with an empty "Rejected alternatives" cell is not
a decision — skip it. Also write one for any decision the *review* forced
(design said X, review found X was wrong, code now does Y).

```sh
./docs/new-record.sh decision <feature> "<the decision as a statement>"
```

If that script isn't there, create
`docs/features/<feature>/decisions/<YYYY-MM-DD>-<kebab-title>.md` by hand from
`docs/templates/decision.md`, keeping every frontmatter key.

Fill it from the design, not from memory:

| Field | Source |
| --- | --- |
| `feature`, `date`, `tags` | frontmatter — spend five seconds on `tags` |
| `decided_by` | `user` if the design's grilling settled it, else `design review` / `implementation` |
| **Context** | the design's problem + constraints, and the alternatives that were actually on the table |
| **Decision** | the chosen option, imperative, one or two sentences |
| **Why** | the design's "Why" cell — constraints, not taste |
| **Consequences** | what it now costs or forecloses, including what it makes harder |

If a new record overturns an existing one, set `status: superseded` and
`superseded_by:` on the old, `supersedes:` on the new. Never edit history out.

### 5. Bug records — only when one was shipped and is instructive

From `review.md`, promote a fix with
`./docs/new-record.sh bug <feature> "<what broke>"` — same helper as step 4, so
the date, frontmatter and collision check come for free — only when it was a
**pre-existing** bug in shipped code with a non-obvious root cause. Bugs introduced and fixed inside this task never happened as far as the
system is concerned — leave them in `review.md`.

### 6. Rebuild the generated files

```sh
./docs/build-index.sh
```

It regenerates `FEATURE-MAP.md` and `INDEX.md`, and **fails if a path in any
`## Key files` no longer exists** — which is exactly the check that catches a
stale README. Fix what it reports; never hand-edit a generated file.

### 7. Commit and report

Commit as `docs(<feature>): document <slug>`. Then report:

- Table: file → created/updated → one line of what it now says
- The decisions you deliberately did **not** record, and why (no real
  alternative was rejected)
- Anything you could not place in an existing feature

## Rules

- **Never scaffold `docs/`.** No tree → skip the stage. That is `flow-setup`'s
  job and the user's call.
- **Never write into `tasks/`.** That folder is closed once review is done.
- **Present tense, current state.** Feature READMEs describe what the code does
  now. Only records carry dates.
- **One fact, one home.** If it is already in a decision record, the README
  links it instead of re-explaining it.
- **A decision needs a rejected alternative.** Otherwise it is documentation of
  the current code, and the README already covers that.
- **Never hand-edit `FEATURE-MAP.md` or `INDEX.md`.**

## Red flags — stop if you think any of these

- *"I'll just scaffold a minimal docs/ folder first."* — No. Skip the stage.
- *"I'll add a `## Changelog` / `## 2026-09-19 update` section to the README."*
  — That is what the records and git history are for.
- *"I'll record every row of the Decisions table for completeness."* — Records
  with no rejected alternative are noise that dilutes the real ones.
- *"I'll paste the design's architecture section into the README."* — The
  README is ~25 lines of orientation, not a copy of the design.
- *"Nothing changed conceptually, I'll skip the README."* — Then at minimum
  verify `## Key files` still lists the files you would open first.
