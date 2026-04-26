---
artifact: implementation-review
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - path/relative/to/repo/
derived_from:
  - implementation-manifest.md
  - plan-approved.md
  - architecture-approved.md
last_updated: YYYY-MM-DD
phase: all
---

<!--
  Reviewer-independence guard applies — see family-contract.md §9.

  Read `implementation-manifest.md` first to scope the review, then
  verify the manifest's claims against repo state. Discrepancies between
  the manifest and the repo are review findings.
-->

# <Element Name> — Implementation Review

## Review Summary

One paragraph: what was reviewed, against what references, headline
finding.

## Reviewed Phase

`all` (v1).

## Reviewed Scope

The set of files / modules covered by this review. In v1 this is the
union of "Touched Files" across the manifest.

## Conformance to Approved Plan

For each plan work item: implemented as planned | implemented with
acceptable variation | not implemented. Variations need a one-line
justification.

## Deviations and Their Impact

Cases where the implementation diverges from the plan or manifest.
Classify each:

- **Non-architectural** — reconcile in favour of repo at finalize.
- **Architecture-violating** — must escalate; finalize must refuse.

## Verification Gaps

Gates that were skipped, gate results that look insufficient, and
behaviours the plan flagged that this review could not confirm.

## Decision

`approve` | `revise` | `reject`

Brief rationale matching the chosen verdict.
