---
artifact: detailed-design-current
element_key: root
element_name: way Repository
architecture_scope: repo
scope_paths:
  - .
derived_from: []
last_updated: 2026-04-26
---

# `way` — Detailed Design

## Purpose and Scope

This document captures one level of detail below
`architecture-current.md`: the artifact contract, frontmatter shape,
section catalogs, archive policy, and finalize reconciliation rules.
It is design-oriented — every claim here must be verifiable by reading
`shared/family-contract.md` and the contents of `skills/` and
`shared/templates/`.

This document is hand-authored for the initial commit. Subsequent
revisions are produced by running the `way-*` family on itself —
specifically by running `way-finalize` against the `root` element after
an approved cycle.

## Key Source Areas

- `shared/family-contract.md` — the canonical contract every `way-*`
  skill reads first. Defines artifact layout, shared frontmatter,
  archive policy, the architecture-vs-code rule, the full-vs-delta
  rule, the reviewer-independence pattern, document section catalogs,
  and finalize reconciliation rules.
- `shared/templates/*.md` — eight per-artifact templates (architecture
  full, architecture delta, architecture review, plan, plan review,
  detailed design, implementation manifest, implementation review).
- `skills/way-*/SKILL.md` — nine skill entrypoints. Each consults the
  family contract via the symlinked
  `references/family-contract.md` and the relevant template via the
  symlinked `references/templates/`.
- `setup.sh` — multi-platform installer that symlinks each
  `skills/way-*/` directory into Claude Code, Codex CLI, Gemini CLI,
  Cursor, and VS Code / Copilot discovery paths. Skips any directory
  under `skills/` that lacks a `SKILL.md`, so `shared/` is not
  surfaced as a skill (and `shared/` lives outside `skills/`
  regardless).

## Runtime Flow

A `way-*` cycle for one element:

1. **Entry.** User invokes `way-advisor` (or already knows the next
   skill). `way-advisor` reads `.way/elements/<element_key>/` and any
   relevant `scope_paths` and recommends the next skill — or
   recommends skipping the framework.
2. **Architecture stage.** Either `way-arch-doc` (capture current) or
   `way-arch-design` (propose change). Output:
   `architecture-current.md` and/or `architecture-proposed.md`.
3. **Architecture review.** `way-arch-review` reads the proposal and
   the reference (current, if present) and writes
   `architecture-review.md`. On approval it normalises into a full
   `architecture-approved.md` — for delta proposals this is a
   mechanical merge with `architecture-current.md`.
4. **Plan stage.** `way-plan` reads `architecture-approved.md` and
   writes `plan-proposed.md`, scoped only to the change relative to
   `architecture-current.md`.
5. **Plan review.** `way-plan-review` reads the plan and the approved
   architecture, writes `plan-review.md`, and on approval normalises
   into `plan-approved.md`.
6. **Implementation.** `way-impl` reads `plan-approved.md` and
   `architecture-approved.md`, edits code, runs validation gates,
   and writes `implementation-manifest.md`.
7. **Implementation review.** `way-impl-review` reads the manifest,
   plan, and architecture, verifies repo state, and writes
   `implementation-review.md`. Architecture-violating drift is the
   most important class of finding.
8. **Finalize.** `way-finalize` refreshes `architecture-current.md`
   (mechanical copy from approved) and `detailed-design-current.md`
   (rewritten from repo state, reconciled against the plan's Detailed
   Design Summary). Archives transients to
   `archive/<artifact>.<YYYY-MM-DD>.rN.md`. Idempotent.

A skill never produces an artifact for a later phase. A skill never
modifies an artifact owned by a different phase. A skill never edits
`*-current.md` outside of `way-arch-doc` (initial creation) and
`way-finalize` (refresh).

## Important Internal Interfaces and Types

### Element directory

```
.way/elements/<element_key>/
├── architecture-current.md          (steady-state, refreshed at finalize)
├── detailed-design-current.md       (steady-state, refreshed at finalize)
├── architecture-proposed.md         (transient, archived at finalize)
├── architecture-review.md           (transient)
├── architecture-approved.md         (transient)
├── plan-proposed.md                 (transient)
├── plan-review.md                   (transient)
├── plan-approved.md                 (transient)
├── implementation-manifest.md       (transient)
├── implementation-review.md         (transient)
└── archive/
    └── <artifact>.<YYYY-MM-DD>.rN.md
```

### Shared frontmatter

```yaml
artifact: <artifact-name>
element_key: <element-key>
element_name: <Human Readable Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - <path>
derived_from: []
last_updated: YYYY-MM-DD
```

