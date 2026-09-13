<!--
This is docs/ARCHITECTURE.md — the entry point. Everything else in docs/ is
reached from here.

It is written ONCE by reading the codebase, and revised when the shape of the
system changes — not per feature, not per PR. It answers three questions in
order: what is this, how is it put together, and where do I go next.

Do not let it become a feature list. Feature detail lives in
docs/features/<f>/README.md; the file map is generated into
docs/FEATURE-MAP.md. This file is the map of the *system*.

Keep it under ~150 lines. An entry point nobody finishes reading is not one.
-->

# <Project> — Architecture

> One sentence: what this project is and who it is for.

- **Stack:** <languages, frameworks, datastores>
- **Entry point:** `<the file that runs first>`
- **Docs entry point:** you are here — see [INDEX.md](./INDEX.md) for every
  record, [FEATURE-MAP.md](./FEATURE-MAP.md) for which files implement what

---

## 1. What it is

Two or three paragraphs. The problem, the shape of the solution, and the one
non-obvious constraint that explains most of the design.

## 2. How it fits together

An ASCII diagram of the real runtime pieces and what flows between them. Boxes
are processes, stores, and external services — not classes.

```
  <client> ──▶ <entry> ──▶ <core> ──▶ <store>
                  │
                  └──▶ <external service>
```

Then a paragraph per box: what it owns, and what it must never do.

## 3. The main flow

The one path through the system that matters most, step by step. If a newcomer
understands only one thing, this is it.

## 4. Where things live

| Area | Code | Docs |
| --- | --- | --- |
| <feature> | `src/<dir>/` | [features/<feature>](./features/<feature>/README.md) |

## 5. Rules that are not obvious from the code

The invariants a newcomer would break. Each one should link to the decision
record that established it.

- <invariant> — see `features/<f>/decisions/<record>.md`

## 6. Where to go next

- **"What is feature X?"** → `features/<x>/README.md`
- **"Which file does X?"** → [FEATURE-MAP.md](./FEATURE-MAP.md)
- **"Why is it like this?"** → [INDEX.md](./INDEX.md) ▸ Decisions
- **"Has this broken before?"** → [INDEX.md](./INDEX.md) ▸ Bugs
- **"What's being built?"** → `plans/`
