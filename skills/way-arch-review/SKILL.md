---
name: way-arch-review
description: >
  Review architecture-proposed.md against architecture-current.md (or the
  prior proposal if current is absent), write architecture-review.md, and
  on approval normalize into a full architecture-approved.md. For delta
  proposals, deterministically merges the accepted change into current to
  produce a full approved doc. Reviewer-independent; prefer running in a
  fresh conversation.
license: MIT
metadata:
  author: mikesrnd
  version: "1.0"
---

# way-arch-review

## Prerequisites

Read `references/family-contract.md` first. §7 (architecture vs. code),
§8 (full vs. delta), and §9 (reviewer independence) are the binding
rules for this skill.

## Reviewer Independence (read first)

> **Prefer running this review in a fresh conversation or session.** A
> reviewer that has not seen the design conversation is genuinely
> independent. This is the highest-fidelity mode and is platform-neutral.
>
> **If running in the same session as `way-arch-design`**, apply
> in-context discipline:
>
> - Do not reference your own prior reasoning or drafts; treat them as
>   if written by someone else.
> - Read only the artifacts named on disk; do not consult the conversation
>   history.
> - Produce the review as if encountering the artifacts cold — surface
>   issues a fresh reader would surface.

The skill works in any tool that can read files and run shell commands.
No platform-specific subagent invocation is required.

## Purpose

Two responsibilities:

1. Produce `architecture-review.md` — a structured review of
   `architecture-proposed.md` against the appropriate reference.
2. On approval, produce a **full** `architecture-approved.md`. For delta
   proposals this means deterministically merging the accepted delta into
   `architecture-current.md`.

`architecture-approved.md` is **always full**, regardless of proposal mode.

## Inputs

- `architecture-proposed.md` (required)
- `architecture-current.md` (required for delta proposals; optional for
  full)
- Prior `architecture-review.md` if this is a re-review

## Procedure

### Step 1 — Read

Read `architecture-proposed.md` and the reference (`architecture-current.md`
if present, otherwise treat as first iteration). Read no conversation
history. Treat the proposal as if a stranger wrote it.

### Step 2 — Draft the review

Use `references/templates/architecture-review.md`. Fill in:

1. **Review Summary** — what was reviewed, against what, headline finding.
2. **Compared Artifacts** — explicitly name files and modes.
3. **Architectural Strengths** — what should not be lost during revision.
4. **Issues Requiring Revision** — at architecture depth only. Each issue
   gets a one-line statement, a "Why" at architecture depth, and an
   optional "Suggested direction" hint (not a redesign).
5. **Regressions or Mismatches** — proposal contradicting carried-forward
   constraints from `architecture-current.md`.
6. **Approval Conditions** — concrete, testable.
7. **Decision** — `approve`, `revise`, or `reject`.

**Code-level leakage in the proposal is itself an Issue Requiring
Revision.** Apply the §7 filter to every paragraph of
`architecture-proposed.md`; flag every sentence that names a function,
algorithm, error type, defensive check, or library API.

### Step 3 — Write the review

Write `architecture-review.md` with frontmatter:

```yaml
---
artifact: architecture-review
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from:
  - architecture-proposed.md
  # add architecture-current.md when comparing against it
last_updated: <YYYY-MM-DD>
---
```

If decision is `revise` or `reject`, **stop here** — do not produce
`architecture-approved.md`. Hand back to `way-arch-design`.

### Step 4 — Normalize on approval

If decision is `approve`, produce `architecture-approved.md` as a full doc:

- **Full proposal.** Apply review-mandated revisions to
  `architecture-proposed.md`. Not a creative rewrite — if unchanged
  sections need broad rewording, the proposal should have been a
  different proposal. Surface that as a revision request instead.
- **Delta proposal.** Deterministically merge the accepted delta into
  `architecture-current.md`:
  - Sections enumerated in **Sections Carried Forward** are copied
    verbatim from current.
  - Sections changed by the delta replace their counterparts in current.
  - Planner Constraints are the union of carried-forward constraints
    plus any new or revised constraints in the delta.
  - This is mechanical application, not creative rewriting. If you find
    yourself rewording carried-forward sections, that is a smell —
    flag it, decision should have been `revise`, and the proposal should
    have been `full` instead of `delta`.

Approved frontmatter:

```yaml
---
artifact: architecture-approved
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from:
  - architecture-proposed.md           # full
# or
derived_from:
  - architecture-proposed.md           # delta
  - architecture-current.md
last_updated: <YYYY-MM-DD>
---
```

The approved doc has no `proposal_mode` field — it is always full by
construction.

## Output

- Always: `architecture-review.md`.
- On `approve`: `architecture-approved.md`.

Report:

- Decision.
- For `approve`: which sections were merged from current vs. proposal
  (delta) or which sections were revised (full).
- Open Approval Conditions, if any.

## Non-Behaviours

- Do **not** rewrite the proposal during normalization beyond what the
  review's Issues and Approval Conditions explicitly require.
- Do **not** consult conversation history.
- Do **not** produce `architecture-approved.md` unless the decision is
  `approve`.
- Do **not** plan or implement.
