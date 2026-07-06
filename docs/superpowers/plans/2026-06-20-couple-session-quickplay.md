# Couple Card Session — Quickplay: Segmented Build Plan

> **For each build session (a fresh "opus max"):** This plan follows Bryan's CLAUDE.md **Build Protocol**, not TDD micro-steps. Every segment = ONE thing · a *Discuss UI/UX first* gate (settle the feel before any code) · a done-condition **verified on device** (feel is correct, not build-succeeds) · a may-not-touch list. Confirm what you're building before writing code. Claude compiles to verify; **Bryan runs the app on device** and confirms feel.

**Goal:** Build the in-person, two-device **quickplay** couple card session end-to-end — Home entry → airlock → eyes-up card loop → close.

**Architecture:** 4-layer (View → Store → Service → Model). A new `CuratedPlayerStore` (couple loop) drives a redesigned player view; `RealtimeSessionService` (already built) is the server-authoritative transport over the `curated_sessions` table; SwiftData persists results. Built **inside-out**: the card loop first (one device), then sync, then the wrapper (airlock, entry, close).

**Tech stack:** SwiftUI · `@Observable @MainActor` stores · SwiftData · Supabase Realtime (`supabase-swift` 2.41.1) · design tokens only.

**Spec:** `docs/superpowers/specs/2026-06-20-couple-session-quickplay-design.md` (read it — wireframes + locked decisions + the research base).

---

## Shared context — read before any segment

