---
name: way-impl-review
description: >
  Review repo state against plan-approved.md and architecture-approved.md
  and write implementation-review.md. Reads implementation-manifest.md to
  scope the review, then verifies the manifest's claims against repo state;
  discrepancies between manifest and repo are review findings. Primary gate
  for catching architecture-violating drift. Reviewer-independent; prefer
  running in a fresh conversation.
license: MIT
metadata:
  author: mikesrnd
  version: "1.0"
---

# way-impl-review

## Prerequisites

Read `references/family-contract.md` first. §9 (reviewer independence)
and §10 (scope discipline) are the binding rules for this skill.

## Reviewer Independence (read first)

> **Prefer running this review in a fresh conversation or session.** A
> reviewer that has not seen the implementation conversation is
> genuinely independent. Highest-fidelity mode; platform-neutral.
>
> **If running in the same session as `way-impl`**, apply in-context
> discipline:
>
> - Do not reference your own prior reasoning; treat the manifest and
>   repo as if produced by someone else.
> - Read only the artifacts named on disk.
> - Produce the review as if encountering the work cold.

## Purpose

Verify that what is in the repo matches what `plan-approved.md` asked
for, with no architecture-violating drift. Catch the failure mode where
implementation silently rewrote the design.

## Inputs

- `implementation-manifest.md` (required — defines review scope)
- `plan-approved.md` (required)
- `architecture-approved.md` (required)

## Procedure

### Step 1 — Read manifest

Read `implementation-manifest.md`. Use it to scope the review — the
**Touched Files** section is the set of files to inspect. Do **not**
rediscover scope from `git diff`; the manifest is the source of truth
for what the implementer claims they did.

### Step 2 — Verify the manifest

Inspect the repo at the touched paths. For each:

- Does the file exist where the manifest claims?
- Do the changes match the Summary of Changes?
- Are there changes the manifest does not mention? Note them; they may
  be findings or may be incidental.

Discrepancies between manifest and repo are review findings.

### Step 3 — Conformance to plan

For each work item in `plan-approved.md`:

- Implemented as planned.
- Implemented with acceptable variation (one-line justification).
- Not implemented.

### Step 4 — Architecture conformance

For each Planner Constraint in `architecture-approved.md`:

- Confirm the implementation respects it.
- Flag any violation as **architecture-violating**. This is the most
  important class of finding — finalize must refuse to run if it is
  unresolved.

For changes outside the plan's declared scope: are they non-architectural
incidental edits, or do they touch interfaces / dataflow / boundaries?
The latter is architecture-violating drift.

### Step 5 — Validation gates

Inspect the manifest's Validation Gate Results.

- Any gate that did not run? Note it.
- Any gate with a non-zero exit? It must be resolved before approval —
  either fix and re-run, or document why the failure is acceptable.

### Step 6 — Write the review

Use `references/templates/implementation-review.md`:

```yaml
---
artifact: implementation-review
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from:
  - implementation-manifest.md
  - plan-approved.md
  - architecture-approved.md
last_updated: <YYYY-MM-DD>
phase: all
---
```

Sections:

1. Review Summary
2. Reviewed Phase (`all` in v1)
3. Reviewed Scope
4. Conformance to Approved Plan
5. Deviations and Their Impact — classify each:
   - **Non-architectural** — finalize will reconcile in favour of repo.
   - **Architecture-violating** — finalize must refuse and the user
     must escalate.
6. Verification Gaps
7. Decision — `approve`, `revise`, or `reject`.

## Output

The single file `implementation-review.md`. Report:

- Decision.
- Architecture-violating findings (highlighted — these block finalize).
- Non-architectural deviations.
- Verification gaps.

## Non-Behaviours

- Do **not** edit code.
- Do **not** rerun the validation gates (the manifest records them).
  If the manifest claims a gate passed and the user wants independent
  verification, the user can re-run; that is outside this skill's scope.
- Do **not** consult conversation history.
- Do **not** approve a cycle with unresolved architecture-violating
  findings.
