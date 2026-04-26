---
name: way-advisor
description: >
  Advisory-only entry point to the way-* family. Inspects repo state and
  .way/elements/<element_key>/ state and recommends the next way-* skill (or
  recommends skipping the framework entirely for trivial work). Never writes
  files. Use when the user is unsure where to start, when picking up partly-
  finished workflow state, or when deciding whether a change warrants the
  framework at all.
license: MIT
metadata:
  author: mikesrnd
  version: "1.0"
---

# way-advisor

## Prerequisites

Read `references/family-contract.md` before doing anything. It defines the
artifact contract, frontmatter shape, and the architecture-vs-code rule the
recommendations rely on.

## Purpose

Help the user (or another tool) figure out the right next move in the
`way-*` lifecycle for a given element — including the "do not use the
framework" answer.

This skill is **read-only**. It never creates, modifies, or deletes
artifacts. Producing files is the job of the other `way-*` skills.

## Inputs

The user supplies one of:

- An `element_key` (lowercase kebab-case)
- A path in the repo (file or directory)
- A reference to an existing `.way/elements/<element_key>/` directory
- A natural-language description of the change

If only a path or description is given, propose an `element_key` (kebab-case,
unique under `.way/elements/`) and confirm it before continuing.

## Procedure

### Step 1 — Scope the change

Classify what the user is actually trying to do:

- **Trivial change.** Single-file fix, dependency bump, doc-only edit,
  rename of a private symbol, lint cleanup. Anything that does not touch
  component boundaries, responsibilities, or interfaces.
- **Substantive change.** New element, cross-component change, or any
  change that alters interfaces, dataflow, or responsibilities.

If the change is trivial, **stop here and recommend off-ramp** (see
"Off-ramp recommendation" below). Do not push users through the framework
for work that does not need it.

### Step 2 — Inspect element state

For the chosen `element_key`, look under `.way/elements/<element_key>/`
and the relevant repo paths. Three entry-path cases:

1. **Undocumented existing element.** Code exists for the element but
   `architecture-current.md` is absent. Recommend `way-arch-doc`. The
   point is to capture the implemented architecture before any redesign.
   After `way-finalize`, subsequent changes go through `way-arch-design`
   (delta).
2. **Greenfield new element.** No existing code, no `.way` state.
   Recommend `way-arch-design` with `proposal_mode: full`. Do **not**
   recommend `way-arch-doc` — there is nothing to reverse-engineer.
3. **Documented existing element.** `architecture-current.md` is present.
   Recommend `way-arch-design` with `proposal_mode: delta` for scoped
   changes, or `proposal_mode: full` for wholesale rearchitecture.

### Step 3 — Detect in-flight workflow

If artifacts beyond `architecture-current.md` and
`detailed-design-current.md` exist, the element is mid-cycle. Determine
the next phase from which artifacts are present:

| Files present (besides `*-current.md`) | Recommend next |
|---|---|
| `architecture-proposed.md` only | `way-arch-review` |
| `architecture-proposed.md` + `architecture-review.md` (decision = revise) | `way-arch-design` (revise) |
| `architecture-proposed.md` + `architecture-review.md` (decision = approve) but no `architecture-approved.md` | `way-arch-review` (normalise into approved) |
| `architecture-approved.md` but no `plan-proposed.md` | `way-plan` |
| `plan-proposed.md` only | `way-plan-review` |
| `plan-proposed.md` + `plan-review.md` (revise) | `way-plan` (revise) |
| `plan-approved.md` but no `implementation-manifest.md` | `way-impl` |
| `implementation-manifest.md` only | `way-impl-review` |
| `implementation-review.md` (decision = approve) | `way-finalize` |
| `implementation-review.md` (decision = revise) | `way-impl` (revise) |

If `architecture-proposed.md` is present, report whether its
`proposal_mode` is `full` or `delta`.

### Step 4 — Required inputs

For the recommended skill, list the on-disk inputs it expects (per the
family contract). Surface anything missing — e.g. "delta proposal needs
`architecture-current.md`, which is absent: run `way-arch-doc` first."

### Step 5 — Off-ramp recommendation

If Step 1 or Step 2 indicates the framework is overkill, output a clear
off-ramp:

> This change does not need `way-*`. Suggested handling: <direct edit /
> direct PR / quick fix>. The framework is meant for changes that touch
> architectural surface; this one does not.

Do **not** silently degrade — explicitly say the framework is being
skipped, and why.

## Output

A short report containing:

1. The `element_key` used (proposed if not supplied).
2. Detected element state (one of the three entry paths) and any
   in-flight workflow phase.
3. Recommended next skill, with required inputs.
4. Off-ramp recommendation, if applicable.
5. Anything missing the user needs to provide before proceeding.

Keep it terse — this skill is a router, not a designer.

## Non-Behaviours

- Never write to `.way/`.
- Never edit code.
- Never run validation gates or tests.
- Never recommend skipping a review phase to "save time" — if a change
  warrants the framework, it warrants the gates.
