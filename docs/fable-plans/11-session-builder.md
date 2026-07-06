# 11 · Session Builder — real `SessionPlan`s, authored order by default (roadmap S5)

**Goal:** In one pass, add a `SessionBuilderStore` + `SessionBuilderView` that produce a real, persistable `SessionPlan` — seeded from `the-opener`'s authored order (rituals included), fully customizable (reorder, drop, per-card + global timers, session settings, live time estimate, soft over-length nudge + opt-in firm cap), plus four fast paths (quick auto-pick, save & reuse, same-as-last, presets). Resolve the plan back to a real `[Card]` hand and feed it into the **existing** `.vaylCover` → `CardSessionContainerView` → `CoupleSessionStore` flow, replacing the ad-hoc "carousel hand" / `SessionPlan.stub` path. **Zero** changes to the transport (`RealtimeSessionService` / Airlock) or the Player internals.

---

> ## ⚡ ONE-SHOT LICENSE — convention override (read first)
>
> Vayl's standing Build Protocol (`CLAUDE.md`) says: _"Never build a full feature in one pass.
> Break every feature into named segments. A segment is not complete until it has run on device."_
> **This plan deliberately suspends that pacing rule.** You (Fable) are authorized — and expected — to
> implement this ENTIRE plan in ONE pass, all segments end to end, without stopping between segments
> for a device check. Deliver one complete, build-green changeset.
>
> **What the license waives:** the _pacing_ rule only — the "one segment at a time, feel-verify on
> device before the next" cadence. Build it all at once.
>
> **What it does NOT waive (still mandatory — the license buys speed, not sloppiness):**
> - **4-layer architecture:** View → Store → Service → Model. Views never call a Service/DB/network
>   directly. Stores are `@Observable @MainActor final class`. `director.advance()` is the only way to
>   change an onboarding phase; no View writes `VaylCardModel`.
> - **Tokens only:** no raw colors / fonts / spacing / radius / opacity / animation-duration literals in
>   Views. Read the token file (`Vayl/App/Theme/*`) before using a token; **never invent one.**
> - **Presentation grammar:** route modals through `.vaylCover` / `.vaylSheet`, never raw
>   `.fullScreenCover` / `.sheet`. Card Session is always a `.vaylCover`.
> - **iOS 26:** zero banned APIs (`UIScreen.main`/`.bounds`, `keyWindow`, `UIWebView`,
>   `NSURLConnection`, `UNAuthorizationOptionAlert`/`…PresentationOptionAlert`).
> - **A11y + empties:** Reduce-Motion fallback on every looping animation (`.ambientAnimation` or a
>   `guard !reduceMotion`); an empty state (icon + headline + sub-label + optional CTA) on every data screen.
> - `.drawingGroup()` stays on `VaylCardFace`; no `VaylCardFace` shell edits.
>
> **Accuracy contract:** every file path, symbol, and line number in this plan was verified against the
> repo on **2026-07-01**. If reality differs when you build, **trust the repo and note the drift** — do
> not invent paths, tokens, or APIs to make the plan "fit."
>
> **Verification is deferred, not skipped:** finish by compiling green, then hand Bryan the
> **"Bryan verifies on device"** checklist at the end. Bryan runs on-device / feel confirmation himself
> (he does not want Claude/Fable running the simulator). Items marked 🎚️ are feel-values Bryan tunes on
> device — use the given default and move on; do not re-derive them.

---

## ⚠️ ONE-SHOT CAVEAT (read this before you start)

This one **is** largely one-shottable and build-provable. The Builder is **single-device authoring**:
it reads a bundled `Deck`, lets the user shape a value type (`SessionPlan` + a working draft), persists
it to SwiftData, and resolves it back to `[Card]`. None of that needs a second phone. The transport
(Airlock/Realtime) and the Player already exist and are **not touched** — the Builder only produces the
`SessionPlan` the Player consumes.

**The one device-only check** Bryan must do: build a custom plan (reorder + drop a card + set a timer)
and confirm it **plays identically** in the existing Player — right order, right count, timers/settings
surfaced. Everything else is compile-provable. Items marked 🎚️ are feel-defaults; use them and move on.

**Definition of Done** = build-green **and** a built authored-order `SessionPlan` replaces the ad-hoc
carousel-hand path as the way a couple session is launched. Bryan's device checklist is at the end.

---

## Context Fable needs

