---
name: flow-doc
description: Stage 5 of the flow workflow — promotes a finished task's artifacts into the project's durable docs/ tree, updating the feature one-pager and writing a decision record for each real alternative that was rejected. Use right after flow-review finishes, or when the user says "document this", "write it up in docs", "update the docs for this change", or asks what a shipped change should leave behind. Only updates an existing docs/ tree; it never scaffolds one.
version: 1.1.0
---

# Flow / Doc: promote the task into the docs

**Input:** `tasks/<date>-<slug>/{design,plan,review}.md` and the shipped diff.
**Output:** updated `docs/features/<feature>/README.md`, one decision record per
rejected alternative, and — only when the task earned one — a new or amended
rule under `docs/guidelines/<area>/<topic>.md`. Nothing is written outside
`docs/`.

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
   design.md   ─┐
   review.md   ─┴ ## Guideline candidates ──► docs/guidelines/<area>/<topic>.md
                                              (append the next <TOPIC-ID>-<n>)
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

### 6. Guidelines — only for rules the task actually earned

A feature doc says how ONE thing works. A decision record says why ONE choice
was made, once. A guideline says how EVERY case of a kind is handled,
product-wide. Only the third kind goes here.

**No `docs/guidelines/` directory → skip this step silently.** Same rule as the
docs tree: do not create the folder, do not create an area, say nothing beyond
a line in the report. This is the step most tempted to scaffold — don't.

Read `## Guideline candidates` in `design.md` (stage 1) and `review.md`
(stage 4), then add anything the task plainly established as a reusable rule
even though nobody nominated it.

**Apply the bar before writing a word.** A guideline is earned when:

| Earned | Not earned |
| --- | --- |
| the same class of issue has now appeared **twice, in different features** | a one-off choice → that is a decision record |
| a design conversation settled a rule **not specific to this feature** | anything a linter or formatter already enforces |
| a bug fix changed **how we do this kind of thing**, not one call site | a rule with no real occurrence behind it |

Inventing rules to look thorough is how a rulebook stops being read. **When
unsure, do not write it** — name it in the report and let the user decide.

**Amend before you create.** For each earned rule, grep `docs/guidelines/` for
an existing topic that covers it and append the next rule number there. Create
a new topic file only when no existing topic can host it:

```sh
./docs/new-record.sh guideline <area> "<Topic>"   # ui-ux, api, data, testing…
```

Topic slugs are globally unique across areas — the script fails if the slug
exists anywhere, because the rule-ID prefix is the filename uppercased
(`data-freshness.md` → `DATA-FRESHNESS-1`). A tree of six-rule topics is
readable; a tree of thirty one-rule topics is not.

Write the rule as:

```markdown
### DATA-FRESHNESS-4 — Refetch the list after any mutation that can reorder it.

**Because:** an optimistic patch leaves the row in its old slot, so the user
sees the item "jump" on the next unrelated render.
**Source:** tasks/2026-09-19-order-sync/
```

- Heading: imperative, concrete enough to **hold a diff against** — "use a
  loading skeleton over a spinner for lists", not "care about perceived speed".
- `**Because:**` names the **failure mode**, not the preference.
- `**Source:**` points at this task folder or the bug record that earned it.

**IDs are permanent.** Allocate the next unused number in creation order.
Never renumber, never delete, never reuse — every review comment ever written
cites them. Superseding a rule strikes it through in place and points forward,
exactly like a superseded decision record:

```markdown
### ~~FORMS-2~~ — Validate on blur. Superseded by FORMS-7.
```

### 7. Rebuild the generated files

```sh
./docs/build-index.sh
```

It regenerates `FEATURE-MAP.md` and `INDEX.md` (including the generated
`## Guidelines` section), and **fails if a path in any `## Key files` no longer
exists** — which is exactly the check that catches a stale README. Fix what it
reports; never hand-edit a generated file.

`./docs/build-index.sh --check` additionally validates rule IDs: malformed
heading, wrong prefix, duplicate number, duplicate topic slug across areas.
Run it after touching guidelines.

### 8. Commit and report

Commit as `docs(<feature>): document <slug>`. Then report:

- Table: file → created/updated → one line of what it now says
- Every guideline rule written or amended, **by ID** (`FORMS-7 — new`,
  `DATA-FRESHNESS-2 — superseded by DATA-FRESHNESS-9`)
- The decisions you deliberately did **not** record, and why (no real
  alternative was rejected), and the guideline candidates you did **not**
  promote, with the reason — so the user can overrule you
- Anything you could not place in an existing feature

## Rules

- **Never scaffold `docs/`.** No tree → skip the stage. That is `flow-setup`'s
  job and the user's call. **No `docs/guidelines/` → skip step 6**, identically:
  do not create the folder or an area to hold a rule you like.
- **Never write into `tasks/`.** That folder is closed once review is done.
- **Present tense, current state.** Feature READMEs describe what the code does
  now. Only records carry dates.
- **One fact, one home.** If it is already in a decision record, the README
  links it instead of re-explaining it.
- **A decision needs a rejected alternative.** Otherwise it is documentation of
  the current code, and the README already covers that.
- **A guideline needs a second occurrence.** One case is a decision record.
- **Guideline IDs are append-only.** Never renumbered, never reused, never
  deleted — struck through in place and pointed forward.
- **Never hand-edit `FEATURE-MAP.md` or `INDEX.md`.**

## Red flags — stop if you think any of these

- *"I'll just scaffold a minimal docs/ folder first."* — No. Skip the stage.
- *"I'll add a `## Changelog` / `## 2026-09-19 update` section to the README."*
  — That is what the records and git history are for.
- *"I'll record every row of the Decisions table for completeness."* — Records
  with no rejected alternative are noise that dilutes the real ones.
- *"There's no `docs/guidelines/ui-ux/` yet, I'll create it for this rule."*
  — No. Skip step 6 and say so.
- *"I'll promote every guideline candidate, they all sound sensible."* — A rule
  with one occurrence behind it is a decision record wearing a rulebook hat.
- *"FORMS-2 is wrong now, I'll rewrite it in place / renumber the rest."* —
  Strike it through and add a new ID. Review comments cite these forever.
- *"I'll paste the design's architecture section into the README."* — The
  README is ~25 lines of orientation, not a copy of the design.
- *"Nothing changed conceptually, I'll skip the README."* — Then at minimum
  verify `## Key files` still lists the files you would open first.
