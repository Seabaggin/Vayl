# 05 · Free-Tier Gates — Centralize the Read + Close the Post-Purchase Auto-Unlock Gap

**Goal:** Make the Play deck wall's Core lock state a live read of `EntitlementStore.isCore` instead of a frozen JSON flag, so a purchase (or restore) flips every locked deck unlocked *in place*, and route the whole app's gating through one source of truth. This is a deliberately SMALL V1 pass: the gating UI already shipped with M5 (Desire reveal) and T2 (the deck-wall CORE tag + PaywallSheet wiring). The only real hole is that `PlayStore` never reads `EntitlementStore`, so purchased couples still see a locked grid until relaunch. This plan wires that read and nothing more.

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

## Context Fable needs

- **What this is (roadmap M3):** free-tier gates centralized through `EntitlementStore`. The store already
  exists and is correct — `Vayl/Features/Monetization/Store/EntitlementStore.swift` exposes the single
  gate `var isCore: Bool { tier != .free || localOwnsCore }` (server tier OR local StoreKit ownership),
  plus `purchase()` / `restore()` that flip it. It is created once in `VaylApp.init` and injected via
  `.environment(entitlementStore)` (see `Vayl/App/VaylApp.swift:34` and `:51`), so every screen can read
  it with `@Environment(EntitlementStore.self)`.

- **The canonical gate pattern to imitate (already built — M5 Desire reveal):** `DesireRevealStore` takes
  `entitlements: EntitlementStore` as an init dependency and derives lock state live:
  `var isFullyUnlocked: Bool { entitlements.isCore }` and, per match,
  `isLocked: !core && !row.isFreeReveal` (`Vayl/Features/Desire Map/Store/DesireRevealStore.swift:92,205`).
  The host view reads `entitlements` from the environment and passes it into the store's initializer
  (`Vayl/Features/Home/Views/HomeRouterView.swift:30` reads it, `:270` injects it). **Copy this pattern
  exactly for `PlayStore`.** Do NOT rebuild the reveal gate — reference it only.

- **Current Play state (the real gap):** `PlayStore` (`Vayl/Features/Play/Store/PlayStore.swift`) does
  NOT hold an `EntitlementStore`. Lock state is read straight off the static JSON flag `summary.isLocked`
  in three places — `PlayStore.resolveFeatured` (lines 69, 73), `DeckDetailView` (lines 58, 82), and
  `DeckCaseView` (line 26). That flag is decoded once from `deck-catalog.json` (`is_locked`) and never
  changes. So after a purchase, `EntitlementStore.isCore` flips `true` but the grid, the detail CTA, and
  the CORE tags all keep reading `true` for `isLocked` → **the couple stays visually locked out of decks
  they now own until the app relaunches.** T2's own handoff notes this: "post-purchase Core auto-unlock is
  a follow-up — the grid won't re-unlock until PlayStore reads EntitlementStore." This plan is that
  follow-up.

- **What is already correct (do NOT touch):** the paywall itself. `PlayView` already presents
  `PaywallSheet(entry: .playDeck(name:))` via `.vaylSheet` when `store.paywallDeck != nil`
  (`Vayl/Features/Play/PlayView.swift:89`), and `PaywallSheet.purchase()` already runs
  `entitlements.purchase()` and calls `onUnlocked` (`Vayl/Features/Monetization/Views/PaywallSheet.swift:392`).
  The locked-deck detail CTA already routes to `store.requestUnlock(deck)` →
  `paywallDeck = deck` (`PlayStore.swift:153`). The full purchase path works; only the *re-derive after it
  succeeds* is missing.

- **The V1 surface is genuinely thin — do not invent gates:**
  - **Games / Simulator gate = N/A for V1.** The rotary "Simulator" world is CUT for launch behind a
    compile-time flag, NOT an entitlement: `PlayFeatureFlags.simulatorEnabled = false`
    (`Vayl/Features/Play/Store/PlayMode.swift:26`). There is no "1 free game" entitlement gate and this
    plan must not create one.
  - **Pulse insights gate = does NOT exist as a built surface.** "Pulse insights" appears only as a
    marketing bullet in `PaywallSheet.included` — a grep of `Vayl/Features/Pulse/` for `isCore`,
    `EntitlementStore`, or `paywall` returns nothing. Out of scope for V1; do not build a Pulse gate.

