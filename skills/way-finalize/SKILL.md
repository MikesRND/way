---
name: way-finalize
description: >
  Refresh architecture-current.md and detailed-design-current.md from the
  approved cycle, then archive all transient artifacts. Idempotent.
  Reconciles non-architectural plan/repo drift in favour of the repo;
  refuses to finalize if it detects architecture-violating drift. Run only
  after way-impl-review approval.
license: MIT
metadata:
  author: mikesrnd
  version: "1.0"
---

# way-finalize

## Prerequisites

Read `references/family-contract.md` first. §6 (archive policy) and
§13 (finalize reconciliation rules) are the binding rules for this skill.

## Purpose

Close out an approved cycle:

1. Refresh `architecture-current.md` from `architecture-approved.md`.
2. Refresh `detailed-design-current.md` from actual repo state, using
   the approved plan's Detailed Design Summary as outline and
   reconciliation checklist.
3. Archive all transient artifacts from the cycle.

`way-finalize` is idempotent. Re-running it with no changes is a no-op.

## Preconditions

- `implementation-review.md` exists with decision `approve`.
- No architecture-violating findings remain unresolved.

If either precondition fails, refuse to run and explain why.

## Inputs

- `architecture-approved.md`
- `plan-approved.md`
- `implementation-manifest.md`
- `implementation-review.md`
- `architecture-current.md` (if it exists)
- `detailed-design-current.md` (if it exists)
- The repo state at `scope_paths`

## Procedure

### Step 1 — Reconciliation check

Read `implementation-review.md`. If any finding is classified
**architecture-violating** and not marked resolved, refuse to finalize.
Output: which finding blocks finalize, and recommend the user escalate
to `way-arch-design`.

### Step 2 — Refresh `architecture-current.md`

Replace (or create) `architecture-current.md` with the contents of
`architecture-approved.md`, with frontmatter rewritten:

```yaml
---
artifact: architecture-current
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from:
  - architecture-approved.md
last_updated: <YYYY-MM-DD>
---
```

This is mechanical — the approved doc is already full and review-blessed.

### Step 3 — Refresh `detailed-design-current.md`

Read the current repo state at `scope_paths`. Use the approved plan's
**Detailed Design Summary** as outline and reconciliation checklist —
not as source of truth. For each section in the template
(`references/templates/detailed-design.md`):

- Re-derive the section from the repo as it stands now.
- Cross-reference against the plan's Detailed Design Summary; reconcile
  per the rules below.

**Reconciliation rules:**

- If repo and plan **agree**, document the agreed design.
- If repo and plan differ in **non-architectural** detail (the
  implementer made a reasonable local choice that does not violate
  `architecture-approved.md`), reconcile in favour of the repo and
  document what is actually there.
- If repo and plan differ in a way that **violates
  `architecture-approved.md`**, refuse to finalize and escalate. (The
  prior step should have caught this; this is the second-line check.)

For incremental work, update only the affected portions of
`detailed-design-current.md` and carry forward unchanged sections.

Frontmatter:

```yaml
---
artifact: detailed-design-current
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from:
  - plan-approved.md
  - architecture-approved.md
last_updated: <YYYY-MM-DD>
---
```

Every substantive claim in `detailed-design-current.md` must be
verifiable against the repo as it exists at finalize time. If you cannot
verify a claim, drop it.

### Step 4 — Archive

Move each of the following from `.way/elements/<element_key>/` to
`.way/elements/<element_key>/archive/<artifact>.<YYYY-MM-DD>.rN.md`:

- `architecture-proposed.md`
- `architecture-review.md`
- `architecture-approved.md`
- `plan-proposed.md`
- `plan-review.md`
- `plan-approved.md`
- `implementation-manifest.md`
- `implementation-review.md`

`rN` is monotonic-per-day starting at `r1`. If an archive file with the
same date and `rN` already exists, increment `N`.

The two `*-current.md` docs are **refreshed in place**, never archived.

### Step 5 — Idempotency

If steps 2 and 3 produced no changes (the current docs are already
identical to what would be written) and step 4 finds no transient
artifacts to archive, declare the cycle finalized and exit. Re-running
in this state must be a no-op.

## Output

Report:

- Whether the cycle was finalized or refused.
- For finalize: which sections of `detailed-design-current.md` were
  rewritten vs. carried forward; reconciled deviations recorded.
- For refusal: which finding blocks finalize and the recommended
  escalation path.
- Files archived (path → archive path).

## Non-Behaviours

- Do **not** finalize with unresolved architecture-violating findings.
- Do **not** invent design claims that cannot be verified against repo.
- Do **not** refresh `detailed-design-current.md` from the plan when it
  contradicts the repo.
- Do **not** archive `*-current.md` docs.
- Do **not** delete the `archive/` directory or any prior archives.
