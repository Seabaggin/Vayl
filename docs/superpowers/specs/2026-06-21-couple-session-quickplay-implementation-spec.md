# Vayl — Couple Card Session Quickplay: Implementation Spec

**Date:** 2026-06-21
**Status:** Implementation — strategy locked, Seg 1–2 built, Seg 3+ open
**Design truth:** [2026-06-20-couple-session-quickplay-design.md](2026-06-20-couple-session-quickplay-design.md) (7 screens, locked decisions, evidence base). This spec is the *build order* over that design — it does not redefine the UX.
**Maps to build plan:** Phase C (entry + airlock) + Phase D (player). Phases A (data) + B (realtime) already built.

> Convention: plain component name = exists / reuse; `Name*` = to build. Segment grammar follows CLAUDE.md Build Protocol: each segment has ONE thing it does, an on-device done condition (build-succeeds is NOT done — feel-is-correct is done), and a may-not-touch constraints list. Bryan runs on device; Claude compile-verifies only.

---

## 1. Goal

Ship the in-person, two-device **quickplay** couple session end to end — Home entry → airlock → in-session player → close + reflection — building **front-end-first as solo-verifiable vertical slices**, and deferring everything that genuinely needs two phones in the room (realtime, push, breakup) to sessions where Bryan has both devices in hand.

## 2. Architecture

- **4-layer, unchanged.** Views read Stores; Stores call Services; Services own I/O; Models are pure. Session presentation routes through `.vaylCover` (the protected contract), never raw `.fullScreenCover`.
- **Front-end-first, local-backed.** Each screen is wired to a local `@Observable @MainActor` store reading the **real** model shapes (`Card`, `Deck`, `CardSession`, `LockInSession`, `SessionPlan`) over a local/mock backing. Swapping the real `RealtimeSessionService` in later is a **one-layer change** (Store→Service), not a rebuild. UI built against real models is not throwaway.
- **Why this order.** The backend backbone (`curated_sessions`, `RealtimeSessionService`, `SyncManager`, the `@Model` types) already exists, so model-first buys nothing. The *hard* backend is two-device realtime + push, which is the worst thing to build blind — it needs two phones and Bryan's hands. Front-end is what's dated, compile-verifiable solo, and de-risks the thing that matters: feel.

## 3. Tech stack

SwiftUI (Swift 6, iOS 16+ baseline, iOS 26 SDK), SwiftData (`@Model` + `ModelContext` created fresh at write time), `@Observable @MainActor` stores, Supabase (`RealtimeSessionService`, `curated_sessions`, `SyncManager` queue) — wired only in two-device segments. Design tokens only (`AppColors`/`AppFonts`/`AppSpacing`/`AppRadius`/`AppAnimation`/`AppGlows`/`AppElevation`).

---

## 4. Current state (already built)

These landed this session and are on disk (a build-DB lock blocked the final compile-verify; re-verify on next clean build):

- **`Vayl/Design/Components/Navigation/VaylPresentation.swift`** — the missing presentation infra the contract mandated but was never written. Provides:
  - `.vaylCover(isPresented:confirmOnExit:confirmTitle:confirmMessage:confirmDiscardLabel:onExit:content:)` — full-screen cover, `interactiveDismissDisabled(true)`, confirm-on-exit dialog (Duolingo-lesson logic).
  - `.vaylSheet(isPresented:detents:showsGrabber:content:)` — sheet with detents, grabber, `AppColors.modalBackground`.
  - `\.vaylDismiss` environment action (`VaylDismissAction`) — protected content calls `vaylDismiss()` to request a guarded exit (`confirm: true` surfaces the dialog; `confirm: false` leaves immediately, e.g. at a natural session close). A raw `dismiss()` bypasses the guard — always use `vaylDismiss`.
- **`Vayl/Features/Sessions/CardSessionContainerView.swift`** — the single `.vaylCover` destination stub. Takes `hand: [Card]`, renders the void shell + "THE HAND / N cards" + a Close button that calls `vaylDismiss()`. The phase machine (lock-in → player → close) replaces its body in later segments.
- **`Vayl/Features/Home/Views/HomeDashboardView.swift`** — handoff wired: `@State private var sessionHand: [Card]?`, passes `onStartHand: { hand in sessionHand = hand }` into `CardChestContainer`, and presents `.vaylCover(isPresented: sessionHand != nil) { CardSessionContainerView(hand: sessionHand ?? []) }`. The dead-end (hand went nowhere) is closed.
- **`Vayl/Features/Sessions/SessionStore.swift`** — existing single-device card-player brain: `currentIndex`, `recordAndAdvance(status:)`, `saveSession()` writing `CardSession`/`CardResult`/`DeckProgress` + enqueuing `SyncManager` sync. This is the seed the in-session player store extends/wraps.

