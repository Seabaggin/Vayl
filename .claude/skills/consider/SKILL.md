---
name: consider (Vayl project)
description: Use when a mostly-built Vayl feature has unconsidered design questions — where it lives in the app, how a lifecycle moment (empty/completion/return) should work, what relational or edge states are unhandled. Advisory only. Not for defect-hunting (use complete) or greenfield (use feature).
---

# Considering a built feature in Vayl

**This is consultant mode: read-only, ends in questions and recommendations, YOU decide.**
It never silently decides, and it never builds. Its job is to surface what hasn't been
thought through about a feature that already exists, advise with tradeoffs, and hand the
call back to Bryan. This is the "guide by clarifying, not prompting" posture from PRODUCT.md
applied to your own build decisions.

**Core principle:** map what actually exists first, *then* surface the gaps in thinking.
You cannot advise on a feature you haven't read. Reason from the shipped code, never from
memory of what you think is there.

## When to use vs the siblings

- **`/consider`** — strategic/design questions on a built feature ("how does the Desire Map
  live in the Map Tab," "does the both-partners-finish moment need rework"). Advisory.
- **`/complete`** — objective execution defects (missing empty states, edges, tests). Delegated.
- **`/feature`** — building something new, or a feel-bearing rework once its direction is decided.

## Flow

1. **Map what's built** (read-only). Trace the real views/stores/services/models and where
   (or whether) the feature is surfaced in navigation. Use `feature-dev:code-explorer`.
   Confirm the map with Bryan before advising — an audit built on a wrong map is worse than none.
2. **Surface the open questions** across these dimensions:
   - **Placement / surfacing** — where does it live, how is it reached, is it discoverable?
   - **Lifecycle moments** — start, empty, in-progress, completion, error, return-visit.
   - **Relational / edge states** — partner not done, one-sided, offline, first-open vs repeat.
   - **Humility check** — does each thing you're tempted to add genuinely earn its place, or
     does it only matter if Vayl is the center of their life? Default to the humbler answer.
3. **Advise, then ask.** For each open question give a recommendation with tradeoffs (and how
   peer couples apps handle it, if useful), then put the decision to Bryan. Do not decide for him.
4. **Route the decisions.** Feel-bearing reworks → `/feature`. Objective execution gaps that
   fall out → `/complete`. Record the calls in a short decisions note.

## Guardrails

- **Surfacing is not cross-feature bolting.** "Make the Desire Map reachable from the Map Tab"
  is navigation/presence and is in bounds. "Make the Desire Map read from Pulse" is a
  cross-feature tie and is banned unless Bryan asks (see MEMORY: don't reach/connect features).
  Keep integration to routing and presence, not data dependencies.
- **Advise, never decide or build.** This skill produces questions and recommendations only.
  If you catch yourself writing Swift or committing to a direction, stop — that's `/feature`.
- **No invented state.** Only surface questions grounded in the mapped code and the named
  concern. Don't manufacture edge cases the feature's real job doesn't have.

## Cross-references

- `CLAUDE.md` → *Product Principles* (humility, guide-by-clarifying), *Presentation Grammar*
- Skills: `feature-dev:code-explorer`, `impeccable`, `apple-design`, then `feature` / `complete`
