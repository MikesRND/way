---
artifact: architecture-review
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - path/relative/to/repo/
derived_from:
  - architecture-proposed.md
  # add architecture-current.md when reviewing a delta or a refresh
last_updated: YYYY-MM-DD
---

<!--
  Read the reviewer-independence guard in family-contract.md §9 before
  drafting. Prefer running this review in a fresh conversation; if running
  in the same session, treat your earlier reasoning as someone else's work.
-->

# <Element Name> — Architecture Review

## Review Summary

One paragraph: what was reviewed, against what reference, the headline
finding.

## Compared Artifacts

- Under review: `architecture-proposed.md` (full | delta)
- Reference: `architecture-current.md` (if present) or "first iteration"
- Any other inputs the reviewer consulted

## Architectural Strengths

What the proposal does well at architecture depth. Worth listing because
it tells future-you what not to lose during revisions.

## Issues Requiring Revision

Each issue gets:

- **Issue.** A one-line statement.
- **Why.** Why this is a problem at architecture depth (not "I would have
  written it differently").
- **Suggested direction.** Optional — a hint, not a redesign.

Code-level leakage in the proposal is itself a revision request — call it
out here.

## Regressions or Mismatches

Cases where the proposal contradicts `architecture-current.md` or breaks
a Planner Constraint that was meant to be carried forward.

## Approval Conditions

Concrete, testable conditions the proposal must satisfy before approval.

## Decision

`approve` | `revise` | `reject`

Brief rationale matching the chosen verdict.
