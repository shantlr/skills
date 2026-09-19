---
name: flow-setup
description: Sets up the two folders the flow workflow reads and writes — a `docs/` tree (ARCHITECTURE.md entry point, per-feature one-pagers, dated decision and bug records, generated FEATURE-MAP.md / INDEX.md) and a `tasks/` folder where each unit of work keeps its design, plan and review. Also migrates an existing project onto that layout, proposing a move for every file already serving the same purpose. Use when the user says "set up docs", "set up the flow", "create a docs folder", "add documentation structure", "scaffold docs", "document this project", "I want ADRs / decision records / bug records", "migrate my docs", or asks for an architecture overview or a map of which files implement what. User-invoked only — never trigger this skill on your own initiative while doing other work; it must be asked for explicitly.
version: 2.0.0
---

# Flow / Setup: the folders the flow lives in

> **User-invoked only.** This skill runs *only* when the user explicitly asks
> for it (by name, or with a phrase from the description above). Do not fire it
> as a side-effect of another task — not after a feature lands, not because a
> project "should have docs", not from inside another skill or subagent, not
> because `flow` found no `tasks/`. Scaffolding these trees nobody asked for
> rewrites `CLAUDE.md`, drops a dozen files into the repo, and — in migration
> mode — **moves files the user did not ask you to touch**. That has to be a
> deliberate choice.
>
> ```
>   user: "set up docs" / "set up the flow" ──▶ run this skill   ✓
>   user: "add feature X"    ──┐
>   finished another skill   ──┼──▶ do NOT run it                ✗
>   repo has no docs/        ──┘    (mention it at most, then move on)
> ```

Creates the durable, agent-friendly `docs/` tree and the `tasks/` folder the
five `flow` stages read and write, **writes the entry point for real** by
reading the codebase, and folds any existing documentation into the layout
instead of leaving two competing conventions in the repo. The point is that the
next bug, the next decision, and the next piece of work each have one obvious
place to land — and that anyone arriving later can *find* them.

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
│   ├── architecture.md  feature.md  bug.md  decision.md
└── features/              ← one directory per feature area
    └── <feature>/
        ├── README.md        what it is, how it works, + ## Key files
        ├── bugs/            YYYY-MM-DD-kebab-title.md
        └── decisions/       YYYY-MM-DD-kebab-title.md

tasks/                     ← SIBLING of docs/, not inside it
├── README.md              ← how a unit of work is recorded
└── YYYY-MM-DD-<slug>/     ← one folder per unit of work
    ├── design.md            what we decided to build, and why
    ├── plan.md              the task breakdown, checkboxes ticked as it runs
    └── review.md            what review found, with root causes
```

**Two trees, one rule.** `docs/` is the system **as it is now** — present tense,
edited in place. `tasks/` is **how it got there** — dated, append-only. A plan
is not documentation: it is a statement about the future that goes stale the
moment the work lands, so it never belongs in `docs/`. The last step of a unit
of work is promoting what outlived it into `docs/` (the `flow-doc` skill does
this automatically).

```
  tasks/<date>-<slug>/design.md ──┐
  tasks/<date>-<slug>/review.md ──┴──►  docs/features/<f>/README.md
                                        docs/features/<f>/decisions/<date>-<slug>.md
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

1. **Survey what the project already has.** Do not go looking for a fixed list
   of known layouts — every team invents its own. **Explore the actual project
   structure** and judge each candidate by what it *is*, not by where it sits.

   ```sh
   ls -d docs doc documentation tasks 2>/dev/null
   find . -maxdepth 3 -type d \( -name .git -o -name node_modules -o -name vendor \
        -o -name target -o -name dist -o -name build \) -prune -o -type d -print | head -60
   find . -maxdepth 3 -name '*.md' -not -path '*/node_modules/*' -not -path '*/.git/*' | head -60
   ```

   Then **open the ones that look like documentation** — a directory name means
   nothing until you have read a file in it. Classify each by the question it
   answers, which is the only thing that decides where it belongs:

   ```
     "how does this work, today?"     ──►  docs/features/<f>/README.md
     "why is it like that?"           ──►  docs/features/<f>/decisions/
     "what broke, and why?"           ──►  docs/features/<f>/bugs/
     "what are we about to build?"    ──►  tasks/<date>-<slug>/design.md
     "how is that work broken down?"  ──►  tasks/<date>-<slug>/plan.md
     "what did review find?"          ──►  tasks/<date>-<slug>/review.md
     none of these                    ──►  leave it exactly where it is
   ```

   Dated or numbered filenames (`2026-01-04-*.md`, `0003-*.md`) are the strongest
   signal of a record; a file that describes future work is a task artifact even
   when it lives under `docs/`. **When you cannot tell, it does not move** — put
   it in the "leave alone" list with one line of why, not in the proposal.

