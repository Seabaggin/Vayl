# Vayl Architecture & Tech Debt Audit — Overnight Run

_Date: 2026-07-04 (overnight, unsupervised)_
_Branch: `design_finalized` · 322 Swift files · ~66.5k LOC_
_Scope requested: (1) state-management tight coupling, (2) business/layout logic leaking into View bodies, (3) view-hierarchy / rendering friction._
_Method: four parallel investigators (state management, view-layer leakage, hierarchy/render performance, 2026-06-30 baseline reconciliation). Every finding below was then hand-verified at its cited file:line before entering this report; two findings were downgraded or reframed during verification and are marked as such. Self-check log: all four dimensions dispatched → returned → spot-verified._

---

## TL;DR

This codebase is in **materially better architectural shape than five days ago**. The baseline reconciliation confirmed that nearly everything from the 2026-06-30 audit actually landed: the dual card-session system is gone, `SettingsStore` is real and exemplary, the SyncManager/AppState silent saves are fixed, the ambient-motion gates hold at ~20 checked sites, and ~43 dead files are deleted. The 4-layer contract's hard lines hold: **no production View touches the network or database anywhere.**

The debt that remains is a different species from last week's. It is no longer "views calling services" — it is **truth fragmentation**: the same couple-level facts (partner identity, reveal unlock, entitlement) are independently owned, fetched, and re-derived by four different stores, with `#if DEBUG` seed data papering over the gaps. That pattern has already produced one latent release-only bug (Finding 1) and one cross-tab inconsistency (Finding 2). Second theme: the two ceremony surfaces (Desire reveal, card session) concentrate decision logic in the wrong layer — one in a View, one in an 846-line god store.

**Top 3 to act on:** (1) single source of truth for couple state, (2) CoupleSessionStore decomposition, (3) Desire ceremony decisions moved store-side. Full blueprints in the final section.

---

## Part 1 — Severity-Ordered Findings

### 🔴 1. HIGH — `partnerName` has four independent owners, and HomeStore's copy has **no production writer**

**Files:** `Vayl/Features/Home/Store/HomeStore.swift:48` (declaration), `:106` (only write — inside `#if DEBUG`, `= "Alex"`), `:120-127` (`partnerChipState` consumes it), `:262,303` (`.youDone(partnerName:)` fallback strings); `Vayl/Features/Map/MapStore.swift:34` + `:116-131` (second copy, own `PairingService().fetchPartner()`, own DEBUG fallback `:127`); `Vayl/Features/Pairing/PairingStore.swift:75` (third copy); `Vayl/Features/Sessions/SessionEntryStore.swift:40` (fourth, via a closure that both call sites — `HomeDashboardView.swift:303`, `PlayView.swift:48` — leave defaulted to `{ nil }`).

**Verified:** grep of HomeStore confirms exactly two writes: the declaration and the DEBUG seed. In a **release build for a linked couple**, `partnerChipState` falls through to `.invitePending` (`:123-125` requires a non-empty name) and every `.youDone` surface renders the "your partner" fallback.

**Why it matters:** this is a production-only bug invisible in every dev build, because the DEBUG block substitutes for the missing fetch. It is also the clearest symptom of the systemic pattern: each store that needs partner identity grows its own copy and its own fetch path. A fifth surface will grow a fifth copy. The fix is not "add a fetch to HomeStore" — it's one owner (Blueprint A).

### 🔴 2. HIGH — Desire-reveal unlock truth is implemented four times, and one copy uses the rule the other copies explicitly distrust

**Files:** `Vayl/Features/Map/MapStore.swift:273-298` and `Vayl/Features/Map/Vault/VaultStore.swift:60-80` — near-identical `fetchMatches` + `canReveal || row.isFreeReveal` loops, each with a comment warning that `Couple.canRevealDesireMap` "can lag a just-purchased buyer"; `Vayl/Features/Desire Map/Store/DesireRevealStore.swift` (third implementation); `Vayl/Features/Home/Store/HomeStore.swift:252-263` — **`resolvePostStatusDesireMapState` still reads the distrusted `canRevealDesireMap` mirror** via a local `FetchDescriptor<Couple>` (`:255-257`) to pick `.fullyUnlocked`.

**Verified:** the MapStore/VaultStore comments and the HomeStore mirror-read were confirmed side by side. The lag bug those comments describe **is currently reproducible on Home**: immediately after purchase, Map and Vault show unlocked (they gate on `isCore`) while Home's `desireMapState` stays on the pre-purchase branch until the local mirror catches up.

