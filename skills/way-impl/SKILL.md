---
name: way-impl
description: >
  Implement code changes directly from plan-approved.md. Treats
  architecture-approved.md and plan-approved.md as binding constraints. Runs
  validation gates declared in the plan and writes implementation-manifest.md.
  v1 runs once per cycle; the manifest format is phase-aware so a future
  per-phase invocation pattern requires no artifact changes.
license: MIT
metadata:
  author: mikesrnd
  version: "1.0"
---

# way-impl

## Prerequisites

Read `references/family-contract.md` first. §10 (scope discipline) and §12
(validation gate execution) are the binding rules for this skill.

## Purpose

Implement the work items in `plan-approved.md`, run the validation gates,
and write `implementation-manifest.md`.

## Inputs

- `plan-approved.md` (required)
- `architecture-approved.md` (required — the binding constraint)

## Procedure

### Step 1 — Read

Read both inputs. Internalise:

- The Phase / Slice Breakdown.
- The Ordered Work Items.
- The Validation and Review Gates.
- The Risks and **Escalation Triggers** — these are the conditions under
  which you must stop and escalate rather than press on.
- The Planner Constraints in `architecture-approved.md`.

### Step 2 — Implement

Work through the plan's Ordered Work Items in order. For each item:

- Make the code changes within the declared touch points.
- Hold the line on `architecture-approved.md` and the plan's
  Planner Constraints. **If implementation requires an architecture
  change, stop and escalate to `way-arch-design` — do not silently
  redesign.** This is the single most important rule for this skill.
- Hold the line on the plan. If a work item turns out to need a
  different touch point or a different ordering, that is acceptable;
  record the variation in the manifest. If it needs a different
  *design*, escalate.

In v1 a single invocation works through all phases. The phase boundary
still matters as a unit of design discipline and as the granularity of
the manifest entries.

### Step 3 — Run validation gates

After implementation, run every gate declared in the plan's "Validation
and Review Gates" section. Each gate is a shell command. Capture:

- Command run
- Exit status
- Notable output (errors, summary lines, links to logs)

A non-zero exit on any gate is a finding — record it in the manifest and
do **not** mark the cycle complete. The user may choose to fix and
re-run, or to revise the plan.

### Step 4 — Write the manifest

Write `.way/elements/<element_key>/implementation-manifest.md` from
`references/templates/implementation-manifest.md`:

```yaml
---
artifact: implementation-manifest
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from:
  - plan-approved.md
last_updated: <YYYY-MM-DD>
current_phase: all
---
```

The manifest body has one Phases entry (`Phase: all` in v1) listing
touched files, summary of changes per phase, and gate results. The list
shape is preserved so v2 can adopt per-phase invocation without changing
the format.

If the plan's Phase / Slice Breakdown is meaningful (more than one
phase), record per-phase Touched Files and Summary of Changes inside the
single `all` entry under sub-headings — or, if the user opts in, write
multiple Phases entries. Either is acceptable in v1.

### Step 5 — Hand off

Report:

- Files touched (count and short list).
- Variations from the plan (and why each is non-architectural).
- Gate results (pass / fail per gate).
- Any escalations triggered.
- Next step: `way-impl-review`.

## Escalation

Stop and escalate (do not implement further) when:

- A work item cannot be done without violating
  `architecture-approved.md`.
- A work item cannot be done without violating a Planner Constraint.
- A Risk listed as an Escalation Trigger fires.
- A validation gate fails for an architectural reason (the design is
  wrong, not the code).

When escalating, write a brief escalation note in the manifest's
Cross-Phase Notes describing the conflict and proposed next step
(usually a return to `way-arch-design`).

## Non-Behaviours

- Do **not** redesign the architecture mid-implementation.
- Do **not** skip validation gates.
- Do **not** edit `architecture-approved.md` or `plan-approved.md`.
- Do **not** archive or rotate any `*-current.md` docs — that is
  `way-finalize`'s job.
