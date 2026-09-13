# The optional top-level files

`setup-docs` writes `ARCHITECTURE.md` (what the system *is*) and generates
`FEATURE-MAP.md` and `INDEX.md`. The three files below describe **intent and
progress** instead, which needs a human's judgement about sequencing and about
how honest the percentages are. Write them by hand when the project needs them.

```
  ARCHITECTURE.md  what it is, as built   ◀── scaffolded + written by the skill
  ─────────────────────────────────────
  DESIGN.md        what it should be     ─┐
  ROADMAP.md       in what order          ├─ by hand, when needed
  STATUS.md        how far along         ─┘   ← the only one that changes weekly
```

**`DECISIONS.md` is obsolete** — `INDEX.md` is its generated replacement, built
from record frontmatter, so it cannot fall out of date. If you have an existing
hand-written `DECISIONS.md`, migrate the records' frontmatter and delete it.

`ARCHITECTURE.md` vs `DESIGN.md`: the first describes the system that exists and
is revised when its shape changes; the second argues for a system that doesn't
exist yet and is frozen once built. Keeping both is only worth it while the gap
between them is still interesting.

---

## DESIGN.md — *what it is*

Written before the build. Numbered sections (`§1`, `§2`, …) so everything else
in the repo can cite it precisely — `(§8.2)` in a feature README is worth more
than a paragraph of restatement.

- Header: status, stack, platforms, repo layout
- §1 Why — what problem, and why the obvious approach was not taken
- §2 Scope — including a **decided constraints** table (the things that are
  settled and should stop being discussed)
- Middle sections: the data model, the flows, one section per subsystem
- A late section: **open questions**, numbered. Each one either becomes a
  decision record or kills a premise. This is the most valuable section.

Use ASCII diagrams for anything with more than two moving parts — a
before/after box diagram for an architectural change beats three paragraphs.

## ROADMAP.md — *in what order, and why that order*

- **The ordering principle**, stated explicitly as 2–4 rules in priority order.
  E.g. *kill the premise-breakers first*; *correctness-critical work lands
  before the thing it protects is usable*.
- A phases-at-a-glance table: `# | Phase | Ships | Answers / de-risks`
- One section per phase: the tasks, and the **exit criterion** — something you
  *run*, not something you read.
- A phase is a **vertical slice you can actually use**, not a layer.

## STATUS.md — *how far*

The only file updated continuously. One rule at the top: **a PR that finishes a
checklist item ticks it in the same PR.**

- Header block — last updated, current phase, **blocked on**. This is the part
  people actually read; keep it current or delete the file.
- An ASCII progress bar per phase:
  ```
  P1 ▓▓▓▓▓▓▓▓▓▓ 100%  foundations       ◀ complete
  P2 ▓▓▓▓▓▓▓░░░  71%  capture           ◀ exit criterion unmet
  ```
- Legend: `[ ]` not started · `[~]` in progress · `[x]` done · `[!]` blocked ·
  `[-]` dropped (say why inline)
- **Say what the percentage measures.** "Rows written" and "behaviour observed"
  are different numbers, and conflating them is how a project reads as 90% done
  while nothing has been run. Write the distinction down.
- A **Log** section at the bottom for anything surprising. The checkboxes are
  the tally; the log is the narrative.

## DECISIONS.md — replaced by the generated INDEX.md

A hand-written chronological index was the old answer to "78 records and no way
to find one". `INDEX.md` does the same job from record frontmatter, so it cannot
be forgotten on the PR that adds a record.

The one piece of the old design worth keeping is the **`decided_by`** field,
which the decision template carries: `user` decisions can only be revisited by
the user, while `design review` / `implementation` decisions can be revisited on
technical grounds. That distinction prevents a lot of relitigation — surface it
in `tags` if you want it in the index.
