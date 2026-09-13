---
name: setup-docs
description: Sets up a project's `docs/` folder — an ARCHITECTURE.md entry point, per-feature one-pagers, dated decision and bug records, plans, and generated FEATURE-MAP.md / INDEX.md so the docs stay searchable. Use when the user says "set up docs", "create a docs folder", "add documentation structure", "scaffold docs", "document this project", "I want ADRs / decision records / bug records", or asks for an architecture overview or a map of which files implement what.
version: 1.0.0
---

# Setup Docs

Creates a durable, agent-friendly `docs/` tree in the current project, and
**writes the entry point for real** by reading the codebase. The point is that
the next bug, the next decision, and the next plan each have one obvious place
to land — and that anyone arriving later can *find* them.

## The structure

```
docs/
├── ARCHITECTURE.md        ← THE ENTRY POINT. you write this one for real
├── FEATURE-MAP.md         ← generated: which files implement which feature
├── INDEX.md               ← generated: every record, from its frontmatter
├── build-index.sh         ← regenerates both; --check verifies them in CI
├── new-record.sh          ← creates a dated record from the right template
├── README.md              ← how the folder works, reading + writing paths
├── templates/             ← copy these; they are the shape, not suggestions
│   ├── architecture.md  feature.md  bug.md  decision.md  plan.md
├── features/              ← one directory per feature area
│   └── <feature>/
│       ├── README.md        what it is, how it works, + ## Key files
│       ├── bugs/            YYYY-MM-DD-kebab-title.md
│       └── decisions/       YYYY-MM-DD-kebab-title.md
└── plans/                 ← YYYY-MM-DD-kebab-title.md, one per chunk of work
```

Records live **under the feature**, not in a global `adr/` pile: *"why does
capture refuse a duplicate?"* is answered in the first place anyone would look.
The two generated files exist because that alone does not scale — at 80 records
a folder tree is storage, not a read path.

```
                    ┌──────────────────┐
   any question ───▶│ ARCHITECTURE.md  │  what is this, how does it fit
                    └────────┬─────────┘
         ┌───────────────────┼───────────────────┐
         ▼                   ▼                   ▼
   FEATURE-MAP.md        INDEX.md          features/<f>/README.md
   "which file?"      "why? / broken?"      "how does F work?"
         │                   │
         └── generated ──────┘   ◀── build-index.sh, from Key files + frontmatter
```

**Nothing generated is ever hand-edited.** `FEATURE-MAP.md` comes from each
feature README's `## Key files`; `INDEX.md` comes from each record's YAML
frontmatter. One fact, one home — the index cannot drift from its source
because it is rebuilt from it.

## Instructions

1. **Check for an existing `docs/`.**
   ```sh
   ls -d docs 2>/dev/null && find docs -maxdepth 2 -type d
   ```
   - Nothing there → go to step 2.
   - It exists → **ask the user** before touching it (use the
     `mcp__jean-claude-mcp__ask_question` tool if available, otherwise ask in
     plain text). Offer exactly these three, and do not guess:
     - **merge** — adds only missing files, never overwrites. Their existing
       `docs/README.md` therefore *survives*, and it will not describe the new
       tree. After scaffolding, say so and offer to fold the index from
       `scripts/assets/docs-readme.md` into it. Silently leaving a stale index
       is the main way this option goes wrong.
     - **a different directory** — `--docs-dir <name>` (e.g. `documentation`).
       Note that `--root` moves the *project* root, not the docs directory;
       `--root sub` produces `sub/docs/`, which is rarely what is wanted.
     - **abort**.

2. **Identify the feature areas.** Do not invent them and do not ask a blank
   question. Read the repo first — top-level source directories, route/screen
   names, package names, `README.md` — and propose a list of 4–10 feature areas
   for the user to confirm or edit. Feature names are lowercase single words
   where possible (`capture`, `queue`, `auth`, `billing`).
   If the user already named the features, skip straight to step 3.

3. **Run the scaffolder** with the confirmed features. You are standing in the
   user's project, not in this skill, so resolve the skill's own path first —
   it is the directory containing the `SKILL.md` you are reading, usually
   `~/.claude/skills/setup-docs`:
   ```sh
   SKILL=~/.claude/skills/setup-docs     # or wherever this SKILL.md lives
   "$SKILL/scripts/setup-docs.sh" --root . <feature> [<feature> ...]
   ```
   If that path does not exist, find it:
   `find ~/.claude/skills -name setup-docs -maxdepth 2`.

   Flags: `--root <path>` scaffolds into a different project root;
   `--docs-dir <name>` uses a directory other than `docs` (use this when the
   user wants `documentation/` or already has a `docs/` you agreed not to touch).
   It is idempotent — existing files are left untouched and reported as `skip`.
   It also installs `docs/new-record.sh` and `docs/build-index.sh`; from here on
   those copies are the ones to use, and the ones the project's own docs name.