- **What this is.** A **couple card session** is played from a *hand* of `Card`s. Today the hand is
  assembled ad-hoc: on Home the `CardCarousel` lets you tap cards into `handIDs`, and "Settle in" maps
  those to `[Card]` and shoves them into a `.vaylCover`. There is **no authored-order default, no
  persistence, no timers, no settings**. This plan builds the real **Session Builder** that produces a
  `SessionPlan` (the roadmap's S5).

- **Current state — evidence.**
  - `SessionPlan` `@Model` **already exists and is already registered.** File
    `Vayl/Features/Sessions/SessionPlan.swift` (fields: `id, coupleId?, deckId, deckVariant?, title,
    orderedCardIds, perCardTimerSeconds, globalTimerSeconds?, isPreset, isLDR, createdAt, lastUsedAt?`).
    Registered in `SchemaV1.models` at `Vayl/App/ModelContainer.swift:42` (`SessionPlan.self`). **Do not
    re-add it. Do not re-register it.** No schema-migration work is needed for existing fields.
  - **The "stub" the roadmap says to replace is TWO things, and neither is the session entry point:**
    1. `SessionPlan.stub(coupleId:)` — a hardcoded 3-id factory at
       `Vayl/Features/Sessions/SessionPlan.swift:69-78`. Grep shows it has **no live callers** in app
       code today (it was scaffolding for Phase B/D). Delete it as part of this pass.
    2. The **real** ad-hoc launch path: the session hand is currently built from the `CardCarousel`
       selection, not from a `SessionPlan` at all. See `HomeDashboardView.startHand()` /
       `toggleHand(_:)` (`Vayl/Features/Home/Views/HomeDashboardView.swift`, `handIDs` at line 85,
       `startHand`/`sessionHand` around 408-412) and `PlayStore.begin(_:)` /
       `ceremonyFinished()` (`Vayl/Features/Play/Store/PlayStore.swift:134-148`) which set
       `sessionHand = deck.orderedCards`. **This** is the thing the Builder replaces as the *front door*.
  - **The session consumer does NOT take a `SessionPlan` — it takes `hand: [Card]`.**
    `CardSessionContainerView(hand: [Card])` (`Vayl/Features/Sessions/CardSessionContainerView.swift:18-45`)
    builds `CoupleSessionStore(hand:modelContainer:appState:)` (`CoupleSessionStore.swift:111-138`, field
    `let hand: [Card]` at line 66). **This is the seam.** The Builder's job ends at producing a
    `SessionPlan`; a small resolver turns that plan into `[Card]` and hands it to the *unchanged*
    `CardSessionContainerView`. You never touch `CoupleSessionStore` internals or the transport.

- **The Deck / Card shape (verified).**
  - `Deck` (`Vayl/Core/Models/Deck.swift`) is a `Codable struct`; `var orderedCards: [Card]` at line 64
    returns `cards.sorted { $0.sortOrder < $1.sortOrder }`. `cards(for: GenderDynamic)` at line 53 filters
    gendered cards. `cardCount`, `hasOpeningRitual`, `hasClosingRitual` are derived.
  - `Card` (`Vayl/Core/Models/Card.swift`) is a `Codable struct`; `let id: String`, `deckId`, `text`,
    `highlightWords`, `type: CardType`, `intensity: CardIntensity`, `isSensitive`, `canSkip`,
    `sortOrder`, and derived `isCeremonial` (true for `.openingRitual`/`.closingRitual`/`.pause`),
    `isLivingCard`. **`Card` is not `Equatable`/`Hashable` today** — key everything by `card.id` (a
    `String`), never by the card value. `ForEach` should use `id: \.id`.
  - Loading: `ContentLoader.loadDeck(id:)` (`Vayl/Core/Services/ContentLoader.swift:101`) → throws;
    decodes `Vayl/Resources/Decks/<id>.json` with `.convertFromSnakeCase`. Only **one** deck ships:
    `the-opener` (10 cards, ids `opener-01`…`opener-10`). Play wraps this in
    `DeckCatalogService.loadDeck(id:)` (`Vayl/Features/Play/Services/DeckCatalogService.swift:11`).

- **Canonical patterns to imitate.**
  - **Store** — model on `PlayStore` (`Vayl/Features/Play/Store/PlayStore.swift`): `@Observable
    @MainActor final class`, `init(modelContainer:appState:)`, `ModelContext(modelContainer)` created
    *fresh at write time* (never stored on `self`), `catalog.loadDeck(...)` for content, a `#if DEBUG
    static var preview`. Persistence writes mirror `CoupleSessionStore.persistSession`
    (`try context.saveWithLogging()`, `OSLog` logger).
  - **Presentation** — the Builder is a **discrete authoring task you return from**, so it is a
    **`.vaylSheet`** (per the presentation-grammar table: "Completing a discrete task → `.vaylSheet`").
    The Card Session it launches stays a **`.vaylCover`** (unchanged). Signatures verified:
    `.vaylSheet(isPresented:heightFraction:screenHeight:showsGrabber:content:)` and
    `.vaylCover(isPresented:confirmOnExit:…content:)` in
    `Vayl/Design/Components/Navigation/VaylPresentation.swift`.
  - **Tokens (verified names):** `AppColors.void / .cardBg / .textPrimary / .textSecondary /
    .textTertiary / .spectrumText / .spectrumBorder / .accentPrimary`; `AppFonts.sectionHeading /
    .cardTitle / .bodyText / .caption / .buttonLabel / .overline`; `AppSpacing.xxs(2) .xs(4) .sm(8)
    .md(16) .lg(24) .xl(32) .xxl(48)`; `AppRadius.sm(8) .md(12) .lg(16) .container(20) .pill`;
    `AppAnimation.spring / .standard / .enter`. `VaylButton(label:style:size:isLoading:isDisabled:action:)`
    and `SafeWordButton` exist. Surfaces use `.vaylGlassCard()` / `.themedCard()` from
    `Vayl/App/Theme/ThemeModifiers.swift`.

---

## Files

### Create

| File | Responsibility |
|---|---|
| `Vayl/Features/Sessions/Builder/SessionDraft.swift` | Pure value type — the in-flight editable session (deck id, ordered ids, per-card timers, global timer, settings). No SwiftData, no logic beyond derived counts. |
| `Vayl/Features/Sessions/Builder/SessionBuilderStore.swift` | `@Observable @MainActor` brain: loads the deck, seeds the draft from authored order, mutates it (reorder/drop/timers/settings), computes the live estimate + cap nudge, runs the four fast paths, persists a `SessionPlan`, and **resolves** a plan → `[Card]` hand for the Player. |
| `Vayl/Features/Sessions/Builder/SessionBuilderView.swift` | The `.vaylSheet` UI: header + fast-path row + reorderable/droppable card list + per-card timer control + settings section + live estimate bar + soft nudge + "Start session" CTA. Empty state when the deck fails to load. |
| `Vayl/Features/Sessions/Builder/SessionBuilderRow.swift` | One card row in the list (drag handle, order index, prompt preview, ritual lock badge, drop button, per-card timer chip). Keyed by `card.id`. |
| `Vayl/Features/Sessions/Builder/SessionSettingsSection.swift` | The settings block (depth ceiling, together/apart → `isLDR`, sensitive-cards toggle, safe-word note). Pure presentation bound to the store. |

### Modify

| File | Change (anchor) |
|---|---|
| `Vayl/Features/Sessions/SessionPlan.swift` | **Delete** the `stub(coupleId:)` extension (lines 63-78). Add small pure helpers on `SessionPlan` (a `seed(from:coupleId:)` static + `estimatedSeconds` derived). |
| `Vayl/Features/Home/Views/HomeDashboardView.swift` | Route "Settle in" through the Builder sheet instead of straight to the cover. `startHand()` (~line 408-412) no longer sets `sessionHand` directly; it opens `SessionBuilderView` seeded with the carousel selection (or the whole deck). The Builder's `onStart(hand)` sets `sessionHand`. Keep the existing `.vaylCover` block (267-274) untouched. |
| `Vayl/Features/Play/PlayView.swift` | `begin`/`ceremonyFinished` route through the Builder sheet before the `.vaylCover` (78-99). Same seam: Builder produces the hand; existing cover consumes it. |

### Delete

| File | Reason |
|---|---|
| _(none as whole files)_ | Only the `SessionPlan.stub` extension is removed (in-file). |

---

## Build steps (segments — all in one pass)

### Segment 1 — `SessionDraft` value type (the editable in-flight session)

**One thing:** a pure, `Sendable` struct the Store mutates while the user authors. Keyed by card id.

Create `Vayl/Features/Sessions/Builder/SessionDraft.swift`:

```swift
//
//  SessionDraft.swift
//  Vayl
//
//  The in-flight, editable session the SessionBuilderStore mutates while the
//  user authors. Pure value type — no SwiftData, no I/O. It snapshots into a
//  persistable SessionPlan (save & reuse) and resolves into a [Card] hand for
//  the Player. Everything is keyed by the String card id — Card is not Hashable.
//

import Foundation

// MARK: - SessionSettings

/// Session-wide toggles. Together vs apart drives `isLDR`; the rest are soft.
struct SessionSettings: Equatable, Sendable {

    /// The deepest intensity the user wants tonight. Cards above it are dimmed
    /// (a soft ceiling), never auto-removed — naming, not gating.
    enum DepthCeiling: Int, CaseIterable, Identifiable, Sendable {
        case gentle = 2, open = 3, deep = 4, unbounded = 99
        var id: Int { rawValue }
        var label: String {
            switch self {
            case .gentle:    return "Gentle"
            case .open:      return "Open"
            case .deep:      return "Deep"
            case .unbounded: return "No ceiling"
            }
        }
    }

    var depthCeiling: DepthCeiling = .unbounded
    /// together = in the same room; apart = long-distance. apart → isLDR.
    var isApart: Bool = false
    /// Keep cards flagged isSensitive in the hand. Off drops them from the seed.
    var includeSensitive: Bool = true
    /// Safe word is always "red"; the toggle only controls whether the reminder shows.
    var showsSafeWordReminder: Bool = true

    /// When over the firm cap is engaged, the hand is trimmed to this many cards.
    var firmCapEnabled: Bool = false
    var firmCapCount: Int = 8
}

// MARK: - SessionDraft

struct SessionDraft: Equatable, Sendable {

    let deckId: String
    let deckVariant: String?

    /// Play order. Seeded from deck.orderedCards; the user may reorder / drop.
    var orderedCardIds: [String]

    /// cardId -> seconds. Absent = no per-card timer (falls back to global).
    var perCardTimerSeconds: [String: Int]

    /// Optional default per-card limit applied when a card has no explicit timer.
    var globalTimerSeconds: Int?

    var settings: SessionSettings

    /// User label used only when saving as a reusable SessionPlan.
    var title: String

    // MARK: - Derived

    var cardCount: Int { orderedCardIds.count }

    /// The effective timer for a card: explicit per-card first, else global.
    func timerSeconds(for cardId: String) -> Int? {
        perCardTimerSeconds[cardId] ?? globalTimerSeconds
    }

    /// Live time estimate in seconds. Each card = its timer if set, else a
    /// reading/discussion default. This is an ESTIMATE surfaced to the user,
    /// not a hard schedule.
    static let defaultCardSeconds = 150   // 🎚️ 2.5 min per card, no timer set

    var estimatedSeconds: Int {
        orderedCardIds.reduce(0) { total, id in
            total + (timerSeconds(for: id) ?? Self.defaultCardSeconds)
        }
    }
}
```

**Done:** compiles; `SessionDraft` is pure, `Sendable`, and keys everything by `String` id.

---

### Segment 2 — `SessionPlan` helpers + delete the stub

**One thing:** give `SessionPlan` a clean seed constructor and a derived estimate; remove the dead stub.

Edit `Vayl/Features/Sessions/SessionPlan.swift`. **Delete** the entire stub extension (lines 63-78) and
replace it with:

```swift
// MARK: - Seed & derive

extension SessionPlan {

    /// The authored-order default: every card in the deck, in sortOrder,
    /// rituals included. This is the SEED the Builder starts from — the user
    /// may reorder or trim it, but authored order is always where it begins.
    static func seed(from deck: Deck, coupleId: UUID?, title: String) -> SessionPlan {
        SessionPlan(
            coupleId: coupleId,
            deckId: deck.id,
            title: title,
            orderedCardIds: deck.orderedCards.map(\.id)
        )
    }

    /// Snapshot a fully-authored draft into a persistable plan.
    static func from(draft: SessionDraft, coupleId: UUID?) -> SessionPlan {
        SessionPlan(
            coupleId: coupleId,
            deckId: draft.deckId,
            title: draft.title,
            orderedCardIds: draft.orderedCardIds,
            deckVariant: draft.deckVariant,
            perCardTimerSeconds: draft.perCardTimerSeconds,
            globalTimerSeconds: draft.globalTimerSeconds,
            isLDR: draft.settings.isApart
        )
    }
}
```

> **Why delete the stub:** `SessionPlan.stub` has no live app callers (grep-verified 2026-07-01); it
> was Phase-B/D scaffolding. The Builder is its replacement. Do not port its hardcoded ids.

**Done:** the stub is gone; `SessionPlan.seed(from:coupleId:title:)` and `.from(draft:coupleId:)` compile.

---

### Segment 3 — `SessionBuilderStore` (authored-order seed + resolve → hand)

**One thing:** the brain. Loads `the-opener`, seeds the draft in authored order, and can resolve any
draft back into a real `[Card]` hand for the *existing* Player. This is the E1 core (replace the stub).

Create `Vayl/Features/Sessions/Builder/SessionBuilderStore.swift`:

```swift
//
//  SessionBuilderStore.swift
//  Vayl
//
//  Brain of the Session Builder. Produces a real SessionPlan from a deck's
//  authored order (the DEFAULT), lets the user reorder / trim / time / configure,
//  runs the fast paths, persists reusable plans, and resolves a plan into the
//  [Card] hand the existing CoupleSession .vaylCover consumes.
//
//  It NEVER touches the transport (RealtimeSessionService / Airlock) or the
//  Player internals. Its output is a [Card] hand handed to CardSessionContainerView.
//
//  Dependencies injected via init. ModelContext created fresh at write time
//  (never stored on self) — matches PlayStore / CoupleSessionStore.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "SessionBuilderStore")

@Observable
@MainActor
final class SessionBuilderStore {

    // MARK: - Content
    private(set) var deck: Deck?
    private(set) var loadFailed = false

    /// The in-flight authored session. nil until the deck loads.
    var draft: SessionDraft?

    // MARK: - Fast-path menu
    /// Saved reusable plans for this couple (for "Same as last" + reuse list).
    private(set) var savedPlans: [SessionPlan] = []

    // MARK: - Dependencies
    private let modelContainer: ModelContainer
    private let appState: AppState
    /// Only fallback deck we ship today. Multi-deck is content-gated (S5 note).
    static let defaultDeckId = "the-opener"

    // MARK: - Init
    init(modelContainer: ModelContainer, appState: AppState) {
        self.modelContainer = modelContainer
        self.appState = appState
    }

    // MARK: - Load & seed (E1)

    /// Load the deck and seed the draft in AUTHORED ORDER (rituals included).
    /// `preselectedIds` (e.g. the Home carousel selection) narrows the seed while
    /// KEEPING authored order; empty/nil => the whole deck. Multi-deck degrades to
    /// the-opener gracefully: an unknown id falls back to the default deck.
    func start(deckId: String? = nil, preselectedIds: [String] = []) {
        let id = deckId ?? Self.defaultDeckId
        let loaded = (try? ContentLoader.loadDeck(id: id))
            ?? (try? ContentLoader.loadDeck(id: Self.defaultDeckId))
        guard let deck = loaded else {
            loadFailed = true
            logger.error("SessionBuilder: no deck for \(id) (and no fallback)")
            return
        }
        self.deck = deck
        self.loadFailed = false

        // Authored order is the default. If a subset was preselected, keep only
        // those ids but IN authored order — never in tap order.
        let authored = deck.orderedCards.map(\.id)
        let seededIds: [String]
        if preselectedIds.isEmpty {
            seededIds = authored
        } else {
            let keep = Set(preselectedIds)
            seededIds = authored.filter { keep.contains($0) }
        }

        draft = SessionDraft(
            deckId: deck.id,
            deckVariant: nil,
            orderedCardIds: seededIds.isEmpty ? authored : seededIds,
            perCardTimerSeconds: [:],
            globalTimerSeconds: nil,
            settings: SessionSettings(),
            title: deck.title
        )
        loadSavedPlans()
    }

    // MARK: - Card lookup

    /// The Card for an id (content layer). nil if the deck is unloaded or the id
    /// is stale. Views read this to render rows.
    func card(_ id: String) -> Card? {
        deck?.cards.first { $0.id == id }
    }

    /// The ordered cards currently in the draft, resolved to Card values.
    var orderedCards: [Card] {
        guard let ids = draft?.orderedCardIds else { return [] }
        return ids.compactMap(card)
    }

    // MARK: - Resolve → hand (the seam to the existing Player)

    /// Turn the current draft into the real [Card] hand the existing
    /// CardSessionContainerView / CoupleSessionStore consumes — in draft order.
    /// This is the ONLY output the Player sees. Transport untouched.
    func resolvedHand() -> [Card] {
        guard let draft, let deck else { return [] }
        var byId: [String: Card] = [:]
        for c in deck.cards { byId[c.id] = c }
        return draft.orderedCardIds.compactMap { byId[$0] }
    }

    // MARK: - Persistence

    private func loadSavedPlans() {
        let context = ModelContext(modelContainer)
        let coupleId = appState.coupleId
        var fetch = FetchDescriptor<SessionPlan>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse),
                     SortDescriptor(\.createdAt, order: .reverse)]
        )
        fetch.fetchLimit = 20
        let all = (try? context.fetch(fetch)) ?? []
        // Only this couple's plans (or unclaimed presets).
        savedPlans = all.filter { $0.coupleId == coupleId || $0.coupleId == nil }
    }
}
```

**Done:** `start()` seeds the draft in authored order (rituals included), degrades to `the-opener` on an
unknown id, and `resolvedHand()` returns `[Card]` in draft order — the exact shape
`CardSessionContainerView(hand:)` already takes.

---

### Segment 4 — Reorder / drop / timers / settings (E2 store logic)

**One thing:** all the mutation methods. Authored order is the DEFAULT the user *moves away from*, never
forced. Rituals are droppable but flagged so the user knows what they're removing.

Add to `SessionBuilderStore` (same file):

```swift
    // MARK: - Reorder & trim (E2)

    /// SwiftUI `.onMove` handler for the card list. Authored order is the
    /// starting point; this is how the user departs from it — by choice.
    func move(from offsets: IndexSet, to destination: Int) {
        draft?.orderedCardIds.move(fromOffsets: offsets, toOffset: destination)
    }

    /// Drop a card from tonight's hand. Rituals CAN be dropped (never forced to
    /// stay) but the row badges them so it's a conscious choice.
    func drop(_ cardId: String) {
        draft?.orderedCardIds.removeAll { $0 == cardId }
        draft?.perCardTimerSeconds[cardId] = nil
    }

    /// Restore the authored default order & full card set for the loaded deck.
    /// The escape hatch back to "just play it as written".
    func resetToAuthored() {
        guard let deck else { return }
        draft?.orderedCardIds = deck.orderedCards.map(\.id)
        draft?.perCardTimerSeconds = [:]
        draft?.globalTimerSeconds = nil
    }

    var isAuthoredOrder: Bool {
        guard let deck, let ids = draft?.orderedCardIds else { return true }
        return ids == deck.orderedCards.map(\.id)
    }

    // MARK: - Timers (E2)

    /// Per-card timer options, in seconds (nil = no timer). 🎚️ tune the ladder.
    static let timerOptions: [Int?] = [nil, 60, 120, 180, 300]

    func setPerCardTimer(_ seconds: Int?, for cardId: String) {
        if let seconds { draft?.perCardTimerSeconds[cardId] = seconds }
        else { draft?.perCardTimerSeconds[cardId] = nil }
    }

    func setGlobalTimer(_ seconds: Int?) {
        draft?.globalTimerSeconds = seconds
    }

    // MARK: - Settings (E2)

    func setDepthCeiling(_ ceiling: SessionSettings.DepthCeiling) {
        draft?.settings.depthCeiling = ceiling
    }
    func setApart(_ apart: Bool)            { draft?.settings.isApart = apart }
    func setIncludeSensitive(_ on: Bool) {
        guard draft != nil, let deck else { return }
        draft?.settings.includeSensitive = on
        // Off => drop sensitive cards from the hand; On => re-seed them in
        // authored order without disturbing existing custom order elsewhere.
        if !on {
            let sensitive = Set(deck.cards.filter(\.isSensitive).map(\.id))
            draft?.orderedCardIds.removeAll { sensitive.contains($0) }
        } else {
            reseedMissingAuthored()
        }
    }
    func setSafeWordReminder(_ on: Bool)    { draft?.settings.showsSafeWordReminder = on }

    /// Add back any authored cards missing from the current hand, in authored
    /// position, without disturbing the user's ordering of what's present.
    private func reseedMissingAuthored() {
        guard let deck, var ids = draft?.orderedCardIds else { return }
        let present = Set(ids)
        for card in deck.orderedCards where !present.contains(card.id) {
            // Insert at the authored index clamped into the current list.
            let authoredIndex = min(card.sortOrder - 1, ids.count)
            ids.insert(card.id, at: max(0, authoredIndex))
        }
        draft?.orderedCardIds = ids
    }

    // MARK: - Live estimate + cap nudge (E2)

    var estimatedSeconds: Int { draft?.estimatedSeconds ?? 0 }

    /// "About 22 min" style label for the estimate bar.
    var estimateLabel: String {
        let mins = max(1, Int((Double(estimatedSeconds) / 60.0).rounded()))
        return "About \(mins) min"
    }

    /// 🎚️ Soft over-length threshold — a nudge, never a block.
    static let softNudgeCardCount = 12

    var isOverLength: Bool { (draft?.cardCount ?? 0) > Self.softNudgeCardCount }

    /// Opt-in FIRM cap. When enabled, trims the hand to the cap on start,
    /// keeping draft order (front of the list). Off by default — the nudge is soft.
    func setFirmCap(enabled: Bool, count: Int? = nil) {
        draft?.settings.firmCapEnabled = enabled
        if let count { draft?.settings.firmCapCount = count }
    }

    /// Apply the firm cap (if engaged) to a hand at start time.
    private func applyFirmCap(_ hand: [Card]) -> [Card] {
        guard let s = draft?.settings, s.firmCapEnabled else { return hand }
        return Array(hand.prefix(max(1, s.firmCapCount)))
    }
```

**Done:** reorder/drop/reset work; `isAuthoredOrder` reports the default; per-card + global timers set;
depth/apart/sensitive/safe-word settings mutate the draft; `estimateLabel` + `isOverLength` drive the
UI; firm cap is opt-in and only trims at start.

---

### Segment 5 — Fast paths + save/persist + start (E3)

**One thing:** quick auto-pick, save & reuse, same-as-last, presets — each ends in a valid draft/plan,
and `startSession()` resolves the (capped) hand for the Player.

Add to `SessionBuilderStore` (same file):

```swift
    // MARK: - Fast paths (E3)

    /// QUICK: auto-pick by depth + length with zero authoring. Seeds authored
    /// order, applies the depth ceiling as a filter, trims to a target length.
    /// Still fully editable afterward — quick is a starting point, not a lock.
    func quickAutoPick(depth: SessionSettings.DepthCeiling, targetCards: Int) {
        guard let deck else { start(); return }
        if draft == nil { start() }
        let filtered = deck.orderedCards.filter { card in
            depth == .unbounded || card.intensity.rawValue <= depth.rawValue
        }
        let ids = filtered.prefix(max(1, targetCards)).map(\.id)
        draft?.orderedCardIds = Array(ids)
        draft?.settings.depthCeiling = depth
        draft?.perCardTimerSeconds = [:]
    }

    /// SAVE & REUSE: persist the current draft as a named SessionPlan.
    @discardableResult
    func saveDraftAsPlan() -> SessionPlan? {
        guard let draft else { return nil }
        let context = ModelContext(modelContainer)
        let plan = SessionPlan.from(draft: draft, coupleId: appState.coupleId)
        context.insert(plan)
        do {
            try context.saveWithLogging()
            logger.info("SessionBuilder: saved plan \(plan.title) — \(plan.orderedCardIds.count) cards")
            loadSavedPlans()
            return plan
        } catch {
            logger.error("SessionBuilder: save plan failed — \(error.localizedDescription)")
            return nil
        }
    }

    /// SAME AS LAST: the most recently used saved plan (by lastUsedAt).
    var lastUsedPlan: SessionPlan? { savedPlans.first(where: { $0.lastUsedAt != nil }) }

    /// Load a saved (or preset) plan back into the editable draft.
    func loadPlan(_ plan: SessionPlan) {
        // Ensure the deck is loaded (degrades to the-opener on an unknown id).
        if deck?.id != plan.deckId { start(deckId: plan.deckId) }
        draft = SessionDraft(
            deckId: plan.deckId,
            deckVariant: plan.deckVariant,
            orderedCardIds: plan.orderedCardIds,
            perCardTimerSeconds: plan.perCardTimerSeconds,
            globalTimerSeconds: plan.globalTimerSeconds,
            settings: SessionSettings(isApart: plan.isLDR),
            title: plan.title
        )
    }

    /// PRESETS: built-in authored templates. V1 ships ONE deck, so the only
    /// preset is the-opener's authored order. Cloning "an authored deck" here
    /// degrades gracefully to that. More presets land when more decks are authored.
    struct Preset: Identifiable { let id: String; let deckId: String; let title: String }
    var presets: [Preset] {
        [Preset(id: "opener-authored", deckId: Self.defaultDeckId, title: "The Opener")]
    }
    func applyPreset(_ preset: Preset) {
        start(deckId: preset.deckId)   // authored order, whole deck
    }

    // MARK: - Start (hand out to the existing Player)

    /// Resolve the final hand and mark the underlying plan (if saved) as used.
    /// Returns the [Card] the caller hands to CardSessionContainerView.
    func startSession() -> [Card] {
        let hand = applyFirmCap(resolvedHand())
        // If this draft matches a saved plan, bump lastUsedAt for "same as last".
        touchLastUsedIfSaved()
        return hand
    }

    private func touchLastUsedIfSaved() {
        guard let draft else { return }
        let context = ModelContext(modelContainer)
        var fetch = FetchDescriptor<SessionPlan>()
        fetch.fetchLimit = 50
        guard let plans = try? context.fetch(fetch) else { return }
        if let match = plans.first(where: {
            $0.deckId == draft.deckId && $0.orderedCardIds == draft.orderedCardIds
        }) {
            match.lastUsedAt = Date()
            try? context.saveWithLogging()
        }
    }

#if DEBUG
    static var preview: SessionBuilderStore {
        let s = SessionBuilderStore(modelContainer: .previewContainer, appState: AppState())
        s.start()
        return s
    }
#endif
}
```

> **Multi-deck note (encode this):** `presets` and every deck lookup degrade to `the-opener`. Only one
> deck exists today; the plan must not assume more. Do not hardcode a preset that can't load.

**Done:** each fast path leaves a valid `draft` (and, for save, a persisted `SessionPlan`);
`startSession()` returns a `[Card]` hand identical in shape to what the Player already consumes.

---

### Segment 6 — `SessionBuilderRow` (one card row)

**One thing:** render a single draft card with order index, prompt preview, ritual badge, drop button,
and a per-card timer chip. Keyed by `card.id` (Card is not Hashable).

Create `Vayl/Features/Sessions/Builder/SessionBuilderRow.swift`:

```swift
//
//  SessionBuilderRow.swift
//  Vayl
//
//  One card in the Session Builder list. Presentation only — every mutation is
//  a call back into SessionBuilderStore. Keyed by card.id.
//

import SwiftUI

struct SessionBuilderRow: View {

    let index: Int
    let card: Card
    let timerSeconds: Int?
    let onDrop: () -> Void
    let onCycleTimer: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text("\(index + 1)")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: AppSpacing.lg, alignment: .center)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                if card.isCeremonial {
                    Text("RITUAL")
                        .font(AppFonts.overline)
                        .foregroundStyle(AppColors.spectrumText)
                }
                Text(card.text)
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
                    .lineLimit(2)
            }

            Spacer(minLength: AppSpacing.sm)

            // Per-card timer chip — tap cycles through the ladder.
            Button(action: onCycleTimer) {
                Text(timerLabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(timerSeconds == nil ? AppColors.textTertiary : AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.pill)
                            .stroke(AppColors.spectrumBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button(action: onDrop) {
                Image(systemName: "minus.circle")
                    .foregroundStyle(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove card \(index + 1)")
        }
        .padding(.vertical, AppSpacing.sm)
        .padding(.horizontal, AppSpacing.md)
        .scaleEffect(isPressed && !reduceMotion ? 0.98 : 1.0)
    }

    private var timerLabel: String {
        guard let s = timerSeconds else { return "no timer" }
        return "\(s / 60)m"
    }
}
```

**Done:** rows render prompt preview + order index; rituals badged; timer chip + drop button wired to
store callbacks; `id: \.id` keying is safe.

---

### Segment 7 — `SessionSettingsSection` (settings block)

**One thing:** the settings UI, bound to the store — depth ceiling, together/apart, sensitive toggle,
safe-word reminder note.

Create `Vayl/Features/Sessions/Builder/SessionSettingsSection.swift`:

```swift
//
//  SessionSettingsSection.swift
//  Vayl
//
//  The Session Builder's settings block. Presentation only; every control calls
//  back into SessionBuilderStore. Together vs apart drives isLDR.
//

import SwiftUI

struct SessionSettingsSection: View {

    @Bindable var store: SessionBuilderStore

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Settings")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)

            // Depth ceiling
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("How deep tonight")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                HStack(spacing: AppSpacing.sm) {
                    ForEach(SessionSettings.DepthCeiling.allCases) { ceiling in
                        pill(ceiling.label,
                             selected: store.draft?.settings.depthCeiling == ceiling) {
                            store.setDepthCeiling(ceiling)
                        }
                    }
                }
            }

            // Together vs apart → isLDR
            Toggle(isOn: Binding(
                get: { store.draft?.settings.isApart ?? false },
                set: { store.setApart($0) }
            )) {
                Text("We're apart tonight")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .tint(AppColors.accentPrimary)

            // Sensitive cards
            Toggle(isOn: Binding(
                get: { store.draft?.settings.includeSensitive ?? true },
                set: { store.setIncludeSensitive($0) }
            )) {
                Text("Include sensitive cards")
                    .font(AppFonts.bodyText)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .tint(AppColors.accentPrimary)

            // Safe word note (always "red")
            Text("Either of you can say \"red\" any time to end the session gently.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .vaylGlassCard()
    }

    @ViewBuilder
    private func pill(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(selected ? AppColors.textPrimary : AppColors.textSecondary)
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.pill)
                        .stroke(selected ? AppColors.spectrumBorder
                                          : LinearGradient(colors: [AppColors.textTertiary],
                                                           startPoint: .leading, endPoint: .trailing),
                                lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
```

> Note: verify `AppColors` exposes a plain stroke color for the unselected pill; if `spectrumBorder` is a
> `LinearGradient` (it is, `AppColors.swift:622`), use a solid token like `AppColors.textTertiary` wrapped
> in a `LinearGradient` as above, or the nearest existing hairline stroke helper. Do not invent a token.

**Done:** settings render and mutate the draft; apart drives `isLDR`; safe-word note present; no raw
literals.

---

### Segment 8 — `SessionBuilderView` (the `.vaylSheet` UI: list + fast paths + estimate + CTA)

**One thing:** the whole authoring screen. Reorderable list, fast-path row, live estimate bar, soft
over-length nudge + opt-in firm cap, empty state, and a "Start session" CTA that calls
`store.startSession()` and hands the resulting `[Card]` to the caller via `onStart`.

Create `Vayl/Features/Sessions/Builder/SessionBuilderView.swift`:

```swift
//
//  SessionBuilderView.swift
//  Vayl
//
//  The Session Builder — a .vaylSheet (discrete authoring task you return from).
//  It shapes a SessionPlan and, on Start, resolves the hand and hands it up via
//  onStart. The caller then presents the EXISTING CardSession .vaylCover with it.
//  This view never touches the transport or the Player.
//

import SwiftUI

struct SessionBuilderView: View {

    @Bindable var store: SessionBuilderStore

    /// The resolved [Card] hand is handed up; the caller opens the session cover.
    let onStart: ([Card]) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.loadFailed || store.deck == nil {
            emptyState
        } else {
            VStack(spacing: 0) {
                header
                fastPathRow
                List {
                    ForEach(Array(store.orderedCards.enumerated()), id: \.element.id) { pair in
                        SessionBuilderRow(
                            index: pair.offset,
                            card: pair.element,
                            timerSeconds: store.draft?.timerSeconds(for: pair.element.id),
                            onDrop: { store.drop(pair.element.id) },
                            onCycleTimer: { cycleTimer(for: pair.element.id) }
                        )
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .onMove { store.move(from: $0, to: $1) }

                    SessionSettingsSection(store: store)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.editMode, .constant(.active))   // always reorderable

                estimateBar
                startCTA
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppSpacing.xs) {
            Text("Build tonight's session")
                .font(AppFonts.sectionHeading)
                .foregroundStyle(AppColors.textPrimary)
            Text(store.isAuthoredOrder ? "Playing as written" : "Your order")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.top, AppSpacing.lg)
        .padding(.bottom, AppSpacing.md)
    }

    // MARK: - Fast paths

    private var fastPathRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                chip("Quick") { store.quickAutoPick(depth: .open, targetCards: 6) }
                if let last = store.lastUsedPlan {
                    chip("Same as last") { store.loadPlan(last) }
                }
                ForEach(store.presets) { preset in
                    chip(preset.title) { store.applyPreset(preset) }
                }
                chip("Reset to written") { store.resetToAuthored() }
            }
            .padding(.horizontal, AppSpacing.md)
        }
        .padding(.bottom, AppSpacing.sm)
    }

    // MARK: - Estimate + nudge

    private var estimateBar: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack {
                Text("\(store.draft?.cardCount ?? 0) cards")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text(store.estimateLabel)
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
            if store.isOverLength {
                HStack {
                    Text("That's a long sitting. Trim it, or set a firm cap.")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textTertiary)
                    Spacer()
                    Button(store.draft?.settings.firmCapEnabled == true ? "Cap on" : "Cap it") {
                        store.setFirmCap(
                            enabled: !(store.draft?.settings.firmCapEnabled ?? false)
                        )
                    }
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.spectrumText)
                }
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    // MARK: - CTA

    private var startCTA: some View {
        VaylButton(label: "Start session  ·  \(store.draft?.cardCount ?? 0)") {
            onStart(store.startSession())
        }
        .disabled((store.draft?.cardCount ?? 0) == 0)
        .padding(.horizontal, AppSpacing.md)
        .padding(.bottom, AppSpacing.lg)
    }

    // MARK: - Empty state (deck failed to load)

    private var emptyState: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.textTertiary)
            Text("No deck to build from")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)
            Text("We couldn't load a deck. Try again in a moment.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.xl)
    }

    // MARK: - Helpers

    private func cycleTimer(for id: String) {
        let options = SessionBuilderStore.timerOptions
        let current = store.draft?.perCardTimerSeconds[id]
        let idx = options.firstIndex(where: { $0 == current }) ?? 0
        let next = options[(idx + 1) % options.count]
        store.setPerCardTimer(next, for: id)
    }

    @ViewBuilder
    private func chip(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.pill)
                        .stroke(AppColors.spectrumBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview("Session Builder") {
    SessionBuilderView(store: .preview, onStart: { _ in })
        .modelContainer(.previewContainer)
        .preferredColorScheme(.dark)
}
#endif
```

**Done:** the sheet renders the seeded authored-order list, is reorderable (`.onMove` + always-active
edit mode), droppable, timer-cyclable; fast-path chips work; the estimate bar + soft nudge + opt-in cap
show; empty state on load failure; "Start" calls `onStart(store.startSession())`.

---

### Segment 9 — Wire the Builder into the two launch sites (replace the ad-hoc hand path)

**One thing:** route Home "Settle in" and Play "begin" through the Builder `.vaylSheet` first; the
Builder's `onStart` sets the same `sessionHand` the existing `.vaylCover` already consumes. **The cover
block and `CardSessionContainerView` are untouched.**

**Home** — in `Vayl/Features/Home/Views/HomeDashboardView.swift`:

- Add state next to `sessionHand` (line ~101):

```swift
@State private var builderStore: SessionBuilderStore?
@State private var showBuilder = false
```

- Change `startHand()` (~408-412) so it opens the Builder seeded with the carousel selection, instead of
  jumping straight to the cover:

```swift
private func startHand() {
    let store = SessionBuilderStore(modelContainer: modelContext.container, appState: appState)
    store.start(preselectedIds: handIDs)   // authored order, narrowed to the selection
    builderStore = store
    showBuilder = true
    handIDs = []
}
```

> `modelContext` + `appState` are already in this view (it uses `modelContext.container` for the cover
> and reads `AppState`). Confirm the exact env property names when you build; the container view uses
> `@Environment(\.modelContext)` + `@Environment(AppState.self)`.

- Add the Builder sheet next to the existing `.vaylCover` (after the 267-274 block, do NOT modify it):

```swift
.vaylSheet(
    isPresented: $showBuilder,
    heightFraction: 0.92,
    screenHeight: layout.screenHeight
) {
    if let builderStore {
        SessionBuilderView(store: builderStore) { hand in
            showBuilder = false
            sessionHand = hand          // hands off to the EXISTING cover, unchanged
        }
    }
}
```

**Play** — in `Vayl/Features/Play/PlayView.swift`, mirror the same seam so `begin`/ceremony opens the
Builder before the cover. The store already exposes `sessionHand`; add a `builderStore`/`showBuilder`
pair on `PlayStore` (or as `@State` in `PlayView`) and, in `PlayStore.begin(_:)` /
`ceremonyFinished()` (`PlayStore.swift:134-148`), replace `sessionHand = deck.orderedCards` with opening
the Builder seeded via `store.start(deckId: id)`. The Builder's `onStart` sets `sessionHand`. Keep the
existing `.vaylCover` (`PlayView.swift:82-87`) exactly as-is.

> **The invariant that makes this safe:** every path still ends at `sessionHand = [Card]` →
> `CardSessionContainerView(hand:)`. The Builder is inserted *before* that assignment. Nothing downstream
> (cover, `CoupleSessionStore`, Airlock, Player, Realtime) changes.

**Done:** "Settle in" (Home) and "begin" (Play) open the Builder sheet; "Start session" inside it sets
`sessionHand`, which opens the unchanged session cover with the authored (or customized) hand.

---

## Definition of Done (build-green)

When the single pass is finished and the project compiles:

1. `SessionPlan.stub` is deleted; `SessionPlan.seed(from:coupleId:title:)` + `.from(draft:coupleId:)` exist.
2. `SessionBuilderStore.start()` loads `the-opener` and seeds the draft in **authored order, rituals
   included**; an unknown deck id degrades to `the-opener`.
3. `resolvedHand()` / `startSession()` return a `[Card]` in draft order — the exact shape
   `CardSessionContainerView(hand:)` already consumes. `CoupleSessionStore` is byte-for-byte unchanged.
4. Reorder (`.onMove`), drop, `resetToAuthored`, `isAuthoredOrder`, per-card + global timers, and all
   settings (depth ceiling, apart→`isLDR`, sensitive, safe-word) mutate the draft.
5. Live estimate (`estimateLabel`), soft over-length nudge (`isOverLength`), and opt-in firm cap
   (`setFirmCap` / `applyFirmCap`) work; the cap only trims at start and is off by default.
6. Fast paths: `quickAutoPick`, `saveDraftAsPlan` (persists a `SessionPlan` via `saveWithLogging`),
   `lastUsedPlan` / `loadPlan` (same-as-last), `presets` / `applyPreset` (clones authored deck, degrades
   to the-opener).
7. `SessionBuilderView` is a `.vaylSheet` with a reorderable list, fast-path chips, estimate bar, nudge,
   empty state, and a "Start session" CTA calling `onStart(store.startSession())`.
8. Home "Settle in" and Play "begin" route through the Builder sheet; both still end at `sessionHand`
   feeding the **existing** `.vaylCover`. No raw `.sheet`/`.fullScreenCover`. No banned iOS-26 APIs. No
   raw color/font/spacing/radius literals in the new Views.

---

## Bryan verifies on device

1. **Authored default plays through.** Home → tap the deck → "Settle in" opens the Builder pre-seeded
   with `the-opener` in authored order (rituals included). Hit "Start session" without editing → the
   session plays the deck in exactly the written order, same as before. (This is the one device-only
   check the caveat named.)
2. **Custom order/timers/settings reflect in the Player.** Reorder two cards, drop one, set a per-card
   timer, toggle "we're apart," then Start → the Player shows the reordered, trimmed hand; the count
   matches; apart-mode / timer surface where the Player expects them.
3. **Fast paths feel right.** 🎚️ Quick auto-pick length (default 6) and depth (default Open); the soft
   nudge threshold (12 cards); per-card timer ladder (`nil/1/2/3/5 min`); the 2.5-min/card estimate
   default. Tune these on device; don't re-derive them.
4. **Save & same-as-last.** Save a plan, reopen the Builder, tap "Same as last" → it reloads that plan.
5. **Play launch parity.** From Play → begin a deck → the Builder opens, Start plays identically.

---

## Constraints / do-not-touch

- **Do NOT touch the transport / Airlock (S2):** `Vayl/Core/Services/RealtimeSessionService.swift`,
  `Vayl/Features/Sessions/AirlockView.swift`, and the realtime scaffold methods in `CoupleSessionStore`
  (`liveOpen`/`liveAdvance`/`liveComplete`/`startRemoteSync`). The Builder never speaks to Realtime.
- **Do NOT touch the Player internals (S4):** `Vayl/Features/Sessions/SessionPlayerView.swift`,
  `SessionCloseView.swift`, `CardSessionContainerView.swift`, and `CoupleSessionStore`'s phase machine /
  persistence. The Builder's only contract with them is the `[Card]` hand it hands to
  `CardSessionContainerView(hand:)`. **Do not change that initializer's signature.**
- **Authored order is the DEFAULT, always.** `start()` seeds authored order; `resetToAuthored()` is the
  escape hatch; the header reads "Playing as written" until the user departs. Never force a reorder or
  auto-drop (except the explicit sensitive-off and the opt-in firm cap).
- **Multi-deck is content-gated.** Only `the-opener` ships. Every deck lookup and every preset must
  degrade to `the-opener` gracefully — no assumption that a second deck exists.
- **`SessionPlan` `@Model` + `SchemaV1` registration already exist** (`ModelContainer.swift:42`). Do not
  re-add or re-register; existing fields need no migration.
- **`Card` is not `Hashable`/`Equatable`** — key everything by `card.id` (`String`); `ForEach(id: \.id)`.
- Persistence uses `ModelContext(modelContainer)` fresh at write time + `try context.saveWithLogging()`
  (mirror `CoupleSessionStore.persistSession`). Never store the context on `self`.

---

## Open decisions (each with a default — proceed on the default, flag it)

1. **Quick auto-pick defaults.** _Default: depth `.open`, `targetCards: 6`._ 🎚️ Bryan tunes on device.
2. **Soft over-length threshold.** _Default: 12 cards._ 🎚️ Tune on device.
3. **Per-card timer ladder + estimate/card.** _Default: `[nil, 60, 120, 180, 300]` s; 150 s/card
   estimate._ 🎚️ Tune on device.
4. **Does the Builder sit in front of the Play ceremony, or after it?** _Default: after the ceremony
   (ceremony → Builder → cover), matching Home's "settle in → build → play" beat._ Flag if Bryan wants
   the ceremony to be the launch instead.
5. **Should "Save" prompt for a title?** _Default: save silently under the deck title; a rename affordance
   is a later polish (not S5 scope)._ Flag.
6. **Preset list beyond the-opener.** _Default: one preset (the-opener authored), content-gated._ Grows
   when more decks are authored — do not scaffold empty presets.
