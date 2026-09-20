# CLAUDE.md block

Append this to the project's agent instruction file — `CLAUDE.md`, or `AGENTS.md`
if that is what the project already uses (if both exist, the one that is not a
symlink to the other) — creating it if it does not exist. If a `## Documentation`,
`## Code comments` or `## Tests` section already exists, merge into it rather than
adding a second heading.

**Everything below the `---` line is the block.** Copy it verbatim, then adjust
two things for the project: `docs` if you scaffolded into a different directory,
and the example feature names. It is deliberately not wrapped in a code fence —
it contains a fenced block of its own, and nesting them truncates the copy.

Or append it mechanically, which cannot truncate:

    awk 'f; /^---$/ {f=1}' "$SKILL/references/claude-md-block.md" >> CLAUDE.md

---

## Documentation

**Start at [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)** — what this project
is and how it fits together. From there:

| Your question | Go to |
| --- | --- |
| Which file does X? | [docs/FEATURE-MAP.md](./docs/FEATURE-MAP.md) *(generated)* |
| Why is it built this way? | [docs/INDEX.md](./docs/INDEX.md) ▸ Decisions *(generated)* |
| Has this broken before? | [docs/INDEX.md](./docs/INDEX.md) ▸ Bugs |
| How does feature F work? | `docs/features/F/README.md` |
| **What rules must my change follow?** | **`docs/guidelines/<area>/`** *(read before writing UI)* |
| How did we build X / what was planned? | `tasks/YYYY-MM-DD-<slug>/` |

| You are writing… | It goes in |
| --- | --- |
| what a feature is / how it works | `docs/features/<feature>/README.md` |
| why we chose this over that | `docs/features/<feature>/decisions/YYYY-MM-DD-*.md` |
| a post-mortem on a real bug | `docs/features/<feature>/bugs/YYYY-MM-DD-*.md` |
| a rule for *every* case of a kind | `docs/guidelines/<area>/<topic>.md` |
| the shape of upcoming work | `tasks/YYYY-MM-DD-<slug>/design.md` |

**Guidelines are house rules, and they are binding.** `docs/guidelines/` holds
the conventions this project has settled on — how stale data is handled, what a
destructive action must confirm, how a failed mutation rolls back. They apply to
**every** feature, which is why they do not live under one.

```
   feature doc          decision record        guideline
   ───────────          ───────────────        ─────────
   how ONE thing        why ONE choice         how EVERY case
   works, today         was made, once         of a kind is handled
```

- **Read the applicable area before writing code**, not after. Any UI change
  means every topic in `docs/guidelines/ui-ux/`.
- **Cite rules by ID** — `DATA-FRESHNESS-3`, the topic filename uppercased plus
  the rule's number. `docs/INDEX.md` ▸ Guidelines lists every topic.
- **Deviating is allowed; deviating silently is not.** Write the exception and
  its reason where the change is designed.
- **A guideline is earned, not invented** — the situation came up in real work,
  usually twice. A one-off choice is a decision record. Padding the rulebook
  with rules nobody hit is how it stops being read.
- **IDs are permanent.** Never renumber, never reuse. A retired rule stays in
  place, struck through, pointing at its replacement — every review comment that
  ever cited it must still resolve.

**Create records with `./docs/new-record.sh`** — it stamps the date, slugifies
the title, seeds the frontmatter, prints the path, and never overwrites. Then
regenerate the index:

```sh
./docs/new-record.sh decision <feature> "Partial dedupe index"
./docs/new-record.sh bug      <feature> "Orphan reclaim skipped attempts"
./docs/new-record.sh feature  <feature> "<Feature>"
./docs/new-record.sh guideline ui-ux    "Data freshness"
./docs/build-index.sh                   # after any of the above
```

**Rules**

- **Never hand-edit `FEATURE-MAP.md` or `INDEX.md`.** They are generated —
  `FEATURE-MAP.md` from each feature README's `## Key files`, `INDEX.md` from
  each record's YAML frontmatter. Edit the source, re-run `build-index.sh`.
- **Fill the frontmatter.** An unfilled `status` or empty `tags` is a record
  nobody will find again.
- **Overturning a decision edits two records; it never deletes one.** Set
  `status: superseded` and `superseded_by:` on the old, `supersedes:` on the new.
- **`./docs/build-index.sh --check` must pass.** It fails on a stale generated
  file, a `## Key files` path that no longer exists, a feature whose key files
  were never filled in, or a guideline rule ID that is malformed, wrongly
  prefixed, duplicated, or whose topic slug collides with another area.

- **A PR that changes documented behaviour updates that doc in the same PR.**
  Docs updated retroactively are fiction.
- **Write a decision record whenever a real alternative was rejected.** Not for
  choices that only ever had one option.
- **Write a bug record when the bug was non-obvious, reached a user, or changed
  a rule.** Not for typos or anything caught before merge.
- **Records are append-only and date-prefixed, never numbered.** `0001-` style
  numbering has to be allocated by reading the directory first, which races when
  work happens in parallel worktrees — two agents both pick `0004`. A superseded
  decision stays, marked `Status: superseded by YYYY-MM-DD-<slug>`. Never
  rename, never delete. Cite records by full filename.
- **Feature READMEs stay under ~25 lines.** Overflow becomes a decision record.
- **Link, don't restate.** One fact, one home.

## Code comments

**A comment is present tense, and it earns its place only by saying something
neither the code nor `docs/` already says.** One fact, one home: if a reader
could derive it from the code, the home is the code; if it is history, the home
is `git log` and the decision record; if it is the spec, the home is `docs/`.