4. **Write `docs/ARCHITECTURE.md` for real.** This is the step that makes the
   rest findable, and it is not optional — a scaffolded entry point that answers
   nothing is worse than none, because it looks like the index.

   Read the codebase first: entry points, the dependency direction, where state
   lives, what talks to the outside world. Then fill in every section of the
   template the scaffolder placed there. Specifically:
   - §2's diagram must show the **real runtime pieces** — processes, stores,
     external services — not a class hierarchy and not the folder tree.
   - §4's table maps each feature to its code directory *and* its docs page.
   - §5 lists the invariants a newcomer would break, each linked to the decision
     record that established it (write those records if they don't exist yet).

   Delete any section the project genuinely has nothing to say about. Do not
   leave placeholder prose in place — an unfilled heading reads as an answer.

5. **Fill in each feature's `## Key files`.** For every
   `docs/features/<f>/README.md`, replace the placeholder list with the 3–7
   files you would actually open first, in the order you would open them, each
   with a short clause on what it does. Write the feature's opening paragraph
   and **How it works** while you are there — you have just read the code.

   This section is the source of `FEATURE-MAP.md`, so guessing here poisons the
   map. Every path must exist; step 6 will tell you if it doesn't.

6. **Generate the read path and verify it.**
   ```sh
   ./docs/build-index.sh          # writes FEATURE-MAP.md and INDEX.md
   ./docs/build-index.sh --check  # must exit 0 before you report success
   ```
   `--check` fails on three things: a generated file that is stale, a
   `## Key files` path that does not exist, and a feature whose key files were
   never filled in. All three are your bugs at this point — fix them, don't
   report them as findings.

7. **Add the maintenance rules** to the project's `CLAUDE.md`, creating it if
   absent. The block is everything after the `---` in
   `references/claude-md-block.md` — append it whole:
   ```sh
   awk 'f; /^---$/ {f=1}' "$SKILL/references/claude-md-block.md" >> CLAUDE.md
   ```
   Then reconcile by hand: if `CLAUDE.md` already had a `## Documentation`
   heading, merge the two rather than leaving both; and if you used
   `--docs-dir`, replace `docs` throughout the block. A scaffold nobody updates
   becomes fiction within two weeks — this block is what keeps it alive.

8. **Report** the tree (`find docs -type f | sort`), show the user
   `ARCHITECTURE.md`'s outline, and state the four habits that keep it alive:
   - a PR that changes documented behaviour updates that doc **in the same PR**;
   - a decision record is earned when a **real alternative was rejected**;
   - a bug record is earned when the bug was **non-obvious** or the fix
     **changed a rule** — not for typos;
   - **overturning a decision edits two records, it never deletes one** — set
     `status: superseded` / `superseded_by:` on the old, `supersedes:` on the new.

   Offer to wire `./docs/build-index.sh --check` into CI. It is the only part of
   this system that notices drift by itself.

## What gets written for real, and what does not

| | Written by you, from the code | Scaffolded as a template |
| --- | --- | --- |
| `ARCHITECTURE.md` | **yes** — it is the entry point | — |
| `features/<f>/README.md` | **yes** — prose + `## Key files` | — |
| `FEATURE-MAP.md`, `INDEX.md` | generated by script | — |
| decision / bug / plan records | only when there is one to write | shape only |

Records are the exception: **do not invent decision records to fill the tree.**
A decision record is earned by a rejected alternative, and inventing them to
look thorough is how the corpus becomes unreadable. If your architecture pass
surfaced real invariants, those are genuine decisions — write them and say so.

Still out of scope: `DESIGN.md`, `ROADMAP.md`, `STATUS.md`. They describe intent
and progress rather than the system as it is, and they need a human's judgement
about sequencing and honesty. Write them by hand when the project needs them —
`references/optional-files.md` has the shape of each. (`DECISIONS.md` is now
obsolete: `INDEX.md` is its generated replacement.)

## Naming records — date-prefixed, never numbered

```
docs/features/queue/decisions/2026-09-13-partial-dedupe-index.md
                              └────┬────┘ └────────┬─────────┘
                              creation date    kebab slug
```

**Sequential `NNNN-` numbers are wrong for parallel work.** Two agents in two
worktrees both read "the last one is `0003`", both write `0004-*.md`, and the
result is either a merge conflict or two different records wearing the same
number. A date prefix needs no coordination: nothing is read before writing, so
two concurrent authors cannot collide, and the directory still sorts
chronologically.

```
   sequential NNNN                     date-prefixed
   ───────────────                     ─────────────
   agent A ─ reads 0003 ─▶ 0004 ─┐     agent A ─▶ 2026-09-13-lease-based-reclaim ─┐
   agent B ─ reads 0003 ─▶ 0004 ─┴─▶ ✗ agent B ─▶ 2026-09-13-partial-dedupe-index ┴─▶ ✓
             (no read = no race)
```

Create records with the helper the scaffolder installed into the project. It
stamps the date, slugifies the title, seeds the obvious fields, and prints the
path it created:

```sh
./docs/new-record.sh decision queue   "Partial dedupe index"
./docs/new-record.sh bug      queue   "Orphan reclaim skipped attempts"
./docs/new-record.sh plan     -       "Extract the queue"
./docs/new-record.sh feature  billing "Billing"     # adds a feature area later
```

Rules that survive from the numbered scheme:

- **Append-only.** A superseded record stays, marked
  `Status: superseded by 2026-10-02-<slug>`. Never rename, never delete.
- **Reference records by their full filename**, not by a number.
- Same title on the same day is the only collision possible; `new-record.sh`
  detects it and exits rather than overwrite.
