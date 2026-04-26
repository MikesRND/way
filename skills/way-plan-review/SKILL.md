---
name: way-plan-review
description: >
  Review plan-proposed.md against architecture-approved.md and write
  plan-review.md. On approval, normalize the accepted result into
  plan-approved.md. Reviewer-independent; prefer running in a fresh
  conversation.
license: MIT
metadata:
  author: mikesrnd
  version: "1.0"
---

# way-plan-review

## Prerequisites

Read `references/family-contract.md` first. §9 (reviewer independence)
and §10 (scope discipline) are the binding rules for this skill.

## Reviewer Independence (read first)

> **Prefer running this review in a fresh conversation or session.** A
> reviewer that has not seen the design conversation is genuinely
> independent. Highest-fidelity mode; platform-neutral.
>
> **If running in the same session as `way-plan`**, apply in-context
> discipline:
>
> - Do not reference your own prior reasoning; treat the plan as if
>   written by someone else.
> - Read only the artifacts named on disk.
> - Produce the review as if encountering the plan cold.

## Purpose

1. Produce `plan-review.md` — structured review of `plan-proposed.md`
   against `architecture-approved.md`.
2. On approval, produce `plan-approved.md`.

## Inputs

- `plan-proposed.md` (required)
- `architecture-approved.md` (required)
- Prior `plan-review.md` if this is a re-review

## Procedure

### Step 1 — Read

Read both inputs. No conversation history.

### Step 2 — Draft the review

Use `references/templates/plan-review.md`. Fill in:

1. **Review Summary**.
2. **Architecture Alignment** — for each plan section that should derive
   from `architecture-approved.md`, does it derive cleanly?
   - Out-of-scope items (plan addressing things outside the approved
     change).
   - Missing items (approved-architecture changes the plan failed to
     address).
   - Hidden redesigns (plan implicitly rewriting an approved decision —
     this is grounds to escalate, not to revise).
3. **Sequencing and Dependency Issues** — phases / work items in the
   wrong order, missing prerequisites, hidden cross-dependencies.
4. **Missing Validation or Review Gates** — gaps in declared gates,
   especially around risk areas the architecture flagged.
5. **Approval Conditions** — concrete, testable.
6. **Decision** — `approve`, `revise`, or `reject`.

If you detect a hidden redesign (plan rewriting an approved decision),
the correct response is to **reject** and recommend `way-arch-design`,
not to revise the plan to match.

### Step 3 — Write the review

```yaml
---
artifact: plan-review
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from:
  - plan-proposed.md
  - architecture-approved.md
last_updated: <YYYY-MM-DD>
---
```

If decision is `revise` or `reject`, stop here.

### Step 4 — Normalize on approval

If decision is `approve`, produce `plan-approved.md` by applying
review-mandated revisions and Approval Conditions to `plan-proposed.md`.
Mechanical application, not creative rewriting.

```yaml
---
artifact: plan-approved
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from:
  - plan-proposed.md
  - architecture-approved.md
last_updated: <YYYY-MM-DD>
---
```

## Output

- Always: `plan-review.md`.
- On `approve`: `plan-approved.md`.

## Non-Behaviours

- Do **not** rewrite the plan beyond what the review explicitly requires.
- Do **not** approve a plan that hides an architecture redesign.
- Do **not** consult conversation history.
- Do **not** implement code.
