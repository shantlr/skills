# Guidelines

Cross-cutting rules that apply to **every** feature, so they cannot live under
one. Written once, obeyed forever, cited by ID in review.

```
docs/guidelines/
├── README.md          ← this file
├── ui-ux/             ← interface & interaction behaviour (the first-class area)
│   ├── data-freshness.md
│   └── forms.md
└── <area>/            ← api/, data/, testing/, … added when one is earned
```

A **feature doc** answers *"how does checkout work?"*. A **guideline** answers
*"how do we handle this kind of situation, anywhere in the product?"* — never
show data that has silently gone stale, always confirm a destructive action,
every mutation rolls back on failure. These accumulate from real work: you hit
the problem once, decide the rule, and never re-decide it.

```
   feature doc          decision record        guideline
   ───────────          ───────────────        ─────────
   how ONE thing        why ONE choice         how EVERY case
   works, today         was made, once         of a kind is handled
   features/<f>/        features/<f>/          guidelines/<area>/
                        decisions/
```

## Rule IDs

Every rule carries a stable ID: the topic filename in caps, plus its number.

```
   docs/guidelines/ui-ux/data-freshness.md
                         └──────┬──────┘
                    ### DATA-FRESHNESS-3 — never render a stale list …
                                       │
                    review cites it ───┘  "violates DATA-FRESHNESS-3"
```

- **Numbers are allocated once and never reused.** A retired rule keeps its ID
  and its position, struck through, with a pointer to what replaced it.
  Renumbering silently invalidates every citation ever written.
- **Topic filenames are unique across areas** — `ui-ux/forms.md` and
  `api/forms.md` cannot both exist, because `FORMS-2` must mean one thing.
  `build-index.sh --check` fails if they collide.

## Reading path

| Your question | Go to |
| --- | --- |
| What rules apply to the screen I'm changing? | `guidelines/ui-ux/` |
| What does `DATA-FRESHNESS-3` say? | `INDEX.md` ▸ Guidelines, then the topic file |
| Why does this rule exist? | the rule's **Because** and **Source** lines |

## Writing path

A guideline is **earned**, not invented. Add one when:

- the same review finding has now appeared **twice** in different features;
- a design conversation settled a rule that is obviously **not specific to this
  feature** ("we never block the UI on an optimistic write");
- a bug record's fix changed *how we do this kind of thing*, not just one call site.

Not earned: a one-off choice (that is a decision record), a style rule your
linter already enforces, or anything you have never actually needed.

```sh
./docs/new-record.sh guideline ui-ux "Data freshness"   # new topic file
./docs/build-index.sh                                   # after any change
```

Adding a rule to an existing topic is a plain edit: append the next `###` with
the next number. Keep topics at 3–10 rules; past that, split the topic.

## Rules about the rules

1. **One imperative sentence per rule**, concrete enough to hold a diff against.
   "Be thoughtful about loading states" is not a rule.
2. **Every rule says *because*.** A rule with no stated failure mode gets
   argued with, then ignored.
3. **Record the source** — the task folder or bug record that earned it. That is
   how a future reader judges whether it still applies.
4. **Never renumber. Never delete.** Strike through and point forward.
5. **If it only applies to one feature, it is not a guideline** — it belongs in
   that feature's README or a decision record.