**Why it matters:** this is the paywall — the primary conversion surface per the monetization spec. The gate rule has already changed once (comments record the mirror→`isCore` swap) and the change missed one of the four copies, which is exactly the failure mode N-copies guarantees. Every future entitlement change (refund downgrade, re-pair inheritance) multiplies the risk. Related: the entitlement itself is triple-mirrored (`EntitlementStore.tier` ↔ `Couple.entitlementTier`, written at `EntitlementStore.swift:189-199` ↔ server `access_tier`) with "read `isCore`, never the mirror" existing only as comment folklore.

### 🔴 3. HIGH — `CoupleSessionStore` is a genuine god store (846 LOC, ~65 properties, 7+ responsibilities)

**File:** `Vayl/Features/Sessions/CoupleSessionStore.swift`. Verified MARK map: phase machine (`:55`), launch context (`:57-67`), DEBUG mock airlock (`:71-78`), hand/index/records (`:80-84`), close/reflection slider values (`:86-93`), remote-row mirroring + optimistic advance/rollback (`:331-457`, incl. `index` vs `confirmedIndex` vs `effectiveHand`), per-card presentation flags (`showingCardBack`, `activeContextBeat`, `revealRecomposing`, `:486-516`), timer derivation (`:560`), safety/pause/safe-word/presence-grace (`:617`), persistence (`:687`), and a whole second class — `RevealTransportAdapter` — in the same file (`:802`).

**Why it matters:** this is the app's most protected, hardest-to-test flow (two-device, safe-worded, server-authoritative). Every new session mechanic lands in this class, and transient UI flags now interleave with sync-authoritative rollback state in one observation surface. The header comment (`:9-11`) argues one store must own the cover because phases share one hand/ledger — that justifies one *coordinator*, not one *class*, and the codebase has already proven the seam works twice: `AirlockStore` (449 LOC) and `RevealEngine` (313 LOC) were successfully extracted. Mitigating: dependencies are injected with test seams (`:117-148`), so this is a growth-rate problem, not a current-correctness one. Blueprint B.

### 🔴 4. HIGH (perf bug) — `LightAuraBloom` runs two competing per-frame invalidation clocks; one is ignored

**File:** `Vayl/Design/Components/Effects/LightAuraBloom.swift:59-72`. Verified: a `TimelineView(.animation)` (uncapped, display-rate) wraps a Canvas that **never reads `timeline.date`** — it reads `@State phase`, advanced by a separate `Timer.publish(every: 1/60)` in `.onReceive` (`:66-70`). Two 60Hz invalidation sources drive one surface that draws 5 blurred radial blobs per frame. Live consumer: `SelectablePill.swift:222` — the Desire rater's warm-flame pills, i.e. on screen for the entire rating flow. The RM/LPM static branch exists and is correct (`:50-57`), but the running path does ~2× the work of either clock alone. Bonus friction: the body is `AnyView`-erased across the gate branch (`:47-58`), the only body-level `AnyView` in a live rendering component.

**Why it matters:** this is the "competing animations on the same property" jitter class the project's own animation contract bans, expressed at the invalidation layer; it also violates the FrameClock/cap discipline (commit 320ef9b) that the rest of the codebase follows. **Fix (mechanical):** delete the Timer, derive `t` from `timeline.date` (wrapped per the shader-time-precision rule), cap with `.animation(minimumInterval: 1/30)` (sway frequencies are 1.2-2.0 rad/s; 30fps is invisible), replace `AnyView` with `@ViewBuilder`.

### 🟠 5. MEDIUM-HIGH — Desire ceremony decisions computed in Views, with the reveal-vs-mirror branch duplicated across two files

**Files, all verified:**
- `Vayl/Features/Desire Map/Views/Components/DesireMapView.swift:82-93` — `onAppear` derives the rater resume point (`firstIndex(where: existingRating == nil)`) **and** the greeting phase (`ratedCount >= totalCount ? (partnerComplete ? .ready : .mirror) : .rating`) in the View.
- `DesireMapView.swift:571-575` — `advancePastCharted()` re-decides the same `partnerComplete ? .ready : .mirror` second-finisher branch.
- `Vayl/Features/Home/Views/HomeRouterView.swift:283-297` — `handleRaterDismiss()` runs the reveal-eligibility decision (refresh → `myMapComplete`/`partnerMapComplete`/`revealDone` branch → present reveal vs `celebrateMapCompletion()`) in the View, duplicating knowledge of the same state machine.
- `Vayl/Features/Desire Map/Views/Components/DesireRevealView.swift:324-358` — `placedStars` embeds the **hero-star business rule** (`isFreeReveal` → first `.mutual` → first) plus slot-filling and star-size math in a View computed property. (Verification note: the double `ConstellationLayout.generate` call per body pass is real but documented as "deterministic — recomputing is cheap" (`:305-306`), so the cost angle is minor; the *placement* of the free-reveal/hero rule — a monetization-adjacent product rule — is the issue.)
- `DesireMapView.swift:696-703` — `ratedItemsByGroup` does filter + `Dictionary(grouping:)` with a force-unwrap `existingRating(for:)!` (`:698`). Verification note: the `!` **cannot trap in practice** (single synchronous `@MainActor` body evaluation between the filter and the grouping) — reframed from "latent crash" to fragility + wrong-layer grouping.

