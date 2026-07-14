---
name: feature (Vayl project)
description: Use when building a new Vayl feature or multi-screen flow from mockup through backend, or reworking an existing screen suite. Not for one-view polish or a bugfix.
---

# Building a feature in Vayl

**This skill is a thin orchestrator, not a doer.** It sequences the phase-gated
pipeline defined in `CLAUDE.md` → *Build Protocol*. That section is the law; this
skill is the operating manual for running it: which subagent handles each phase,
which existing skill it loads, what single authoritative input it gets, and where
Bryan gates. Read the Build Protocol first; do not duplicate its rules here, follow them.

**Core principle (why an orchestrator, not one big pass):** hallucination comes from
context bloat and fuzzy sourcing. So every phase runs in a *fresh, isolated subagent*
with ONE authoritative input and ONE specialized skill loaded. A screen agent sees its
Screen Brief and the token contract — never the other screens' code. Clean context,
single source of truth, no room to invent a dialect of the design system.

## When to use vs skip

- **Use** for a new feature or a multi-screen flow, mockup → frontend → backend, or a
  full screen-suite rework (e.g. the session sequence).
- **Skip** for a single-view polish or a bugfix. Run the tail only: build against the
  locked reference, verify. Do not perform the pipeline on a one-liner (Build Protocol →
  *Right-size the pipeline*).

## The pipeline (gates are Bryan's, always)

| Phase | Dispatch | Skill loaded | Authoritative input | Gate to advance |
|---|---|---|---|---|
| 1. Function-in-practice | none (Claude + Bryan talk) | `superpowers:brainstorming` | the conversation | Bryan approves how it behaves in real use |
| 2. Screen suite + edge cases | design pass + a parallel WebSearch agent (how peer couples apps solve the moment) | `impeccable`, `apple-design`, `design:design-critique` | PRODUCT.md + DESIGN_DOC.md + mockups | Bryan approves screen list, flow, and per-screen data contract |
| 2.5 Data contract | `feature-dev:code-architect` | — | the screen list + **real Supabase schema** (project MCP) | contract is storable against the live schema |
| 3. Frontend | ONE subagent per screen (parallel) | `swiftui-expert-skill`, `swiftui-patterns`, `apple-design` | that screen's **Screen Brief** only | build-clean + renders with stub data |
| 3.5 Reconciliation | one reviewer subagent | `code-review`, `design:design-critique` | all screens + the Screen Brief | no token/motion/grammar drift, no invented elements |
| 4. Backend | subagent per Store/Service (parallel) | `supabase:supabase` | the data contract + Supabase MCP | routes + persists/reads correctly |
| 5. Verify | build + tests | `verify` | the diff | green build, tests pass, exact counts reported |

## The Screen Brief — the anti-drift anchor

At the **end of Phase 2**, write ONE file (scratchpad or `docs/`) holding, per screen:
its purpose, the tokens/motion/presentation-grammar decisions it uses, its **data
contract** (what its Store reads/writes), and its **definition of done**. Plus the
shared token/motion decisions for the whole suite.

Every Phase 3 subagent is handed **only its own screen's brief plus the token contract**.
It never reads sibling screens' code. This is what replaces "Bryan in the loop each
segment" — without it, N parallel agents produce N dialects of the design system.

## Non-negotiable operating rules

- **Confirm before code, every phase.** State what's being built and the on-disk
  authoritative reference (mockup path / DESIGN_DOC section) before writing anything.
  Never add a visual element (glow, hairline, accent) or a flow/screen not in the
  reference. Inventing detail is the top historical failure mode here.
- **Data-contract-first.** Frontend builds against **stubbed Stores/Services** returning
  fake data so Bryan sees the whole flow immediately; backend fills the identical contract
  later without touching Views (the 4-layer seam). Verify the contract against the real
  schema in Phase 2.5, so a stub never promises data the DB can't store. **If the Supabase
  MCP is unavailable this session** (it often needs auth via `/mcp`), do not assume the
  contract is storable — flag the schema check as blocked, verify against migrations in the
  repo where possible, and treat Phase 4 backend as gated on that check clearing.
- **Reconciliation is mandatory** after the Phase 3 fan-out — it is not optional cleanup.
  Parallel agents each drift; 3.5 catches it adversarially.
- **Feel is Bryan's, and it is a real gate before Phase 4.** Phase 3's gate is "renders
  correctly," NEVER "feels right." Build-clean is never "done." Do not assert a feel verdict.
- **Subagents return conclusions, not file dumps.** Each reads its narrow slice; the
  orchestrator holds the thread.

## Dispatch hygiene

- Screens are usually separate files, so parallel Phase 3 agents rarely conflict. If two
  touch a shared file (a router, an enum, `AppEnums.swift`), either serialize those or give
  each `isolation: worktree`. Flag the shared-file risk in the plan, don't discover it in a
  merge.
- Present the Phase 2 plan and **wait for approval before spawning any agents.** Unrequested
  fan-out is a violation (see MEMORY: over-eager 5-agent sweep). The gate is the point.

## XcodeBuildMCP

Phase 5 is `build_sim` / `test_sim` for a compile + test verdict — **no UI driving**.
Screenshots, taps, `snapshot_ui` are opt-in only, per `CLAUDE.md` → *XcodeBuildMCP Usage
Gatekeeping*. Do not reach for the sim to "see" a screen when you can reason from the code
and the mockup. That gate is strict on purpose.

## Cross-references

- `CLAUDE.md` → *Build Protocol* (the law), *Design Token Contract*, *Presentation Grammar*,
  *Animation Feel Contract*, *Safe Area & Tab Bar Contract*
- Skills: `superpowers:brainstorming`, `impeccable`, `apple-design`, `feature-dev:code-architect`,
  `swiftui-expert-skill`, `code-review`, `supabase:supabase`, `verify`
- The deterministic full fan-out can also be run as a **Workflow** (opt-in) instead of manual
  dispatch, when Bryan asks for it explicitly.