Per-artifact additions:

- `architecture-proposed.md` adds `proposal_mode: full|delta`.
- `implementation-manifest.md` adds `current_phase: <name|"all">`
  (`"all"` in v1).
- `implementation-review.md` adds `phase: <name|"all">` (`"all"` in
  v1).

`status` is **not** a field. State is derived from which files exist.

### `derived_from` table

| Artifact | `derived_from` |
|---|---|
| `architecture-current.md` (initial via `way-arch-doc`) | `[]` |
| `architecture-current.md` (refresh at finalize) | `[architecture-approved.md]` |
| `architecture-proposed.md` (full) | `[]` |
| `architecture-proposed.md` (delta) | `[architecture-current.md]` |
| `architecture-review.md` | `[architecture-proposed.md, architecture-current.md?]` |
| `architecture-approved.md` (full) | `[architecture-proposed.md]` |
| `architecture-approved.md` (delta merge) | `[architecture-proposed.md, architecture-current.md]` |
| `plan-proposed.md` | `[architecture-approved.md]` |
| `plan-review.md` | `[plan-proposed.md, architecture-approved.md]` |
| `plan-approved.md` | `[plan-proposed.md, architecture-approved.md]` |
| `implementation-manifest.md` | `[plan-approved.md]` |
| `implementation-review.md` | `[implementation-manifest.md, plan-approved.md, architecture-approved.md]` |
| `detailed-design-current.md` (refresh at finalize) | `[plan-approved.md, architecture-approved.md]` |

### Document section contracts

Architecture full and `architecture-current.md` / `architecture-approved.md`:

- **Core (always present):** Executive Summary, Goals, Non-Goals,
  Constraints and Assumptions, System Elements and Responsibilities,
  Dataflow and Interactions, Interfaces and Contracts, Risks and
  Open Questions, Planner Constraints, Deferred Detailed Design.
- **Conditional:** State and Ownership, Concurrency and Execution
  Model, Deployment and Runtime Context, Deep Dive Reference.

Architecture delta:

- Executive Summary, Affected Elements, Changed Responsibilities,
  Changed Interfaces and Contracts, Changed Dataflow and
  Interactions, Changed State or Concurrency, Risks and Open
  Questions, Deferred Detailed Design, Planner Constraints, Sections
  Carried Forward, Applicability Notes.

Architecture review:

- Review Summary, Compared Artifacts, Architectural Strengths,
  Issues Requiring Revision, Regressions or Mismatches, Approval
  Conditions, Decision.

Plan:

- Plan Summary, Preconditions and Assumptions, Phase or Slice
  Breakdown, Ordered Work Items, Detailed Design Summary,
  Validation and Review Gates, Risks and Escalation Triggers,
  Completion Criteria.

Plan review:

- Review Summary, Architecture Alignment, Sequencing and Dependency
  Issues, Missing Validation or Review Gates, Approval Conditions,
  Decision.

Detailed design current:

- **Core:** Purpose and Scope, Key Source Areas, Runtime Flow,
  Important Internal Interfaces and Types, Invariants and Failure
  Boundaries, Extension Points and Constraints.
- **Conditional:** State, Ownership, and Lifecycles; Concurrency and
  Synchronization; Critical Data Structures and Algorithms.

Implementation manifest:

- Manifest Summary, Phases (one entry per phase — single entry in
  v1: Touched Files, Summary of Changes, Validation Gate Results),
  Cross-Phase Notes.

Implementation review:

- Review Summary, Reviewed Phase, Reviewed Scope, Conformance to
  Approved Plan, Deviations and Their Impact, Verification Gaps,
  Decision.

Each conditional section omitted is recorded in a single compact
**Applicability Notes** block as `<Section> — N/A — <reason>`. Empty
sections are not padded into the document.

## Invariants and Failure Boundaries

- **Architecture stays at architecture depth.** Code-level leakage is
  flagged by the self-check pass in `way-arch-doc` and `way-arch-design`
  and treated as a revision request by `way-arch-review`. The sentence-
  level filter looks for: function or method names, specific
  algorithms or data structures, error types, defensive checks, retry
  counts, library APIs.
- **Plans don't redesign architecture.** Planners that need to escalate
  back to `way-arch-design` rather than silently rewriting an approved
  decision. Plan reviewers reject hidden redesigns; they do not revise
  them.
- **Implementation doesn't redesign architecture.** `way-impl` escalates
  rather than violating `architecture-approved.md`. Architecture-
  violating findings in `implementation-review.md` block `way-finalize`.
