# Discussion Card ("Talk about this") Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn the stub discussion card into a real tier-based conversation prompt that surfaces in the Vault's Desire segment and is pointed to by a low-hierarchy wayfinder in the reveal.

**Architecture:** `companion_cards.json` (Content) → `ContentLoader` (Service) → `CompanionCardStore` (resolver, owned by `VaultStore`) → `VaultStore` (state owner, resolves + exposes `selectedDiscussionCard`) → `VaultSheet` / `VaultDesireSection` (View). The reveal's `DesireStarDetailSheet` gets an `onTalkTapped` closure that dismisses the cover, switches tab, and signals `MapView` to auto-open the Vault. No second renderer; `ConversationCard` is reused.

**Tech Stack:** Swift 6, SwiftUI, `@Observable @MainActor`, `ContentLoader` (bundle JSON), `ConversationCard` (existing renderer).

**Read before starting:**
- `docs/superpowers/specs/2026-06-27-discussion-card-implementation-plan.md` — the resolved §2 decisions
- `Vayl/Core/Models/CompanionCard.swift` — existing data shape being extended
- `Vayl/Core/Services/ContentLoader.swift` — the load pattern to mirror
- `Vayl/Design/Components/Cards/ConversationCard.swift` + `ConversationCardTypes.swift` — the renderer to wrap
- `Vayl/Features/Map/Vault/VaultStore.swift` — where discussion state lives
- `Vayl/Features/Map/Vault/Components/VaultDesireSection.swift` — rows being wired
- `Vayl/Features/Map/MapView.swift` — where Vault is presented + `showVault` state
- `Vayl/Features/Desire Map/Views/Components/DesireStarDetailSheet.swift` — wayfinder destination

---

## File map

| Action | File | What changes |
|---|---|---|
| Create | `Vayl/Resources/Content/companion_cards.json` | 3-tier prompt pool content |
| Modify | `Vayl/Core/Models/CompanionCard.swift` | Add `CompanionCardTier`, `CompanionCardPool`, `CompanionCardPrompt` |
| Modify | `Vayl/Core/Services/ContentLoader.swift` | Add `loadCompanionCards()` |
| Modify | `Vayl/Features/Desire Map/Store/CompanionCardStore.swift` | Real tier lookup, retire stubs |
| Modify | `Vayl/Features/Map/Vault/VaultStore.swift` | Add `selectedDiscussionCard`, `openDiscussion`, `closeDiscussion` |
| Create | `Vayl/Features/Map/Vault/Components/DiscussionCardView.swift` | Card view wrapping `ConversationCard` |
| Modify | `Vayl/Features/Map/Vault/Components/VaultDesireSection.swift` | Wire `alignRow` + `openedRow` taps |
| Modify | `Vayl/Features/Map/Vault/VaultSheet.swift` | Present `DiscussionCardView` as `.vaylSheet` |
| Modify | `Vayl/Core/Services/AppState.swift` | Add `vaultOpenPending: Bool` |
| Modify | `Vayl/Features/Desire Map/Views/Components/DesireStarDetailSheet.swift` | Thread `onTalkTapped` to `DesireMatchDetail` |
| Modify | `Vayl/Features/Map/MapView.swift` | Watch `vaultOpenPending`, auto-open Vault |
| Modify | `VaylTests/DesireMapStoreTests.swift` | Add companion card + content loader tests |

---

## Task 1: Content types + `companion_cards.json` + `ContentLoader`

**Files:**
- Modify: `Vayl/Core/Models/CompanionCard.swift`
- Modify: `Vayl/Core/Services/ContentLoader.swift`
- Create: `Vayl/Resources/Content/companion_cards.json`
- Modify: `VaylTests/DesireMapStoreTests.swift`

- [ ] **Step 1: Add `CompanionCardTier`, `CompanionCardPool`, `CompanionCardPrompt` to `CompanionCard.swift`**

Open `Vayl/Core/Models/CompanionCard.swift`. The file currently holds only `struct CompanionCard`. Append these types below it:

