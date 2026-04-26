---
artifact: architecture-proposed
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - path/relative/to/repo/
derived_from:
  - architecture-current.md
last_updated: YYYY-MM-DD
proposal_mode: delta
---

<!--
  Use this template for `architecture-proposed.md` (delta mode) — incremental
  modification of an element that already has `architecture-current.md`.

  Describe ONLY the scoped change. Do not restate unchanged sections; list
  them under "Sections Carried Forward".

  Stay at architecture depth. Code-level detail belongs in "Deferred
  Detailed Design" or, if it is genuinely outside the change, omit it.
-->

# <Element Name> — Architecture Delta

## Executive Summary

What is changing, why now, and the shape of the change in two or three
sentences.

## Affected Elements

Which components from `architecture-current.md` are touched by this delta.

## Changed Responsibilities

Responsibility shifts — what an element is newly responsible for, what it
is no longer responsible for.

## Changed Interfaces and Contracts

Interfaces gaining, losing, or revising contracts. Describe the new
contract at the boundary.

## Changed Dataflow and Interactions

New / removed / re-routed data flows.

## Changed State or Concurrency

<!-- Drop if state and concurrency are unchanged; note in Applicability Notes. -->

State ownership shifts, new concurrency requirements.

## Risks and Open Questions

Risks introduced by the delta and unresolved questions specific to it.

## Deferred Detailed Design

Details inside the change scope that the planner should resolve. Required
even when empty.

## Planner Constraints

New or revised invariants the planner must respect for this delta. Carried
constraints from `architecture-current.md` still apply unless explicitly
overridden here.

## Sections Carried Forward

Explicitly enumerate which sections of `architecture-current.md` are
unchanged by this delta. The reviewer uses this list to confirm the merge
is mechanical:

- Goals — unchanged
- Non-Goals — unchanged
- Constraints and Assumptions — unchanged
- ...

## Applicability Notes

- Changed State or Concurrency — N/A — <reason>