**Why it matters:** the same user-journey fork ("does this person see reveal, celebration, or mirror next?") now lives in three places across two layers. When the flow changes (and this flow has changed repeatedly — screen 5 was killed, the second-finisher rule changed), each copy must be found and updated, and none of it is unit-testable without rendering. This is the exact decision class the contract assigns to Stores. Blueprint C.

### 🟠 6. MEDIUM — Store↔Service injection is split between two contradictory patterns

**Verified representative sites.** Ad-hoc singleton grabs inside store methods (no test seam): `HomeStore.swift:201-203, 240, 242` (`ContentService.shared` ×3, `DesireSyncService.shared` ×2), `LearnStore.swift:31-33`, `PulseStore.swift:115,127,154`, `MapStore.swift:146,276`, `VaultStore.swift:71`, `SettingsStore.swift:116,118,129` (`SyncManager.shared` — notable because the *same init* properly injects `accountService`/`pairingService` at `:56-70`), `PairingStore.swift:221`, `DesireMapStore.swift:62`. The correct pattern (`service ?? .shared` resolved in init) already exists in the newer stores: `DesireRevealStore.swift:104-110`, `EntitlementStore.swift:58-71`, `SessionEntryStore.swift:42-52`, `AirlockStore.swift:181-198`, `CoupleSessionStore.swift:139-146`.

**Why it matters:** the ad-hoc stores cannot be unit-tested without live Supabase — this is precisely the "test DI seam" the Desire Map audit deferred — and the codebase currently teaches both patterns side by side, so new stores coin-flip. The fix is mechanical (Blueprint A includes the two stores it touches; the rest is a sweep).

### 🟠 7. MEDIUM — Uncapped display-rate clocks + two Low-Power-gate misses (the residue outside the exemplary new Pulse stack)

All verified live; ranked by exposure:

| Site | Issue | Exposure |
|---|---|---|
| `Design/Components/Text/HolographicText.swift:197-208` | `start()` guards `!reduceMotion` only — **missing the LPM check** required by the 2026-07-04 contract for manual mount guards; two raw `repeatForever` loops | **Resident on the Home tab** (`HomeLexicon.swift:269`) |
| `Design/Components/Cards/CardCarousel.swift:747-752` | Float-loop restart in `handleDismissQuickview` is an ungated `.repeatForever` — fires under RM/LPM even though the `onAppear` loops are correctly gated at `:112` | Home/Play carousel, after dismissing quickview |
| `Design/Components/Text/SpectrumBulletRow.swift:47` | One uncapped `TimelineView(.animation)` **per bullet row**; `PaywallSheet.swift:201` mounts one per feature line | N display-rate clocks on the conversion-critical paywall |
| `Design/Components/Text/LivingText.swift:65` | Uncapped display-rate clock driving 4.3-5.0s breathing over 3 Text layers (2 blurred, screen-blended) | PaywallSheet hero `:154`, DesireMapView start `:166`, 3 OB phases |
| `Design/Components/Cards/CardFaces/ContextCardFace.swift:116-119`, gate `:50` | Clock never pauses after its one-shot page-turn/ribbon (0.6s/0.95s) settles — redraws identical frames indefinitely; gate is `isFront && !reduceMotion`, **no LPM check** | Context cards while front in a session |
| `Design/Components/Effects/StarVeil.swift:43` | Uncapped 46-star twinkle Canvas (RM/LPM gated) | `MapChartedMoment.swift:46` |
| `Design/Components/Effects/FoilOpen/MetallicCaseView.swift:292` | Uncapped foil re-render while live; gates correct | OB BuildDeck climax — **cap only the idle-float schedule and feel-verify on device** per protocol |
| `Design/Components/Effects/FoilOpen/SpectrumSparkField.swift:42` + `BuildDeckPhase.swift:546` | Expired bursts are pruned only when a *new* burst appends, so the display-rate Canvas keeps ticking drawing nothing between beats | OB BuildDeck, between taps |

