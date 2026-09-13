<!--
This is docs/features/<feature>/README.md — the one page that answers
"what is this and how does it work?" for this feature area.

Hard rule: keep the prose under ~25 lines. It is an orientation document, not a
spec. Anything longer belongs in a decision record or in the code.

Write in the present tense about what the code DOES, not what it will do.
Link out: `decisions/2026-09-13-...` and `bugs/2026-09-13-...` rather than
re-explaining.

## Key files is the SOURCE of docs/FEATURE-MAP.md. Keep it to the 3-7 files you
would open first, in the order you would open them. `./docs/build-index.sh`
regenerates the map and fails if any path here no longer exists, so a moved
file is caught instead of quietly misleading the next reader.
-->

# <Feature>

One paragraph: what this feature is, and the requirement that justifies its
existence. If it replaced something, say what and why.

**How it works.** The mechanism, in the order it happens. Name the real
functions, tables, and files so the reader can jump straight to them.

**Edge cases.** The behaviours that are surprising but deliberate — each one is
usually a decision record; link it.

**Constants / config.** The tunable names, not their values.

## Key files

- `src/path/to/entry.ts` — the way in; start here
- `src/path/to/core.ts` — where the actual work happens
- `src/path/to/types.ts` — the shapes everything else agrees on

---

- Decisions: `decisions/`
- Known bugs & post-mortems: `bugs/`
