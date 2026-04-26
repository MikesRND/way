---
artifact: implementation-manifest
element_key: <element-key>
element_name: <Element Name>
architecture_scope: repo|directory|file|logical
scope_paths:
  - path/relative/to/repo/
derived_from:
  - plan-approved.md
last_updated: YYYY-MM-DD
current_phase: all
---

<!--
  Transient artifact written by `way-impl`, consumed by `way-impl-review`
  and `way-finalize`. v1 writes a single Phases entry with name "all".
  The list shape is preserved so v2 can adopt per-phase invocation
  without changing the format.
-->

# <Element Name> — Implementation Manifest

## Manifest Summary

One paragraph: what was implemented this cycle and how the gates fared.

## Phases

### Phase: all

#### Touched Files

```
path/to/file1.ext
path/to/file2.ext
```

#### Summary of Changes

What changed, grouped by area. Description-level — link the manifest to
the plan's work items but do not paste diffs.

#### Validation Gate Results

| Gate | Command | Exit Status | Notes |
|------|---------|-------------|-------|
| <gate name> | `<command>` | 0 | <notable output, links to logs if any> |

## Cross-Phase Notes

Anything that spans phases or that did not fit cleanly into a single
phase entry. In v1 this is usually empty.