**What already exists (reuse, don't rebuild):**
- `Vayl/Features/Sessions/SessionPlan.swift` — `@Model` with `id, coupleId?, deckId, deckVariant?, title, orderedCardIds, perCardTimerSeconds, globalTimerSeconds?, isPreset, isLDR, createdAt, lastUsedAt?` + `static func stub(coupleId:)`. Registered in `SchemaV1`.
- `Vayl/Core/Services/RealtimeSessionService.swift` — transport. Key methods:
  - `openSession(coupleId: UUID, initiatorId: UUID, draft: CuratedSessionDraft) async throws -> CuratedSessionDTO`
  - `fetchOpenSession(coupleId: UUID) async throws -> CuratedSessionDTO?`
  - `setBandwidth(sessionId:role:value:Float)` · `setConsent(sessionId:role:consented:)` · `setPresence(sessionId:role:present:)` · `setStatus(sessionId:status:)`
  - `advance(sessionId: UUID, expectedIndex: Int) async throws -> Bool` (conditional — false if partner already advanced)
  - `sessionChannel(coupleId:userId:) -> RealtimeChannelV2` · `trackPresence(on:userId:)` · `leaveChannel(_:)`
  - Types: `CuratedSessionDraft(deckId, deckVariant, cardIds, perCardTimer, globalTimerSeconds)`, `CuratedSessionDTO` (`id, coupleId, initiatorId, deckId, cardIds, status, currentIndex, aPresent, bPresent, aBandwidth?, bBandwidth?, aConsented, bConsented, timerStartedAt?, safeWordUsed, …`), `enum SessionRole { case a, b }`, `enum CuratedSessionStatus { lobby, airlock, active, paused, complete, abandoned }`.
  - **NOT built yet:** a postgres-changes row stream (`sessionRowUpdates`) and broadcast — Segment 2 adds these.
- `Vayl/Features/Sessions/SessionStore.swift` + `SessionView.swift` — the **existing one-device player** (renders a card, `recordAndAdvance(status: CardStatus)`, `saveSession()` writes `CardSession`/`CardResult`/`DeckProgress`). Reuse its persistence pattern; do **not** overload it for the couple loop.
- Models: `CardSession(coupleId, deckId, startedAt, completedAt?, sessionNumber, cardsAttempted/Discussed/Skipped/Bookmarked, lockInBandwidthA?, lockInBandwidthB?, cardResults[])`, `CardResult(sessionId, cardId, status: CardStatus)`, `DeckProgress(coupleId, deckId, currentCardIndex, completedAt?, …)`, `LockInSession(cardSessionId, partnerABandwidth, partnerBBandwidth, bandwidthGap, isLDR, …)`.
- `Card` (`id, deckId, text, highlightWords, type: CardType, intensity, whoStarts, isSensitive, canSkip, sortOrder, …`) · `Deck.orderedCards` · `ContentLoader.loadDeck(id:) throws -> Deck`.
- Components: `VaylCardFace(question:credential:content:onAction:isFront:confirmed:)` · `CardCarousel(cards:onCardAction:…)` · `VaylButton(label:style:size:isLoading:isDisabled:action:)` (styles `.primary/.secondary/.ghost/.gold`, sizes `.fullWidth/.compact/.pill(width:)`) · `SpectrumBulletRow(text:phaseOffset:font:)` · `.cardStyle(...)` · `SpectrumHairline` / `TaperedSpectrumHairline` · `.spectrumBorderGlow(intensity:)` · `.screenshotProtected()`.
- `AppState` — `appMode`, `linkState`, `coupleId: UUID?`, `selectedTab`. `ModelContainer` → `SchemaV1.models`.

**Hard corrections (memory was stale):** `.glassCard()` and `.hairline()` **do not exist** — use `.cardStyle()` and `SpectrumHairline`. `AtmosphereView` does **not** exist for the main app — use `AppColors.auroraBlob1/2` radial blobs (or `OnboardingAtmosphere`, OB-only). Card radius for full cards = `AppRadius.container` (20), not `.lg`.

**Token discipline (every segment):** zero raw colors/fonts/spacing/radius/opacity/durations in views. No `UIScreen.main`. Reduce-Motion fallback on every looping animation (`.ambientAnimation`). 4-layer separation: Views read Stores; Stores call Services; Services never import Views/Stores; fresh `ModelContext` at write time.

**Never touch (all segments):** Onboarding (`Vayl/Features/Onboarding/**`), `VaylCardFace` shell internals, `VaylCardModel`, `PlayView` (reserved for generative), legacy `couple_session_records`/`SessionSyncService`.

---

## Segment sequence

| # | Segment | Feel-validates | Depends on |
|---|---------|----------------|------------|
| 1 | In-session player (one device, debug) | the card loop rhythm | — |
| 2 | Two-device sync | both phones move together | 1 |
| 3 | `.vaylCover` / `.vaylSheet` foundation | confirm-on-exit guard | — |
| 4 | The Airlock | the friction + priming | 2, 3 |
| 5 | Home quickplay entry + transition | the full top-to-bottom path | 4 |
| 6 | Close / post-session | the bounded ending | 2 |
| 7 | Whisper card | the reveal moment | 2 |
| 8 | Pause / re-center | the chill-pill | 4 |

After **Segment 6** a couple can play a full quickplay session start→finish. 7–8 are enrichments.

---

## Segment 1 — In-session player (one device, debug bypass) · THE HEART

**One thing:** render the eyes-up card loop and advance through a stub session on a single device, behind a debug entry — no realtime, no airlock.

**Discuss UI/UX first (settle the feel, then code):**
- **In-session layout (#7)** — the prompt must dominate; minimal chrome; glanceable enough to read aloud and set the phone down. *Rec:* `VaylCardFace(question: card.text)` centered, `AppFonts.prompt`; top row `Card N · M` + depth chip + ⏸; bottom `pass` (text) + `we're ready →` (`VaylButton .primary .compact`); no countdown anywhere.
- **Default card count (#2)** — *Rec:* stub of **6** for feel; real default **8**.
- **Turn cue + read-aloud framing (#5)** — *Rec:* a soft line under the prompt: `✦ Your draw — read it aloud`, alternating drawer label by index; responsiveness stays taught-up-front (Segment 4), not an in-card step.
- **Advance affordance feel** — one device here = a simple Next; the both-ready gate arrives in Segment 2. *Rec:* tapping `we're ready` advances immediately in this segment.

**Build:**
- Create `Vayl/Features/Sessions/CuratedPlayerStore.swift` — `@Observable @MainActor`. Init with `cards: [Card]` (from `ContentLoader.loadDeck(id:"the-opener").orderedCards`, trimmed to count) + `modelContainer` + `appState`. State: `currentIndex`, `drawerRole: SessionRole` (alternates each advance), `isComplete`. Methods: `var currentCard: Card?`, `func advanceLocal()` (bump index, flip `drawerRole`, set `isComplete` at end), `func passCard()` (advance, mark skipped). Mirror `SessionStore.saveSession()` for completion (write `CardSession`/`CardResult`/`DeckProgress` with a fresh `ModelContext`).
- Create `Vayl/Features/Sessions/CuratedPlayerView.swift` — renders the Screen 3 layout from the spec using `VaylCardFace`, `VaylButton`, tokens. Reads `CuratedPlayerStore` only.
- Add a `#if DEBUG` entry: a temporary button (e.g. in `PlayView` or a debug menu) that pushes `CuratedPlayerView` with a stub store. (Does **not** need `.vaylCover` yet.)

**Done (on device):** a 6-card stub plays start→finish; advancing feels right; the prompt reads as glanceable/eyes-up; `pass` skips; completion persists a `CardSession` (verify via log). **Bryan confirms the rhythm feels right** — that is the done condition.

**May not touch:** `RealtimeSessionService`, airlock, `.vaylCover`, `SessionStore`/`SessionView` (legacy — leave intact), `PlayView` beyond a debug entry.

**Unlocks:** Segment 2.

---

## Segment 2 — Two-device sync

**One thing:** make the card loop server-authoritative so both phones show the same card and advance together via the both-ready gate.

**Discuss UI/UX first:**
- **Advance gate (#3)** — both tap *ready* vs either advances. *Rec:* **both-ready** (mutual premise; doubles as the responsiveness gate). Show "✦ you're ready · ◌ waiting for Alex…".
- **Presence/waiting feel** — what the screen shows while waiting for the partner's tap, and on partner disconnect. *Rec:* inline waiting state, no blocking modal.

**Build:**
- Add to `RealtimeSessionService`: `func sessionRowUpdates(coupleId: UUID) -> AsyncStream<CuratedSessionDTO>` using a postgres-changes `UpdateAction` listener on `curated_sessions` filtered `eq("couple_id", …)`. **Register the listener before `subscribeWithError()`**; decode payload → `CuratedSessionDTO`.
- Extend `CuratedPlayerStore`: take a `sessionId: UUID` + `RealtimeSessionService`; subscribe to `sessionRowUpdates`; render `cards[dto.currentIndex]`; resolve `drawerRole` from index parity. Replace `advanceLocal()` with `markReady()` → `setConsent`/a "ready" flag and, when both ready, `advance(sessionId:expectedIndex:)` (conditional — ignore `false` returns; the stream delivers the new index). Completion → `setStatus(.complete)` + persist.
- Determine local role: `SessionRole` from `Couple.partnerAId == myUserId` (mirror existing pairing logic).

**Done (on device, two devices/sims):** both show the same stub card; either taps ready → other sees "waiting"; both ready → both advance together; simultaneous taps never double-advance; completion persists once. **Bryan confirms the two-device feel.**

**May not touch:** airlock, Home entry, `SessionStore`/`SessionView`, the legacy sync layer.

**Depends on:** 1. **Unlocks:** 4, 6, 7.

---

## Segment 3 — `.vaylCover` / `.vaylSheet` foundation

**One thing:** build the two presentation modifiers the whole app's nav contract depends on.

**Discuss UI/UX first:**
- **Confirm-on-exit copy + feel** (Duolingo-lesson logic) — *Rec:* swipe-to-dismiss disabled; an attempted exit raises a `.vaylSheet` confirm ("End the session? You can always come back." / "Keep going" · "End"). Settle the wording + whether exit writes `paused` vs `abandoned`.

**Build:**
- Create `Vayl/Design/Components/Navigation/VaylPresentation.swift`:
  - `func vaylCover<Item: Identifiable, C: View>(item: Binding<Item?>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping (Item) -> C) -> some View` — wraps `.fullScreenCover`, applies `.interactiveDismissDisabled(true)`, and a confirm-on-exit guard.
  - `func vaylSheet<…>(item:…)` — wraps `.sheet` with standard detents + grabber + `AppColors`/`AppRadius` background.
- Follow existing `OBSheetChrome.swift` for chrome styling.

**Done (on device):** a throwaway preview presents a dummy view via `.vaylCover`; swipe-down does nothing; the exit button raises the confirm; confirm dismisses. Build compiles clean. (Light feel — Bryan confirms the confirm-dialog feel.)

**May not touch:** existing `.sheet`/`.fullScreenCover` call sites (migrate them in their own later pass — not here).

**Unlocks:** 4, 5.

---

## Segment 4 — The Airlock

**One thing:** the friction gate — house rules → bandwidth + 3-sec hold → both confirm → flip the session to `active`, presented as a `.vaylCover`.

**Discuss UI/UX first:**
- **House rules (#4)** — confirm/edit the 6 (spec §4, Screen 1A); add a phones-down rule? *Rec:* ship the 6 as written; full first session, one-line "settle in" on repeat.
- **Airlock form/gesture (#6)** — how rules present (read-aloud vs swipe) + the 3-sec hold feel. *Rec:* rules on one panel (`SpectrumBulletRow` ×6) → `We're ready` → bandwidth + `HoldToConfirm` with `.spectrumBorderGlow(intensity:)` ramping over 3s.
- **Bandwidth form (#8)** — slider vs low/med/high; informs vs caps depth. *Rec:* a `light ◦──●──◦ deep` slider (0–1, private), **informs** for V1 (don't hard-cap yet).

**Build:**
- Create `Vayl/Features/Sessions/AirlockStore.swift` — `@Observable @MainActor`; `enum AirlockState { rules, bandwidth, holding, waitingForPartner, active }`; owns the `sessionChannel` lifecycle (model on `PresenceDebugStore`), `trackPresence` after subscribe; calls `setBandwidth`/`setConsent`/`setPresence`; idempotent flip to `setStatus(.active)` when both present + both consented; subscribes to `sessionRowUpdates` to observe the partner.
- Create `Vayl/Features/Sessions/AirlockView.swift` (Screens 1A+1B) + `BandwidthSlider` + `HoldToConfirm` subviews. Present via `.vaylCover`. `.screenshotProtected()`.
- On `.active` → present `CuratedPlayerView` (Segment 2 store), seeded from the session row.

**Done (on device, two devices):** both run rules → bandwidth → 3-sec hold; presence shows "waiting for Alex…"; row flips `active` exactly once; both land in the player. **Bryan confirms the friction + priming feel.**

**May not touch:** the player internals (navigate to it), Home entry (Segment 5), `PlayView`.

**Depends on:** 2, 3. **Unlocks:** 5, 8.

---

## Segment 5 — Home quickplay entry + transition

**One thing:** launch a real session from Home — hero (most-recent) + presets → `openSession` → airlock → phones-down transition → player.

**Discuss UI/UX first:**
- **Preset spine (#1)** — occasion vs depth. *Rec:* occasion (`Reconnect / Go deep / Wind down`) — how people reach for it, and it houses the re-center mood. (Biggest conceptual call — settle here.)
- **Hero vs presets layout** (spec Screen 0) + **transition feel** (Screen 2, "put your phones down. look at each other.") — *Rec:* `VaylCardFace` hero + 3 `PresetCard`s; ~2.5s transition over `AppColors.void` + a breathing `✦`.

**Build:**
- Seed 3 author preset `SessionPlan`s (`isPreset = true`) for the opener deck (vary `orderedCardIds`/length).
- Create `PresetCard` view; add the quickplay entry block to `HomeDashboardView` (most-recent `SessionPlan` by `lastUsedAt` + presets).
- On tap: build `CuratedSessionDraft` from the plan → `RealtimeSessionService.openSession(...)` → present `AirlockView` via `.vaylCover` (replace the legacy `.sheet(item: $activeSession)` path in `HomeRouterView` for quickplay).
- Create `Vayl/Features/Sessions/TransitionView.swift` (Screen 2); play between airlock-`active` and card 1.
- On `.task`/`scenePhase == .active`, `fetchOpenSession(coupleId:)` so partner B sees a pending session.

**Done (on device):** tapping a preset on Home opens the airlock; completing it transitions ("phones down") into card 1; the whole path feels continuous. **Bryan confirms the top-to-bottom flow.**

**May not touch:** `PlayView`, the desire-map/reveal presentation paths in `HomeRouterView`, Onboarding.

**Depends on:** 4.

---

## Segment 6 — Close / post-session

**One thing:** the bounded ending — closing beat → optional reflection + post-bandwidth → persist → save/reuse.

**Discuss UI/UX first:**
- **Close depth (#9)** — how much to capture. *Rec:* one-word reflection (optional) + a post-bandwidth slider; `save this session` + `done`. Keep it light.

**Build:**
- Create `Vayl/Features/Sessions/PostSessionView.swift` (Screen 7). Reached when `CuratedPlayerStore.isComplete`.
- Persist reflection + post-bandwidth into `CardSession` (extend `saveSession`-pattern write) and write a `LockInSession` row. Offer save-as-`SessionPlan` (set `lastUsedAt`). Update `DeckProgress`. Confirm-on-exit per `.vaylCover`.

**Done (on device):** finishing the player shows the close; reflection + bandwidth persist; "save" creates a reusable `SessionPlan` that appears as most-recent on Home. **Bryan confirms the ending lands.**

**May not touch:** the player loop, airlock, Home hero rendering beyond reading "most recent."

**Depends on:** 2.

---

## Segment 7 — Whisper card

**One thing:** the one reveal mechanic — both type privately, both seal, simultaneous reveal.

**Discuss UI/UX first:** the private-type + 3-2-1 simultaneous-reveal feel; reveal not stored (unless consented). *Rec:* spec Screen 5.

**Build:**
- In `CuratedPlayerStore`, branch when `card.type == .whisper` (`Card.isRevealMechanic`). Use the `reveal_state` jsonb column + a broadcast event for the 3-2-1; exchange answers at reveal, don't persist.
- Create `WhisperField` subview; `.screenshotProtected()`; presence shows "Alex is writing…" (content hidden).

**Done (on device, two devices):** neither sees the other until both seal → countdown → simultaneous reveal; answers not persisted. **Bryan confirms the reveal moment.**

**May not touch:** standard-card loop, airlock, close.

**Depends on:** 2.

---

## Segment 8 — Pause / re-center (the chill-pill)

**One thing:** an in-session pause that offers reconnection moves and a graceful exit.

**Discuss UI/UX first:** *this whole screen is yours to finalize* (AI-specced). Settle the move list + framing (spec Screen 6). *Rec:* `Pause → pick a move (6-sec hug · say one thing you love · just sit) → resume / end well`.

**Build:**
- Create `Vayl/Features/Sessions/ReCenterSheet.swift`, presented via `.vaylSheet` from the in-card ⏸. `resume` → back to the card; `end well` → `setStatus(.complete)` + Close (a clean end, never `abandoned`).

**Done (on device):** ⏸ opens re-center; resume returns to the same card; "end well" routes to a graceful close. **Bryan confirms the pause feel.**

**May not touch:** the safe-word column semantics (this replaces the framing, not the schema), the standard loop.

**Depends on:** 4.

---

## Self-review (against the spec)

- **Coverage:** every spec screen (0–7) maps to a segment — Home/transition→S5, airlock(1A/1B)→S4, standard card→S1/S2, advance→S2, whisper→S7, re-center→S8, close→S7(post)... ✓. The in-session *responsiveness beat* is taught in S4's guidebook + S1's turn cue (not a hard step) — consistent with the spec.
- **Open questions resolved at the right segment:** #2,#5,#7→S1 · #3→S2 · confirm-exit→S3 · #4,#6,#8→S4 · #1→S5 · #9→S6 · re-center→S8. ✓
- **Type consistency:** real signatures (`advance(sessionId:expectedIndex:) -> Bool`, `CuratedSessionDraft`, `SessionRole`, `CuratedSessionStatus`) used throughout; `CuratedPlayerStore` is the single new player store; `.cardStyle()`/`SpectrumHairline` (not the nonexistent `.glassCard()`/`.hairline()`). ✓
- **Known wrinkle to flag in S2/S5:** `AppShell` uses a local `@State selectedTab` (not `appState.selectedTab`) — fine for in-person quickplay (both open the app together), but note it if routing a partner via a banner.