2. **Propose the migration, then apply only what is confirmed.** Present one
   table. Never move anything before the user has seen it.

   | From | → To | Why |
   | --- | --- | --- |
   | `docs/plans/2026-01-04-extract-queue.md` | `tasks/2026-01-04-extract-queue/plan.md` | dated plan = a unit of work |
   | `docs/adr/0003-use-postgres.md` | `docs/features/storage/decisions/2024-03-11-use-postgres.md` | ADR; date from git history |
   | `NOTES.md` | *(stays)* | scratch, not a record |

   Rules for the proposal:
   - **One row per file**, with its destination *fully resolved* — no globs, no
     "and the rest". A row the user cannot verify at a glance is a row they will
     approve blindly.
   - **Recover the real date** for anything being date-prefixed — the *oldest*
     commit that touched it, following renames:
     ```sh
     git log --follow --format=%ad --date=short -- <file> | tail -1
     ```
     `--follow` is not optional: without it a file that was ever `git mv`d reads
     as created on the day it moved, and an ADR pile being reorganised is
     exactly the history these files have. Do **not** use `--diff-filter=A -1`
     — that returns the *newest* add, which is the rename.

     If the command prints nothing (untracked file, no git), say so in the row
     and ask the user for the date. Never silently fall back to today: that
     backdates the project's whole history to the day it was migrated.
   - **Ask before renaming a numbered ADR scheme** — some teams cross-reference
     `ADR-0003` in code comments and commit messages. If they keep the numbers,
     keep the filenames and only move the directory.
   - **A file that needs splitting is not a move.** A single `DECISIONS.md`
     holding twelve decisions: propose it as a separate, explicit step, and do
     it by writing new records and leaving the original in place with a pointer
     — never by deleting the source.
   - Ask with the `mcp__jean-claude-mcp__ask_question` tool if available,
     otherwise in plain text. Offer per-row opt-out, not just yes/no.

   Then apply with plain `mv` (this must work in non-git projects too),
   `mkdir -p` first, and **never overwrite**. Use exactly this, once per row —
   `mv -n` is what makes the no-overwrite guarantee real rather than advisory:

   ```sh
   if [ -e "$dst" ]; then
     echo "SKIPPED (destination exists): $src -> $dst"
   else
     mkdir -p "$(dirname "$dst")" && mv -n "$src" "$dst" && echo "moved: $src -> $dst"
   fi
   ```

   Do not compress this into `[ -e "$dst" ] && { …; continue; }` — outside a
   loop `continue` fails, execution falls through to the `mv`, and the
   destination is destroyed while the output still says "skip".

   **Tell the user how to undo, before you start — and be accurate.** A move is
   *not* reverted by `git checkout -- .`: that restores the tracked source and
   leaves the new untracked copy in place, so the corpus ends up duplicated
   rather than restored. The honest undo is:

   ```sh
   git status --porcelain          # every move, before you trust anything
   git stash -u                    # or: git checkout -- . && rm -rf <new dirs>
   ```

   In a project with no git and no clean tree, say so and let the user decide
   whether to proceed — do not move files that have no way back.

3. **Handle an existing `docs/` directory.** If one survived the migration,
   **ask the user** before scaffolding into it. Offer exactly these three, and
   do not guess:
   - **merge** — adds only missing files, never overwrites. Their existing
     `docs/README.md` therefore *survives*, and it will not describe the new
     tree. After scaffolding, say so and offer to fold the index from
     `scripts/assets/docs-readme.md` into it. Silently leaving a stale index
     is the main way this option goes wrong.
   - **a different directory** — `--docs-dir <name>` (e.g. `documentation`).
     Note that `--root` moves the *project* root, not the docs directory;
     `--root sub` produces `sub/docs/`, which is rarely what is wanted.
   - **abort**.

   Same for `tasks/`: if the project already uses that name for something else
   (a build task runner, fixtures), **stop and report it**. Do not scaffold into
   it and do not silently pick another name — ask.

