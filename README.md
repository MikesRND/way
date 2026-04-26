# way

> a way of doing things

A small, opt-in framework for separating **architecture**, **planning**, and
**implementation** when working with AI agents — packaged as nine portable
skills that work in Claude Code, Codex CLI, Cursor, Gemini CLI, and VS Code /
Copilot.

There are many ways. This is just *a* way that happens to work well for
keeping high-level concerns from being drowned in code-level detail.

## Quick Start

`way` installs **per project** as a git submodule. It does not modify
anything user-global.

```bash
cd ~/projects/myapp
git submodule add git@github.com:MikesRND/way.git .way/way
.way/way/setup.sh                  # or .way/way/setup.sh ~/projects/myapp
```

That writes, scoped to `myapp/`:

- `.agents/skills/way-*` — nine relative symlinks into the submodule.
  This is the canonical location and is what
  [Codex discovers natively](https://developers.openai.com/codex/skills).
- `.claude/skills` → `../.agents/skills` — single dir-level symlink so
  Claude Code's per-project skill discovery picks up the same set. If
  `.claude/skills/` already exists with other skills, `setup.sh` falls
  back to per-skill symlinks under that directory instead of replacing it.
- `AGENTS.md` — appended (or created) with a sentinel-guarded pointer
  block. Honored by Codex and any other tool that reads `AGENTS.md`.

The submodule mount path is whatever you pick when adding it — `setup.sh`
auto-detects its own location relative to the target project.
Workflow artifacts live at `myapp/.way/elements/<element_key>/`.

**Updating the framework:** `git -C .way/way pull` and commit the
submodule bump. The pin gives you version control over which framework
revision the project is on.

### Using it

In any supported tool, ask the agent to use a `way-*` skill — start with
`way-advisor` if you don't know which one applies:

```
use way-advisor on src/auth/
```

## What it does

`way` separates the lifecycle of a substantive change into three stages with
explicit review gates between each one:

1. **Architecture** — components, responsibilities, dataflow, interfaces, concurrency, parallelism.
   No function names, no algorithms, no defensive checks.
2. **Planning** — ordered, executable work derived strictly from approved
   architecture. Plans don't redesign architecture.
3. **Implementation** — code changes bound by the approved plan and
   architecture. If implementation needs an architecture change, it
   escalates rather than silently redesigning.

Two long-lived design docs survive every cycle: `architecture-current.md`
and `detailed-design-current.md`. Everything else is transient and archived
at finalize.

## Available Skills

| Skill | What it does |
|-------|--------------|
| [`way-advisor`](skills/way-advisor/) | Read-only router. Recommends the next skill — or recommends skipping the framework. |
| [`way-arch-doc`](skills/way-arch-doc/) | Reverse-engineer existing code into `architecture-current.md`. |
| [`way-arch-design`](skills/way-arch-design/) | Propose new or changed architecture (full or delta). |
| [`way-arch-review`](skills/way-arch-review/) | Review the proposal; on approval, normalise into a full approved doc. |
| [`way-plan`](skills/way-plan/) | Elaborate approved architecture into an ordered plan, scoped to the change. |
| [`way-plan-review`](skills/way-plan-review/) | Review the plan against approved architecture; on approval, normalise. |
| [`way-impl`](skills/way-impl/) | Implement the plan, run validation gates, write a manifest. |
| [`way-impl-review`](skills/way-impl-review/) | Verify repo state against plan and architecture; catch architecture-violating drift. |
| [`way-finalize`](skills/way-finalize/) | Refresh the two long-lived docs from the approved cycle; archive transients. |

Platforms tested: Claude Code, Codex CLI. The skills are platform-neutral —
they should work in Cursor, Gemini CLI, and VS Code / Copilot.

## Workflow

```
way-advisor ──→ (way-arch-doc) ──→ way-arch-design ──→ way-arch-review
                                                              │
                                                              ▼
                                              way-plan ──→ way-plan-review
                                                              │
                                                              ▼
                                              way-impl ──→ way-impl-review
                                                              │
                                                              ▼
                                                         way-finalize
                                                              │
                                                              ▼
                                          architecture-current.md
                                          detailed-design-current.md
                                          archive/<old transients>
```

### Two doc layers

- **`architecture-current.md`** — readable structural architecture: what
  the components are, how they interact, what the contracts at boundaries
  guarantee.
- **`detailed-design-current.md`** — one level deeper, design-oriented.
  Refreshed from actual repo state at finalize. Not a code reference.

### Full vs. delta proposals

This rule applies **only to architecture proposals**. Plans are always
full.

- **Full proposal** — greenfield work, or wholesale rearchitecture of a
  documented element. Produces a complete proposal with all sections.
- **Delta proposal** — incremental modification of an element that already
  has `architecture-current.md`. Describes only the scoped change.
  Explicitly enumerates carried-forward sections.

`way-arch-review` always normalises into a **full** `architecture-approved.md`
— delta proposals are deterministically merged into the current doc on
approval.

### Core vs. conditional sections

Documents have a fixed list of core sections (always present) and a list
of conditional sections (present when relevant). Omitted conditional
sections are recorded in a single compact **Applicability Notes** block.
Empty sections are not padded into the document.

### Reviewer independence

Each of the three review skills (`way-arch-review`, `way-plan-review`,
`way-impl-review`) opens with the same guard:

> **Prefer running this review in a fresh conversation or session.** A
> reviewer that has not seen the design conversation is genuinely
> independent. Highest-fidelity mode; platform-neutral.
>
> If running in the same session, apply in-context discipline: do not
> reference your own prior reasoning or drafts; read only the artifacts
> named on disk; produce the review as if encountering them cold.

The skill does not depend on platform-specific subagent invocation. Users
who want stronger isolation in tools that support subagents can launch
one — but the skill is written to work the same way in any tool.

### When to use vs. not use the framework

`way-advisor` is permitted (and expected) to recommend "this change does
not need `way-*`" as a valid output. Suggested thresholds:

- **Skip the framework entirely** for single-file fixes, dependency bumps,
  doc-only edits, and any change that does not touch component boundaries,
  responsibilities, or interfaces.
- **Use the framework** for new elements, cross-component changes, or any
  change that alters interfaces, dataflow, or responsibilities.

The framework is not the only path to modify code. It is the path for
changes that warrant architectural review.

### Cross-tool portability

Every artifact is plain Markdown with YAML frontmatter, and every skill is
written without platform-specific tool dependencies. Run `way-arch-design`
in Claude Code, switch to Codex for `way-arch-review`, return to Claude
Code for `way-plan` — artifacts and frontmatter remain interpretable
across tools.

## Worked Example

The framework documents itself. See `.way/elements/root/`:

- [`architecture-current.md`](.way/elements/root/architecture-current.md) —
  the family's structural architecture: nine skills, two maintained docs,
  the full-vs-delta rule, single-cycle impl/review (v1), reviewer
  independence, cross-tool portability.
- [`detailed-design-current.md`](.way/elements/root/detailed-design-current.md) —
  one level deeper: artifact contract, frontmatter and section catalogs,
  archive policy, finalize reconciliation rules.

These two files are the in-repo reference for what "good" looks like for
any element documented with this family.

## Skill Structure

Every `way-*` skill follows the [Agent Skills standard](https://agentskills.io/specification):

```
skills/<name>/
├── SKILL.md          # Entrypoint — YAML frontmatter + instructions
├── assets/           # (optional) Templates, schemas, static resources
├── examples/         # (optional) Worked output examples
└── references/
    ├── family-contract.md   → ../../../shared/family-contract.md
    └── templates/           → ../../../shared/templates/
```

Only `name` + `description` from the frontmatter are loaded at startup.
The full `SKILL.md` loads when the skill is activated. `references/`
loads on demand — the family contract and per-artifact templates are
shared across all nine skills via symlinks into `shared/`.

## Repository Layout

```
way/
├── README.md                       # this file
├── LICENSE                         # MIT
├── .gitignore
├── setup.sh                        # multi-platform installer
├── skills/                         # nine way-* skill directories (symlinked by setup.sh)
│   └── way-<name>/
│       ├── SKILL.md
│       └── references/
│           ├── family-contract.md  → shared/family-contract.md
│           └── templates           → shared/templates
├── shared/                         # NOT a skill (setup.sh skips it)
│   ├── family-contract.md          # canonical artifact contract
│   └── templates/                  # eight per-artifact templates
└── .way/
    └── elements/
        └── root/                   # framework documenting itself
            ├── architecture-current.md
            └── detailed-design-current.md
```

`shared/` lives outside `skills/` so it is not surfaced as a skill. As a
second guard, `setup.sh` skips any directory under `skills/` that does
not contain a `SKILL.md`.

## Adding a New Element

1. Pick an `element_key` — repo-unique lowercase kebab-case (e.g.
   `auth-service`, `data-ingest`).
2. Run `way-advisor` against the element's path. It will tell you whether
   to start with `way-arch-doc` (existing code, no doc), `way-arch-design`
   (greenfield), or skip the framework altogether.
3. Follow the recommended skill chain. `way-advisor` re-runs at any time
   show you where you are and what's next.
4. After `way-impl-review` approves, run `way-finalize` — the two
   long-lived docs are refreshed and the cycle's transients move into
   `archive/`.

## Design Principles

- **One skill, one job.** Each `way-*` skill handles one phase. They
  compose, not nest.
- **Examples define quality.** Templates define structure; the worked
  `root` example defines the bar for every other element.
- **Platform-neutral source.** Skills live in `skills/`, not inside any
  platform's config directory. Symlinks bridge the gap.
- **Design over code-reference.** Architecture stays at architecture
  depth. Detailed design stays at design depth. Code lives in the repo.
- **Eat your own dogfood.** The framework documents itself in
  `.way/elements/root/`.

## License

[MIT](LICENSE)
