# Weekend Build Plan — Sunday Core Loop + Mon/Tue Polish

**Date:** 2026-06-20
**Branch:** `spec/contextphase-2x3-redesign`
**Author:** Bryan + Claude (code-grounded pass)
**Status:** Planning. Every claim below was verified against the source on 2026-06-20.

---

## Today's work (June 20) — shipped

The whole day was the **paywall layer**, committed in sequence:

- `0e4397a` Reusable `PaywallSheet` + `SpectrumBulletRow` (the reveal "door")
- `d22b23e` On-device polish pass + handoff doc
- `052dde6` Tri-color spectrum bloom behind the reveal hook
- `a5faeff` Content-height layout refactor, spacing rhythm, hero rewrite, tappable footer
- `d9fbd1f` Accessibility pass + Dynamic Type scroll backstop
- `3485b80` `LegalLinks` source-of-truth + `SafariView` wrapper
- `f362b4f` Restore Purchases → `EntitlementStore.restore()`
- `4250746` Terms/Privacy wired in paywall + sign-in
- `9bdd879` Code-review fixes on legal/restore

Net: `PaywallSheet` exists at `Vayl/Features/Monetization/Views/PaywallSheet.swift`, fully styled,
legal + restore wired. **It is not yet consumed by the Desire Reveal** (see Sunday item 5).

---

## Sunday (June 21) — the core loop

Reality check up front: **the session loop is more built than it feels, and the solo-deck work is
less defined than it sounds.** Three items are "verify on device + small fixes," two are genuinely
done, and one (solo openers) needs a product decision before any code.

### 1. Cards / Session feature — WIRE + VERIFY

**State: the whole chain exists and compiles.**

- `CardCarousel.swift:467` fires `onCardAction?(cards[i], .startSession)` on tap.
- `CardChestContainer.swift:10,138` forwards `onCardAction` straight through to the carousel.
- `HomeRouterView.swift:216` `handleCardAction(.startSession)` builds a `SessionStore` and sets
  `activeSession`.
- `HomeRouterView.swift:74` presents it via `.sheet(item: $activeSession)`.
- `SessionStore` is complete: `recordAndAdvance(status:)` logs result, advances, and on the last
  card calls `saveSession()` → writes `CardSession` + `CardResult[]` + `DeckProgress`, then enqueues
  a Supabase sync task.
- `SessionView` is complete: top bar, card text, progress pips, Skip / Bookmark / Discussed,
  session-complete summary screen.

**Gaps (in priority order):**

1. **Solo / unpaired play does not persist.** `SessionStore.saveSession()` (line 130) and
   `updateDeckProgress()` (line 214) both early-return when `appState.coupleId == nil`. A solo user
   playing the deck gets no `DeckProgress`, no resume point, no history. This directly collides with
   Sunday item 3 (solo deck). **Decision needed:** persist solo sessions against `userId`
   (mirror the `SoloSession` model that already exists) or accept solo as ephemeral for V1.
2. **Session is a `.sheet`, not a `.vaylCover`.** The nav contract (CLAUDE.md) says Card Session is
   *always* a cover: dismiss-guard + confirm-on-exit. Today a mid-session swipe-down silently
   abandons. Swap `.sheet(item:)` → `.vaylCover` at `HomeRouterView.swift:74`.
3. **Card rendering is plain `Text`.** `SessionView.cardArea` (line 107) renders
   `store.currentCard?.text` as a centered string — no `VaylCardFace`, no atmosphere, no spectrum.
   Acceptable for a smoke test; flag as a fidelity pass, not a blocker.

**Done condition:** on device, tap a deck card on Home → cover opens → deal through cards →
Skip/Bookmark/Discussed each register → last card → summary screen → Done dismisses → re-open
resumes at the right index (paired) or behaves per the solo decision.

**Files:** `Features/Sessions/SessionStore.swift`, `Features/Sessions/SessionView.swift`,
`Features/Home/Views/HomeRouterView.swift:74,216`.

