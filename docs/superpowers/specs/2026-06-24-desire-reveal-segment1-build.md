# Desire Map — Segment 1: The Reveal (build spec)

**Date:** 2026-06-24
**Status:** Design settled. This is a reconciliation of the prior specs against the as-built code and the current aesthetic. Ready for an implementation plan.
**Slice:** Segment 1 of the full Desire Map vertical (Seg 2 = Home entry surfaces; Seg 3 = Vault hosting + consent). Build one segment at a time, feel verified on device between each. The desire card-face treatment (warm-biased spectrum motion + glow-pop) is folded into this segment.

---

## Goal

Turn the existing reveal **stub** (which renders the free match, locked teasers, and CTA all at once) into the settled **3-beat conversion moment**, wire the already-built `PaywallSheet` in place of the inline CTA, and **unlock in place** on purchase.

**Done means** (on device, not "build succeeds"): the reveal plays the three beats and feels right, a purchase unlocks in place without leaving the screen, and the edges are graceful.

---

## What already exists (do NOT rebuild)

- **`DesireRevealStore`** — loads matches, resolves the free/locked split, `unlockAll()` runs `entitlements.purchase()` then reloads. Solid.
- **`PaywallSheet(entry: .reveal, onUnlocked:)`** — full body, final copy, purchase, **restore wired** (`entitlements.restore()` + "nothing to restore" alert), **Terms/Privacy wired** (in-app Safari), real StoreKit price, ⓘ receipt pop-out, DynamicType scroll backstop. Built as a **custom bottom sheet** (`vaylSheetChrome`, own grabber, bottom-bleed). NOTE: the 2026-06-20 handoff's "restore/legal are stubs" is **stale** — they are wired.
- **Data/backend** — `DesireSyncService.fetchMatches`, the `compute-desire-matches` edge fn (picks a mutual as the free reveal), `EntitlementStore` (couple-level, StoreKit). Out of scope to touch.
- **Feel reference** — `docs/prototypes/desire-reveal.html` (3-card fan + cinematic flip + locked-row stagger + paywall rise, with the per-transition timing below).

---

## Reveal architecture (reconciled across three sources)

