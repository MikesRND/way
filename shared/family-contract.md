# `way-*` Family Contract

This document is the shared contract every `way-*` skill operates under. Each
skill has its own `SKILL.md` describing its specific behaviour; this file
covers the cross-cutting rules: where artifacts live, what frontmatter they
carry, what sections they contain, when they are archived, and what
"architecture vs. code" means in this family.

**Read this before doing anything in any `way-*` skill.**

## 1. Premise

Planner agents routinely dive into code-level detail (specific algorithms,
error types, defensive checks) before architecture has stabilised, drowning
out higher-level concerns: dataflow, component boundaries, parallelism,
interfaces, responsibilities. The result is iterating on details against
the wrong foundation.

The `way-*` family separates architecture from planning from implementation,
with explicit review gates between each stage and two long-lived design
artifacts that survive every cycle. Architecture stays at architecture depth.
Planning stays bounded by the approved architecture. Implementation is bound
by the approved plan. A single finalize step refreshes the maintained docs
and archives the rest.

The framework is **opt-in per element**: trivial work bypasses it; substantive
design changes flow through it.

## 2. Cross-Tool Portability

Every artifact this family produces is plain Markdown with YAML frontmatter,
and every skill's instructions are platform-neutral. The user must be able to
run any phase in Claude Code, switch to Codex for the next phase, then to
Cursor or Gemini for a third — without losing fidelity. Skills do not depend
on Claude-specific subagent invocation; reviewer independence is achieved by
asking the user to run review skills in a fresh conversation, with in-context
discipline guards as fallback.

## 3. Element Layout

Artifacts live under:

```
.way/elements/<element_key>/
```

`element_key` is the workflow join key — repo-unique lowercase kebab-case
(e.g. `auth-service`, `way-arch-doc`, `data-ingest`). It may align with a
path or filename but does not need to. The key `root` is reserved for
whole-repo architecture (delta mode is supported on `root`).

Actual repo locations are recorded separately via the `scope_paths` frontmatter
field, so the workflow fits existing repos without imposing structure.

## 4. Shared Frontmatter

All `way-*` artifacts share this frontmatter shape:

```yaml
---
artifact: <artifact-name>
element_key: <element-key>
element_name: <Human Readable Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - path/relative/to/repo/
derived_from: []
last_updated: YYYY-MM-DD
---
```

`derived_from` lists the artifact filenames this one was produced from:

| Artifact | `derived_from` |
|---|---|
| `architecture-current.md` (initial) | `[]` |
| `architecture-current.md` (refreshed at finalize) | `[architecture-approved.md]` |
| `architecture-proposed.md` | `[]` (full) or `[architecture-current.md]` (delta) |
| `architecture-review.md` | `[architecture-proposed.md, architecture-current.md?]` |
| `architecture-approved.md` (full) | `[architecture-proposed.md]` |
| `architecture-approved.md` (delta merge) | `[architecture-proposed.md, architecture-current.md]` |
| `plan-proposed.md` | `[architecture-approved.md]` |
| `plan-review.md` | `[plan-proposed.md, architecture-approved.md]` |
| `plan-approved.md` | `[plan-proposed.md, architecture-approved.md]` |
| `implementation-manifest.md` | `[plan-approved.md]` |
| `implementation-review.md` | `[implementation-manifest.md, plan-approved.md, architecture-approved.md]` |
| `detailed-design-current.md` (refreshed at finalize) | `[plan-approved.md, architecture-approved.md]` |

`status` is **not** a frontmatter field. Workflow state is derived from which
files exist under `.way/elements/<element_key>/`.

`architecture-proposed.md` adds:

```yaml
proposal_mode: full|delta
```

`implementation-manifest.md` adds:

```yaml
current_phase: <phase-name-or-"all">
```

`implementation-review.md` adds:

```yaml
phase: <phase-name-or-"all">
```

In v1, both `current_phase` and `phase` are `all` (or omitted) — the format
is intentionally phase-aware so a future per-phase invocation pattern can be
added without changing the artifact format.

## 5. Active vs. Steady-State Artifacts

**Active workflow** (during an in-flight change):

- `architecture-current.md` (if a prior iteration produced it)
- `architecture-proposed.md`
- `architecture-review.md`
- `architecture-approved.md`
- `plan-proposed.md`
- `plan-review.md`
- `plan-approved.md`
- `implementation-manifest.md`
- `implementation-review.md`
- `detailed-design-current.md` (if a prior iteration produced it)

**Steady state** (after `way-finalize`):

- `architecture-current.md`
- `detailed-design-current.md`

Only the two current docs survive each cycle.

## 6. Archive Policy

Archiving happens **only at `way-finalize`**, not per revision. Within an
active workflow, supersede artifacts in place; rely on `git log` for
inter-revision history.

Archive path:

```
.way/elements/<element_key>/archive/<artifact>.<YYYY-MM-DD>.rN.md
```