**Reuse (verified to exist):** `VaylCardFace`, `VaylButton`, `CardCarousel`, `CardChestContainer`, `SpectrumBulletRow`, `OBSheetChrome`, `ScreenshotProtectionModifier`, `SafeWordButton`, `RealtimeSessionService`, `SyncManager`, `SessionPlan`, `LockInSession`, `Card`/`Deck`/`CardSession`/`CardResult`/`DeckProgress`.

---

## 5. Segment build order

### Solo / autonomous-safe (no second device, compile-verifiable)

#### Seg 1 — Presentation infra + handoff  ✅ BUILT (re-verify build)
- **Does:** create the `.vaylCover`/`.vaylSheet`/`vaylDismiss` infra and turn the Home carousel hand into a real, demoable protected cover.
- **Files:** `Design/Components/Navigation/VaylPresentation.swift` (create), `Features/Sessions/CardSessionContainerView.swift` (create), `Features/Home/Views/HomeDashboardView.swift` (modify — `sessionHand` state + `onStartHand` + `.vaylCover`).
- **Done (on device):** "Start · N cards" presents a protected cover; the cover cannot be swiped away; Close → confirm dialog → leave works.
- **May not touch:** `VaylCardFace` shell, `CardChestContainer` selection internals, any Service/network.
- **Status:** code on disk; **next action is a clean build to clear the stale build-DB lock and confirm compile.**

> Note: the original plan split this as Seg 1 (carousel feel pass) + Seg 2 (handoff). The carousel *feel* re-tune (its hand-tuned springs) is deliberately deferred — retuning documented intentional springs blind would be gambling. It folds into Seg 3's on-device pass. What shipped is the low-regret structural half.

#### Seg 3 — Lock-in UI (airlock, local)  ← next
- **Does:** build the airlock — Screen 1A (house rules guidebook) + Screen 1B (bandwidth + hold-to-lock-in) + Screen 2 (phones-down transition) — driven by an `AirlockStore*` with a **mock partner-present flag** (no realtime).
- **Files:**
  - Create `Features/Sessions/AirlockStore.swift` — `@Observable @MainActor`; state: `bandwidth: Double`, `selfHolding: Bool`, `partnerPresent: Bool` (mock, default `true`), `bothLocked: Bool`; the 3-sec hold timer; emits `onLockedIn`.
  - Create `Features/Sessions/AirlockView.swift` — 1A `SpectrumBulletRow` rules + 1B `BandwidthSlider*` + `HoldToConfirm*` + the phones-down `✦` transition. Reuse `OBSheetChrome` chrome, `LivingText`, `VaylButton`.
  - Modify `Features/Sessions/CardSessionContainerView.swift` — host an internal phase enum (`.airlock` → `.player` → `.close`); airlock is the first phase before the hand stub.
