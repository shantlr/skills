# CLAUDE.md block

Append this to the project's `CLAUDE.md`, creating the file if it does not
exist. If a `## Documentation` section already exists, merge into it rather than
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
