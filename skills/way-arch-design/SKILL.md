---
name: way-arch-design
description: >
  Produce architecture-proposed.md for a new or changing element. Full mode
  for greenfield work or wholesale rearchitecture; delta mode for
  incremental modification of an element that already has
  architecture-current.md. Stays at architecture depth and defers code-level
  detail to the planner. Does not implement code.
license: MIT
metadata:
  author: mikesrnd
  version: "1.0"
---

# way-arch-design

## Prerequisites

Read `references/family-contract.md` first. §7 (architecture vs. code) and
§8 (full vs. delta) are the binding rules for this skill.

## Purpose

Author or revise `.way/elements/<element_key>/architecture-proposed.md` —
the proposal that goes into `way-arch-review`.

## When to invoke

- Designing a new element (greenfield).
- Proposing changes to a documented element.

If an element exists in code but has no `architecture-current.md`, run
`way-arch-doc` first to capture the current state, then return here.

## Mode selection

- `proposal_mode: full` —
  - Greenfield (no existing code), or
  - Wholesale rearchitecture of a documented element.
- `proposal_mode: delta` —
  - Incremental modification of an element that already has
    `architecture-current.md`.

In delta mode, **do not restate unchanged architecture**. Describe only
the scoped change and explicitly enumerate carried-forward sections.

## Inputs

- `element_key`
- `scope_paths`
- `proposal_mode` (`full` or `delta`)
- For delta mode: `architecture-current.md` must exist.

## Procedure

### Step 1 — Read inputs

Read `architecture-current.md` if present. Note its Planner Constraints
and Deferred Detailed Design — they are carried forward by default unless
the proposal explicitly overrides them.

### Step 2 — Draft

Use the right template:

- Full → `references/templates/architecture-full.md`
- Delta → `references/templates/architecture-delta.md`

Stay strictly at architecture depth:

- Speak in terms of components, responsibilities, boundaries, dataflow,
  interfaces, state ownership, concurrency, failure boundaries.
- Do not name specific functions, algorithms, error types, defensive
  checks, or library APIs.
- Real but non-architectural detail goes into **Deferred Detailed
  Design**, not the main narrative.
- Phrase Planner Constraints as binding rules the planner cannot relax.

### Step 3 — Required self-check pass

Re-read every sentence. Apply the filter from §7 of the family contract.
For each flagged sentence: rewrite, relocate to Deferred Detailed Design,
or delete.

This step is **mandatory**. Code-level leakage is the failure mode this
family was built to prevent.

### Step 4 — Delta-specific check

If `proposal_mode: delta`:

- Confirm every section either describes a change or is listed under
  **Sections Carried Forward**.
- Confirm Planner Constraints from `architecture-current.md` that should
  carry forward are not silently dropped.
- If broad rewording of unchanged sections seems necessary, this is a
  smell — switch to `proposal_mode: full`.

### Step 5 — Frontmatter and write

Write to `.way/elements/<element_key>/architecture-proposed.md`:

```yaml
---
artifact: architecture-proposed
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from: []                    # full
# or
derived_from:
  - architecture-current.md         # delta
last_updated: <YYYY-MM-DD>
proposal_mode: full|delta
---
```

If revising after a `revise` decision in `architecture-review.md`, address
each Issue Requiring Revision and each Approval Condition before writing.
Do not delete the old proposal — supersede it in place. `git log` carries
the inter-revision history; archives happen only at finalize.

## Output

The single file `architecture-proposed.md`. Report:

- Path written.
- Mode (`full` or `delta`).
- For delta: sections carried forward; new or revised sections.
- Self-check pass results (count of sentences rewritten / relocated /
  deleted).
- Hand off to `way-arch-review`.

## Non-Behaviours

- Do **not** write `architecture-approved.md`. That is `way-arch-review`'s
  job.
- Do **not** write `architecture-current.md` from this skill. Current is
  refreshed by `way-finalize` from approved.
- Do **not** plan or implement. Plans live in `plan-proposed.md`; code
  changes live in `way-impl`.
- Do **not** redesign during a "revise" pass beyond what the review
  requested. If new issues surface, raise them; do not silently expand
  scope.