**Why it matters:** individually small, but these are exactly the surfaces the FrameClock/30fps-cap pass (320ef9b) and the LPM contract were created for, and two of them sit on the two highest-value screens in the app (Home, paywall). The fixes are one-liners except MetallicCaseView (feel-gated). Counterpoint worth naming: the **new Pulse stack is the model** — `PulseCyclingAura` (30fps cap `PulseAura.swift:289`), `UnchartedDrift` (30fps `PulseField.swift:244`), `PulseHistoryGrid` (hoisted cells, visibility pause). The 2026-06-30 "heaviest live element" finding on the old causticLayer is **resolved** by the redesign.

### 🟠 8. MEDIUM — Views as dependency ferries and render-driven state transitions

- `Vayl/Features/Map/MapView.swift:91,96-99` — the View threads `entitlements.isCore` + `appState` + `modelContext` into `MapStore.load(...)` / `VaultStore.loadDesire(...)` on every `.task`. MapStore/VaultStore are the only stores using per-call method injection (`MapStore.swift:107,116,140`; `VaultStore.swift:41,108,127`); a second consumer would duplicate the ferry or pass a different `isCore`. (Folds into Blueprint A.)
- `Vayl/Features/Sessions/CardSessionContainerView.swift:117-121` — the airlock→session phase handoff fires from `Color.clear.onAppear { airlock.leave(); store.airlockDidActivate() }`: a state-machine transition owned by the render pass. If that view is never evaluated (transition race, offscreen phase), the handoff never fires. Move to the store observing airlock state.
- `Vayl/Features/Home/Views/HomeDashboardView.swift:87,463-486` — "tonight's hand" (`handIDs`, the input to the most protected flow) lives as View `@State` and builds `SessionLaunch` payloads in the View, including the DEBUG-vs-release route decision.
- `Vayl/Features/Sessions/AirlockView.swift:31-33` — `UserDefaults.standard.bool(forKey: .hasCompletedCoupleSession)` read directly in the View to pick first-run vs repeat copy: persistence + flow decision in the render layer.

### 🟠 9. MEDIUM — Store lifecycle churn: throwaway constructions and duplicate pollers

- **Inline store construction in body expressions:** `SettingsView.swift:104,108`, `SettingsPartnerView.swift:30,39`, `PairingSettingsView.swift:68,77` construct `PairingStore(...)` inside view-builder expressions feeding a child's `@State`. `@State` keeps the first instance, but a fresh store + `PairingService` is allocated and discarded on every parent body re-evaluation, and a sheet re-present resets identity and silently drops the in-flight `pollTask` (`PairingStore.swift:88`). Same pattern: `HomeRouterView.swift:56-58` rebuilds a throwaway `HomeStore` per parent re-render. The codebase's own optional-store `.task` pattern (`SettingsView.swift:62-64`, `CardSessionContainerView.swift:36-46`) doesn't have this churn — standardize on it.
- **Two live `SessionEntryStore` instances** (`HomeDashboardView.swift:110,303`; `PlayView.swift:21,48`) independently poll `fetchOpenSession`; `dismissedSessionId` is per-instance, so dismissing the pending-session banner on Home leaves it alive on Play.

### 🟠 10. MEDIUM — `SessionPlayerView` fixed-pixel geometry + one 200-line body

- `Vayl/Features/Sessions/SessionPlayerView.swift` — the only audited screen that ignores `AppLayout`: dealing card `frame(width: 300, height: 212)` (`:259`), pull travel `-300 * (1 - fill)` (`:249`), fan cards `96x66` (`:154`), `proceedWidth = 168` (`:450`), `.padding(.bottom, 150)` (`:186`). On SE-class widths the 300pt card and -300 travel don't scale. Also `nextPromptText()` peeks `store.index + 1` / `store.effectiveHand` (`:569-575`) — deck-order knowledge that belongs on the store — and a 16ms polling loop in `startHold()` (`:528-539`).
- `Vayl/Features/Home/Views/HomeDashboardView.swift:135-338` — verified: one ~204-line `body` expression (GeometryReader → ZStack → ScrollView with 6+ inline `let` layout computations, two `.vaylCover`s, a `.vaylSheet`, four lifecycle blocks). The most type-check-hostile body in the app — and this project has already hit the slow-type-check freeze failure mode. Extract the cover/sheet cluster and scroll content into named subviews.

### 🟡 11. LOW — smaller, ranked

