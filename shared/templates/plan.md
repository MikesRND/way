---
artifact: plan-proposed
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - path/relative/to/repo/
derived_from:
  - architecture-approved.md
last_updated: YYYY-MM-DD
---

<!--
  Plans are always full documents (no delta mode).

  Plan ONLY for what `architecture-approved.md` introduces or changes
  relative to `architecture-current.md`. Do not redesign the approved
  architecture; if you need to, escalate.
-->

# <Element Name> — Plan

## Plan Summary

What this plan implements, scoped to the change in
`architecture-approved.md`.

## Preconditions and Assumptions

What must be true before implementation starts (env, dependencies, prior
work). Note assumptions that, if wrong, invalidate the plan.

## Phase or Slice Breakdown

Named phases or vertical slices. v1 runs all phases in a single
`way-impl` invocation; the breakdown still exists for design discipline
and is consumed by `way-impl-review`.

For each phase: name, intent, exit criteria.

## Ordered Work Items

Numbered, granular work items grouped by phase. Each item:

- Touch points (files / modules expected to change)
- Outcome (what is true once this item is done)
- Dependencies (other items / external prerequisites)

## Detailed Design Summary

Implementation-relevant design captured here so it does not pollute the
work-item list. This is the seed material `way-finalize` uses to refresh
`detailed-design-current.md` — write it as durable design, not task notes.

Suggested sub-sections (drop those that don't apply):

- Key source areas
- Runtime flow
- Important internal interfaces and types
- Invariants and failure boundaries
- Extension points and constraints
- State, ownership, and lifecycles
- Concurrency and synchronisation
- Critical data structures and algorithms

## Validation and Review Gates

Shell commands `way-impl` will run at the end of each phase / cycle.
Platform-neutral — anything that can run via shell:

- `npm test`
- `pytest -q`
- `cargo check`
- custom verification scripts

Plus any review gates the plan requires (e.g. "way-impl-review must pass
before way-finalize").

## Risks and Escalation Triggers

Risks specific to the plan and the conditions under which `way-impl` must
**stop and escalate** (e.g. "if the proposed touch points conflict with a
Planner Constraint, stop and escalate to `way-arch-design`").

## Completion Criteria

What "done" means for this cycle, in observable terms — gate results,
artifact states, repo state.