`rN` is monotonic-per-day starting at `r1`. If finalize runs twice on the
same calendar date for the same element, the second run uses `r2`, etc.

Files archived on each finalize run:

- `architecture-proposed.md`
- `architecture-review.md`
- `architecture-approved.md`
- `plan-proposed.md`
- `plan-review.md`
- `plan-approved.md`
- `implementation-manifest.md`
- `implementation-review.md`

The two `*-current.md` docs are **refreshed in place**, never archived.

## 7. Architecture vs. Code: The Discipline Rule

Architecture documents and the architecture portion of design discussions
must stay at architecture depth. The smell test:

A sentence is **too low-level for architecture** if it names:

- a specific function or method
- a specific algorithm or data structure choice
- a specific error type or exception class
- a defensive check, a null guard, a retry count
- a specific library API

A sentence is **architecture-level** if it concerns:

- responsibilities of components
- boundaries between components
- direction and shape of dataflow
- interface contracts (inputs, outputs, invariants — not signatures)
- ownership of state
- concurrency / execution model
- failure boundaries (where errors are handled, not how)

If a detail is real but not architecture, it belongs in the **Deferred
Detailed Design** section — the safety valve that keeps architecture clean
without losing the insight.

`way-arch-doc` and `way-arch-design` both run a self-check pass that flags
and relocates code-level leakage. The reviewer (`way-arch-review`) treats
remaining leakage as a revision request.

## 8. Full vs. Delta Proposals

This rule applies **only to `architecture-proposed.md`**. Plans are always
full documents.

- `proposal_mode: full` — greenfield work (no existing code) **or** wholesale
  rearchitecture of a documented element. Produces a complete
  `architecture-proposed.md` with all required sections.
- `proposal_mode: delta` — incremental modification of an existing documented
  element. Describes only the scoped change. Explicitly lists carried-forward
  sections rather than restating them.

`way-arch-review` always normalises into a **full** `architecture-approved.md`.
For deltas, it deterministically merges the accepted change into
`architecture-current.md`; this is mechanical application, not creative
rewriting. If unchanged sections need broad rewording, that is a smell that
the proposal should have been full instead of delta — flag and revise.

## 9. Reviewer Independence Pattern

Applies to `way-arch-review`, `way-plan-review`, and `way-impl-review`.

Every review skill begins with this guard:

> **Prefer running this review in a fresh conversation or session.**
> A reviewer that has not seen the design conversation is genuinely
> independent. This is the highest-fidelity mode and is platform-neutral
> (works in any tool the user prefers).
>
> **If running in the same session as the prior phase**, apply in-context
> discipline:
> - Do not reference your own prior reasoning or drafts; treat them as if
>   written by someone else.
> - Read only the artifacts named on disk; do not consult the conversation
>   history.
> - Produce the review as if encountering the artifacts cold — surface
>   issues a fresh reader would surface.

The skill does not depend on platform-specific subagent invocation. Users who
want stronger isolation in Claude Code can launch a subagent themselves, but
the skill is written to work the same way in Codex, Cursor, Gemini, or any
other tool.

## 10. Scope Discipline

- **Architecture** stays at architecture depth (rule §7).
- **Plans** address only what `architecture-approved.md` introduces or
  changes relative to `architecture-current.md` — not the entire approved
  architecture. They must not redesign the approved architecture; if they
  need to, escalate back to architecture.
- **Implementation** is bound by `plan-approved.md` and
  `architecture-approved.md`. If implementation requires an architecture
  change, **stop and escalate back to architecture rather than silently
  redesigning**.

## 11. Document Section Catalog

If a conditional section is omitted, record it in a single compact
**Applicability Notes** block with `<Section> — N/A — reason`. Do not pad
docs with empty sections.

### `architecture-current.md`, `architecture-proposed.md` (full), `architecture-approved.md`

**Core (always present):**

1. Executive Summary
2. Goals
3. Non-Goals
4. Constraints and Assumptions
5. System Elements and Responsibilities
6. Dataflow and Interactions
7. Interfaces and Contracts
8. Risks and Open Questions
9. Planner Constraints
10. Deferred Detailed Design

**Conditional:**

- State and Ownership
- Concurrency and Execution Model
- Deployment and Runtime Context
- Deep Dive Reference

**Section meanings:**

