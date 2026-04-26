---
name: way-plan
description: >
  Produce plan-proposed.md from architecture-approved.md. Plans are always
  full documents (never delta) but are scoped to what the approved
  architecture changes relative to architecture-current.md, not the entire
  approved architecture. Includes a Detailed Design Summary that seeds
  detailed-design-current.md at finalize.
license: MIT
metadata:
  author: mikesrnd
  version: "1.0"
---

# way-plan

## Prerequisites

Read `references/family-contract.md` first. §10 (scope discipline) and
§11 (sections) are the binding rules for this skill.

## Purpose

Author `.way/elements/<element_key>/plan-proposed.md` from
`architecture-approved.md`. The plan elaborates an approved architecture
into ordered, executable work without redesigning it.

## Inputs

- `architecture-approved.md` (required)
- `architecture-current.md` (used to scope the plan to the approved
  *change*, not the entire approved architecture)

## Procedure

### Step 1 — Read and scope

Read `architecture-approved.md` and `architecture-current.md` (if
present). Compute the **scope of change**: the elements, interfaces,
dataflows, and constraints that differ between the two.

The plan addresses **only** that scope. It does not re-plan parts of
the approved architecture that were already implemented. If
`architecture-current.md` is absent (greenfield), the scope is the
entire approved architecture.

### Step 2 — Draft

Use `references/templates/plan.md`. Fill in:

1. **Plan Summary** — the change being implemented, scoped to the diff.
2. **Preconditions and Assumptions** — environment, dependencies, prior
   work that must be in place.
3. **Phase or Slice Breakdown** — named phases / vertical slices. v1
   runs all phases in a single `way-impl` invocation, but the breakdown
   exists for design discipline and is consumed by `way-impl-review`.
4. **Ordered Work Items** — granular, numbered, grouped by phase. Each
   item has touch points, outcome, dependencies.
5. **Detailed Design Summary** — design-oriented content that informs
   implementation but does not belong in the work-item list. This is
   seed material for `detailed-design-current.md` at finalize, so
   write it as durable design, not task notes.
6. **Validation and Review Gates** — shell commands `way-impl` will
   run. Platform-neutral. Plus any review gates the plan requires.
7. **Risks and Escalation Triggers** — when `way-impl` must stop and
   escalate (e.g. "if implementation requires changing an Interface
   declared stable, escalate to `way-arch-design`").
8. **Completion Criteria** — observable definition of done.

### Step 3 — Scope discipline check

Re-read the plan and confirm:

- Every work item is justified by a change in
  `architecture-approved.md` relative to `architecture-current.md` (or
  the entire approved architecture if greenfield).
- The plan does **not** redesign decisions in
  `architecture-approved.md`. If it implicitly does so, stop and
  escalate to `way-arch-design`.
- Planner Constraints from the approved architecture are honoured. Any
  work item that would violate one is recategorised as an Escalation
  Trigger, not a work item.

### Step 4 — Write

Write `plan-proposed.md` with frontmatter:

```yaml
---
artifact: plan-proposed
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from:
  - architecture-approved.md
last_updated: <YYYY-MM-DD>
---
```

## Output

The single file `plan-proposed.md`. Report:

- Path written.
- Phase / slice count and total work-item count.
- Validation gates declared.
- Anything raised as an Escalation Trigger that should have been an
  architecture revision.
- Hand off to `way-plan-review`.

## Non-Behaviours

- Do **not** redesign the approved architecture. If the plan needs to,
  raise an Escalation Trigger and stop; the user should run
  `way-arch-design` instead.
- Do **not** plan beyond the approved change. Anything that would touch
  unchanged architecture goes into Risks (or is dropped).
- Do **not** implement code.