- **The bright-line free surface (north-star — gating any of these is a VIOLATION):** Deck 1 `the-opener`
  (and in fact all three foundation decks currently free in the catalog: `the-opener`, `the-check-in`,
  `boundaries`), Lock In, all of Learn, journaling, pulse logging, full onboarding, Desire-Map input +
  the 1 free match, and Agreements (a free safety primitive per the Vault spec — NEVER gate it). This
  plan only changes *how the already-gated Play decks read their lock state*; it must not extend gating
  to anything on this list.

- **The rule to encode:** Views never read purchases directly. A Store exposes a derived gated bool; a
  locked state says "not yet," never "denied," and routes to `PaywallSheet(entry:)`. The single source of
  truth is `EntitlementStore.isCore`.

---

## Files

### Create
_None. This is a wiring pass — no new types or files._

### Modify

| File | Line anchor | Responsibility of the change |
|---|---|---|
| `Vayl/Features/Play/Store/PlayStore.swift` | `init` (`:43`), `resolveFeatured` (`:67`), derived section (`:107`), `#if DEBUG preview` (`:160`) | Add `entitlements: EntitlementStore` dependency; expose `isLocked(_:)` derived from `entitlements.isCore`; re-derive featured/available off it. |
| `Vayl/Features/Play/PlayView.swift` | `@State`/`@Environment` (`:15`), `.task` store build (`:38`), preview (`:106`) | Read `EntitlementStore` from the environment and pass it into the `PlayStore` initializer. |
| `Vayl/Features/Play/Components/DeckCaseView.swift` | `locked` computed (`:26`), call sites | Take the effective locked bool from the store instead of `summary.isLocked`. |
| `Vayl/Features/Play/Components/DeckCellView.swift` | props (`:13`), `DeckCaseView(...)` call (`:26`) | Thread the store-derived `locked` bool down to `DeckCaseView`. |
| `Vayl/Features/Play/Components/DeckWallView.swift` | grid `ForEach` (`:41`) | Pass `store.isLocked(s)` into each `DeckCellView`. |
| `Vayl/Features/Play/Components/DeckDetailView.swift` | `sealedNotice` gate (`:58`), `cta` gate (`:82`) | Read `store.isLocked(deck)` instead of `deck.isLocked` for the sealed notice + CTA branch. |

### Delete
_None._

---

## Build steps (segments)

> All segments ship in ONE pass. They are ordered for readability only.

### Segment 1 — `PlayStore` holds `EntitlementStore` and exposes a live `isLocked(_:)`

**One thing it does:** give `PlayStore` the entitlement dependency and a single derived method every Play
view will read, so lock state tracks `isCore` live.

`PlayStore` is `@Observable @MainActor`, so any view that reads a value routed through the store re-renders
when the underlying `entitlements.isCore` changes. The method reads `entitlements.isCore` at call time —
no caching, no manual invalidation, no notification plumbing.

**Change 1 — add the dependency and store it.** In `Vayl/Features/Play/Store/PlayStore.swift`, extend the
`// deps` block and the initializer.

Current (`:37`–`:50`):

```swift
    // deps
    private let catalog: DeckCatalogService
    private let modelContainer: ModelContainer
    private let appState: AppState

    init(modelContainer: ModelContainer,
         appState: AppState,
         catalog: DeckCatalogService = DeckCatalogService()) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.catalog = catalog
        load()
    }
```

Replace with:

```swift
    // deps
    private let catalog: DeckCatalogService
    private let modelContainer: ModelContainer
    private let appState: AppState
    private let entitlements: EntitlementStore   // the single Core gate — M3 centralizes the read here

    init(modelContainer: ModelContainer,
         appState: AppState,
         entitlements: EntitlementStore,
         catalog: DeckCatalogService = DeckCatalogService()) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.entitlements = entitlements
        self.catalog = catalog
        load()
    }
```

**Change 2 — expose the derived gate.** Add this to the `// Derived` section (just after
`func summary(_:)` / `var featured` at `:108`–`:110`):