4. **Identify the feature areas.** Do not invent them and do not ask a blank
   question. Read the repo first — top-level source directories, route/screen
   names, package names, `README.md` — and propose a list of 4–10 feature areas
   for the user to confirm or edit. Feature names are lowercase single words
   where possible (`capture`, `queue`, `auth`, `billing`).
   If the user already named the features, skip straight to step 5.

5. **Run the scaffolder** with the confirmed features. Migration (steps 1–2)
   comes first on purpose: the scaffolder is idempotent and reports `skip` for
   anything already in place, so moved files survive it untouched.

   You are standing in the
   user's project, not in this skill, so resolve the skill's own path first —
   it is the directory containing the `SKILL.md` you are reading, usually
   `~/.claude/skills/flow-setup`:
   ```sh
   SKILL=~/.claude/skills/flow-setup     # or wherever this SKILL.md lives
   "$SKILL/scripts/setup-flow.sh" --root . <feature> [<feature> ...]
   ```
   If that path does not exist, find it:
   `find ~/.claude/skills -name flow-setup -maxdepth 2`.

   Flags: `--root <path>` scaffolds into a different project root;
   `--docs-dir <name>` uses a directory other than `docs` (use this when the
   user wants `documentation/` or already has a `docs/` you agreed not to touch).
   It is idempotent — existing files are left untouched and reported as `skip`.
   It also installs `docs/new-record.sh` and `docs/build-index.sh`; from here on
   those copies are the ones to use, and the ones the project's own docs name.

   It additionally creates `tasks/` with its README at the **project root** —
   never inside the docs directory, even when `--docs-dir` is nested. An
   existing `tasks/` is adopted only when it is empty or already holds task
   folders; anything else (a task runner, fixtures) is reported as `SKIP` and
   left completely untouched. Pass `--no-tasks` to skip the step when the user
   wants task artifacts kept elsewhere — and surface the `SKIP` line to them
   rather than reporting a clean scaffold.

6. **Write `docs/ARCHITECTURE.md` for real.** This is the step that makes the
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

7. **Fill in each feature's `## Key files`.** For every
   `docs/features/<f>/README.md`, replace the placeholder list with the 3–7
   files you would actually open first, in the order you would open them, each
   with a short clause on what it does. Write the feature's opening paragraph
   and **How it works** while you are there — you have just read the code.

   This section is the source of `FEATURE-MAP.md`, so guessing here poisons the
   map. Every path must exist; step 8 will tell you if it doesn't.

8. **Generate the read path and verify it.**
   ```sh
   ./docs/build-index.sh          # writes FEATURE-MAP.md and INDEX.md
   ./docs/build-index.sh --check  # must exit 0 before you report success
   ```
   `--check` fails on three things: a generated file that is stale, a
   `## Key files` path that does not exist, and a feature whose key files were
   never filled in. All three are your bugs at this point — fix them, don't
   report them as findings.

9. **Add the maintenance rules** to the project's `CLAUDE.md`, creating it if
   absent. The block is everything after the `---` in
   `references/claude-md-block.md` — append it whole:
   ```sh
   awk 'f; /^---$/ {f=1}' "$SKILL/references/claude-md-block.md" >> CLAUDE.md
   ```
   Then reconcile by hand: if `CLAUDE.md` already had a `## Documentation`
   heading, merge the two rather than leaving both; and if you used
   `--docs-dir`, replace `docs` throughout the block. A scaffold nobody updates
   becomes fiction within two weeks — this block is what keeps it alive.

10. **Report** the tree (`find docs -type f | sort`), show the user
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
| decision / bug records | only when there is one to write | shape only |
| `tasks/README.md` | — | scaffolded as-is |

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
./docs/new-record.sh feature  billing "Billing"     # adds a feature area later
```

Rules that survive from the numbered scheme:

- **Append-only.** A superseded record stays, marked
  `Status: superseded by 2026-10-02-<slug>`. Never rename, never delete.
- **Reference records by their full filename**, not by a number.
- Same title on the same day is the only collision possible; `new-record.sh`
  detects it and exits rather than overwrite.