**ONE `.vaylCover` hosts `DesireRevealView`.** The paywall is **not** a separate presentation — it is a custom bottom-sheet layer over a scrim **inside** that cover (`ZStack(alignment: .bottom)`, mirroring `CredentialEditorSheet`'s host). Unlock happens in place. No navigation between screens; one continuous emotional arc.

- The mockup's line-214 note ("paywall = `.vaylSheet`, never `.vaylCover`") is **stale** and contradicts the as-built `PaywallSheet`. Do **not** present `PaywallSheet` via `.vaylSheet` or a system `.sheet` (double-chromes the grabber/background and triggers the width-inset bug). Host it as the custom layer.

---

## The 3 beats (mapped from the mockup)

| Beat | What happens | Timing (locked in mockup) |
|---|---|---|
| **1 — the free match lands** | 3-card fan arrives (2 ghost + 1 center, echoing the rater), then a cinematic flip reveals the free match. **Medium haptic** on the flip. The emotional peak, clean — no locked cards, no price. | fan stagger 70ms / 140ms; flip 540ms; idle ring pulse 1.4s |
| **2 — the gap opens** | Free match settles up; locked teasers slide up **staggered 80ms** each; "and N more you share" count + spectrum hairline fade in. Blurred names + lock glyph. The curiosity gap. Count **templated to the real `lockedCount`**, never hardcoded. | row stagger 80ms; count/line in at ~4×80+140ms |
| **3 — the ask** | `PaywallSheet(entry: .reveal)` rises over a scrim. | sheet rise 500ms |
| **payoff — unlock in place** | On `onUnlocked`: sheet falls, scrim clears, blur lifts off the teasers, all matches reveal. `store.load()` re-resolves (now Core). No navigation. | — |

### Beat-advance model (decision, confirm by feeling)

**Chosen:** auto-timed sequence with timed holds, total ~4–5s, plus a **tap-to-advance accelerator** (a tap skips immediately to the next beat so impatient users aren't stuck waiting). The mockup is tap-only for stepping; the inter-beat **holds** still need to be felt. Proposed holds to tune: Beat-1 hold after flip-settle **~1.5s** → Beat 2; Beat-2 hold after the count appears **~1.2s** → Beat 3.

- **Reduce Motion:** collapse to a single static composed state (free match + locked teasers + paywall available), no beat animation, still purchasable.
- **Pre-Swift task:** add a small auto-play toggle to `desire-reveal.html` so the holds are felt before any timing is written into Swift (per the build protocol — never guess a timing value).

---

## Card face treatment (folded into Segment 1)

**Reframe:** this is a *treatment* on the existing card, not a new component. `VaylCardFace` already has `colorway` + `heat` + `CardHeatGlow` (a glow that brightens as a 0...1 value rises). A desire identity = a magenta-weighted desire tint feeding `FaceAtmosphere` (via the card's colorway/heat hooks or an equivalent); the glow-pop = animating `heat` 0 → 1. This keeps us clear of the `.drawingGroup()` shell contract.

**Direction (settled, feel-first):** warm-biased spectrum motion. A living edge in the existing palette weighted toward magenta so the desire card reads hotter than a cyan-led card, without leaving cyan/purple/magenta. NOT literal fire color (that breaks the system).

**Restraint:** the border is subtle-to-static at rest; the real bloom is spent on the *event* — the flip-land in the reveal, the answer-select in the rater. Reward the action, don't hum. The reveal is already glow-dense (atmosphere, resting border glow, inset frame, outer hairline, emblem pulse, paywall bloom); one hero glow moment, not constant ambient flame.

**Technical constraint:** never bake a per-frame flame inside `VaylCardFace`'s ZStack — it is `.drawingGroup()`-rasterized (contract: never remove), so CPU-animated flicker regenerates the Metal texture every frame. Continuous motion is a `TimelineView`-driven moving gradient mask on a border overlay *outside* the drawingGroup (escalate to a `HolographicShimmer` `.colorEffect` only if the SwiftUI version isn't alive enough; respect the shader-time-precision + clean-build gotchas). The one-shot heat-glow is cheap and fine inside.

**Surfaces:** the treatment is shared. Reveal = glow-pop on flip-land (Beat 1). Rater = glow-pop on answer-select (a light touch on `DesireMapView`, otherwise out of scope). Folding the card face in pulls this rater touch into the segment.

**Feel-first:** prototype the treatment in Swift, on device, composing the real `OnboardingAtmosphere` + `VaylButton` + the card's tint/heat (zero fidelity gap). Lock the warm-bias amount, flicker intensity, and glow-pop curve on device before writing them into the reveal. Per the swift-over-html rule, this is a Swift prototype, not an HTML mock.

---

## Branches (grace the edges)

- **Already-Core couple:** skip Beats 2–3. All matches shown as a celebration — no locked teasers, no paywall.
- **0 matches:** `.empty` state (exists).
- **1 match, 0 locked:** Beat 1 only, then a gentle close affordance. No gap, no paywall.

---

## Settled decisions

1. **Remove the "Ask about something you didn't match on" row** (`requestHiddenConversation`) from the reveal. Revisit the hidden-conversation mechanic in Segment 3 (consent/Vault), where consent already lives. `requestHiddenConversation()` stays stubbed.
2. **Copy source of truth = `PaywallSheet`** (final copy). The 2026-06-19 spec copy is stale (older mission lines + em dashes); do not reintroduce it.
3. **Presentation:** move `HomeRouterView`'s reveal from raw `.fullScreenCover(item: $activeReveal)` to **`.vaylCover(isPresented:, confirmOnExit: false)`**. `vaylCover` is Bool-based, so drive it from a `Binding` mapped off `activeReveal != nil` and unwrap the store inside. `confirmOnExit: false` (a reveal is re-openable, not a destructive mid-task exit). The X button calls the `\.vaylDismiss` action, not `@Environment(\.dismiss)`.

---

## Constraints (files this segment may NOT touch)

- `PaywallSheet.swift` body / copy / layout — use as-is via `entry: .reveal` + `onUnlocked`. Tuning its internal bloom/height knobs is out of scope.
- `DesireSyncService`, the `compute-desire-matches` edge fn, `EntitlementStore`, `DesireMatch` / `DesireMapEntry` models — no changes.
- The rater (`DesireMapView` / `DesireMapStore`) — untouched.
- Shared `vaylSheetChrome` / `VaylPresentation` — extend only if strictly necessary; do not restyle.
- The rater's and session's raw presenters in `HomeRouterView` — parked (a separate nav-grammar cleanup), not this segment.

---

## Done condition (verified on device)

1. Free couple: opening the reveal plays Beat 1 (fan + flip + haptic) → Beat 2 (gap + count) → Beat 3 (paywall), feel confirmed against the mockup.
2. A purchase unlocks **in place** (blur lifts, all matches shown) without leaving the cover.
3. Already-Core: celebration, no paywall. 0/1-match: graceful, no broken gap.
4. Reveal presents via `.vaylCover`; no interactive swipe-away mid-beat; X closes cleanly.
5. Reduce Motion: static composed state, no beat animation, still purchasable.
6. ~~The desire card face flame~~ — cut 2026-06-26.

---

## Files touched (anticipated)

- `DesireRevealView.swift` — restructure `.ready` into the beats; host `PaywallSheet`; unlock-in-place; remove `requestRow`.
- `DesireRevealStore.swift` — add a beat-state enum (the mockup's SwiftUI note drives beats from the store); keep `load()` / `unlockAll()` as-is.
- `HomeRouterView.swift` — reveal → `.vaylCover`.
- `docs/prototypes/desire-reveal.html` — add an auto-play toggle to feel the holds (mockup only, before Swift).
- ~~`DesireCardFace` treatment~~ — cut 2026-06-26.

Relates to: `2026-06-19-desire-reveal-paywall-design`, `2026-06-20-paywall-sheet-handoff`, `monetization_paywall_spec`, `frontend_ux_nav_spec`, `d4_reveal_stub_built`.