```swift
    /// The single Core gate the whole Play tab reads. A deck is locked only while it is a Core
    /// deck AND this couple is not Core. One purchase flips `entitlements.isCore` → every locked
    /// deck re-derives to unlocked in place (no relaunch). Views read THIS, never `summary.isLocked`
    /// (the static catalog flag) or `EntitlementStore` directly.
    func isLocked(_ summary: DeckSummary) -> Bool {
        summary.isLocked && !entitlements.isCore
    }
```

**Change 3 — re-derive featured/available off the live gate.** In `resolveFeatured` (`:67`), the two
`summaries.filter { !$0.isLocked }` reads use the static flag, so a purchased couple's just-unlocked deck
would never be picked as featured until relaunch. Route them through the new method.

Current (`:67`–`:76`):

```swift
    private func resolveFeatured() {
        let progress = fetchProgress()
        let availableIDs = Set(summaries.filter { !$0.isLocked }.map(\.id))   // free = playable
        let recentInProgress = progress
            .filter { availableIDs.contains($0.deckId) && $0.completedAt == nil && $0.currentCardIndex > 0 }
            .max { ($0.firstOpenedAt ?? .distantPast) < ($1.firstOpenedAt ?? .distantPast) }
        let fallback = summaries.first { !$0.isLocked }?.id ?? summaries.first?.id
        featuredID = recentInProgress?.deckId ?? fallback
        featuredContinuity = continuity(forDeck: featuredID, in: progress)
    }
```

Replace with:

```swift
    private func resolveFeatured() {
        let progress = fetchProgress()
        let availableIDs = Set(summaries.filter { !isLocked($0) }.map(\.id))   // playable = free OR Core-owned
        let recentInProgress = progress
            .filter { availableIDs.contains($0.deckId) && $0.completedAt == nil && $0.currentCardIndex > 0 }
            .max { ($0.firstOpenedAt ?? .distantPast) < ($1.firstOpenedAt ?? .distantPast) }
        let fallback = summaries.first { !isLocked($0) }?.id ?? summaries.first?.id
        featuredID = recentInProgress?.deckId ?? fallback
        featuredContinuity = continuity(forDeck: featuredID, in: progress)
    }
```

> Note: `resolveFeatured` runs inside `load()` at init. Because the featured pick is derived and `load()`
> is cheap, an already-Core couple resolves correctly on first build. A *mid-session* purchase does not
> re-run `load()`, but that is fine: the featured deck was already playable-or-free, and the grid/detail
> lock state (Segments 2–3) re-derives live off `isLocked(_:)` regardless. Do not add a purchase observer
> to `PlayStore` — the derived reads are sufficient and simpler.

**Change 4 — fix the DEBUG preview to supply the new dependency.** The preview factory at `:157`–`:164`
builds a `PlayStore` and will no longer compile without `entitlements`.

Current:

```swift
#if DEBUG
extension PlayStore {
    /// In-memory store for SwiftUI previews (loads the bundled catalog).
    @MainActor static var preview: PlayStore {
        PlayStore(modelContainer: .previewContainer, appState: AppState())
    }
}
#endif
```

Replace with:

```swift
#if DEBUG
extension PlayStore {
    /// In-memory store for SwiftUI previews (loads the bundled catalog). Free-tier by default —
    /// the preview couple is not Core, so locked decks render locked.
    @MainActor static var preview: PlayStore {
        let appState = AppState()
        return PlayStore(
            modelContainer: .previewContainer,
            appState: appState,
            entitlements: EntitlementStore(modelContainer: .previewContainer, appState: appState)
        )
    }
}
#endif
```