---

### 2. OB — BuildDeck path — VERIFY ON DEVICE

**State: code-complete.** All seven beats are choreographed in `BuildDeckPhase.swift` (melt → float
→ arm → 3-strike crack → spark cascade → deck carousel browse → founder letter). `BuildDeckCeremony`
holds foil-tear state.

**Gaps:** this is a *feel/verify* item, not a build item.

1. Run the full OB → BuildDeck → founder letter → Home handoff on device.
2. Watch for the known scar from the 2026-06-17 audit: ceremony state leaking into the persistent
   felt (the `dissolutionT`-never-reset pattern). Confirm felt is clean after the letter.
3. `WelcomeDeck.of(openerDeckType)` (`BuildDeckPhase.swift:87`) reveals a typed welcome deck, but its
   cards are **placeholders** (`WelcomeDeck.placeholderCards`). The reveal name/purpose/colorway are
   real; the six prompt cards are stand-ins. This ties into item 3.

**Done condition:** full run-through on device with no felt scarring; the reveal reads as personal.

**Files:** `Features/Onboarding/Phases/BuildDeckPhase.swift`,
`Features/Onboarding/Director/BuildDeckCeremony.swift`,
`Features/Onboarding/Canvas/VaylDirector.swift:368`.

---

### 3. Solo deck — "his & hers openers" — DECISION FIRST, THEN CONTENT

**This is the least-defined item and needs a product call before code.**

What exists today:

- `OpenerDeckType` (`AppOBEnums.swift:208`) has **four register-based variants**:
  `anxious / excited / reflectiveCalm / reflectiveOpen`.
- `VaylDirector.evaluateOpenerDeckType()` (line 368) assigns one silently from
  `(NMStage × SituationalRegister × curiosity richness)`.
- It is persisted: `OnboardingStore.swift:138` writes `profile.openerDeckType`.
- `WelcomeDeck.of(_:)` maps those four to named welcome decks (STEADY / OPENING / RETURN / WIDER)
  with **placeholder cards**.
- **Only one real playable deck exists:** `Resources/Decks/the-opener.json` (10 cards, couple-first,
  generic). `deck-index.json` literally reads `["the-opener"]`.
- **Nothing consumes `openerDeckType` for session play.** `HomeStore.loadDeck()` (line 313)
  hardcodes `ContentLoader.loadDeck(id: "the-opener")`. The typed opener influences only the OB
  welcome reveal and a stored profile field.

**The open question — "his and hers" is a brand-new axis.** There is no gender-based deck concept
anywhere in the code. The existing variation axis is *emotional register*, not gender. So "his/hers
openers" can mean one of:

- **(A) Gender-keyed variants** — a new axis on top of (or replacing) `OpenerDeckType`, e.g. resolve
  the deck from `UserProfile.gender`. New concept, new content, new resolution path.
- **(B) Rename the register variants** — "his/hers" is just informal shorthand for the 4 existing
  typed openers, and the real work is authoring their card content + wiring `loadDeck`.
- **(C) Solo-vs-couple split** — "solo opener" = a single-player deck distinct from `the-opener`
  (which is two-device), and "his/hers" is a within-solo personalization.