```swift
// MARK: - Tier

enum CompanionCardTier: String, Codable {
    case mutual
    case adjacent
    case consentOpened = "consent_opened"
}

// MARK: - Content pool (deserialized from companion_cards.json)

struct CompanionCardPool: Codable {
    let tier: CompanionCardTier
    let prompts: [CompanionCardPrompt]
}

struct CompanionCardPrompt: Codable, Identifiable {
    let id: String
    let text: String
}
```

- [ ] **Step 2: Add `ContentLoader.loadCompanionCards()` to `ContentLoader.swift`**

In `Vayl/Core/Services/ContentLoader.swift`, add inside `struct ContentLoader` after `loadDesireItems()`:

```swift
static func loadCompanionCards() throws -> [CompanionCardPool] {
    try load(CompanionCardPool.self, from: "companion_cards")
}
```

- [ ] **Step 3: Create `Vayl/Resources/Content/companion_cards.json`**

```json
[
  {
    "tier": "mutual",
    "prompts": [
      { "id": "m1", "text": "What part of this feels most exciting to you?" },
      { "id": "m2", "text": "When you imagine exploring this together, what does that look like?" },
      { "id": "m3", "text": "Is there a version of this that feels like the right starting point?" },
      { "id": "m4", "text": "What would make this feel really good for both of you?" },
      { "id": "m5", "text": "Has this been something you have been thinking about for a while, or is it newer?" }
    ]
  },
  {
    "tier": "adjacent",
    "prompts": [
      { "id": "a1", "text": "What draws you toward this, even if you are not sure yet?" },
      { "id": "a2", "text": "Is there a part of this that feels easier to imagine than others?" },
      { "id": "a3", "text": "What would you want me to know about how you are thinking about it?" },
      { "id": "a4", "text": "What would make exploring this feel comfortable for you?" },
      { "id": "a5", "text": "Are there parts of this you are more curious about than others?" }
    ]
  },
  {
    "tier": "consent_opened",
    "prompts": [
      { "id": "c1", "text": "No rush here. Where would you want to start?" },
      { "id": "c2", "text": "Is there something you would want to understand better before going further?" },
      { "id": "c3", "text": "What would make this conversation feel easy?" },
      { "id": "c4", "text": "What matters most to you about how this goes?" },
      { "id": "c5", "text": "What would a comfortable first step look like for you?" }
    ]
  }
]
```

> **Important:** After creating the file, add it to the Xcode target: in Xcode, drag the file into the `Resources/Content` group and confirm "Add to targets: Vayl" is checked. The JSON is read via `Bundle.main.url(forResource:withExtension:)` — it must be in the app bundle.

- [ ] **Step 4: Write failing tests in `VaylTests/DesireMapStoreTests.swift`**

Add at the bottom of the file (inside the existing `final class DesireMapStoreTests: XCTestCase`):

```swift
// MARK: - CompanionCard content loader

func test_loadCompanionCards_returnsThreeTiers() throws {
    let pools = try ContentLoader.loadCompanionCards()
    XCTAssertEqual(pools.count, 3)
    let tiers = Set(pools.map(\.tier))
    XCTAssertTrue(tiers.contains(.mutual))
    XCTAssertTrue(tiers.contains(.adjacent))
    XCTAssertTrue(tiers.contains(.consentOpened))
}

func test_loadCompanionCards_eachTierHasPrompts() throws {
    let pools = try ContentLoader.loadCompanionCards()
    for pool in pools {
        XCTAssertFalse(pool.prompts.isEmpty, "Tier \(pool.tier.rawValue) has no prompts")
    }
}
```

- [ ] **Step 5: Build and run tests**

In Xcode: Product → Test (Cmd+U). Focus on the two new tests.
Expected: both pass. If `loadCompanionCards` throws `fileNotFound`, the JSON was not added to the bundle target — check Step 3's Xcode target membership.

- [ ] **Step 6: Commit**

```bash
git add Vayl/Core/Models/CompanionCard.swift
git add Vayl/Core/Services/ContentLoader.swift
git add Vayl/Resources/Content/companion_cards.json
git add VaylTests/DesireMapStoreTests.swift
git commit -m "feat(discussion-card): companion_cards.json + ContentLoader + pool types"
```

---

## Task 2: Real `CompanionCardStore` — tier lookup

**Files:**
- Modify: `Vayl/Features/Desire Map/Store/CompanionCardStore.swift`
- Modify: `VaylTests/DesireMapStoreTests.swift`

