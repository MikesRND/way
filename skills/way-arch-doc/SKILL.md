---
name: way-arch-doc
description: >
  Reverse-engineer an existing element and produce architecture-current.md.
  Use when an element exists in code but has no architecture-current.md and
  needs one before any redesign. Do NOT use for greenfield work — when
  there is no existing code, way-arch-design with proposal_mode full is the
  correct entry point.
license: MIT
metadata:
  author: mikesrnd
  version: "1.0"
---

# way-arch-doc

## Prerequisites

Read `references/family-contract.md` first. The architecture-vs-code rule
in §7 is the single most important constraint on this skill.

## Purpose

Capture the **implemented** architecture of an existing element into
`.way/elements/<element_key>/architecture-current.md`. This is reverse
engineering, not redesign.

The output must read as architecture: components, responsibilities,
boundaries, dataflow, interfaces. It must not read as a code summary.

## When to invoke

- Element has code in the repo.
- `.way/elements/<element_key>/architecture-current.md` does not exist.
- A redesign is anticipated and the team wants the current state captured
  before changing it.

If there is no existing code, do not run this skill. Use `way-arch-design`
with `proposal_mode: full` instead.

## Inputs

- `element_key`
- `scope_paths` (the directories / files that constitute the element in
  the repo)

If `scope_paths` is unclear, ask before proceeding rather than guessing
boundaries.

## Procedure

### Step 1 — Survey

Read the code in `scope_paths`:

- Identify components / modules / subsystems and what each is responsible
  for.
- Trace dataflow between them.
- Identify external interfaces (what the element exposes; what it depends
  on).
- Identify state — where it lives, who owns it.
- Identify concurrency / execution model if relevant.
- Note risks, sharp edges, and undocumented assumptions encountered while
  reading.

Do not start writing prose during this step.

### Step 2 — Draft

Use `references/templates/architecture-full.md` as the section skeleton.
Fill in the core sections:

1. Executive Summary
2. Goals (best-effort reverse engineering — what does this element appear
   to be designed to do?)
3. Non-Goals (what is conspicuously not covered)
4. Constraints and Assumptions
5. System Elements and Responsibilities
6. Dataflow and Interactions
7. Interfaces and Contracts
8. Risks and Open Questions
9. Planner Constraints (rules that the existing implementation appears
   to be holding the future planner to)
10. Deferred Detailed Design

Conditional sections (State and Ownership, Concurrency and Execution
Model, Deployment and Runtime Context, Deep Dive Reference) are included
only if they are materially relevant. Use the Applicability Notes block
to record omissions.

If the implementation embodies decisions that belong in
`detailed-design-current.md` rather than architecture, note them but do
not include them here. Architecture is one level above detailed design.

### Step 3 — Required self-check pass

After drafting, **re-read every sentence** and apply this filter:

A sentence is too low-level for architecture if it names:

- a specific function or method
- a specific algorithm or data structure choice
- a specific error type or exception class
- a defensive check, a null guard, a retry count
- a specific library API

Action for each flagged sentence:

- If the sentence is genuinely architecture (e.g. "the queue is bounded
  to bound memory"), keep it but rewrite without the code-level token.
- If the sentence is borderline detail, relocate it to **Deferred Detailed
  Design**.
- If the sentence is pure code summary, delete it.

This step is **mandatory**. Skipping it is a failure mode the family was
explicitly built to prevent. Do not output the document until this pass
is complete.

### Step 4 — Frontmatter and write

Write the file to `.way/elements/<element_key>/architecture-current.md`
with the shared frontmatter:

```yaml
---
artifact: architecture-current
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from: []
last_updated: <YYYY-MM-DD>
---
```

`derived_from` is empty — this is a first capture, not a transformation
of another artifact.

## Output

The single file `architecture-current.md`. Report:

- Path written.
- Sections included.
- Conditional sections omitted, with reasons (Applicability Notes).
- Number of sentences relocated or deleted by the self-check pass.

## Non-Behaviours

- Do **not** propose redesigns. If a fix is obvious, mention it once in
  Risks and Open Questions and stop.
- Do **not** write `architecture-proposed.md`. That is `way-arch-design`'s
  job.
- Do **not** edit code.
