---
name: flow-design-fidelity
description: Checks whether a finished implementation follows the supplied design guidelines, mockups, screenshots, prototypes, or written UI requirements. Use standalone when asked to check design fidelity or compare a build to a design, and after general Flow review whenever applicable design guidance was supplied for the task.
version: 1.0.0
---

# Check design fidelity

1. Gather the original sources, the task design if available, and any approved
   departures. List the applicable requirements with their source and the
   affected screen, component, viewport, or state. Use the agreed design and
   approved departures when interpreting the reference. Record conflicting or
   inaccessible sources when they prevent a check.
2. Run the implementation through its normal entry point. Match the reference
   viewport, state, and content as closely as possible. Capture the rendered
   result and compare it side by side with any visual reference. Check written
   guidelines through the rendered UI and its interactions, using code
   inspection where needed to verify tokens or behavior. Cover the relevant
   responsive layouts and states called out by the sources.
3. Report each requirement as matched, mismatched, or unverified. For a mismatch,
   show the expected and actual result, with a screenshot or reproduction steps
   when available. For an unverified item, identify what prevented verification.
4. In Flow, fix determinate in-scope mismatches and repeat the affected checks.
   When invoked standalone for a check, report findings and make edits only if
   fixing them is also in scope. For each fix, state its root cause and report
   the recheck result. If an item needs user input, explain the affected UI,
   the choice, and your recommendation. Ask via Jean-Claude's ask-question tool.
5. Report the result in the conversation with the reference and evidence links
   and what the user should check or decide next. Mark the implementation as
   verified against the design only if the applicable checks passed.