- **Done (on device):** airlock renders on `AppColors.void` + `AtmosphereView`; bandwidth slider moves; the 3-sec hold ring fills and "releases" into the transition **solo** (mock partner auto-present); phones-down beat holds ~2–3s then reveals the hand. Reduce-Motion → static mark.
- **May not touch:** `RealtimeSessionService` (presence is a local mock), `RealtimeSessionService.advance`, the carousel, `VaylCardFace` shell, Onboarding.
- **Gated on:** house-rules copy confirm (design §7 #4) — use the 6 placeholder rules until Bryan edits.

#### Seg 4 — In-session player (Screen 3, local)  *(the heart)*
- **Does:** the in-session loop on one device — fan deck / hold-to-deal, prompt dominant (eyes-up, no countdown), turn cue, `pass`, `we're ready` advance, progress + depth chip, ⏸ — driven by a local player store over the hand.
- **Files:**
  - Create `Features/Sessions/CuratedPlayerStore.swift` (or extend `SessionStore`) — `@Observable @MainActor`; owns `hand: [Card]`, `currentIndex`, `drawer` (alternates), `mockPartnerReady: Bool`; `markSelfReady()` → both-ready (mocked) advances; `pass()`; completion hands off to close. Mirrors `SessionStore.recordAndAdvance` semantics so the real-service swap is one layer.
  - Create `Features/Sessions/CuratedPlayerView.swift` — Screen 3 layout: `VaylCardFace` (prompt), `SessionProgressBar*` (`Card 3 · 8`), depth chip, `PauseButton*`, turn cue, `pass` text button, `VaylButton` (Ready). Screen 4's advance gate is an **inline micro-state** on this view, not a separate screen.
  - Modify `CardSessionContainerView.swift` — `.player` phase renders `CuratedPlayerView`.
- **Done (on device):** a stub hand of N cards deals start→finish on one device; advancing feels right; the prompt reads as glanceable; alternate-drawer flips each card; `pass` skips gracefully; completion transitions to close.
- **May not touch:** `RealtimeSessionService` (advance is mocked locally), whisper card (Seg 5b/deferred), airlock interfaces, `VaylCardFace` shell, `couple_session_records` (legacy), Onboarding.
- **Gated on:** default card count (design §7 #2) — pick a working default, mark it as feel-TBD.

#### Seg 5 — Close + reflection (local) + the one additive backend bit
- **Does:** Screen 7 close → auto-raise reflection (one-word + post-bandwidth slider + optional note) → persists locally; adds the **only** additive backend piece (no two-device dependency): a `session_reflections` table + `@Model SessionReflection`.
- **Files:**
  - Create `Features/Sessions/PostSessionView.swift` — "that's a wrap / you went N cards deep", one-word field, drained↔full slider (writes post-`LockInSession`), `save this session` / `done`. Confirm-on-exit per the cover contract (close uses `vaylDismiss(confirm: false)` — natural end).
  - Create `Core/Models/SessionReflection.swift` — `@Model`; `id`, `sessionId`, `word`, `fullnessAfter`, `note`, `createdAt`.
  - Modify `App/ModelContainer.swift` — register `SessionReflection` in the schema.
  - Add Supabase migration `session_reflections` (additive table, service-role/RLS scoped per the M1 security rule — entitlement-style isolation, never a user-profile column). Wire `SyncManager` enqueue mirroring `SessionStore.saveSession`.
  - Modify `SessionStore`/`CuratedPlayerStore` — on completion write `CardSession`/`CardResult`/`DeckProgress` (existing path) + the new `SessionReflection`.
- **Done (on device):** completing a hand raises the close; submitting persists a `SessionReflection` locally and the existing `CardSession` write still fires; "save this session" offers save-as-`SessionPlan`; Home's most-recent updates.
- **May not touch:** realtime sync of the live session, whisper, push, breakup.

### Needs Bryan + two devices (build together, later — never blind)

#### Seg 6 — Live session wiring
- **Does:** Store → `RealtimeSessionService` CRUD on `curated_sessions`; a single device writes its own row; replaces the player store's mock advance with `advance(expectedIndex:)` (conditional update, server-authoritative — simultaneous taps can't double-advance).
- **Done (two devices):** one device drives a real `curated_sessions` row start→finish.
- **May not touch:** push, breakup.

#### Seg 7 — Two-device realtime
- **Does:** presence + state sync across both phones — replaces `AirlockStore.partnerPresent` and `CuratedPlayerStore.mockPartnerReady` mocks with real presence/Broadcast; both-ready gate; whisper card (Screen 5) simultaneous-reveal if in scope.
- **Done (two devices):** both phones see presence, mutual hold-to-lock-in, synchronized advance.

#### Seg 8 — Push invite
- **Does:** device-token table + edge function to invite a partner into a session. Needs Apple push config (APNs). Notifications use `.Banner` variants (iOS 26 — `Alert` banned).
- **Done (two devices):** partner receives an invite and joins.

#### Seg 9 — Breakup / archival
- **Does:** unlink flow + fix the `Couple` cascade-delete footgun (sessions/reflections must archive, not vanish). Per CLAUDE.md humility: a breakup needs no in-app notification — this is data hygiene, not an engagement surface.
- **Done (two devices):** unlink archives cleanly without orphaning or cascade-deleting history.

---

## 6. The local→real swap boundary

The seam that makes the front-end-first bet safe — exactly one layer changes per mock when devices arrive:

| Mock (Seg 3–5) | Real (Seg 6–7) | Layer that changes |
|---|---|---|
| `AirlockStore.partnerPresent = true` | `RealtimeSessionService` presence | Store only |
| `CuratedPlayerStore.mockPartnerReady` | `RealtimeSessionService` Broadcast | Store only |
| local `currentIndex += 1` advance | `advance(expectedIndex:)` conditional update | Store only |
| `SessionReflection` local write | already real (additive, Seg 5) | none |

Views, model shapes, and the `.vaylCover` phase machine stay fixed across the swap.

---

## 7. Cross-cutting rules (from design §6 — enforce every segment)

- `.vaylCover` from airlock → close: dismiss-disabled, confirm-on-exit. Card Session is **never** a sheet.
- `.screenshotProtected()` on whisper + any private input.
- Keep-awake + dim-after-idle via `connectedScenes` — never `UIScreen.main`.
- Reduce-Motion fallbacks on the transition + every looping mark (`.ambientAnimation`).
- Design tokens only; OB card faces stay 1D outline + spectrum + `.drawingGroup()`.
- OB voice = individual ("you"/"I"), never "we"/"our" — each partner onboards alone.
- No em dashes in copy.

---

## 8. Open questions carried from design §7

Blocking nothing in Seg 1–5 except as noted: **#2 default card count** (Seg 4), **#4 house-rules copy** (Seg 3). The preset spine (#1), advance-gate mutual-vs-either (#3), and the feel calls (#5–8) resolve on device during their segment. Close depth (#9) and airlock public name (#10) are later/cosmetic.

---

## 9. Build log

**2026-06-21 — Seg 3–5 built front-end in one pass (BUILD SUCCEEDED, compile-only; feel pending on device).**

Built from the four mockups (`docs/prototypes/couple-session-{carousel,airlock,hero-v2,close}.html`):

- `Vayl/Core/Models/SessionReflection.swift` — `@Model`, registered in `SchemaV1`. Device-only.
- `Vayl/Features/Sessions/SessionAtmosphere.swift` — void + breathing spectrum aurora + A/B turn tint (app-wide tokens only, not OB-table tokens).
- `Vayl/Features/Sessions/CoupleSessionStore.swift` — **one** store for the whole cover (phase machine + airlock + player + close + persistence).
- `Vayl/Features/Sessions/AirlockView.swift` — 2×2 house rules + bandwidth segmented control + hold-and-release sync ring (tolerance 0.13).
- `Vayl/Features/Sessions/SessionPlayerView.swift` — fan deck, hold-to-deal (card pulls from the fan ∝ hold, dives on commit), drawer ceremony, hero prompt, care-mark `.vaylSheet`, presence, idle dim.
- `Vayl/Features/Sessions/SessionCloseView.swift` — landing beat + auto-raised reflection `.vaylSheet` (multi-select `FlexibleWrap` word bank + two `ReflectionSlider`s + optional note).
- `CardSessionContainerView.swift` — rewritten as the phase machine (airlock → transition → session → close → done); builds the store from `@Environment`, owns the guarded exit.
- `VaylPresentation.swift` — `vaylDismiss` now takes `confirm: Bool`; the close uses `confirm: false` (natural exit).

**Deviation:** §5 named `AirlockStore` + `CuratedPlayerStore`; built as one `CoupleSessionStore` instead — the phases share one hand, one bandwidth, one card-result ledger, and one end-of-session write, so splitting would only add cross-store coordination. The local→real swap boundary (§6) is unchanged: all mocks (`partnerPresent`, partner release point, advance) live in that one store.

**Feel-gated (ported from mockups, tune on device, not blind):** sync-ring fill 3.2s; hold-to-deal 0.85s; dive 0.82s; idle-dim 3.6s. Carousel feel re-tune (Seg 1 note) still deferred.

**Still mocked / deferred to the two-device segments (6–9):** real presence, partner-ready, server-authoritative advance, whisper card, push, breakup.

**2026-06-21 — mockup-fidelity pass (BUILD SUCCEEDED).** Closed the audit gaps per `docs/superpowers/plans/2026-06-21-couple-session-mockup-fidelity-fixes.md`: prompt keyword highlighting, card 3D deal-flip, warp flash, screenshot protection on sensitive cards, keep-awake, breathing sync-ring glow, the sync-tutorial "i" sheet, airlock copy, carousel "tap to add" hint + fly-to-corner ghost, and the "Settle in →" CTA. Documented divergences kept: drawer says "Partner" (no partner-name plumbing) and carousel depth label deferred (no clean data mapping).