- **`*-approved.md` is always full.** Delta approval merges into the
  current doc to produce a full approved doc — mechanical, not
  creative.
- **State is on-disk.** No frontmatter `status` field; the set of files
  in `.way/elements/<element_key>/` is the workflow state.
- **Reviewer independence is honour-based.** Each review skill states
  the preference for a fresh conversation and the discipline guard for
  same-session use. Tools that support subagents may launch them; tools
  that do not still get the same fidelity contract by following the
  guard.

Failure boundaries:

- A skill never silently corrects another skill's artifact. Reviews
  flag; finalize reconciles non-architectural drift; everything else
  escalates.
- `way-finalize` refuses to run with unresolved architecture-violating
  findings. The block is explicit, not silent.
- `way-finalize` never archives `*-current.md`. If those need to change,
  they are refreshed in place; history is in `git log`.

## Extension Points and Constraints

Adding a new `way-*` skill:

1. Create `skills/<name>/SKILL.md` with the standard frontmatter
   (`name`, `description`, `license`, `metadata.author`,
   `metadata.version`).
2. Add `references/family-contract.md` and `references/templates`
   symlinks pointing to `../../../shared/...`.
3. State which artifacts the skill reads and which it writes — keep
   per-phase ownership clean.
4. Re-run `setup.sh` to register with all platforms.

Adding a new artifact type:

1. Add a section to `shared/family-contract.md` covering shared
   frontmatter additions, document sections, and archive treatment.
2. Add a template under `shared/templates/`.
3. Update the `derived_from` table.
4. Update the skill that produces it; update any review or finalize
   step that consumes it.

Constraints on extensions:

- Plain Markdown only.
- No platform-specific tool dependencies in any skill body.
- No frontmatter `status` field.
- Approved artifacts remain full documents.
- Reviewer-independence pattern stays the same shape across all
  review skills.

## State, Ownership, and Lifecycles

The only mutable state the framework cares about is the set of files
under `.way/elements/<element_key>/`. Ownership of each artifact is
fixed by phase:

| Artifact | Owned by | Created at | Refreshed at | Archived at |
|---|---|---|---|---|
| `architecture-current.md` | `way-arch-doc` (initial) / `way-finalize` (refresh) | First doc pass | Each finalize | Never |
| `architecture-proposed.md` | `way-arch-design` | Each design pass | Same skill on revise | Each finalize |
| `architecture-review.md` | `way-arch-review` | Each review pass | Same skill on re-review | Each finalize |
| `architecture-approved.md` | `way-arch-review` | On approval | n/a | Each finalize |
| `plan-proposed.md` | `way-plan` | Each plan pass | Same skill on revise | Each finalize |
| `plan-review.md` | `way-plan-review` | Each review pass | Same skill on re-review | Each finalize |
| `plan-approved.md` | `way-plan-review` | On approval | n/a | Each finalize |
| `implementation-manifest.md` | `way-impl` | Each impl pass | Same skill on revise | Each finalize |
| `implementation-review.md` | `way-impl-review` | Each review pass | Same skill on re-review | Each finalize |
| `detailed-design-current.md` | `way-finalize` | First finalize | Each finalize | Never |

Within a cycle, "refresh" means **supersede in place**: the next
revision overwrites the file. Inter-revision history is in `git log`.
Archiving happens **only at `way-finalize`**.

Archive path:

```
.way/elements/<element_key>/archive/<artifact>.<YYYY-MM-DD>.rN.md
```

`rN` is monotonic-per-day starting at `r1`. Two finalize runs on the
same date produce `r1` and `r2`.

## Concurrency and Synchronization

Not applicable at the framework level — a single element's lifecycle is
a sequential pipeline driven by the user. Distinct elements may be in
different phases concurrently but share no state.

## Critical Data Structures and Algorithms

The "delta merge" performed by `way-arch-review` on approval is the only
non-trivial transformation in the family:

- Read `architecture-current.md`.
- Read `architecture-proposed.md` (delta mode).
- For each section enumerated in the proposal's **Sections Carried
  Forward**, copy verbatim from current.
- For each section described as changed in the proposal, replace the
  corresponding section in current.
- Compose **Planner Constraints** as the union of carried-forward
  constraints and any new or revised constraints in the proposal.
- Write the result as a full `architecture-approved.md`.

The merge is mechanical. If the reviewer finds themselves rewording
carried-forward sections, the proposal should have been full instead
of delta — and the correct response is `revise` with that observation,
not a creative rewrite during normalisation.

## Applicability Notes

- All conditional sections of this document are present because the
  `root` element has meaningful state, ownership, and a non-trivial
  algorithm.