- [ ] **Step 1: Write failing tests**

Add to `VaylTests/DesireMapStoreTests.swift` inside the existing test class:

```swift
// MARK: - CompanionCardStore tier lookup

func test_companionCardStore_mutualMatchReturnsMutualPrompt() async throws {
    let store = await CompanionCardStore()
    let card = await store.card(forItemId: "desire-001", tier: .mutual)
    XCTAssertNotNil(card)
    // Verify it came from the mutual pool: mutual prompts start with known ids (m1-m5)
    // We can't easily verify which prompt without mocking the loader, so just check non-generic
    XCTAssertFalse(card!.prompt.isEmpty)
}

func test_companionCardStore_sameItemAlwaysReturnsSamePrompt() async throws {
    let store = await CompanionCardStore()
    let card1 = await store.card(forItemId: "desire-003", tier: .adjacent)
    let card2 = await store.card(forItemId: "desire-003", tier: .adjacent)
    XCTAssertEqual(card1?.prompt, card2?.prompt)
}

func test_companionCardStore_consentOpenedTierUsesCorrectPool() async throws {
    let store = await CompanionCardStore()
    let pools = try ContentLoader.loadCompanionCards()
    let consentPool = pools.first { $0.tier == .consentOpened }!
    let card = await store.card(forItemId: "desire-005", tier: .consentOpened)
    XCTAssertNotNil(card)
    XCTAssertTrue(consentPool.prompts.map(\.text).contains(card!.prompt))
}
```

- [ ] **Step 2: Run tests to verify they fail**

Cmd+U. Expected: all three new tests fail because `CompanionCardStore` has no `card(forItemId:tier:)` method yet. Confirm the failure message references a missing method.

- [ ] **Step 3: Rewrite `CompanionCardStore.swift`**

Replace the entire file with:

```swift
//
//  CompanionCardStore.swift
//  Vayl
//
//  Resolves a tier-appropriate conversation prompt for a desire item.
//  Owned by VaultStore. Calls ContentLoader (service layer) for content.
//

import Foundation

@Observable
@MainActor
final class CompanionCardStore {

    private var pools: [CompanionCardPool] = []

    init() {
        pools = (try? ContentLoader.loadCompanionCards()) ?? []
    }

    /// Returns a CompanionCard for a mutual or adjacent match.
    /// Prompt selection is stable: same itemId always returns the same prompt from the tier pool.
    func card(forItemId itemId: String, tier: CompanionCardTier) -> CompanionCard? {
        guard let pool = pools.first(where: { $0.tier == tier }),
              !pool.prompts.isEmpty else { return nil }
        let idx = stableIndex(for: itemId, count: pool.prompts.count)
        let prompt = pool.prompts[idx]
        return CompanionCard(
            id: "discussion_\(tier.rawValue)_\(itemId)",
            desireItemId: itemId,
            title: "Talk about this",
            prompt: prompt.text,
            suggestedDeckId: nil
        )
    }

    // MARK: - Private

    /// Deterministic index derived from the itemId string — stable across process restarts.
    /// Uses Unicode scalar sum (not hashValue, which is randomized in Swift).
    private func stableIndex(for itemId: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let sum = itemId.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return abs(sum) % count
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Cmd+U. All three new `CompanionCardStore` tests should pass.

- [ ] **Step 5: Commit**

```bash
git add "Vayl/Features/Desire Map/Store/CompanionCardStore.swift"
git add VaylTests/DesireMapStoreTests.swift
git commit -m "feat(discussion-card): CompanionCardStore real tier lookup, retire stub"
```

---

## Task 3: `VaultStore` discussion state + `DiscussionCardView`

**Files:**
- Modify: `Vayl/Features/Map/Vault/VaultStore.swift`
- Create: `Vayl/Features/Map/Vault/Components/DiscussionCardView.swift`

- [ ] **Step 1: Add discussion state to `VaultStore`**

In `VaultStore.swift`, add after the `// MARK: - Consent exchange` block (around line 227):

