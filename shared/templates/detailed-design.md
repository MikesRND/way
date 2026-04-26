---
artifact: detailed-design-current
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - path/relative/to/repo/
derived_from:
  - plan-approved.md
  - architecture-approved.md
last_updated: YYYY-MM-DD
---

<!--
  This is a long-lived doc. `way-finalize` rewrites it (or the affected
  portions) from actual repo state. The approved plan's Detailed Design
  Summary is used as outline and reconciliation checklist, not as source
  of truth.

  This is design-oriented, not a code reference. Describe how the system
  behaves and is structured one level deeper than architecture, but do
  not duplicate code.
-->

# <Element Name> — Detailed Design

## Purpose and Scope

What this document covers and the boundary against
`architecture-current.md`.

## Key Source Areas

Where in the repo the implementation lives. Directory- or module-level
pointers, not function-level.

## Runtime Flow

How requests / events / data move through the implementation at one
level below architecture. Sequence diagrams welcome.

## Important Internal Interfaces and Types

The internal contracts that matter for understanding or extending the
element. Boundary semantics, not signatures.

## Invariants and Failure Boundaries

What the implementation guarantees, where errors are handled, and what
is intentionally allowed to propagate.

## Extension Points and Constraints

Where the implementation expects to be extended and the rules a future
extension must follow.

## State, Ownership, and Lifecycles

<!-- Conditional. Drop if no meaningful state; note in Applicability Notes. -->

## Concurrency and Synchronization

<!-- Conditional. -->

## Critical Data Structures and Algorithms

<!-- Conditional. -->

## Applicability Notes

- State, Ownership, and Lifecycles — N/A — <reason>
- Concurrency and Synchronization — N/A — <reason>
- Critical Data Structures and Algorithms — N/A — <reason>
