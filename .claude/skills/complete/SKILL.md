---
name: complete (Vayl project)
description: Use when a mostly-built Vayl feature needs an execution audit to reach done — missing empty states, unhandled edge/relational states, missing tests, token/grammar/contract violations, dead code. Produces a ranked gap list, then delegates confident fixes after Bryan picks the WIP. Not for strategic design questions (use consider) or greenfield (use feature).
---

# Completing a built feature in Vayl

**This is executor mode: a read-only audit that produces a ranked gap list, then delegates
fixes — but only after Bryan picks the WIP.** The audit and the fixing are strictly separated:
you audit first, present, gate, then fan out. Fanning out before the gate is a violation
(see MEMORY: the killed 5-agent sweep). The read-only-first structure is the whole safety model.

**Core principle:** audit against what actually exists and against the repo's own contracts,
not against memory. Reason from the shipped code. Rank by severity and confidence so Bryan
can choose a small WIP (finish-first discipline: the audit will surface more than you'll do).

## When to use vs the siblings

- **`/complete`** — objective execution defects on a built feature. Delegated.
- **`/consider`** — strategic/design questions ("where does it live," "does this moment need
  rework"). Advisory, Bryan decides.
- **`/feature`** — greenfield, or a feel-bearing rework once its direction is decided.

## Phases (gates are Bryan's)

| Phase | What happens | Gate |
|---|---|---|
| 1. Map what's built (read-only) | Trace real views/stores/services/models/tests via `feature-dev:code-explorer` | Bryan confirms the map |
| 2. Audit + rank (read-only) | Produce a ranked gap list, each tagged severity + confidence + route | — |
| 3. Pick the WIP | Bryan chooses which gaps to close now; rest go to the parking lot | **hard stop before any fix** |
| 4. Close gaps | Confident/mechanical → parallel subagents; feel-bearing → `/feature`; strategic-unknown → `/consider` | per gap |
| 5. Reconcile + verify | drift check + build/tests, exact counts reported | green |

## The audit checklist

Run against `CLAUDE.md` → *Violation Checklist* first (it is the canonical list: tokens,
iOS 26 bans, safe-area/tab-bar, presentation grammar, motion, empty states, taps). Then:

- **Empty / loading / error states** on every data screen (required, often the gap).
- **Lifecycle + relational states** — completion, return-visit, partner-not-done, offline,
  one-sided. These are the states that get skipped because the happy path was built first.
- **Test coverage** — Store/Service logic exercised? New test files wired into `VaylTests`
  (the manual `PBXGroup` — an unwired test silently passes vacuously; confirm it actually ran).
- **Dead code / stale duplicates** ("X 2.swift" auto-compile artifacts).
- **Backend write paths** — every Supabase write has an RLS policy (a missing policy silently
  affects 0 rows and reports success; it will not surface as a build/test failure).

## Routing rule

Not every gap is a delegate-and-fix. Tag each:
- **Mechanical / high-confidence** (missing empty state, unwired test, token violation) → subagent.
- **Feel-bearing** (a moment that needs to *feel* right) → `/feature`, do not delegate blind.
- **Strategic / unknown-answer** (should this even exist, where does it live) → `/consider`.

## Guardrails

- **Read-only until the WIP gate.** No edits, no agents, no sim during Phases 1–2.
- **Feel stays Bryan's.** Phase 5 is build + tests only; UI driving is opt-in per `CLAUDE.md`
  → *XcodeBuildMCP Usage Gatekeeping*. Build-clean is never "feels done."
- **Don't inflate the list.** Rank honestly; a 40-item audit where 6 matter buries the 6.

## Cross-references

- `CLAUDE.md` → *Violation Checklist*, *Design Token Contract*, *Build Protocol*
- Skills: `feature-dev:code-explorer`, `code-review`, `verify`, then `feature` / `consider`