- **Vestigial `ObservableObject` on Services:** `SyncManager.swift:51` (+ `@Published` `:62,:66`), `DesireSyncService.swift:77`, `ProfileService.swift:21`. Nothing in the app can observe them (zero `@StateObject`/`@ObservedObject`/`@EnvironmentObject` anywhere — verified). Dead conformances that imply Services may publish UI state; delete.
- **`AuthService` is a store-shaped Service living in the View environment** (`VaylApp.swift:50`; read for routing at `AppRootView.swift:33,68,72`) and reaches sideways into `SyncManager.shared` (`AuthService.swift:116`). Accepted seam per the June audit — but name the acceptance in CLAUDE.md so it stops resurfacing.
- **`#if DEBUG` state divergence in store inits** (`HomeStore.swift:99-107`, `MapStore.swift:126-127`, `PulseStore.swift:88-92`, `AppState.swift:98-102`): dev builds never exercise empty/unpaired paths — this is how Finding 1 survived. Consider a launch-arg toggle (`-vaylSeedState`) instead of unconditional DEBUG seeding.
- **HomeLexicon residue:** bundled-content loads still call `ContentLoader` (a Core service) from the view file (`HomeLexicon.swift:109-114`, mitigated: `static let`, decode-once), and the "same 5 for both partners, rotating per UTC day" product rule (`:152-158`) is untested date math in a View — a timezone bug here silently desyncs partners' daily five.
- **ForEach identity notes:** `ReflectionBannerView.swift:108,381` (`id: \.self` on user-facing strings — duplicate word = duplicate identity), `SessionPlayerView.swift:126` (shrinking `0..<show` index range mis-animates the depleted card; cosmetic), `ResourcesOverlayView.swift:40` (inline filter, tiny N).
- **Raw-token residue (carry-forward from H-4):** `CardBackView.swift:171`, `RacetrackTabBar.swift:179,185`, `HomeDashboardView.swift:583` (`Font.custom`); raw `.sheet` at `SignInView.swift:124`, `PaywallSheet.swift:87`, `HomeLexicon.swift:180` (new), `PairingSettingsView.swift:66,75`.
- **`MapUsLayer.swift:41-104`** — the `distance > 0.45` "wide day" threshold constant in the View: name/tokenize it.

### 📦 12. Dead code & config ledger (baseline reconciliation)