```swift
// MARK: - Discussion card

private let companionCardStore = CompanionCardStore()
private(set) var selectedDiscussionCard: CompanionCard? = nil

/// Opens the discussion card for a desire item at the given tier.
func openDiscussion(itemId: String, itemName: String, tier: CompanionCardTier) {
    let card = companionCardStore.card(forItemId: itemId, tier: tier)
        ?? CompanionCard(
            id: "discussion_fallback_\(itemId)",
            desireItemId: itemId,
            title: itemName,
            prompt: "What would you want to explore together here?",
            suggestedDeckId: nil
        )
    selectedDiscussionCard = card
}

/// Clears the discussion card state.
func closeDiscussion() {
    selectedDiscussionCard = nil
}
```

The fallback prompt fires only if the JSON fails to load — it ensures the View always has something to render.

- [ ] **Step 2: Build to confirm `VaultStore` compiles**

Cmd+B. Resolve any import or type errors (e.g. `CompanionCard` and `CompanionCardTier` must be in scope — they are both in `Vayl/Core/Models/CompanionCard.swift`).

- [ ] **Step 3: Create `DiscussionCardView.swift`**

Create `Vayl/Features/Map/Vault/Components/DiscussionCardView.swift`:

```swift
//
//  DiscussionCardView.swift
//  Vayl
//
//  Renders a companion discussion card: the desire item name as context above,
//  then a ConversationCard showing the tier-appropriate prompt.
//  Hosted as a .vaylSheet from VaultSheet. Never forked — reuses ConversationCard.
//

import SwiftUI

struct DiscussionCardView: View {

    let card: CompanionCard
    var onDismiss: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            // Context header
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Talk about this")
                    .font(AppFonts.overline)
                    .tracking(1.0)
                    .foregroundStyle(AppColors.textTertiary)
                Text(card.title)
                    .font(AppFonts.sectionHeading)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.md)

            // Prompt card
            ConversationCard(
                content: .prompt(card.prompt),
                fuseConfig: .none,
                ghostDeckMode: .none,
                onPillSelected: nil,
                onContinue: onDismiss
            )
            .padding(.horizontal, AppSpacing.md)

            Spacer(minLength: AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.void)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Mutual prompt") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DiscussionCardView(
            card: CompanionCard(
                id: "preview-mutual",
                desireItemId: "desire-001",
                title: "New Relationship Energy",
                prompt: "What part of this feels most exciting to you?",
                suggestedDeckId: nil
            )
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Consent opened prompt") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        DiscussionCardView(
            card: CompanionCard(
                id: "preview-consent",
                desireItemId: "desire-007",
                title: "Overnight Stays",
                prompt: "No rush here. Where would you want to start?",
                suggestedDeckId: nil
            )
        )
    }
    .preferredColorScheme(.dark)
}
#endif
```

> **Note:** After creating this file, add it to the Xcode `Vault/Components` group (right-click the group → Add Files). The app target membership is confirmed there.

- [ ] **Step 4: Build to verify compile**