**Recommendation:** (B) for V1 unless there's a strong product reason for gender-keyed decks —
the register axis is already earned through onboarding and is psychologically grounded; a gender
axis is a new content-authoring burden with weaker justification (and cuts against the humility
test if it's cosmetic). Confirm before authoring.

**Work once decided (assuming B):**

1. Author real card content for the chosen opener variants (JSON in `Resources/Decks/`,
   add ids to `deck-index.json`).
2. Resolve deck id from `UserProfile.openerDeckType` in `HomeStore.loadDeck()` and the Play tab.
3. Reconcile with item 1's solo-persistence decision.

**Files:** `Core/Models/Enums/AppOBEnums.swift:208`, `Features/Onboarding/Models/WelcomeDeck.swift`,
`Features/Home/Store/HomeStore.swift:313`, `Resources/Decks/*.json`,
`Core/Models/UserProfile.swift:55`.

---

### 4. Getting Started milestones — DONE (verify only)

**State: fully built and clean.** The "phases / milestone objects" already exist as
`GettingStartedStepKind` + `GettingStarted.resolve()`:

- Four steps: `profile → mapDesires → invitePartner → seeReveal`, each titled + subtitled.
- `GettingStarted.resolve()` derives state purely from `(myMapComplete, isPaired,
  partnerMapComplete, revealDone)`; exactly one step is `.active`; `seeReveal` is gated on both maps.
- Rendered by `GettingStartedEntryCard` (compact, on Home) and `GettingStartedPathView`
  (matched-geometry overlay). Step taps route through `HomeRouterView.handleStep()`.

**Gaps:** minor, non-blocking.

1. `HomeStore.stageIndex` is hardcoded to `1` (no Stage model yet) — only matters if it's user-visible.
2. `resolveDesireMapState` has a TODO: partner completion isn't tracked locally when unlinked.
3. `handleStep` has a TODO(Moments) hook for a future warm event when a step advances.

**Done condition:** on device, walk all four steps and confirm each routes correctly and the active
step advances as flags flip.

**Files:** `Features/Home/GettingStarted.swift`, `Features/Home/Views/GettingStartedPathView.swift`,
`Features/Home/Components/GettingStartedEntryCard.swift`, `Features/Home/Views/HomeRouterView.swift:240`.

---

### 5. Desire Map deep pass — WIRE PAYWALL + TUNE BEATS

**State: structure + live data complete; today's `PaywallSheet` not yet plugged in.**

- `DesireRevealView` renders header → unlocked matches → locked teasers → request row, with a staged
  `appeared`-driven reveal animation (delays at lines 75/84/91/96).
- `DesireRevealStore` resolves the free/locked split from `DesireSyncService.fetchMatches`
  (alignment-only — never raw answers). `unlockedMatches` / `lockedMatches` / `lockedCount` derived.
- The reveal **already has an inline `unlockCTA`** (line 189) that calls `store.unlockAll()` →
  `entitlements.purchase()` directly (M2). It is *not* the new `PaywallSheet`.

**Gaps:**

1. **Wire `PaywallSheet` into the reveal.** Today's styled sheet is unused here. Decision: replace
   the inline `unlockCTA` (or its button action) with a `.vaylSheet` presenting `PaywallSheet`. The
   store comment at `DesireRevealStore.swift:104` explicitly anticipates this ("M5 … can replace this
   entry with a richer sheet").
2. **Tune the 3-beat choreography on device** — appear → first/free match → locked teasers →
   paywall. The structure is there; the timing hasn't been felt.
3. **`requestHiddenConversation()` is a no-op** (`DesireRevealStore.swift:114`) — the "Ask about
   something you didn't match on" row does nothing. Open design decision: notify partner? queue a
   discussion card? Either define it or hide the row for V1.
4. Post-purchase **unlock-in-place** animation is deferred (Segment 2) — mark it explicitly so it
   isn't mistaken for a bug.

**Done condition:** free couple sees one match + locked teasers; tapping unlock presents the styled
`PaywallSheet`; the staged reveal feels paced, not abrupt.

**Files:** `Features/Desire Map/Views/DesireRevealView.swift:189`,
`Features/Desire Map/Store/DesireRevealStore.swift:104,114`,
`Features/Monetization/Views/PaywallSheet.swift`.

---

### 6. Home carousel → Session routing — DONE (verify only)

**State: the routing chain is complete** (same chain as item 1). `CardCarousel → CardChestContainer
→ HomeDashboardView → HomeRouterView.handleCardAction → SessionStore → presentation`.

**Gaps:** same two as item 1 — verify the `onCardAction` callback actually propagates end-to-end on
device, and convert the presentation to `.vaylCover`. There is no separate routing work here beyond
item 1; treat 1 and 6 as one task.

---

## Monday / Tuesday (June 23–24) — polish + scaffolding

### A. Pulse overhaul — frontend + backend

**Reality check:** the frontend is substantial, but **there is no backend at all** — "not a lot of
work" undersells the backend half.

- Views built: `PulseFullView`, `DailyCheckInView`, `CheckInShell`, `PulseGraph`, `PulseSheetView`,
  `PulseDotSummary`, `PulseWidget`, `TierGuideSheet`, `PulseCanvasScrollView`.
- `PulseStore` persists to **UserDefaults** (`pulse.entries.v1`) as a JSON blob. It is **not**
  `@MainActor`, **not** SwiftData, **not** injected, and has **no sync service**. This deviates from
  the 4-layer Store pattern every other store follows.
- `LockInSession` model (bandwidth check-in) exists and is fully built, but is device-only by design.

**Work:**

1. Audit what's actually wired on Home — `HomeWidgetShell` supports a `.pulse` case but confirm
   `PulseWidget` is placed in `HomeDashboardView` and reads real entries.
2. Backend is net-new: decide whether Pulse syncs across the couple at all (humility test — does a
   partner need to see your daily pulse, or is it private?). If it syncs: SwiftData model + sync
   service + Supabase table + RLS, mirroring the Desire Map pattern. If private: migrate
   UserDefaults → SwiftData for durability and move on.
3. Frontend: refactor `PulseStore` to `@MainActor` + injected container to match the architecture;
   resolve the `Color(hex:)` token TODOs in `PulseSheetView` / `PulseGraph`.
4. Presentation: Pulse check-in = `.vaylSheet` (discrete task) per the nav contract.

**Files:** `Features/Pulse/**`, `Core/Models/PulseEntry.swift`, `Core/Models/LockInSession.swift`.

### B. Placeholder content hub

- No Swift implementation exists; the design lives in `docs/mockups/learn-tab.html`.
- Build a minimal tab: 4–6 glossary terms + 2–3 research summaries, hardcoded, enough to feel the
  UI/UX and the **sharing presentation** logic.
- Define what "share a term" produces (a card? a sheet?) before building it.
- Do **not** build the flavor quiz or research-ingestion pipeline (parked).

### C. Partner pill / hub — design first

- `PartnerChipState` enum exists (`None / InvitePending / Nudge / Active / MultipleActive`);
  `PartnerChip.swift` component exists. Per memory, this is deferred to a whole-home-tab pass.
- Decide what the hub shows (presence? desire-map status? nothing when unpaired?) and what tapping it
  does. Settled scope from memory: v1 = presence + desire-map status; date/event reminders cut.
- Then build the small surface.

### D. Home tab + tab bar revamp

- 9 Home prototypes in `docs/prototypes/home-*.html`; tab-bar redesign mockups ready but deferred.
- Full-screen Home audit on device with all live components (deck chest + partner chip + getting
  started + desire-map indicator + reflection card). Check hierarchy and breathing.
- Tab bar: bring in line with the void + spectrum + glass palette. Reference
  `docs/prototypes/app-routing-map.html` for the 4-tab decisions.

---

## Cross-cutting decisions to make before Sunday code

1. **Solo session persistence** (item 1 gap 1 + item 3) — persist against `userId` via `SoloSession`,
   or accept ephemeral solo for V1?
2. **"His & hers" opener definition** (item 3) — gender axis (A), rename register variants (B,
   recommended), or solo-vs-couple split (C)?
3. **Desire Reveal `requestHiddenConversation`** (item 5 gap 3) — define behavior or hide for V1?
4. **Pulse sync** (Mon/Tue A) — couple-shared or private-only? Drives whether backend is a table or
   just a SwiftData migration.

These four are the real forks. Everything else is verify-on-device or known content authoring.
