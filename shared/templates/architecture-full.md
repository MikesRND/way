---
artifact: architecture-proposed
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - path/relative/to/repo/
derived_from: []
last_updated: YYYY-MM-DD
proposal_mode: full
---

<!--
  Use this template for `architecture-proposed.md` (full mode) and as the
  shape for `architecture-current.md` and `architecture-approved.md`.
  Drop sections under "Conditional" if they do not apply, and record the
  omission in "Applicability Notes" at the bottom.

  Stay at architecture depth. No function names, no algorithms, no
  defensive checks. If a useful detail is real but not architecture, put
  it in "Deferred Detailed Design".
-->

# <Element Name> — Architecture

## Executive Summary

A few sentences a stakeholder can read and understand what this element
does, who it serves, and the shape of the design.

## Goals

- What this design must achieve.
- Phrased in user / system terms, not implementation terms.

## Non-Goals

- What this design explicitly does not address.
- Out-of-scope items that a reader might otherwise expect.

## Constraints and Assumptions

- External constraints (platforms, latencies, regulatory, deployment env).
- Assumptions whose violation would invalidate the design.

## System Elements and Responsibilities

Component-level breakdown. For each element: name, one-sentence purpose,
and the responsibilities it owns. Avoid implementation language.

## Dataflow and Interactions

How data and control flow between elements. Diagrams welcome (Mermaid is
portable). Describe direction, shape of data, and important timing.

## Interfaces and Contracts

The boundary contracts each element exposes — inputs, outputs, invariants,
error/failure semantics. Describe **what is true at the boundary**, not
the function signatures that satisfy it.

## Risks and Open Questions

Known risks to the design and questions that are unresolved at this
architectural pass.

## Planner Constraints

Invariants the planner is forbidden from relaxing while elaborating this
design. Phrase as binding rules:

- "All writes go through queue X before persistence."
- "Interface Y is stable across this change."

## Deferred Detailed Design

Details the architect noticed but is deliberately leaving for the planner
to resolve. Required even when empty — declare "no deferred details for
this iteration" rather than omitting the section.

## State and Ownership

<!-- Conditional. Drop if not relevant; note in Applicability Notes. -->

Where state lives, who owns it, lifetime semantics.

## Concurrency and Execution Model

<!-- Conditional. -->

Thread / process / async model. Synchronisation expectations.

## Deployment and Runtime Context

<!-- Conditional. -->

How this element is deployed, scaled, observed.

## Deep Dive Reference

<!-- Conditional. -->

Pointers into `detailed-design-current.md` sections, prior decision
records, or external docs.

## Applicability Notes

- State and Ownership — N/A — <reason>
- Concurrency and Execution Model — N/A — <reason>
- Deployment and Runtime Context — N/A — <reason>
- Deep Dive Reference — N/A — <reason>