- **Planner Constraints** — invariants the planner is forbidden from relaxing
  while elaborating (e.g. "all writes go through the queue," "interface X is
  stable across this change"). Architectural rules expressed as binding
  constraints on the planner.
- **Deferred Detailed Design** — details the architect noticed but is
  deliberately leaving for the planner. The safety valve that prevents
  detail leakage into the architecture. Required even when empty (declare
  "no deferred details for this iteration").
- **Deep Dive Reference** — pointers from the architecture into deeper
  material: `detailed-design-current.md` sections, external docs, prior
  decision records.

### `architecture-proposed.md` (delta)

1. Executive Summary
2. Affected Elements
3. Changed Responsibilities
4. Changed Interfaces and Contracts
5. Changed Dataflow and Interactions
6. Changed State or Concurrency
7. Risks and Open Questions
8. Deferred Detailed Design
9. Planner Constraints
10. Sections Carried Forward
11. Applicability Notes

### `architecture-review.md`

1. Review Summary
2. Compared Artifacts
3. Architectural Strengths
4. Issues Requiring Revision
5. Regressions or Mismatches
6. Approval Conditions
7. Decision (`approve` | `revise` | `reject`)

### `plan-proposed.md`, `plan-approved.md`

1. Plan Summary
2. Preconditions and Assumptions
3. Phase or Slice Breakdown
4. Ordered Work Items
5. Detailed Design Summary
6. Validation and Review Gates
7. Risks and Escalation Triggers
8. Completion Criteria

The **Detailed Design Summary** captures implementation-relevant design
without task-management noise. It is the seed material for refreshing
`detailed-design-current.md` at finalize.

### `plan-review.md`

1. Review Summary
2. Architecture Alignment
3. Sequencing and Dependency Issues
4. Missing Validation or Review Gates
5. Approval Conditions
6. Decision (`approve` | `revise` | `reject`)

### `detailed-design-current.md`

**Core:**

1. Purpose and Scope
2. Key Source Areas
3. Runtime Flow
4. Important Internal Interfaces and Types
5. Invariants and Failure Boundaries
6. Extension Points and Constraints

**Conditional:**

- State, Ownership, and Lifecycles
- Concurrency and Synchronization
- Critical Data Structures and Algorithms

### `implementation-manifest.md`

1. Manifest Summary
2. Phases (one entry per phase — single entry in v1)
   - Phase Name
   - Touched Files
   - Summary of Changes
   - Validation Gate Results (gate command, exit status, notable output)
3. Cross-Phase Notes

### `implementation-review.md`

1. Review Summary
2. Reviewed Phase (`all` in v1)
3. Reviewed Scope
4. Conformance to Approved Plan
5. Deviations and Their Impact
6. Verification Gaps
7. Decision (`approve` | `revise` | `reject`)

## 12. Validation Gate Execution

Validation gates are platform-neutral shell commands declared inside
`plan-approved.md` (e.g. `npm test`, `pytest -q`, `cargo check`). `way-impl`
runs each gate via shell and records the result in
`implementation-manifest.md`. Any tool that can execute shell commands can
run this skill.

## 13. Finalize Reconciliation Rules

`way-finalize` is idempotent — re-running with no changes is a no-op.

- Refresh `architecture-current.md` so it always reflects the implemented
  system. For full proposals this is largely a copy of
  `architecture-approved.md`; for deltas it is the merged result.
- Refresh `detailed-design-current.md` from **actual repo state**, not from
  the plan. The approved plan's Detailed Design Summary is used only as
  outline and reconciliation checklist.
- Every substantive claim in `detailed-design-current.md` must be verifiable
  against the repo at finalize time.
- If repo and plan differ in **non-architectural** detail, reconcile in
  favour of the repo.
- If repo and plan differ in a way that **violates `architecture-approved.md`**,
  refuse to finalize and escalate.
- For incremental work, update only the affected portions of
  `detailed-design-current.md` and carry forward unchanged sections.
- After updating the two current docs, archive all transient artifacts per §6.

## 14. Off-Ramp

The framework is not the only way to modify code; it is the way for changes
that warrant architectural review. `way-advisor` is permitted (and expected)
to recommend "this change does not need `way-*`" as a valid output.

Suggested thresholds:

- **Skip the framework entirely** for single-file fixes, dependency bumps,
  doc-only edits, and any change that does not touch component boundaries,
  responsibilities, or interfaces.
- **Use the framework** for new elements, cross-component changes, or any
  change that alters interfaces, dataflow, or responsibilities.

A defined partial-pipeline path (skipping certain reviews for medium-sized
changes) is intentionally out of scope for v1 — once the full pipeline is
in use, threshold tuning can be done with real evidence rather than
guesswork.

## 15. Glossary

- **Element** — a unit the framework reasons about: a service, module,
  subsystem, or the whole repo (`root`). Identified by `element_key`.
- **`*-current.md`** — long-lived doc that survives each cycle.
- **`*-proposed.md`** — draft for review.
- **`*-approved.md`** — review-blessed input to the next phase.
- **`*-review.md`** — output of a review skill.
- **Manifest** — `way-impl`'s record of what changed.
- **Phase** — a named slice of implementation. v1 runs all phases at once
  but the artifact format is phase-aware for v2.
- **Off-ramp** — `way-advisor`'s recommendation that a given change does
  not warrant the framework.