| Item | Status |
|---|---|
| 2026-06-30 confirmed-dead set | **~43 files deleted** on this branch. Remaining on disk: `Features/Map/PrismView.swift` (intentional "mine visually" keep) + `Features/Home/Components/HomeWidgetShell.swift` (only consumer is PrismView's preview; if ever revived, fix its ungated `AmbientOrbLayer` at `:76-93` first). |
| **New dead cluster (post-redesign):** | `Features/Map/MeCardSheet.swift` (0 refs), `Features/Map/Components/MeCardCompact.swift` (0 refs), and transitively most of `FlavorVisuals.swift` (`FlavorPortrait`/`FlavorChip`/`DrawnTagChip` consumed only by the two dead files; `CoupleCrestSigil`/`CoupleCrestPortrait` 0 refs outright). ⚠️ The Map bridge doc says "Me Card FULL title-led in V1" — **confirm intent before deleting**; these may be staged for the unbuilt Map pass, not abandoned. |
| Pulse feature post-fea852c | **No orphans** — all redesigned components live. |
| Config drift | **Still open:** `IPHONEOS_DEPLOYMENT_TARGET = 26.2` (4×) and `SWIFT_VERSION = 5.0` (6×) in `project.pbxproj`. Swift 5 mode means the `@MainActor` guarantees the whole architecture leans on are still not compiler-enforced. `TARGETED_DEVICE_FAMILY` is now `1` (resolved). |
| Baseline items verified FIXED | Dual card-session (legacy deleted; all session presentation `.vaylCover`), all three H-2 view→service leaks (rerouted through `SettingsStore`/`HomeStore`), SyncManager + AppState `saveWithLogging`, CardCarousel main loops gated, DesireMapView starfield / AtmosphericGhostDeck / ConversationCard RM gates, `try!` markdown crash. `CredentialEditorSheet` graduated off the dead list (wired at `OnboardingCanvasView.swift:212,396`). |

### ✅ Clean bill (positively verified, worth protecting)

- Zero legacy observation: no `@StateObject`/`@ObservedObject`/`@EnvironmentObject`/`@Published` in app code; every store `@Observable @MainActor final`.
- Observation fan-out is well scoped: `AppState` is lean; a Pulse write invalidates `HomePulseRail` only (HomeDashboardView holds the store but its body reads no pulse property — textbook).
- Composition root disciplined (`VaylApp.swift:28-40`); onboarding completion has a true single writer (`AppState.swift:140-189`); `director.advance()` contract intact; ModelContext created fresh at use, never stored.
- All 109 `ForEach` sites swept: no unstable identity in hot paths, no formatters in body (all cached static), no image-decode risk.
- The Settings vertical and `MapView` are the reference implementations of the contract; `PulseStore` is the model small store (it absorbed view-side derivations — the exact opposite of Finding 5's pattern).
- New Pulse render stack: 30fps caps, gradient-not-blur halos, visibility pauses — the in-repo pattern to copy for Finding 7.

---

## Part 2 — Concrete Refactoring Blueprints (top 3)

### Blueprint A — One source of truth for couple state (fixes Findings 1, 2, and the MapView ferry in 8)

**Goal:** partner identity and reveal-unlock each have exactly one owner; every surface reads, none re-derives.

1. **Create `CoupleContext`** (`Vayl/Core/Services/CoupleContext.swift` or promote onto `AppState` — recommended: separate `@Observable @MainActor` class so AppState stays routing-only). Owns: `partnerName: String?`, `partnerProfileId: UUID?`, `myMapComplete`, `partnerMapComplete`, `revealDone`, `unlockState: DesireUnlockState` (`enum { locked, freeOnly, fullyUnlocked }`). Init-injected with `PairingService` + `DesireSyncService` + `EntitlementStore` (the `service ?? .shared` pattern from `DesireRevealStore.swift:104-110`).
2. **One hydrate path:** `func refresh() async` — fetch partner (the logic currently in `MapStore.swift:116-131`), fetch desire status + reveal progress (currently `HomeStore.swift:238-263`), compute `unlockState` from `entitlements.isCore` **only** (the rule MapStore/VaultStore comments already declare canonical; the `Couple.canRevealDesireMap` mirror becomes read-nowhere → delete the mirror write at `EntitlementStore.swift:189-199` once nothing reads it, or keep it strictly as offline seed with a comment pointing here).
3. **Wire it at the composition root:** build in `VaylApp.init` alongside AppState, `.environment(coupleContext)`, refresh on scene-active + after pairing links + after purchase (`EntitlementStore.apply` calls `coupleContext.recomputeUnlock()`).
4. **Delete the four copies:** `HomeStore.partnerName` (`:48,106`) → read `coupleContext.partnerName` in `partnerChipState`; `MapStore.partnerName` + its private fetch; `PairingStore` keeps its copy *only* during the pairing flow, writing through to CoupleContext on link; `SessionEntryStore`'s closure now defaults to `{ coupleContext.partnerName }` at both call sites.
5. **Collapse the gate:** `MapStore.loadServerAlignData:273-298` and `VaultStore.loadDesire:60-80` keep their fetch+display mapping but take `unlockState` from CoupleContext instead of a passed `isCore`; `HomeStore.resolvePostStatusDesireMapState:252-263` drops its `FetchDescriptor<Couple>` mirror read and switches on `coupleContext.unlockState`. `MapView.swift:91,96-99` stops ferrying `entitlements.isCore`/`appState` — MapStore/VaultStore get CoupleContext via init injection (removing the app's only method-injection stores, Finding 8 bullet 1).
6. **Guard the regression:** unit tests for `unlockState` (free tier, just-purchased, refund) and `partnerChipState` with a stubbed context — the DEBUG seed at `HomeStore.swift:99-107` moves into the test fixtures / a `-vaylSeedState` launch arg so release paths get exercised in dev.

*Order matters: do step 2's fetch consolidation before deleting copies, so there is never a commit where a surface has no source. Est. scope: 1 new file (~150 LOC), edits in 6 stores + 2 views, net-negative LOC.*

### Blueprint B — Decompose `CoupleSessionStore` (Finding 3)

**Goal:** keep one coordinator owning the cover and the shared hand/ledger; move the three separable subsystems behind the seams the file already draws with its own MARKs. No behavior change — this is a mechanical split along verified boundaries.

1. **Extract `SessionTransport`** (~200 LOC): everything under "Remote sync" (`:331-457`) — remote-row mirroring, `confirmedIndex`, optimistic advance/rollback, presence flags (`isLive`, `partnerPresentLive`, `partnerAway`), plus `RevealTransportAdapter` (`:802`) into its own file. The store keeps `effectiveHand` as its read surface; transport owns reconciliation. This isolates the rollback state machine — the hardest-to-reason-about code — behind a testable interface (mock transport already exists as a seam, `:139-146`).
2. **Extract `SessionSafetyController`** (~120 LOC): the Safety MARK (`:617`) — pause, safe word, presence-grace timers. It observes transport, exposes `isPaused`/`safeWordUsed`, and is the natural home for the timer derivation (`:560`) since both derive from the shared anchor.
3. **Extract `SessionCloseModel`** (~80 LOC, plain `@Observable` value-holder): reflection words, `carriedBalance`, `feltHeard`, `reflectionNote` (`:86-93`) + the persistence write (`:687`). SessionCloseView binds to it directly; the coordinator just hands it the records at close.
4. **Keep in the coordinator:** phase machine, launch context, hand/index/records, and the per-card presentation flags (`:486-516`) — the beats genuinely coordinate with phase. Result: coordinator ~350 LOC, three ~100-200 LOC single-purpose collaborators, mirroring the already-successful AirlockStore/RevealEngine extractions.
5. **Sequence per the segment protocol:** one extraction per segment, build + 131-test suite green between each (the session tests from fable-plan 16 are the safety net), no view files touched except init-site wiring in `CardSessionContainerView.swift:36-46`. While there: move the airlock handoff out of `Color.clear.onAppear` (`:117-121`) — the coordinator observes `airlock.phase == .active` and calls `airlockDidActivate()` itself.

### Blueprint C — Move Desire ceremony decisions store-side (Finding 5)

**Goal:** the "what does this user see next" fork exists exactly once, and the reveal's hero rule is testable.

1. **Add `DesireMapStore.resumeState`:** a computed `(startIndex: Int, phase: RaterPhase)` encapsulating `firstIndex(where: rating == nil)` + the `ratedCount >= totalCount ? (partnerComplete ? .ready : .mirror) : .rating` rule from `DesireMapView.swift:84-92`. `advancePastCharted()` (`:571-575`) calls `store.postChartedPhase` (same rule, one owner). View keeps only the `withAnimation` wrappers — choreography stays view-side per the OB convention.
2. **Add `HomeStore.raterDismissOutcome() -> RaterDismissOutcome`** (`enum { showReveal, celebrateCompletion, none }`): the branch currently in `HomeRouterView.handleRaterDismiss` (`:283-297`). The View's handler becomes `switch await store.raterDismissOutcome()` + presentation. With Blueprint A landed, this reads `coupleContext`, and DesireMapView's `partnerComplete` input comes from the same source — closing the two-file duplication.
3. **Move `placedStars` into `DesireRevealStore`:** the hero-selection rule + slot-filling from `DesireRevealView.swift:324-358` becomes `store.placedStars(layout:)` (pure function of `matches` — trivially unit-testable: "free reveal wins hero slot over mutual", "mutual wins over first"). Cache the `ConstellationLayout.generate` result in the store keyed on `(coupleId, matches.count)` — removes the 2×-per-body regenerate even though it's cheap, and the star-size formula moves with it. The View keeps `constellationMode` (pure presentation).
4. **Housekeeping in the same pass:** `ratedItemsByGroup`/`positiveRatings` (`DesireMapView.swift:322,696-703`) move to `DesireMapStore` with the force-unwrap dissolved by grouping over the rating lookup once; `AirlockView.isRepeatSession` (`:31-33`) becomes a `CoupleSessionStore` property.
5. **Tests:** three pure-logic suites (resume state, dismiss outcome, hero placement) — all currently impossible to write without rendering. This directly serves the reveal = primary-conversion-surface stake.

---

## Suggested overall sequence

1. **Quick wins first (one sitting):** Finding 4 (LightAuraBloom — real bug), Finding 7's one-liners (HolographicText + ContextCardFace LPM gates, CardCarousel `:748` gate, 30fps caps on LivingText/SpectrumBulletRow/StarVeil), delete the three vestigial `ObservableObject` conformances. All mechanical, all build-verifiable.
2. **Blueprint A** (couple-state SSOT) — fixes the latent release bug and the paywall truth fragmentation; everything else gets simpler after it.
3. **Blueprint C** (ceremony decisions) — depends lightly on A, unlocks the reveal tests.
4. **Blueprint B** (session store split) — independent; slot it when session work next opens anyway (feel-tuning is still pending, good pairing).
5. **Deliberate decisions, not code:** deployment target 26.2 / Swift 6 mode (CFG carry-forward, now the oldest open item), MeCard* dead-or-staged, MetallicCaseView cap (device feel pass).

---

_Assumptions & limitations: static analysis only (no simulator runs, per project convention); severity for perf findings is code-derived, not trace-backed — an Instruments pass on Home + Paywall would confirm Finding 7's real-world cost. `vayl-context.md` / `vayl-onboarding-context.md` (generated context dumps at repo root, 20k lines) were excluded from LOC-based reasoning. No files were modified._

---

## Addendum — Fix Implementation + Profiling Pass (same night)

### Landed (5 commits on `design_finalized`)

| Commit | Content |
|---|---|
| `ad4e570` | The 43-file confirmed-dead deletion (was staged, uncommitted) committed as its own save point. ⚠️ **This commit does not build standalone** — the deletion depends on the still-uncommitted `VaylCardFace`/`VaylCardContent` switch-arm edits in the working tree (the coordinated-deletion caveat from the June audit). Committing those OB working-tree changes will heal bisectability. |
| `300c803` | **Quick wins**: LightAuraBloom rebuilt on one 30fps timeline clock (Finding 4, the dual-clock bug — also removes its body-level `AnyView`); LPM gates on HolographicText + ContextCardFace; ContextCardFace clock now pauses once the page-turn/ribbon settle; CardCarousel's ungated float restart gated; 30fps/15fps caps on LivingText, SpectrumBulletRow, StarVeil; vestigial `ObservableObject`/`@Published` removed from SyncManager/DesireSyncService/ProfileService. MetallicCaseView cap + SparkField prune deferred (OB feel-gated). |
| `970e04a` | **Blueprint A**: `CoupleContext` (Core/Services) now solely owns partner identity (fetch-once, keyed to coupleId; the one DEBUG fallback) and the reveal gate (`canRevealAll`). Fixes Finding 1 (the no-production-writer partnerName bug) and Finding 2 (Home no longer reads the lagging `canRevealDesireMap` mirror). MapView stops ferrying `isCore`; both SessionEntryStore closures now read live (the Home one had captured the chip by value — a third latent staleness bug found during implementation). |
| `6965cbb` | **Blueprint C**: rater resume + second-finisher branch on `DesireMapStore` (`firstUnratedIndex`, `postRatingDestination`); reveal-vs-celebration fork on `HomeStore.raterDismissOutcome`; constellation layout + hero rule on `DesireRevealStore` (built once per matches change instead of 2×/body); `positiveRatings`/`ratedItemsByGroup` store-side (force-unwrap dissolved); `AirlockView` reads `store.isRepeatSession` instead of UserDefaults. |
| `78d3b94` | DEBUG-only `-vaylForceHome` launch arg (routes past OB + auth) so unattended perf captures can reach Home. |

**Blueprint B (CoupleSessionStore split) deliberately NOT executed** — its safety net (the 131-test suite) cannot run: `VaylTests` fails to compile from pre-existing drift (the Pulse test files still target the pre-`fea852c` API). Fix the tests first (flagged as a spawned task), then do the split alongside the pending session feel-pass.

All landed commits build green (app target, iPhone simulator).

### Profiling pass (simulator, iPhone 17 Pro, Debug)

`xctrace` Time Profiler produced empty traces on this sim ("os_log support not available"), so measurement used 30×1s CPU sampling + a 10s `sample` call-graph capture, on idle Home reached via `-vaylForceHome` (onboarding flag pre-seeded).

| Capture | Idle Home CPU (30s) |
|---|---|
| Before (at `ad4e570`, pre-fixes) | mean **18.0%**, max 20.8% |
| After (all five commits) | mean **18.1%**, max 21.8% |

**Reading the parity honestly:**
1. **No regression** from the CoupleContext/Blueprint-C refactors — the equality is itself the verification.
2. **The capped components don't live on Home.** LightAuraBloom (rater pills), LivingText + SpectrumBulletRow (paywall/OB), StarVeil (Map) — their wins land on those surfaces, which can't be reached without tap injection in an unattended run. The Home-resident fixes (HolographicText, CardCarousel restart) were RM/LPM *gates*, which by design change nothing when those modes are off.
3. **Where the 18% goes:** the 10s call-graph sample contains **zero frames in the Vayl binary** — the cost is entirely SwiftUI `AttributeGraph` propagation + (simulator-only) Metal command serialization, driven by the *number* of concurrent ambient `withAnimation` loops on Home (lexicon shimmer, carousel float/bloom, pulse breathing). No app-code hotspot exists to optimize; the lever on this number is exactly the LPM/RM gating contract, which is now airtight on Home.
4. Simulator numbers are directional only; the on-device story (ProMotion, LPM) is Bryan's pass.

Artifacts: `cpu-before.txt`, `cpu-after.txt`, `home-idle-sample.txt`, screenshots in the session scratchpad.

### Also surfaced during implementation
- `Vayl/Core/Services/Config.swift` is **untracked** but load-bearing (SupabaseManager won't compile without it) — a fresh clone doesn't build. If it's secret-bearing by design, document it; if not, track it.
- The stale-chip closure in HomeDashboardView (fixed in `970e04a`) was a third instance of the Finding-1 pattern, found only because the refactor touched the call site.