**Done when:** `PlayStore` compiles with the `entitlements` dependency and `isLocked(_:)` reads
`entitlements.isCore` live; no view yet reads it (that's Segments 2–3).

---

### Segment 2 — `PlayView` injects the environment `EntitlementStore` into `PlayStore`

**One thing it does:** wire the app's real `EntitlementStore` (already in the environment) into the store
`PlayView` builds, so the gate the store reads is the live one.

This mirrors `HomeRouterView` exactly: read `@Environment(EntitlementStore.self)`, pass it into the store's
initializer.

**Change 1 — read the environment store.** In `Vayl/Features/Play/PlayView.swift`, add the environment
read alongside the existing ones (`:15`–`:19`).

Current:

```swift
struct PlayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var store: PlayStore?
```

Replace with:

```swift
struct PlayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Environment(EntitlementStore.self) private var entitlements
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var store: PlayStore?
```

**Change 2 — pass it into the store build.** In `.task` (`:38`–`:42`):

Current:

```swift
        .task {
            if store == nil && injectedStore == nil {
                store = PlayStore(modelContainer: modelContext.container, appState: appState)
            }
        }
```

Replace with:

```swift
        .task {
            if store == nil && injectedStore == nil {
                store = PlayStore(
                    modelContainer: modelContext.container,
                    appState: appState,
                    entitlements: entitlements
                )
            }
        }
```

**Change 3 — the preview already injects an `EntitlementStore` into the environment** (`PlayView.swift:109`),
so `PlayView(injectedStore: .preview)` still resolves. No preview change needed here.

**Done when:** `PlayView` compiles and the store it builds reads the app's real, live `EntitlementStore`.

---

### Segment 3 — every Play view reads the store gate, not the static flag

**One thing it does:** replace the three static `summary.isLocked` / `deck.isLocked` reads in the deck
views with `store.isLocked(...)`, so the CORE tag, the sealed notice, and the detail CTA all track `isCore`
live.

**Change 1 — `DeckCaseView` takes the effective locked bool.** It currently derives `locked` from
`summary.isLocked` (`:22`–`:26`), which is static. Make it a passed-in parameter so the store's live gate
flows down. (Keeping it a plain `Bool` prop keeps this static, `.drawingGroup`-friendly render dumb — it
just draws what it's told.)

Current (`:22`–`:26`):

```swift
struct DeckCaseView: View {
    let summary: DeckSummary
    let style: DeckStyle

    private var locked: Bool { summary.isLocked }
```

Replace with:

```swift
struct DeckCaseView: View {
    let summary: DeckSummary
    let style: DeckStyle
    /// Effective lock state from the store's live Core gate (NOT `summary.isLocked`, the static
    /// catalog flag). A purchase flips this false and the CORE tag disappears in place.
    var locked: Bool
```

> The `#Preview("Cases")` at the bottom of `DeckCaseView.swift` (`:234`–`:250`) constructs
> `DeckCaseView(summary: s, style: …)` and will no longer compile. Update that call to pass the static
> flag for the preview (no store in scope there):
>
> ```swift
>                 ForEach(samples) { s in
>                     DeckCaseView(summary: s, style: DeckStyle.make(for: s), locked: s.isLocked)
>                 }
> ```

**Change 2 — `DeckCellView` threads the bool through.** It builds `DeckCaseView` (`:26`). Add a `locked`
prop and forward it.

Current (`:13`–`:27`):

```swift
struct DeckCellView: View {
    let summary: DeckSummary
    let style: DeckStyle
    var index: Int = 0
    var namespace: Namespace.ID
    var onTap: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                DeckCaseView(summary: summary, style: style)
                    .matchedGeometryEffect(id: summary.id, in: namespace, isSource: true)
```

Replace with:

```swift
struct DeckCellView: View {
    let summary: DeckSummary
    let style: DeckStyle
    let locked: Bool
    var index: Int = 0
    var namespace: Namespace.ID
    var onTap: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                DeckCaseView(summary: summary, style: style, locked: locked)
                    .matchedGeometryEffect(id: summary.id, in: namespace, isSource: true)
```

**Change 3 — `DeckWallView` passes the store gate into each cell.** The grid `ForEach` (`:41`–`:45`)
builds each `DeckCellView`.

Current:

```swift
            ForEach(Array(store.summaries.enumerated()), id: \.element.id) { i, s in
                DeckCellView(summary: s, style: store.style(for: s), index: i, namespace: namespace) {
                    store.openDetail(s.id)
                }
            }
```

Replace with:

```swift
            ForEach(Array(store.summaries.enumerated()), id: \.element.id) { i, s in
                DeckCellView(summary: s, style: store.style(for: s), locked: store.isLocked(s),
                             index: i, namespace: namespace) {
                    store.openDetail(s.id)
                }
            }
```

**Change 4 — `DeckDetailView` reads the store gate for the sealed notice + CTA.** Both the sealed notice
(`:58`) and the CTA branch (`:79`–`:87`) read the static `deck.isLocked` / `d.isLocked`. `DeckDetailView`
already holds `store`, so route through it. Also thread `locked` into the detail's own `DeckCaseView`
(`:32`) so the CORE tag in the zoomed detail matches.

Current sealed-notice gate + case build (`:32`, `:58`):

```swift
                    DeckCaseView(summary: deck, style: store.style(for: deck))
                        .frame(width: 190)
```
...
```swift
                    if deck.isLocked { sealedNotice() }
                    cta(deck)
```

Replace the case build with:

```swift
                    DeckCaseView(summary: deck, style: store.style(for: deck), locked: store.isLocked(deck))
                        .frame(width: 190)
```

Replace the sealed-notice line with:

```swift
                    if store.isLocked(deck) { sealedNotice() }
                    cta(deck)
```

Current CTA (`:78`–`:87`):

```swift
    @ViewBuilder
    private func cta(_ d: DeckSummary) -> some View {
        // Free vs Core: a Core deck offers the paywall; a free deck begins.
        // Canonical VaylButton — not a hand-rolled CTA.
        if d.isLocked {
            VaylButton(label: "Unlock with Core") { store.requestUnlock(d) }
        } else {
            VaylButton(label: "Begin") { store.beginCeremony(d.id) }
        }
    }
```

Replace with:

```swift
    @ViewBuilder
    private func cta(_ d: DeckSummary) -> some View {
        // Free vs Core, read LIVE off the store's Core gate (not the static catalog flag): a still-locked
        // Core deck offers the paywall; a free or now-owned deck begins. Canonical VaylButton.
        if store.isLocked(d) {
            VaylButton(label: "Unlock with Core") { store.requestUnlock(d) }
        } else {
            VaylButton(label: "Begin") { store.beginCeremony(d.id) }
        }
    }
```

> `DeckSummary.swift`'s own `#Preview("Catalog decodes")` (`:27`) reads `s.isLocked` for a caption string.
> That is a standalone preview with no store and is describing the catalog flag directly — leave it
> unchanged.

**Done when:** the CORE tag (grid + detail case), the sealed notice, and the detail CTA all read
`store.isLocked(...)`; the project compiles.

---

## Definition of Done (build-green)

When the single pass is finished and the project compiles:

- [ ] `PlayStore` has an `entitlements: EntitlementStore` dependency (required init param) and exposes
      `func isLocked(_ summary: DeckSummary) -> Bool { summary.isLocked && !entitlements.isCore }`.
- [ ] `PlayStore.resolveFeatured` derives the available/featured set via `isLocked(_:)`, not the raw flag.
- [ ] `PlayView` reads `@Environment(EntitlementStore.self)` and passes it into the `PlayStore` it builds.
- [ ] `DeckCaseView`, `DeckCellView`, `DeckWallView`, and `DeckDetailView` read lock state from
      `store.isLocked(...)` — grep of `Vayl/Features/Play/` for `.isLocked` shows the only remaining reads
      are `DeckSummary.isLocked` (the model property + its own catalog-describing preview) and
      `PlayStore.isLocked(_:)` itself.
- [ ] No View reads `EntitlementStore` to make a Play lock decision — it goes through `PlayStore`.
- [ ] All `#Preview`s that construct `PlayStore` / `DeckCaseView` are updated and compile.
- [ ] The paywall path is unchanged: locked detail CTA → `store.requestUnlock` → `PaywallSheet(entry:
      .playDeck(name:))` via `.vaylSheet`; `PaywallSheet.purchase()` → `entitlements.purchase()`.
- [ ] No new gate introduced anywhere for Simulator/games, Pulse insights, Learn, journaling, pulse
      logging, onboarding, Desire-Map input/free-match, or Agreements.
- [ ] No new files; no deletions; no model or JSON changes.

---

## Bryan verifies on device

- [ ] **Free couple:** the deck wall shows the three foundation decks (`the-opener`, `the-check-in`,
      `boundaries`) without a CORE tag; every other deck shows the gold CORE tag. Tapping a CORE deck →
      detail shows the "The cards unlock with Core." sealed notice + an "Unlock with Core" CTA, which
      opens the paywall sheet. Free decks show "Begin."
- [ ] **Purchase in place (the core fix 🎚️):** from a locked deck's detail, tap Unlock → complete a
      StoreKit sandbox purchase → the paywall dismisses and, **without relaunching**, every CORE tag
      disappears from the wall and that deck's detail now shows "Begin." Confirm the whole grid flips at
      once, not just the one deck.
- [ ] **Restore:** on a fresh install of an already-Core couple, "Restore purchase" in the paywall footer
      unlocks the grid in place the same way.
- [ ] **Already-Core couple, cold launch:** the wall renders with no CORE tags at all on first paint (no
      flash of locked → unlocked).
- [ ] **Free surfaces untouched:** Deck 1 / foundation decks, Learn, journaling, pulse logging, the Desire
      Map input + 1 free match, and Agreements are all reachable with no paywall anywhere.

---

## Constraints / do-not-touch

- **Do NOT touch `EntitlementStore.swift`.** It is correct and shared by M5; its `isCore` is the source of
  truth. This plan only *reads* it.
- **Do NOT touch `PaywallSheet.swift`, the purchase/restore flow, or `PlayView`'s `.vaylSheet` paywall
  presentation.** They already work; only the lock *read* was missing.
- **Do NOT touch the Desire reveal gate** (`DesireRevealStore`) — reference only.
- **Do NOT change `deck-catalog.json`, `DeckSummary`, or `Deck`.** `is_locked` stays the static
  "is this a Core deck" fact; the *effective* lock is computed in `PlayStore.isLocked(_:)`. (`Deck` even
  already carries an unused `isAvailable(for tier:)` helper — do not wire or delete it in this pass.)
- **Do NOT add a purchase observer / notification to `PlayStore`.** The `@Observable` derived-read chain
  (View reads `store.isLocked` → store reads `entitlements.isCore`) is sufficient for live re-derive.
- **Do NOT introduce any new gate.** No Simulator/games gate (flag-cut for V1), no Pulse-insights gate
  (unbuilt), and never gate a free-surface north-star item.
- **Copy rule:** no em dashes in any user-facing string. (No new copy is introduced here; the existing
  "The cards unlock with Core." / "Unlock with Core" strings stay.)

---

## Open decisions (each with a recommended default — proceed on the default, flag it)

1. **`solo-prep` is marked `is_locked: true` in `deck-catalog.json`, but `PaywallSheet` copy promises
   "your solo decks are always free."** This is a data/copy inconsistency, not a code bug in this plan.
   **Recommended default:** leave the catalog as-is for this pass (do NOT edit JSON here — it's out of
   scope and would change the free/paid boundary), and flag it to Bryan as a separate catalog decision.
   Fable: implement the read-centralization exactly as specified and note this discrepancy in the summary.

2. **Mid-session purchase does not re-run `PlayStore.resolveFeatured`, so the *featured hero* deck won't
   re-pick a newly-unlocked deck until relaunch** (the grid + detail lock state DO re-derive live). The
   featured deck was already a free/owned deck, so nothing breaks; it's a cosmetic "hero doesn't switch to
   a just-unlocked deck" nicety. **Recommended default:** accept this for V1 (no observer) — it's within
   the "deliberately small" scope and avoids adding purchase-observation plumbing to `PlayStore`. If Bryan
   wants the hero to re-resolve on purchase, that's a one-line follow-up (call `resolveFeatured()` from an
   `onChange(of: entitlements.isCore)` in `PlayView`), flagged but not built here.

3. **Should `isLocked(_:)` live on `PlayStore` or on a `DeckSummary` extension taking a tier?** A
   `DeckSummary.isAvailable(for:)` mirror of `Deck.isAvailable(for:)` would be model-pure, but then each
   view would need the tier and would read `entitlements` directly — a View-reads-purchases violation.
   **Recommended default:** keep the gate on `PlayStore` (as specified) so Views only ever talk to the
   Store. This is the architecturally correct home for the decision.
