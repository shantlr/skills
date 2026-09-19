# Documentation

How this project is documented, and where a new page goes.

```
docs/
├── ARCHITECTURE.md   ← START HERE. what this is, how it fits together
├── FEATURE-MAP.md      generated — which files implement which feature
├── INDEX.md            generated — every decision and bug record
├── build-index.sh      regenerates the two files above; --check verifies them
├── new-record.sh       creates a dated record from the right template
├── templates/          the shape of every record — copy, don't improvise
├── features/<f>/
│   ├── README.md         what it is, how it works, + ## Key files
│   ├── decisions/        why it is that way — YYYY-MM-DD-kebab-title.md
    └── bugs/             what broke and why — YYYY-MM-DD-kebab-title.md

../tasks/               units of work — see tasks/README.md
└── YYYY-MM-DD-<slug>/  design.md · plan.md · review.md
```

`docs/` is the system **as it is now**; `tasks/` is **how it got there**. Work
in progress never lands in `docs/` — only what outlives the task does.

Records live **under the feature**, not in a global pile, so that
*"why does X behave like that?"* is answered in the first place anyone looks.
`INDEX.md` and `FEATURE-MAP.md` exist so that the pile stays searchable as it
grows — they are **generated**, never hand-edited.

## Reading path

| Your question | Go to |
| --- | --- |
| What is this project? | `ARCHITECTURE.md` |
| Which file does X? | `FEATURE-MAP.md` |
| How does feature F work? | `features/F/README.md` |
| Why is it built this way? | `INDEX.md` ▸ Decisions |
| Has this broken before? | `INDEX.md` ▸ Bugs |
| What is being built next? | `../tasks/` (and `INDEX.md` ▸ Tasks) |

## Writing path

| You are writing… | It goes in | Earned when |
| --- | --- | --- |
| what a feature is / how it works | `features/<f>/README.md` | always — one page per feature |
| why we chose this over that | `features/<f>/decisions/` | a real alternative was rejected |
| a post-mortem | `features/<f>/bugs/` | the bug was non-obvious, reached a user, or changed a rule |
| the shape of upcoming work | `../tasks/<date>-<slug>/design.md` | before the work starts |

Not earned: typos, one-line nits, anything caught before merge, a decision that
never had an alternative.

```sh
./docs/new-record.sh decision queue   "Partial dedupe index"
./docs/new-record.sh bug      queue   "Orphan reclaim skipped attempts"
./docs/new-record.sh feature  billing "Billing"
./docs/build-index.sh                 # after any of the above
```

## Rules

1. **A PR that changes documented behaviour updates the doc in the same PR.**
   Documentation updated retroactively is fiction.
2. **Records are append-only, named `YYYY-MM-DD-kebab-title.md`** — never
   `0001-`. Sequential numbers require reading the directory before writing,
   which races when work happens in parallel branches or worktrees; two authors
   both pick `0004`. A date prefix needs no coordination and still sorts
   chronologically.
3. **Overturning a decision is an edit to two files, not a delete.** Set
   `status: superseded` and `superseded_by:` on the old record, `supersedes:` on
   the new one. Never rename, never delete.
4. **Keep the frontmatter filled.** `INDEX.md` is built from it; an unfilled
   `status` or empty `tags` is a record nobody will find again.
5. **A feature README stays under ~25 lines of prose**, and its `## Key files`
   lists the 3–7 files you would open first. That section is the source of
   `FEATURE-MAP.md`.
6. **Link, don't restate.** One fact, one home.

## Keeping it honest

```sh
./docs/build-index.sh --check
```

Exits non-zero if a generated file is stale, if a `## Key files` path no longer
exists, or if a feature never got its key files filled in. Wire it into CI — it
is the only part of this system that can notice the docs drifting from the code
on its own.

## Why dates and not 0001, 0002, …

Sequential numbers have to be *allocated*, which means reading the directory
before writing to it. Two people — or two agents in two worktrees — both read
`0003` and both write `0004`:

```
   sequential NNNN                     date-prefixed
   ───────────────                     ─────────────
   A ─ reads 0003 ─▶ 0004 ─┐           A ─▶ 2026-09-13-lease-based-reclaim ─┐
   B ─ reads 0003 ─▶ 0004 ─┴─▶  ✗      B ─▶ 2026-09-13-partial-dedupe-index ┴─▶ ✓
   conflict, or two 0004s              nothing is read, so nothing can race
```

The date prefix needs no coordination, still sorts chronologically, and merges
cleanly across branches. Cite records by full filename, never by number.
