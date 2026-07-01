# Pulse — Full Audit + One-Shot Plan to Final — 2026-06-30

Top-to-bottom state of the Pulse feature (front + back), then a segmented plan to fix
what's broken and take it to V1-final. Audit verified from source (3 parallel code audits).
Feel references: `docs/prototypes/pulse-ball-physics.html` (physics, locked) and
`docs/prototypes/home-pulse-widget-shine.html` (widget, locked direction C).

---

## PART 1 — STATE OF THE FEATURE

### Front-end rendering — built and recently polished ✅
- `PulseAura` — glossy caustic-under-glass orb; now **color-parameterizable** (`ramp:` / `quadrant:`), plus a `PulseCyclingAura` variant (dormant tours all 4 spaces).
- `PulseField` — 2D circumplex; zones refined (fade-before-overlap, luminance-balanced), ghost labels fixed (big/bold, staggered, no collision).
- `PulseCapsule`, `PulseHistoryGrid` (flat glass chips), all live.

### Check-in — live and working, but with real problems
- **Canonical view:** `PulseCheckInView` (the only live check-in). 5 questions, aura drifts live from Q1–Q3, blooms, commits a `PulseEntry` → `PulseStore.add`.
- **Two live entry points:** Home rail `onCheckIn` (`HomeDashboardView.swift:313`) and Map hero `onCheckIn` (`MapView.swift:196`).
- **Presentation:** BOTH are `.vaylSheet` at `heightFraction 0.82` — this is the buggy path (the field doesn't land because a sheet sizes from measured content, not the screen).
- **Q4 overrides the color:** `commitEntry` sets `glowColor` = Q4's override if answered, else the quadrant color (`PulseCheckInView.swift:226-228`) — fights "the ball is the color of its spot."
- **"Stable" lands dead-center:** Q1 "Stable" = energy delta 0 → energy exactly 0.5 → the `>= 0.5` tie-break silently forces it into the charged half. This is the "no-between" hole.
- **Duplicated mapping:** the answer→position math exists twice — `PulseAnswers.position()` AND re-implemented inline in `PulseCheckInView.currentPosition`.

### Home — wired, but the active tap dead-ends
- Dormant rail now shows the **cycling aura** ✅. Active row shows the landed aura + state.
- **Active tap is orphaned:** `onTap` toggles `pulseExpanded`, a `@State` nothing consumes. `HomeRouterView.swift:220` already passes `onPulseTap = { select .map }` into the dashboard, but the dashboard never calls it — it wired the tap to the dead toggle. So "tap → Map" is one line away.
- `expansion` / `maxGraphHeight` / `pulseExpanded` are **vestigial** (HomePulseRail explicitly ignores them, `:19-21`).
- `onInfo` param + `PulseInfoSheet` are an unused stub.

### Map — Me is live, Us is all placeholder
- **Me:** `MapPulseHero` (real last-entry position) + `MapFieldSheet` (a `.vaylCover`, full-screen — lands the field fine, the model for the check-in fix). Live ✅.
- **Us:** `MapUsLayer` is fully built but runs on **placeholder data** — `partnerPosition` is hardcoded `nil` (`MapStore.swift:75`, "Segment 7" TODO, zero writes anywhere), and the paired grid gets `partner: []`. So distance, capsule, headline, and partner grid column are never real (only in previews). Me/Us toggle = the masthead name; the Us name only renders in DEBUG (`partnerName = "Alex"`).

### Data / back-end — thin, partly stubbed
- **Persistence:** local **UserDefaults** JSON (`pulse.entries.v1`), survives restart. `PulseEntry` is a plain `Codable` struct, **deliberately not** SwiftData.
- **Network:** `PulseSyncService.pushCurrentCapacity` fires on every check-in, pushing a single **capacity scalar** to `pulse_shared_capacity` if sharing is on. `fetchPartnerCapacity` / `fetchSharing` / `setSharing` exist but have **zero callers**.
- **Back-end schema:** Supabase migrations have **nothing** for Pulse. `pulse_shared_capacity` + `user_profiles.share_pulse_with_partner` exist **only in prod** (untracked drift) — a fresh `db reset` would break the sync path. No pulse edge function.

### Dead code inventory (safe to delete)
6 orphaned view files: `DailyCheckInView`, `CheckInShell`, `PulseCheckInCover`, `PulseWidget`, `PulseSheetView`, `TierGuideSheet` (all stubs / deprecated, zero live presenters). Plus the legacy `PulseTier` enum (shadows `PulseQuadrant`), the vestigial `pulseExpanded`/`expansion` machinery, and the `PulseInfoSheet`/`onInfo` stub. (`PulseFullView` is a live-but-stub history sheet — keep, it's mounted.)

---

## PART 2 — WHAT'S BROKEN / MISSING (the fix list)

| # | Issue | Severity |
|---|-------|----------|
| 1 | Check-in presented as a fragile sheet → the graph doesn't land | **P0** |
| 2 | Home active-widget tap dead-ends (orphaned `onPulseTap`) | **P0** |
| 3 | Locked ball behaviors unbuilt: drift spring, idle float, silver-to-start | **P0** |
| 4 | Home widget isn't the agreed ambient-hero design | **P1** |
| 5 | Q4 overrides the ball's color (fights position-color) | **P1** |
| 6 | "Stable"/no-between: check-in can land on a quadrant boundary | **P1** |
| 7 | Duplicated answer→position math (two copies) | **P1** |
| 8 | Us layer has no partner data (backend + wiring absent) | **P1 (scope)** |
| 9 | Back-end: no pulse migration; prod schema drift; dead sync methods | **P1** |
| 10 | Dead code: 6 view files + legacy `PulseTier` + vestigial machinery | **P2** |

---

## PART 3 — ONE-SHOT PLAN TO FINAL

Ordered by dependency. Each segment: one thing, a done-condition verified on device, and
files it may touch. Feel values are already locked (playground) — no guessing.

### Phase A — Foundations (model + mapping + cleanup)

**A1 · Single source of truth for position + no-between snap.**
Delete the inline copy in `PulseCheckInView.currentPosition`; make it call `PulseAnswers.position(...)`. Add the off-axis snap there (resolved energy/openness pushed ≥ 0.16 off center) so a completed check-in always lands in one space.
*Done:* answering all 5 always lands the ball clearly inside a quadrant; only one mapping function exists. *Files:* `PulseAnswers.swift`, `PulseCheckInView.swift`. **Needs decision: "Stable" lean (below).**

**A2 · Position is the only color source.**
In `commitEntry`, drop the Q4 `glowColor` override — store the quadrant color; keep Q4/Q5 answers as recorded reflective metadata.
*Done:* the committed orb color always equals the ball's grid position. *Files:* `PulseCheckInView.swift`.

**A3 · Delete dead code.**
Remove the 6 orphaned view files, the legacy `PulseTier` enum (after confirming zero use), the vestigial `pulseExpanded`/`expansion`/`maxGraphHeight` threading, and the `PulseInfoSheet`/`onInfo` stub. Keep `PulseSyncService`'s partner methods (seed for Phase F) but mark them.
*Done:* build green, no orphaned Pulse files, `HomeDashboardView` no longer computes `expansion`. *Files:* the 6 view files, `AppPulseEnums.swift`, `HomeDashboardView.swift`, `HomePulseRail.swift`.

### Phase B — The ball behaviors (locked feel)

**B1 · Drift spring.** Add `AppAnimation.pulseBallDrift = .spring(response: 1.20, dampingFraction: 0.70)`; use it for the aura's position moves in `PulseField` + the check-in.
**B2 · Idle float.** Add the `6.5pt @ 5.2s` bob + `±0.030` breathe to the live ball (a `PulseAura` option so the history grid stays static).
**B3 · Silver-to-start.** The ball is silver (neutral ramp) until it first lands in a quadrant (both axes committed), then quadrant color; never returns to silver. Wire into the check-in.
*Done (B1–B3):* on device the check-in ball starts silver, drifts languidly to each answer, colors when it lands, floats while idle — matching the playground. *Files:* `AppAnimation.swift`, `PulseAura.swift`, `PulseField.swift`, `PulseCheckInView.swift`.

### Phase C — Check-in presentation (the stable pop-out)

**C1 · Move check-in to a stable full canvas.** Replace the `.vaylSheet` at both live sites with a full-screen presentation that gives `PulseField` a screen-derived geometry (like `MapFieldSheet`). Lay out `PulseCheckInView` full-screen.
**C2 · Pop-out choreography.** Present it as the widget aura blooming open → check-in → collapse back to the landed orb, with confirm-on-exit. *Fallback:* plain cover if the choreography slips.
*Done:* the field lands cleanly every time (bug gone); the check-in feels like the widget opening, not a slab. *Files:* `HomeDashboardView.swift`, `MapView.swift`, `PulseCheckInView.swift`, possibly a new presentation helper. **Needs decision: confirm pop-out vs plain cover.**

### Phase D — The Home widget (ambient hero)

**D1 · Rebuild `HomePulseRail` as ambient-hero**, direction validated across 3 mockup rounds (`docs/prototypes/home-pulse-widget-shine.html` → `-alignment-options.html` → `-orb-size-options.html`):
  - **Row-paired hero + orb.** Eyebrow (`.overline`, "THE PULSE") on its own line. The hero line (state name / "How's your capacity?") and the orb share one `HStack` row with `alignment: .center` — this guarantees they stay vertically centered against each other regardless of 1-line vs 2-line hero text; independent-block centering (the old approach) drifted between dormant/active by ~14pt depending on copy length. Sub-label sits below in normal flow.
  - **Hero gets room to breathe.** Swap `cardTitleCompact` (16pt, chosen for the old single-line dense row) → `cardTitle` (22pt) for the hero; drop `.lineLimit(1)` so a longer real Pulse question/state name can wrap to 2 lines without truncating or breaking the row-pairing above.
  - **Orb grows, modestly.** `PulseAura`/`PulseCyclingAura` already take an arbitrary `size:` (see the 150pt hero / 44pt field / 32pt widget presets in `PulseAura.swift`'s own preview) — this is a size-argument change only, no component work. Target ~60pt (from today's 42pt); *FEEL: tune on device*, but stay well under the 150pt Map-hero preset. A fully orb-dominant version (~140pt, hero text reduced to a caption) was mocked and explicitly rejected: it reads as a second hero competing with the Home dashboard's own hero card, and duplicates what `MapPulseHero` already does. Home's widget stays the quiet, secondary signal; Map keeps the immersive one.
  - **The Check-in pill lives under the orb in BOTH states** (already this plan's intent) — paired in the same column as the orb, not as a separate trailing element, so re-checking in is always one tap.
  - **Uniform spacing, not ad-hoc margins.** Give eyebrow → hero-row → sub-block a consistent gap rather than one-off margins — a tight gap crowds the sub-text against the bigger orb's glow halo.
  - **Absorb A3's cleanup here if it hasn't landed yet** — no reason to rebuild this file around the vestigial `expansion`/`maxGraphHeight` params.
  - **Out of scope for D1:** the "brighter than yesterday" trend line seen in the mockup's active state isn't part of this plan — it needs a new `PulseStore` trend computation (today's `capacityScore` vs. the prior entry) that doesn't exist yet. Track it as a possible D1.5 if wanted; don't build it silently as part of this segment.
**D2 · Wire the active tap → Map.** Point the rail's `onTap` at the existing `onPulseTap` (routes to Map); delete the dead toggle.
*Done:* the widget matches the validated mockup direction; in Xcode preview, the hero line stays centered against the orb even with a deliberately long state name (2-line wrap test); tapping the widget opens the Map Pulse. *Files:* `HomePulseRail.swift`, `HomeDashboardView.swift`.

### Phase E — Map surfaces

**E1 · Apply ball behaviors to Map** Me hero + field sheet (drift/float/silver as relevant; color already discrete). *Files:* `MapPulseHero.swift`, `MapUsLayer.swift`.
**E2 · Us empty state stays honest** until Phase F lands partner data — no fake capsule.

### Phase F — Back-end + partner data (the Us feature) — SCOPE DECISION

**F1 · Reconcile the schema.** Bring `pulse_shared_capacity` + `share_pulse_with_partner` into a tracked migration, and decide the shape: the Us layer needs a **2D position**, not just a scalar — so store `energy`/`openness` (or the position), not only `capacity_score`.
**F2 · Wire the fetch.** Extend `PulseSyncService` to push/fetch the position; assign `MapStore.partnerPosition` from it; wire the sharing toggle into Settings.
**F3 · RLS + tests** (partner can read only when both consent; pgTAP + a Deno test).
*Done:* with a paired, consenting partner, the Us layer shows two real auras + capsule + split grid. *Files:* `supabase/migrations/*`, `PulseSyncService.swift`, `MapStore.swift`, settings.

### Phase G — Persistence call (decision)
Keep pulse history **local UserDefaults** for V1 (works today), or sync it server-side to match the online-first stance? Local is fine for V1; server-sync is a follow-up unless the Us grid needs partner history.

---

## DECISIONS NEEDED BEFORE BUILD
1. **"Stable" lean** — charged, depleted, or drop the option? (blocks A1)
2. **Partner / Us layer in V1?** — wire the backend (Phase F, real work) or ship **Me-only + honest Us empty state** and defer Us? (biggest scope lever)
3. **Presentation** — confirm pop-out choreography vs plain full-screen cover. (C2)
4. **Persistence** — UserDefaults-only for V1, or server-sync pulse history? (G)

## SUGGESTED SEQUENCE
A (foundations + cleanup) → B (feel) → C (presentation) → D (widget + tap) → E (Map) → then F only if Us is in V1. A–E is "Pulse for one person, final and polished." F is "the couple layer."
