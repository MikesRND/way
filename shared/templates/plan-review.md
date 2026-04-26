---
artifact: plan-review
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - path/relative/to/repo/
derived_from:
  - plan-proposed.md
  - architecture-approved.md
last_updated: YYYY-MM-DD
---

<!--
  Reviewer-independence guard applies — see family-contract.md §9.

  Review the plan against `architecture-approved.md`, not the
  conversation that produced it.
-->

# <Element Name> — Plan Review

## Review Summary

One paragraph stating what was reviewed and the headline finding.

## Architecture Alignment

For each plan section that should derive from
`architecture-approved.md`: does it derive cleanly?

- Out-of-scope items (plan addressing things outside the approved change)
- Missing items (approved-architecture changes the plan failed to address)
- Hidden redesigns (plan implicitly rewriting an approved decision —
  this is grounds to escalate, not to revise)

## Sequencing and Dependency Issues

Phases / work items in the wrong order, missing prerequisites, hidden
cross-dependencies between supposedly-independent slices.

## Missing Validation or Review Gates

Gaps in the gates the plan declares. Anything the architecture flagged
as risky should have a gate; verify.

## Approval Conditions

Concrete, testable conditions the plan must satisfy before approval.

## Decision

`approve` | `revise` | `reject`

Brief rationale matching the chosen verdict.