**Comments are the most expensive text in the repo.** They are re-read on every
visit to the file, by every human and every agent, and — unlike `docs/` — nothing
regenerates or checks them. A comment layer that grows to rival the `docs/` tree
has stopped being documentation and become a second, unmaintained copy of it.

```
   ✗ the expensive failure                 ✓ earns its place
   ───────────────────────                 ──────────────────
   /**                                     /** Retry policy — see docs/features/
    * ── Why this file exists ─────         *  sync/decisions/2026-03-04-*.md */
    * Before the refactor there was
    * no layer here at all, and the        // 3 attempts: upstream 502s on cold
    * value was inlined everywhere.        // start. Fewer and the first call of
    * This used to be OLD_NAME, kept       // the day fails.
    * so every caller agreed. The
    * spec calls this X, meaning …         // Keep in sync with migrations/0142 —
    */                                     // the order is persisted as an int.
   const retries = 3
   ── 30 lines of comment, one line of code, and the history is in git anyway
```

Write a comment when, and only when:

- **Why this and not the obvious alternative** — a trade-off, a constraint from
  outside the file (a vendor quirk, a platform limit, a spec clause).
- **A warning** — this looks removable and is not; this order matters; this
  duplication is deliberate; this must stay in sync with X.
- **A pointer** — *one line*, linking the record that holds the story:
  `@see docs/features/<f>/decisions/YYYY-MM-DD-<slug>.md`.
- **A deliberate absence** — why the case you would expect is *not* handled here.
- **An API contract** — a one-or-two-line docstring on an exported symbol, about
  behaviour callers depend on. Not its implementation, not its types.

Do **not** write:

- **History.** "This used to…", "before the refactor…", "previously we…", "no
  longer…", a date, a version, a sprint or wave label, or anything naming how the
  code was produced (a task, an agent, a review round). `git log` and `docs/` own
  the past; the file is only ever *now*.
- **A retelling of `docs/`.** A spec section, a design decision, or a bug
  post-mortem paraphrased into prose. Cite it in one line instead — a pointer to
  the section is useful; paragraphs restating it will drift, and then the comment
  lies while the doc is still right.
- **An incident transcript** — captured payloads, observed-vs-expected tables, a
  dated "we saw X in production" narrative. That is a `docs/**/bugs/` record.
  Keep the *rule* it produced; link the rest.
- **An essay.** No `── Section ──` banners, ASCII diagrams, before/after module
  graphs, or markdown tables inside a comment. Diagrams belong in `docs/`, where
  they are read on purpose rather than scrolled past.
- **Meta-commentary** — a comment about another comment ("the sentence above is
  no longer literally true", "the earlier reading was wrong"). If a comment is
  wrong, delete it; do not append a correction.
- **A restatement** of the next line, the function's own name, or a type the
  language already declares (`/** the user id */ userId`). Self-evident enum
  arms, union members and struct fields do not each need a docstring — annotate
  only the one that would surprise a reader.
- Commented-out code, or a `TODO` with no owner or issue.

**Rules**

- **Prefer making the code self-explanatory over explaining it** — a named
  constant, an extracted function, or a clearer type deletes the comment outright.
- **Keep a file header to ~3 lines**: what this module is for, and a link. A
  header that needs more than that is describing a feature — write it in
  `docs/features/<f>/README.md` and point at it.
- **Comment lines should be a small fraction of code lines.** If a file is more
  comment than code, the excess is almost always history or a retold doc, and it
  is not the code that needs fixing.
- **Stale comments are worse than none.** Changing a line means updating or
  deleting the comment above it in the same edit.
- **When you cut a comment, check its content is really elsewhere** — if it holds
  the only copy of a real constraint, move it to `docs/` first, then cut.
- **Never narrate a diff in the code.** What changed, and why it changed *now*,
  goes in the commit message or the PR.

## Tests

**A test earns its place by being able to fail for a real reason.** Prefer a
handful of tests over paths that actually break to broad coverage of paths that
cannot.

Write a test when:

- The logic has **branches, boundaries or arithmetic** — an empty collection,
  a zero, an off-by-one, a timezone, a rounding rule.
- It **encodes a decision or a guideline** so a future change cannot silently
  undo it.
- It is a **regression test for a real bug** — one per `docs/**/bugs/` record,
  citing it by filename.
- It covers a **contract others depend on** — a public API's shape, a wire
  format, a migration's up *and* down path.

Do **not** write:

- Tests of the language, the framework or a third-party library — that a
  getter returns what the constructor was handed, that the ORM saves, that the
  router routes.
- Tests whose assertions restate the implementation line for line, or that
  mock so much that only the mocks are exercised.
- Snapshot tests over output nobody reads, wholesale — they fail on every
  cosmetic change and get blanket-updated, which trains people to ignore them.
- One test per trivial getter, constant, or pure re-export.
- A new test that a broader existing test would already have caught — extend
  that one instead.

**Rules**

- **Ask "what bug would this have caught?"** No answer, no test.
- **A test with no failing assertion is not a test.** It must be able to go red;
  if you cannot make it fail by breaking the code, delete it.
- **Never weaken, skip or delete a test to make a change pass.** Fix the code, or
  change the test deliberately and say why in the commit.
- **Test behaviour through the public surface**, not private internals — internal
  tests make refactors expensive and teach nothing about real breakage.
- **Flaky is failing.** A test that passes on retry gets fixed or removed, not
  re-run.
- **A test name is its documentation.** `## Code comments` applies here too — no
  header essay justifying the file, no banner rules between `describe` blocks
  that already name themselves. One line and a `@see` link to the bug record is
  the whole budget.