Cmd+B. Resolve any token or type errors.

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Map/Vault/VaultStore.swift
git add Vayl/Features/Map/Vault/Components/DiscussionCardView.swift
git commit -m "feat(discussion-card): VaultStore discussion state + DiscussionCardView"
```

---

## Task 4: Wire Vault rows → discussion card

**Files:**
- Modify: `Vayl/Features/Map/Vault/Components/VaultDesireSection.swift`
- Modify: `Vayl/Features/Map/Vault/VaultSheet.swift`

- [ ] **Step 1: Make align rows tappable in `VaultDesireSection`**

In `VaultDesireSection.swift`, replace the private `alignRow` method:

```swift
private func alignRow(_ item: MapStore.AlignItem) -> some View {
    let tier: CompanionCardTier = item.isMutual ? .mutual : .adjacent
    return Button {
        store.openDiscussion(itemId: item.id, itemName: item.name, tier: tier)
    } label: {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "diamond")
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppColors.spectrumBridge)
            Text(item.name)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(AppColors.textBody)
            Spacer()
            badge(item.isMutual)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm + 2)
        .contentShape(Rectangle())
    }
    .buttonStyle(PressableCardStyle())
}
```

- [ ] **Step 2: Make opened consent rows tappable in `VaultDesireSection`**

Replace the private `openedRow` method:

```swift
private func openedRow(_ c: VaultStore.ConsentVM) -> some View {
    Button {
        store.openDiscussion(itemId: c.itemId, itemName: c.itemName, tier: .consentOpened)
    } label: {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 13))
                .foregroundStyle(AppColors.spectrumCyan)
            VStack(alignment: .leading, spacing: 1) {
                Text(c.itemName).font(AppFonts.bodyMedium).foregroundStyle(AppColors.textBody)
                Text("Opened together").font(AppFonts.caption).foregroundStyle(AppColors.spectrumCyan)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding(AppSpacing.md)
        .contentShape(Rectangle())
    }
    .buttonStyle(PressableCardStyle())
    .vaylGlassCard()
}
```

- [ ] **Step 3: Present `DiscussionCardView` from `VaultSheet`**

In `VaultSheet.swift`, the file currently starts at line 1. Add the discussion card presentation. Find where the body's content ends (after the `ScrollView`) and add a `.vaylSheet` modifier.

First, read the bottom portion of `VaultSheet.swift` to find the right insertion point. The `.vaylSheet` for the discussion card should be the last modifier on the `ScrollView` (or the outermost VStack), before the `.task` calls. Add:

```swift
.vaylSheet(
    isPresented: Binding(
        get: { store.selectedDiscussionCard != nil },
        set: { if !$0 { store.closeDiscussion() } }
    ),
    heightFraction: 0.80
) {
    if let card = store.selectedDiscussionCard {
        DiscussionCardView(card: card, onDismiss: { store.closeDiscussion() })
    }
}
```

> **How to find the insertion point:** In `VaultSheet.swift`, the `body` property returns a `ScrollView`. The `.vaylSheet` goes on that `ScrollView` as a chained modifier, alongside any existing `.task` modifiers. If there are `.task` calls already, add `.vaylSheet` before them.

- [ ] **Step 4: Build and verify compile**

Cmd+B. Fix any scope errors (e.g. `@Bindable var store` is already in scope in `VaultSheet`).

- [ ] **Step 5: Verify in simulator**

Bryan runs on device. Expected behavior:
1. Open the Vault from the Map tab.
2. In the Desire Map segment, tap an align row (mutual or adjacent) → `DiscussionCardView` sheet slides up showing the desire item name + a prompt card.
3. Tap an opened-consent row → same sheet, consent-opened tier prompt.
4. Sheet dismisses cleanly on swipe or `onDismiss`.

- [ ] **Step 6: Commit**

```bash
git add Vayl/Features/Map/Vault/Components/VaultDesireSection.swift
git add Vayl/Features/Map/Vault/VaultSheet.swift
git commit -m "feat(discussion-card): Vault align + consent rows open discussion card"
```

---

## Task 5: Reveal wayfinder

The "Talk about this" button in the reveal's star detail sheet becomes a low-hierarchy link that dismisses the cover, switches to the Map tab, and auto-opens the Vault.

**Files:**
- Modify: `Vayl/Core/Services/AppState.swift`
- Modify: `Vayl/Features/Desire Map/Views/Components/DesireStarDetailSheet.swift`
- Modify: `Vayl/Features/Map/MapView.swift`

- [ ] **Step 1: Add `vaultOpenPending` to `AppState`**

In `AppState.swift`, add inside the class, after `var selectedTab: AppTab = .home`:

```swift
/// Set to true by the reveal wayfinder to signal MapView to auto-open the Vault.
/// MapView reads this on appear / onChange and resets it after presenting.
var vaultOpenPending: Bool = false
```

No persistence needed — this is transient in-session navigation state.

- [ ] **Step 2: Add `onTalkTapped` to `DesireStarDetailSheet`**

In `DesireStarDetailSheet.swift`, the struct currently has:
```swift
let match: RevealMatch
var onClose: () -> Void = {}
```

Add a new property:
```swift
var onTalkTapped: (() -> Void)? = nil
```

Then pass it through to `DesireMatchDetail`. The body currently has:
```swift
DesireMatchDetail(
    match: match,
    onTalkTapped: nil,   // stub — S1.3; bridge nav wired later
    onLearnTapped: nil
)
```

Replace with:
```swift
DesireMatchDetail(
    match: match,
    onTalkTapped: onTalkTapped,
    onLearnTapped: nil
)
```

- [ ] **Step 3: Wire the wayfinder action in `DesireRevealView`**

Open `Vayl/Features/Desire Map/Views/DesireRevealView.swift`. Find where `DesireStarDetailSheet` is instantiated (the in-cover custom sheet host). It currently passes `onClose`. Add `onTalkTapped`:

```swift
DesireStarDetailSheet(
    match: selectedMatch,
    onClose: { store.dismissSheets() },
    onTalkTapped: {
        store.dismissSheets()
        vaylDismiss()
        appState.selectedTab = .map
        appState.vaultOpenPending = true
    }
)
```

> `vaylDismiss` is `@Environment(\.vaylDismiss) private var vaylDismiss` — confirm it is already declared in `DesireRevealView`. `appState` is `@Environment(AppState.self) private var appState`. If either is missing, add the appropriate `@Environment` property.

- [ ] **Step 4: Auto-open the Vault in `MapView` when `vaultOpenPending` is set**

In `MapView.swift`, the `body` already has `.task` calls and a `showVault` state variable. Add an `.onChange` on `appState.vaultOpenPending` to watch for the signal. Find the outer-most ZStack or ScrollView in the body and add:

```swift
.onChange(of: appState.vaultOpenPending) { _, pending in
    if pending {
        showVault = true
        appState.vaultOpenPending = false
    }
}
```

This must be on a view in the body that is always in the hierarchy (not behind a conditional). The ZStack wrapping `ScrollView` at the top of the body is the right target.

- [ ] **Step 5: Build and verify compile**

Cmd+B. Confirm no errors.

- [ ] **Step 6: Verify in simulator (Bryan runs on device)**

Expected flow:
1. Open the reveal (from Home's "See what you share").
2. Tap the free/unlocked star → detail sheet opens.
3. "Talk about this" is present. Confirm it is visually **low hierarchy** — styled as a text link / ghost button per the existing `_DetailPressStyle`, not a primary `VaylButton`. If it looks too prominent, review `DesireMatchDetail`'s `onTalkTapped` button label style (it already uses `.ctaLabel` font + chevron, which is subdued — this is correct).
4. Tap "Talk about this" → detail sheet closes, reveal cover closes, Map tab becomes active, Vault sheet opens automatically.
5. Vault opens on the Desire segment (default). User can see align rows.

- [ ] **Step 7: Commit**

```bash
git add Vayl/Core/Services/AppState.swift
git add "Vayl/Features/Desire Map/Views/Components/DesireStarDetailSheet.swift"
git add "Vayl/Features/Desire Map/Views/DesireRevealView.swift"
git add Vayl/Features/Map/MapView.swift
git commit -m "feat(discussion-card): reveal wayfinder — dismiss + route to Vault"
```

---

## Constraints (apply throughout)

- **No em dashes** in any copy (prompts, labels, comments)
- **Tokens only** — no raw colors, fonts, spacing, or radius literals in Views
- **Do NOT touch** `consent-respond` / `consent-ask` / `consent_declines` — the privacy mechanic is correct
- **Do NOT fork** `ConversationCard` — `DiscussionCardView` wraps it, never reimplements it
- **No deck CTA** — `suggestedDeckId` is `nil` for V1; `DiscussionCardView` has no "Open the deck" button
- **Neutrality** — `DiscussionCardView` never references who asked, who wanted it, or who declined
- **4-layer** — Views call Store methods only; `VaultStore` calls `CompanionCardStore` and `ContentLoader`; no Service calls in Views

---

## Done criteria

Each task is done when it compiles AND Bryan confirms the feel on device. Build-succeeds is not done.

- **D1** `companion_cards.json` loads, content loader tests pass.
- **D2** `CompanionCardStore` returns real tier-appropriate prompts; same itemId always returns same prompt.
- **D3** `DiscussionCardView` renders with item name context above the card.
- **D4** Tapping an align row in the Vault Desire segment opens the discussion card in the correct tier. Tapping an opened-consent row opens with `consent_opened` tier. Sheet dismisses cleanly.
- **D5** "Talk about this" in the reveal detail sheet is visually low-hierarchy. Tapping it dismisses the cover, switches to Map, and the Vault auto-opens.
