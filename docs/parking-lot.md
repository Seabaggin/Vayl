# Parking Lot

Everything here is **real** and **not now.** It lives here so it's out of your head and off the
critical path. Nothing in this file gets touched until the launch-blocker path is closed.

**The operating rules (the actual plan):**
1. **WIP = 1.** One segment in flight. Not "started," not "next" — the *only* thing you may touch.
2. **Finish-first.** No new segment opens until the current one is `done`. Drain the in-flight pile
   (cheapest-to-close first) before starting anything new.
3. **Done = your own bar:** runs on device + feel confirmed. NOT "matches the mockup pixel-for-pixel."
4. **Anything that isn't the current segment lands here** — then you keep moving.

Source of truth for *what to build* stays `docs/roadmap/vayl-build-roadmap.html`. This file is only
for the polish/redesign urges that would otherwise pull you off the current segment.

---

## Parked: Pulse mockup-fidelity polish (14 gaps)
Pulse is at **75–85% fidelity** per `docs/audits/2026-06-28-pulse-mockup-vs-impl-RESULTS.md`.
**That is done-enough for launch.** By choosing the verifying sweep over more Pulse work, Pulse is
declared done-as-is. All 14 audit gaps park here.
- If you ever return: the audit's own "fix three things" is the only shortlist worth it —
  (1) unify zone/aura palette [C2], (2) restore glass/border token strength [S2-1/S3-2], (3) drop
  Home state name to ~15pt [S3-1]. Everything else is invisible-to-users polish.

## Parked: Settings visual micro-iteration
The Settings *shell* exists. The ~35 icon/spacing tweak commits (Jun 28) were polish on a feature
that isn't on the critical path. **T5 (Settings — real page)** is a `todo` segment; when it comes up,
build it to the "works + truthful" bar and stop. No more `person.fill` iterations.

## Parked: VaylMark / brand-moment polish
`MapChartedMoment` + `VaylMark` brand-animation refinements. The mark draws and reads. Further
polish waits until after launch-path.

## Parked: T4/Learn real content
Structure is built + device-verifiable now. Real research authoring + Flavor/Boundary quiz flows +
Orientation-Map blend = **Phase 7 / C3**, not a T4 blocker.

## Correction (not parked — critical path): S3 + S4 were mislabeled `verifying`
Both have all checklist items unbuilt. They are real build work, not device passes. They belong in
the **Sessions push behind S2 (the handshake)**, not in any "verifying sweep." Relabel to `todo`.
