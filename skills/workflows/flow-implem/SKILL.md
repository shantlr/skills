---
name: flow-implem
description: Stage 3 of the flow workflow — executes a wave-structured implementation plan by dispatching every file-disjoint task in a wave to concurrent subagents, verifying at each wave barrier and committing one task per commit. Use when the plan declares Wave / Owns / Verify per task, typically docs/plans/*-plan.md from flow-plan-implem, and the user says "implement the plan", "build it", or "run these tasks in parallel". For a plain checklist plan without wave and ownership metadata, use superpowers-subagent-driven-development instead.
version: 1.0.0
---

# Flow / Implem: run every wave as wide as it will go

**Input:** `docs/plans/<date>-<slug>-plan.md`.
**Output:** working code, one commit per task, plan checkboxes ticked.

You are the **orchestrator**, not the implementer. Your job is to keep the
maximum number of agents busy without ever letting two of them write the same
file — and to own all git operations yourself.

```
 preflight ─► WAVE n ──┬─ agent T1 ─┐
                       ├─ agent T2 ─┤  concurrent, disjoint Owns
                       └─ agent T3 ─┘
                              │
              commit each passing task ─► tick checkboxes
                              │
              wave barrier: full typecheck + suite ─► WAVE n+1
```

Working around a rule below while telling yourself you are honoring its intent
is still a violation.

## Instructions

### 1. Preflight

**STOP. Do not dispatch a single agent until every item here is confirmed.**

Run the plan's install / typecheck / test / lint commands **before touching
anything**. A pre-existing failure must be recorded now — otherwise you will
spend the session debugging someone else's breakage.

Then establish the ground rules for this repo:

- **Branch.** Confirm you are on a feature branch, not the default branch.
  Create one if not. Not a git repo at all? Say so, skip every commit step,
  and warn that failure recovery will be manual.
- **Clean tree.** `git status --short` must be clean, or you must know exactly
  why it isn't. Uncommitted files from a crashed mid-wave run will otherwise get
  swept into the wrong task's commit. Either commit them as a recovery commit
  or stash them before dispatching.
- **No test suite?** Say so once, then substitute the strongest available check
  for every `Verify` — typecheck, lint, a build, or a runtime smoke command from
  the `run` skill. Never silently downgrade a verify to "looks right".
- **Ownership.** Validate the plan's `Owns` sets are disjoint per wave:
  ```sh
  ~/.claude/skills/flow-plan-implem/scripts/check-plan.sh docs/plans/<file>.md
  ```
  If the script isn't installed, check the plan's file-ownership table by hand.
  Fix the plan before dispatching — catching it now costs a line edit, later it
  costs two agents' work.
- **Agent capability.** You need the Agent tool to dispatch a wave. If you are
  yourself running as a subagent without it, do not fake parallelism: execute
  the waves serially in task order, note in the report that the plan's
  parallelism was not exploited, and why.

### 2. Dispatch a wave

Take the next wave's unchecked tasks whose dependencies are all checked. Launch
**all of them in a single message**, one subagent per task, so they actually run
concurrently. Cap at ~4–6 concurrent agents; beyond that, verification commands
contend and wall-clock stops improving.

Give each agent, and nothing more:

- its task block **verbatim** from the plan
- the design sections its task references
- the preflight commands
- these standing constraints:

> - Write **only** the files in your `Owns` list. Read anything.
> - If you need to change a file you don't own, **stop and report it** — do not
>   edit it, do not work around it.
> - Do not run `git add`, `git commit`, `git stash`, or any branch operation.
>   The orchestrator commits.
> - Run only your scoped `Verify` command, not the full test suite.
> - Your siblings are editing their own files in this same working tree right
>   now. A whole-program typecheck will therefore show errors in files outside
>   your `Owns` — **ignore those**, they are not yours and they are transient.
>   Only failures inside your own files count. If you cannot tell, report it
>   rather than "fixing" a sibling's file.
> - Do not install dependencies or run migrations; report if you need one.
> - **Red before green.** For each test in your `Tests` list: write it, run it,
>   confirm it fails *for the expected reason* (not a typo or import error),
>   then implement, then run it again and read the output. A test you never
>   watched fail is not evidence of anything.
> - **Before reporting, self-check:** did you implement everything in `Do` —
>   nothing missing, nothing extra? Did you follow the pattern file your task
>   names? Did you write outside `Owns`? Re-read your own diff and answer these.
> - Report: files written, the **verbatim** verify output (not a summary),
>   and anything you had to leave undone. Never write "should pass" or "looks
>   correct" — report only a result you ran and read.

Serial exceptions from the plan's **Do not parallelize** list — migrations,
codegen, dependency installs, repo-wide formatters, port-binding tasks — you run
yourself, one at a time, between waves.

If tasks genuinely must write the same file concurrently, don't share the
working tree: give those agents separate git worktrees and merge after — confirm
the worktree path is gitignored first, or you will commit a nested worktree.
Prefer re-slicing the tasks instead; it is almost always cheaper.

### 3. Wave barrier

When every agent in the wave has returned:

1. `git status --short` — flag any file written by an agent that didn't own it.
   That is a contract violation; review that file closely before keeping it.
2. **Re-run each task's `Verify` yourself.** Do not commit off a subagent's
   reported output — an agent that finished suspiciously fast, summarized its
   test run instead of quoting it, or claims green on a file it barely touched
   gets independently checked. Read its diff too, not just its summary.
3. **Commit the tasks whose verify you just watched pass**, one commit each,
   staging only that task's `Owns` files: `feat(<scope>): <task title>`,
   Conventional Commits. Tick their checkboxes. Do this **before** the full
   suite — a failed sibling must not hold hostage work that is already correct.
4. Run the **full** typecheck + test suite. This is where wave-level integration
   breakage shows up — two individually-correct tasks that disagree at their seam.
5. Triage the result, because red here has two very different causes:

   | Red because | Action |
   | --- | --- |
   | A task in this wave failed and its `T0` stub still throws `not implemented` | **Expected.** Not a barrier failure. Record which suites are red for this reason, and move on. |
   | Two completed tasks disagree at a seam | **Real barrier failure.** Fix before dispatching the next wave. |

   Keep an explicit list of "known red, owned by task Tn". A test that is red for
   any reason *not* on that list blocks the next wave.

Do not open the next wave with an unexplained red barrier — but never let one
failed task freeze the rest of the plan either.

### 4. When something fails

| Situation | Action |
| --- | --- |
| One task fails, siblings fine | Let the wave finish. Fix the failed task yourself, or redispatch it with the failure output. Its siblings still commit. |
| Verify fails | State one hypothesis, then fix. Still failing after **2 attempts** → stop guessing, add logging/instrumentation and find the real cause before editing again. |
| Third consecutive failure on one task | Stop touching the code. The contract or the design is wrong, not your implementation — escalate to the two rows below. |
| Barrier fails at a seam between two tasks | The contract (T0) was ambiguous. Fix the contract, then the two tasks — not one side of the seam. |
| Agent reports it needs a file it doesn't own | Planning bug. Reassign that file's edits to one task, or add a wiring task. Do not let two tasks share it. |
| Root cause is in the design | Stop. Re-enter `flow-design` for that part, append a `## Revision` section to the design, then re-enter `flow-plan-implem` in **revision mode** to patch the plan. Never renumber or rewrite committed tasks. |
| Task needs an undecided product choice | Ask the user (batched, with recommendation). Don't invent. |
| Unrelated pre-existing bug found | Note it in the plan's `## Discovered` section. Don't fix it here. |
| A dependency of the failed task is blocked | Skip the dependents, keep running the rest of the plan, report what is blocked. |

Never mark a task done with a failing verify. Never comment out or `skip` a test
to get green.

### 5. Report

When all tasks are checked, post:

- Wave-by-wave table: tasks per wave, what ran concurrently, commit shas
- Anything added to `## Discovered`
- Any design revisions made and why
- Ownership violations caught at a barrier
- ASCII diagram of the final shape if it differs from the design's

Then hand off to `flow-review`.

## Rules

- **Dispatch the whole wave at once** — one message, many agents. Sequential
  launches waste the parallelism the plan paid for.
- **`Owns` is law.** An agent writing outside it is a bug to investigate, not a
  convenience to accept.
- **Only the orchestrator touches git.** Concurrent agents committing corrupt
  the index and produce unreviewable interleaved commits.
- **One task, one commit, always green.**
- **Full suite at wave barriers only** — scoped verifies inside tasks.
- **The plan is the contract.** Out-of-scope work goes in `## Discovered`.
- **Two failed fixes = add logs.** Blind third attempts are forbidden.
- **Report root causes**, not just "fixed it".
- **No new dependencies** unless the plan named them — otherwise ask.
- **Never push or open a PR** unless the user asked.
- **Never state a result you did not just run and read.** "Should pass" is not
  a result.

## Red flags — stop if you think any of these

| Thought | Reality |
| --- | --- |
| "The sibling's typecheck errors are trivial, I'll just fix them too." | You are about to write outside `Owns` and collide with a running agent. Report it instead. |
| "The agent said tests pass, that's good enough to commit." | Re-run the verify yourself. Trusting the report is how a broken commit lands. |
| "It's basically passing — one unrelated test is red." | Then you don't know it's unrelated. Triage it against the known-red list first. |
| "This is the third fix attempt but I'm sure this one's right." | Three strikes means the contract is wrong, not your code. Stop and escalate. |
| "I'll just commit everything at once, it's cleaner." | One task per commit is what makes a bad task revertible. |
| "The plan says T4 owns this file, but it's faster if I do it here." | The plan is the contract. Change the plan, not the ownership. |
| "I'll write the test after the implementation, same thing." | A test you never watched fail proves nothing about your code. |
