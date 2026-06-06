# OB Sequence Reconciliation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the reconciled OB sequence from `docs/superpowers/specs/2026-06-04-ob-sequence-reconciliation.md` — new phases (Demo, Relational Context), updated phases (Register Read, ModeSelect, Gender), model additions (AgeRange, RelationshipTenure), compass removal, NMStage-keyed starter deck, and post-OB routing.

**Architecture:** The live OB is entirely canvas-driven: `OnboardingCanvasView` renders phase views by switching on `director.phase` (`OBPhase`); `VaylDirector` (@Observable @MainActor) owns all state and drives phase transitions via `advance(to:)`. `OnboardingFlowView` and `OnboardingStep` are dead code and are deleted in Segment 1. `OnboardingStore` is injected into the director and called at `founderLetter`.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, iOS 16+ baseline. All tokens via `AppColors`/`AppFonts`/`AppSpacing`/`AppAnimation`/`AppLayout`. No raw values in Views. `director.advance()` is the sole phase gate.

---

## Read Before Starting

- `Vayl/Features/Onboarding/Canvas/VaylDirector.swift` — owns all OB state; every phase entry method lives here
- `Vayl/Features/Onboarding/Canvas/OnboardingCanvasView.swift` — phase switch that renders Views
- `Vayl/Core/Models/Enums/AppOBEnums.swift` — `OBPhase` enum; add/remove cases here
- `Vayl/Core/Models/OnboardingData.swift` — transient struct; committed to `UserProfile` at end
- `Vayl/Features/Onboarding/Store/OnboardingStore.swift` — `commit(data:)` writes `OnboardingData` → `UserProfile`
- Spec: `docs/superpowers/specs/2026-06-04-ob-sequence-reconciliation.md`

---

## File Map

**Delete:**
- `Vayl/Features/Onboarding/Views/OnboardingFlowView.swift` — dead code
- `Vayl/Features/Onboarding/Store/OnboardingStep.swift` — dead code
- `Vayl/Features/Onboarding/Phases/CompassPhase.swift` — cut from flow

**Create:**
- `Vayl/Features/Onboarding/Phases/DemoPhase.swift`
- `Vayl/Features/Onboarding/Phases/RelationalContextPhase.swift`
- `docs/mockups/ob-demo-prototype.html` — React feel prototype (required before DemoPhase Swift)

**Modify:**
- `Vayl/Core/Models/Enums/AppEnums.swift` — remove `AppMode.browsing`
- `Vayl/Core/Models/Enums/AppOBEnums.swift` — add `AgeRange`, `RelationshipTenure` enums; add `.demo`, `.relationalContext` to `OBPhase`; remove `.compass`
- `Vayl/Core/Models/OnboardingData.swift` — add `ageRange`, `tenure`; remove browsing references
- `Vayl/Core/Models/UserProfile.swift` — add `ageRange: AgeRange?`
- `Vayl/Core/Models/Couple.swift` — add `relationshipTenure: RelationshipTenure?`
- `Vayl/Features/Onboarding/Canvas/VaylDirector.swift` — remove compass, spin 2; add demo/relationalContext entries; update `concludeContext` → register read; update `evaluateOpenerDeckType`; add NMStage-keyed deck selection
- `Vayl/Features/Onboarding/Canvas/OnboardingCanvasView.swift` — add `.demo`, `.relationalContext` cases; remove `.compass`
- `Vayl/Features/Onboarding/Models/ContextOption.swift` — replace 24-option matrix with 4 universal register options
- `Vayl/Features/Onboarding/Phases/ContextPhase.swift` — update question copy; update callback to write `emotionalRegister`
- `Vayl/Features/Onboarding/Phases/GenderPhase.swift` — remove spin 2 `onChange`; add together-mode handoff copy
- `Vayl/Features/Onboarding/Views/OnboardingModeSelectView.swift` — remove browsing card
- `Vayl/Features/Onboarding/Store/OnboardingStore.swift` — write `ageRange` in `persist()`; remove `situationalRegister`/compass fields; add post-OB branch logic
- `Vayl/Features/Home/Models/HomeModels.swift` — add `.soloPrePairing` to `HomeState`
- `Vayl/Features/Home/Store/HomeStore.swift` — add solo pre-pairing path to state computation

---

## Segment 1: Foundation — Enums, Models, Dead Code Removal

**Does:** Adds new enums and model fields; removes dead code and deprecated cases. App must build cleanly after this segment with no errors or warnings on changed files.

**Done condition:** `cmd+B` succeeds. Simulator launches to the OB canvas. No crash on any existing phase.

**Constraints:** Do not touch any Phase view files or VaylDirector logic yet.

- [ ] **Delete dead code files**

```bash
rm Vayl/Features/Onboarding/Views/OnboardingFlowView.swift
rm Vayl/Features/Onboarding/Store/OnboardingStep.swift
```

Then remove from Xcode target if needed (check for "file not found" build errors referencing these paths and delete references in the `.xcodeproj`).

- [ ] **Add `AgeRange` and `RelationshipTenure` enums to `AppOBEnums.swift`**

Add after the existing `OpenerDeckType` enum:

```swift
// MARK: - Age Range

enum AgeRange: String, CaseIterable, Codable {
    case under25     = "under_25"
    case range25to35 = "25_35"
    case range35to45 = "35_45"
    case over45      = "over_45"

    var displayLabel: String {
        switch self {
        case .under25:     return "Under 25"
        case .range25to35: return "25–35"
        case .range35to45: return "35–45"
        case .over45:      return "45+"
        }
    }
}

// MARK: - Relationship Tenure

enum RelationshipTenure: String, CaseIterable, Codable {
    case earlyDays   = "early_days"
    case findingShape = "finding_shape"
    case shifted     = "something_shifted"
    case beenThrough = "been_through_it"

    var stageLabel: String {
        switch self {
        case .earlyDays:    return "Still figuring each other out"
        case .findingShape: return "Finding our shape"
        case .shifted:      return "Something's shifted"
        case .beenThrough:  return "We've been through it"
        }
    }

    var timeLabel: String {
        switch self {
        case .earlyDays:    return "under 1 year"
        case .findingShape: return "1–3 years"
        case .shifted:      return "3–7 years"
        case .beenThrough:  return "7+ years"
        }
    }
}
```

- [ ] **Add `.demo` and `.relationalContext` to `OBPhase`; remove `.compass`**

In `AppOBEnums.swift`, update `OBPhase`:

```swift
enum OBPhase: String, CaseIterable {
    case stat               // "1 in 5", dealer copy, CTA → table world
    case demo               // NEW — "this is what Vayl is for", floating card
    case name               // table fades in, dealer types, card deals/flips, name input → deck[1]
    case modeSelect         // mirror deal, two cards (browsing removed), tap to lift → deck[2]
    case relationalContext  // NEW — age card (all modes) + tenure card (together only)
    case gender             // slot machine drag, reel spin, one spin only → deck[3]
    case experienceLevel    // Monte deal, shuffle, flip, candle face → deck[4]
    case context            // register read — same mechanic, new copy → deck[5]
    case curiosity          // tinder swipe, two rounds → deck[6]
    case confirmation       // corner deck fan, arc review, swipe up
    case buildDeck          // personalized 5-card starter deck, foil + tear
    case founderLetter      // sheet rises, dealer letter, swipe down → home
}
```

- [ ] **Remove `AppMode.browsing` from `AppEnums.swift`**

```swift
enum AppMode: String, CaseIterable, Codable {
    case together   // both partners talked, doing this as a couple
    case solo       // in a relationship, conversation hasn't happened yet

    var displayName: String {
        switch self {
        case .together: return "Shared Journey"
        case .solo:     return "Solo Discovery"
        }
    }
}
```

- [ ] **Fix `OnboardingData.swift` — add new fields, remove browsing**

Add `ageRange` and `tenure` fields. Remove the `.browsing` switch case from `isReadyToComplete`. Update comments:

```swift
// ── RelationalContextPhase ───────────────────────────────────────
var ageRange: AgeRange? = nil           // nil until relationalContext phase
var relationshipTenure: RelationshipTenure? = nil  // together mode only; nil for solo

// In isFullOnboarding — browsing removed, always true now:
var isFullOnboarding: Bool { true }

// In isReadyToComplete — remove .browsing case:
var isReadyToComplete: Bool {
    !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        && ageRange != nil
        && emotionalRegister != nil
        && !curiositySelections.isEmpty
}
```

Also remove the comment `// browsing: just looking, two-tab experience` from the `appMode` field. Update `genderB`/`pronounsB` comments from `// nil for solo / browsing` to `// nil for solo — partner self-provides via pairing`.

- [ ] **Add `ageRange` to `UserProfile.swift`**

In the `// MARK: - Onboarding Routing` section, add:

```swift
var ageRange: AgeRange?             // nil until relationalContext phase completes
```

Add to `init()` with default `nil`, and add to any sample profiles as `ageRange: nil`.

- [ ] **Add `relationshipTenure` to `Couple.swift`**

In the `// MARK: - Shared Config` section, add:

```swift
var relationshipTenure: RelationshipTenure?   // set by first together-mode partner to onboard
```

Add to `init()` with default `nil`.

- [ ] **Update `OnboardingStore.persist()` to write new fields**

In the write block inside `persist(data:)`:

```swift
// RelationalContext fields
profile.ageRange = data.ageRange

// Remove these — no longer written from OB:
// profile.relationshipContext = data.relationshipContext   ← remove
// profile.situationalRegister = data.situationalRegister  ← remove

// Compass fields — remove entire block:
// profile.agency = data.agency                           ← remove
// profile.motivation = data.motivation                   ← remove
// profile.compassNotes = data.compassNotes               ← remove
```

Keep `profile.emotionalRegister = data.emotionalRegister` — this is now written by the updated register read.

- [ ] **Build and verify**

`cmd+B` — must succeed with zero errors. Run in simulator; tap through to existing phases to confirm nothing crashes.

---

## Segment 2: Compass Removal

**Does:** Removes CompassPhase from the OB flow entirely. `ContextPhase.concludeContext()` advances directly to `.curiosity` instead of `.compass`.

**Done condition:** OB flow runs stat → … → context → curiosity with no compass phase, no crash, and no dead `runCompassEntry` call.

**Constraints:** Do not touch ContextPhase copy or option data yet (Segment 3). Do not touch GenderPhase spin 2 (Segment 5).

- [ ] **Delete `CompassPhase.swift`**

```bash
rm Vayl/Features/Onboarding/Phases/CompassPhase.swift
```

Remove from Xcode target if needed.

- [ ] **Remove `.compass` from `OnboardingCanvasView.swift`**

Delete the case block:
```swift
case .compass:
    CompassPhase(director: director, screenSize: screenSize)
        .transition(.opacity)
```

- [ ] **Update `VaylDirector.swift` — remove compass entry and redirect advance**

Remove `private func runCompassEntry() {}` entirely.

In `handlePhaseEntry(_:)`, remove:
```swift
case .compass: runCompassEntry()
```

In `concludeContext()`, change the final advance from `.compass` to `.curiosity`:
```swift
// Before:
advance(to: .compass)
// After:
advance(to: .curiosity)
```

- [ ] **Remove compass-related compass card face content from `VaylCardContent.swift` and `VaylCardFace.swift`** (optional cleanup — only if these cases are exclusively used by CompassPhase; leave them if anything else references them)

Check usages:
```bash
grep -rn "compassOption\|compassSlider" Vayl --include="*.swift" | grep -v CompassPhase | grep -v CompassOptionCardFace | grep -v CompassSliderCardFace
```

If the only references are in the deleted CompassPhase file and the two card face files, delete `CompassOptionCardFace.swift` and `CompassSliderCardFace.swift` and remove the `compassOption`/`compassSlider` cases from `VaylCardContent` and `VaylCardFace`.

- [ ] **Build and verify**

`cmd+B` — no errors. Run in simulator; advance through context phase — confirm it goes directly to curiosity.

---

## Segment 3: Register Read — ContextPhase Copy Swap

**Does:** Replaces the 24-option relationship-archetype matrix with 4 universal register options. Updates `concludeContext()` to write `emotionalRegister` instead of `situationalRegister`. Updates `evaluateOpenerDeckType()` to read `emotionalRegister`.

**Done condition:** Context phase shows 4 register options regardless of mode/NMStage. Selecting an option writes `emotionalRegister` on `OnboardingData`. `evaluateOpenerDeckType()` correctly returns `.anxious` or `.excited` based on the selection.

**Constraints:** Do not change the ContextPhase mechanic/animation. Do not touch ModeSelect or Gender yet.

- [ ] **Replace option data in `ContextOption.swift`**

Replace the entire `static func options(appMode:stage:)` and all the static option arrays with a single universal set. Keep the `ContextOption` struct shape but add `emotionalRegister: EmotionalRegister`:

```swift
struct ContextOption: Identifiable {
    let id:              String
    let emotionalRegister: EmotionalRegister
    let title:           String
    let subtitle:        String
    let detail:          String

    // Keep for backwards compat if anything reads derivedRegister.
    // Maps EmotionalRegister → SituationalRegister for legacy routing.
    var derivedRegister: SituationalRegister {
        switch emotionalRegister {
        case .anxious:  return .anxious
        case .excited:  return .excited
        case .flexible, .unknown: return .flexible
        }
    }
}

extension ContextOption {
    /// Universal register options — mode and NMStage independent.
    static func options(appMode: AppMode, stage: NMStage) -> [ContextOption] {
        return registerOptions
    }

    static let registerOptions: [ContextOption] = [
        .init(
            id: "register_safer",
            emotionalRegister: .anxious,
            title: "I want to feel safer about this",
            subtitle: "Reassurance first",
            detail: "We'll build a foundation of safety and trust before going anywhere unfamiliar."
        ),
        .init(
            id: "register_alive",
            emotionalRegister: .excited,
            title: "I want to feel more alive",
            subtitle: "Expansion first",
            detail: "You're ready to lean in. We'll start with the edges of what's possible."
        ),
        .init(
            id: "register_between",
            emotionalRegister: .flexible,
            title: "Somewhere in between",
            subtitle: "Clarity first",
            detail: "You're open and grounded. We'll find the shape of it as you go."
        ),
        .init(
            id: "register_unsure",
            emotionalRegister: .unknown,
            title: "Honestly, not sure yet",
            subtitle: "We'll figure it out",
            detail: "That's a real answer. The app will read where you are and adjust."
        ),
    ]
}
```

- [ ] **Update `ContextPhase.swift` — question copy**

The dealer line / question text shown above the carousel needs to change from the relationship-archetype framing to the register question. Find the dealer line copy in `ContextPhase.swift` (look for the string passed to the director's `showDealerLine` or set as a `@State`) and update it to:

```
"What are you hoping this gives you?"
```

- [ ] **Update `VaylDirector.concludeContext()` — write `emotionalRegister`**

The method currently takes `(relationshipContext: RelationshipContext, situationalRegister: SituationalRegister)`. Update the signature and body:

```swift
/// Called by ContextPhase on selection. Writes emotionalRegister, adds deck card,
/// shows responsive dealer line, then advances to .curiosity.
func concludeRegisterRead(register: EmotionalRegister) {
    onboardingData.emotionalRegister = register.rawValue

    let collected = VaylCardModel()
    collected.credential = .context
    cornerDeckCards.append(collected)

    withAnimation(AppAnimation.tableRecede.reduceMotionSafe) { tableFade = 1.0 }
    withAnimation(AppAnimation.deckReceive) { deckPulse = true }
    showDealerLine(registerResponse(for: register))

    sequenceAttempt += 1
    let current = sequenceAttempt
    Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(600))
        deckPulse = false
        try? await Task.sleep(for: .milliseconds(2000))
        guard current == self.sequenceAttempt else { return }
        advance(to: .curiosity)
    }
}

private func registerResponse(for register: EmotionalRegister) -> String {
    switch register {
    case .anxious:  return "We'll take this slow."
    case .excited:  return "Let's keep that momentum."
    case .flexible: return "Good — let's find the shape of it."
    case .unknown:  return "The deck will find you where you are."
    }
}
```

Update `ContextPhase.swift` to call `director.concludeRegisterRead(register:)` instead of the old `director.concludeContext(relationshipContext:situationalRegister:)`. Pass `selectedOption.emotionalRegister`.

- [ ] **Update `evaluateOpenerDeckType()` in `VaylDirector.swift`**

```swift
func evaluateOpenerDeckType() {
    let register = EmotionalRegister(rawValue: onboardingData.emotionalRegister ?? "") ?? .flexible
    let hasHeavyRegister  = register == .anxious
    let hasMoreSelections = onboardingData.curiositySelections.count >= 4
    openerDeckType = hasHeavyRegister && !hasMoreSelections ? .anxious : .excited
    onboardingData.openerDeckType = openerDeckType
}
```

- [ ] **Build and verify**

Run in simulator. Advance to context phase — confirm 4 register options appear. Select each option in turn; confirm dealer response line matches the register. Confirm flow advances to curiosity (not compass).

---

## Segment 4: ModeSelect — Remove Browsing

**Does:** Updates `ModeSelectPhase` (or its backing view) to present two cards instead of three. Removes all browsing-mode UI paths.

**Done condition:** ModeSelect shows exactly two cards ("For me" / "For us"). Selecting either advances the flow correctly. No crash or empty state.

**Constraints:** Do not touch gender, context, or any other phase.

- [ ] **Find the browsing card in `OnboardingModeSelectView.swift`**

```bash
grep -n "browsing\|Browsing\|just looking\|Just looking" Vayl/Features/Onboarding/Views/OnboardingModeSelectView.swift
```

- [ ] **Remove the browsing card from the layout**

The ModeSelect mechanic uses a mirror-deal of cards. Remove the browsing card option. The two remaining options are `together` and `solo`. Update any `ForEach` or explicit card list to contain only these two.

- [ ] **Remove any browsing-mode branch in the director's mode-commit method**

In `VaylDirector.swift`, find `commitMode` (or similar — search for where `onboardingData.appMode` is written). Remove any `case .browsing:` branch. The method should handle only `.together` and `.solo`.

```bash
grep -n "browsing\|appMode\|commitMode\|modeSelect" Vayl/Features/Onboarding/Canvas/VaylDirector.swift | head -20
```

- [ ] **Build and verify**

Run in simulator; advance to mode select. Confirm two cards. Tap each; confirm flow continues normally.

---

## Segment 5: Gender — Remove Spin 2

**Does:** Removes the spin 2 (partner gender) sequence from `GenderPhase` and `VaylDirector`. The phase becomes identical for all users — one spin, swipe-right, done. No mode-branching, no extra copy.

**Done condition:** Both together-mode and solo users see exactly one gender spin. Swipe-right exits to the next phase with no crash and no waiting state. The handoff layer is gone.

**Constraints:** Do not touch any other phase. Do not change the slot machine mechanic itself.

- [ ] **Locate spin 2 logic in `VaylDirector.swift`**

```bash
grep -n "spin2\|spin 2\|genderHandoff\|partnerGender\|genderB\|startGenderSpin2\|genderSpinCount" Vayl/Features/Onboarding/Canvas/VaylDirector.swift | head -20
```

- [ ] **Remove spin 2 entry sequence from `VaylDirector.swift`**

Delete: `genderHandoffVisible`, `genderHandoffCopy`, any `startGenderSpin2()` or equivalent method, and any `case .together:` branch inside the gender confirm sequence. After the single spin confirms, set `genderShouldPocket = true` directly — no mode check, no extra dealer line.

- [ ] **Remove spin 2 UI from `GenderPhase.swift`**

Delete the `handoffLayer` view builder and any `onChange` handler that triggers spin 2. The phase view should have no awareness of `appMode`.

- [ ] **Build and verify**

Run in simulator in both together and solo mode — confirm identical single spin, flow advances to relational context in both cases.

---

## Segment 6: Relational Context Phase — Age + Tenure

**Does:** Adds a new `OBPhase.relationalContext` phase between modeSelect and gender. Deals two face-up cards back-to-back: Card A (age, all modes), Card B (tenure, together mode only — skipped for solo). No flip ceremony — both cards deal face-up immediately.

**Done condition:** All-modes: age card appears, user taps bracket, card pockets. Together mode: tenure card then appears, user taps stage, card pockets, flow advances to gender. Solo mode: age card pockets, flow advances directly to gender — tenure card never shown.

**Constraints:** Do not change GenderPhase. Do not add a corner deck card for this phase (factual data, no ceremony card per spec).

- [ ] **Wire `relationalContext` into `VaylDirector.handlePhaseEntry`**

```swift
case .relationalContext: runRelationalContextEntry()
```

Add entry method:
```swift
private func runRelationalContextEntry() {
    // No tableFade change — table stays visible.
    // Phase view handles its own card deal.
}
```

Add commit method:
```swift
func commitAge(_ range: AgeRange) {
    onboardingData.ageRange = range
    // If solo — skip tenure, advance to gender immediately.
    if onboardingData.appMode == .solo {
        advance(to: .gender)
    }
    // If together — RelationalContextPhase shows tenure card next.
    // No advance here; tenure commit fires the advance.
}

func commitTenure(_ tenure: RelationshipTenure) {
    onboardingData.relationshipTenure = tenure
    advance(to: .gender)
}
```

- [ ] **Create `RelationalContextPhase.swift`**

```swift
// Features/Onboarding/Phases/RelationalContextPhase.swift
//
// Two face-up cards back-to-back. No flip ceremony.
// Card A — Age (all modes). Card B — Tenure (together mode only).
// No corner deck card added — factual data, no ceremony.
//
// View contract:
//   .onAppear → deal age card immediately
//   Age tap → director.commitAge(_:)  [solo: advances to gender; together: shows tenure card]
//   Tenure tap → director.commitTenure(_:)  [advances to gender]

import SwiftUI

struct RelationalContextPhase: View {

    let director: VaylDirector
    let screenSize: CGSize

    @State private var showTenure: Bool = false

    private var cardWidth: CGFloat {
        AppLayout.obCardWidth(in: screenSize.width)
    }
    private var cardHeight: CGFloat {
        AppLayout.obCardHeight(in: screenSize.width)
    }

    var body: some View {
        ZStack {
            if !showTenure {
                ageCard
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            } else {
                tenureCard
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(AppAnimation.standard, value: showTenure)
        .frame(width: screenSize.width, height: screenSize.height)
    }

    // MARK: - Age Card

    private var ageCard: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("How old are you?")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: AppSpacing.sm) {
                ForEach(AgeRange.allCases, id: \.self) { range in
                    ageOptionRow(range)
                }
            }
        }
        .padding(AppSpacing.xl)
        .glassCard()
        .frame(width: cardWidth)
        .position(x: screenSize.width / 2, y: screenSize.height * 0.5)
    }

    private func ageOptionRow(_ range: AgeRange) -> some View {
        Text(range.displayLabel)
            .font(AppFonts.bodyText)
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(AppColors.cardBackground.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            .scaleEffect(1.0) // press state handled below
            .onTapGesture {
                if director.onboardingData.appMode == .together {
                    withAnimation(AppAnimation.standard) { showTenure = true }
                }
                director.commitAge(range)
            }
    }

    // MARK: - Tenure Card (together mode only)

    private var tenureCard: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("How long have you two been together?")
                .font(AppFonts.cardTitle)
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: AppSpacing.sm) {
                ForEach(RelationshipTenure.allCases, id: \.self) { tenure in
                    tenureOptionRow(tenure)
                }
            }
        }
        .padding(AppSpacing.xl)
        .glassCard()
        .frame(width: cardWidth)
        .position(x: screenSize.width / 2, y: screenSize.height * 0.5)
    }

    private func tenureOptionRow(_ tenure: RelationshipTenure) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Text(tenure.stageLabel)
                .font(AppFonts.bodyText)
                .foregroundStyle(AppColors.textPrimary)
            Text(tenure.timeLabel)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.cardBackground.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
        .onTapGesture {
            director.commitTenure(tenure)
        }
    }
}
```

**Note:** All tap targets need press state + haptic per `CLAUDE.md`. Add `@State private var pressedAge: AgeRange? = nil` and `@State private var pressedTenure: RelationshipTenure? = nil`, apply `.scaleEffect(pressed ? 0.96 : 1.0)` and `.sensoryFeedback(.impact(.light), trigger: pressed)` to each row. Pattern matches existing phase views.

- [ ] **Wire into `OnboardingCanvasView.swift`**

Add case in the phase switch (between `.modeSelect` and `.gender`):
```swift
case .relationalContext:
    RelationalContextPhase(director: director, screenSize: screenSize)
        .transition(.opacity)
```

- [ ] **Update `modeSelect` advance in `VaylDirector.swift`**

Find where ModeSelectPhase confirms and calls `advance(to: .gender)`. Change to `advance(to: .relationalContext)`.

- [ ] **Build and verify**

Run together mode: age card appears → tap → tenure card slides up → tap → gender phase. Run solo mode: age card appears → tap → gender phase directly (no tenure).

---

## Segment 7: Demo Phase — React Prototype First, Then Swift

**Does:** Adds `OBPhase.demo` as the second phase (after stat, before name). The phase deals one glowing card with "What do you want that you've never said out loud?", holds silence, shows dealer pivot copy, and pockets the card to the corner deck (first sight of it).

**⚠ FEEL BEFORE SWIFT.** Build the React prototype first. Verify timing on device before writing any Swift.

**Done condition:** Demo phase plays in simulator — card rises, dealer copy appears at the right beats, card pockets cleanly. The experience lands as intended per the spec. Corner deck shows 1 card after demo exits.

**Constraints:** Nothing recorded. No data written. Do not change stat phase.

- [ ] **Build the React feel prototype at `docs/mockups/ob-demo-prototype.html`**

The prototype needs to simulate (in a browser):
1. Black void background
2. Card fades + rises from center (CSS transform: translateY + opacity)
3. Card glows (box-shadow pulsing)
4. Dealer line 1 fades in: *"Forget the setup for a second."*
5. Dealer line 2 fades in: *"This is what Vayl is for."*
6. Card WHAM — snaps to full size/brightness
7. Card face text appears: **"What do you want that you've never said out loud?"**
8. 3-second silence
9. Dealer line 3 fades in: *"Now picture asking them that."*
10. 1.5-second pause
11. Dealer line 4 fades in: *"Feel it?"*
12. 2-second pause
13. Pivot copy fades in: *"That's the whole reason we're here. Let's build a deck that's yours."*
14. Card shrinks + slides to corner (pocket animation)

Use CSS keyframes and `setTimeout` chains. No frameworks needed. Open in browser and time each beat until it feels right. Adjust `setTimeout` values. **The timing values from the prototype become the `Task.sleep` values in Swift.**

- [ ] **Record final timing values from prototype**

Write these down before starting Swift:
- Beat 1 → beat 2 delay: ___ms
- Beat 2 → WHAM delay: ___ms
- WHAM → card text delay: ___ms
- Card text → silence end: ___ms (should be ~3000ms)
- etc.

- [ ] **Add `demo` to `VaylDirector.handlePhaseEntry`**

```swift
case .demo: runDemoEntry()
```

```swift
private func runDemoEntry() {
    // Uses timing values from the React prototype.
    // All values below are PLACEHOLDERS — replace with prototype-verified timings.
    sequenceAttempt += 1
    let current = sequenceAttempt

    Task { @MainActor in
        // Beat 1
        try? await Task.sleep(for: .milliseconds(600))
        guard current == sequenceAttempt else { return }
        showDealerLine("Forget the setup for a second.")

        // Beat 2
        try? await Task.sleep(for: .milliseconds(2200))
        guard current == sequenceAttempt else { return }
        showDealerLine("This is what Vayl is for.")
        withAnimation(AppAnimation.cardSlide) { demoPending = true }  // triggers card rise

        // WHAM — card settles + glows (timing from prototype)
        try? await Task.sleep(for: .milliseconds(/* from prototype */ 1200))
        guard current == sequenceAttempt else { return }
        withAnimation(AppAnimation.standard) { demoCardVisible = true }

        // Silence
        showDealerLine("")
        try? await Task.sleep(for: .milliseconds(/* from prototype */ 3000))
        guard current == sequenceAttempt else { return }

        // "Now picture asking them that."
        showDealerLine("Now picture asking them that.")
        try? await Task.sleep(for: .milliseconds(/* from prototype */ 1500))
        guard current == sequenceAttempt else { return }

        // "Feel it?"
        showDealerLine("Feel it?")
        try? await Task.sleep(for: .milliseconds(/* from prototype */ 2000))
        guard current == sequenceAttempt else { return }

        // Pivot + pocket
        showDealerLine("That's the whole reason we're here. Let's build a deck that's yours.")
        try? await Task.sleep(for: .milliseconds(/* from prototype */ 2500))
        guard current == sequenceAttempt else { return }

        // Pocket to corner deck (first time user sees it)
        demoCardVisible = false
        let demoCard = VaylCardModel()
        demoCard.credential = .demo   // needs a .demo case on OnboardingCardSlot — add it
        cornerDeckCards.append(demoCard)
        withAnimation(AppAnimation.deckReceive) { deckPulse = true }
        try? await Task.sleep(for: .milliseconds(400))
        deckPulse = false

        // Advance to name
        advance(to: .name)
    }
}
```

Add `@Published` (or `var` since VaylDirector is `@Observable`) state:
```swift
var demoPending: Bool = false
var demoCardVisible: Bool = false
```

Add `.demo` to `OnboardingCardSlot` enum in `AppOBEnums.swift`:
```swift
case demo           // demo card — pockets first, before any disclosure
```

- [ ] **Create `DemoPhase.swift`**

```swift
// Features/Onboarding/Phases/DemoPhase.swift
//
// Renders the floating demo card and dealer copy.
// Nothing recorded. No user input collected.
// All timing driven by VaylDirector.runDemoEntry().
//
// View contract:
//   director.demoCardVisible → show/hide card
//   director.demoPending → card rise animation

import SwiftUI

struct DemoPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cardWidth: CGFloat  { AppLayout.obCardWidth(in: screenSize.width) }
    private var cardHeight: CGFloat { AppLayout.obCardHeight(in: screenSize.width) }

    var body: some View {
        ZStack {
            if director.demoCardVisible {
                demoCard
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
    }

    private var demoCard: some View {
        VaylCardFace(content: .text("What do you want that you've never said out loud?"))
            .frame(width: cardWidth, height: cardHeight)
            .spectrumBorderGlow(intensity: 0.85)
            .cardElevation()
            .position(x: screenSize.width / 2, y: screenSize.height * 0.46)
            .allowsHitTesting(false)   // nothing recorded — no interaction
    }
}
```

**Note:** `VaylCardContent.text(_:)` may not exist — check `VaylCardContent` cases. Use the appropriate existing case that renders a text prompt face (likely `VaylCardContent.prompt(text:)` or similar). Match whatever the existing card faces use.

- [ ] **Wire into `OnboardingCanvasView.swift`**

Add between `.stat` and `.name`:
```swift
case .demo:
    DemoPhase(director: director, screenSize: screenSize)
        .transition(.opacity)
```

- [ ] **Update `stat` advance to go to `.demo`**

In `VaylDirector.swift`, find where StatPhase confirms and calls `advance(to: .name)`. Change to `advance(to: .demo)`.

- [ ] **Build and verify in simulator**

Run the demo phase. Verify all timing beats feel right. Adjust `Task.sleep` values until confirmed. This is the feel-verification step — do not proceed until it lands.

---

## Segment 8: Starter Deck Assembly — NMStage-Keyed Selection

**Does:** Extends `evaluateOpenerDeckType()` (or adds a new `evaluateStarterDeck()` method) to key starter deck selection on `NMStage` in addition to register. Experienced users get the reflective variant (retrospective NM cards); newer users get the anticipatory variant.

**Done condition:** Running OB with `nmStage = .experienced` produces a different `openerDeckType` selection than `nmStage = .curious`. Confirmed by running both paths in the debug phase jumper and checking `director.onboardingData.openerDeckType`.

**Constraints:** Do not change card content JSON — the reflective swap is a selection filter, not a rewrite. Do not touch any phase UI.

- [ ] **Extend `OpenerDeckType` in `AppOBEnums.swift`**

```swift
enum OpenerDeckType: String, Codable {
    case anxious          // newer + anxious register → reassurance-first, anticipatory
    case excited          // newer + excited/flexible register → expansion-first, anticipatory
    case reflectiveCalm   // experienced + anxious register → retrospective, measured
    case reflectiveOpen   // experienced + excited/flexible register → retrospective, expansive
}
```

- [ ] **Update `evaluateOpenerDeckType()` in `VaylDirector.swift`**

```swift
func evaluateOpenerDeckType() {
    let register = EmotionalRegister(rawValue: onboardingData.emotionalRegister ?? "") ?? .flexible
    let stage    = onboardingData.nmStage
    let richCuriosity = onboardingData.curiositySelections.count >= 4

    switch (stage, register) {
    case (.experienced, .anxious):
        openerDeckType = .reflectiveCalm
    case (.experienced, _):
        openerDeckType = .reflectiveOpen
    case (_, .anxious) where !richCuriosity:
        openerDeckType = .anxious
    default:
        openerDeckType = .excited
    }

    onboardingData.openerDeckType = openerDeckType
}
```

- [ ] **Document the card selection intent in `OnboardingStore.swift` or a new `StarterDeckSelector.swift`**

The actual card selection (which 5 cards get dealt) is content-dependent — it requires authored card JSON to be populated. Add a placeholder comment in the build deck phase entry that explains the routing contract so the content author knows what to populate:

```swift
// MARK: - Starter Deck Selection
// openerDeckType routes to a 5-card authored set:
//   .anxious         → reassurance-first cards, anticipatory NM framing (newer couples)
//   .excited         → expansion-first cards, anticipatory NM framing (newer couples)
//   .reflectiveCalm  → retrospective cards, measured tone (experienced, anxious register)
//   .reflectiveOpen  → retrospective cards, open tone (experienced, excited/flexible register)
//
// Solo users: reflection-weighted cut — skew toward .reflect type cards.
// Gendered cards: filtered by GenderDynamic derived from genderIdentity.
//
// Content author: populate starter deck JSON per openerDeckType before build deck phase ships.
```

- [ ] **Build and verify**

Use the debug phase jumper in the simulator. Set `nmStage` to `.curious` and `.experienced` via the director debug state. Run through to `evaluateOpenerDeckType()` firing (after curiosity exits). Log `openerDeckType` — confirm different values per stage.

---

## Segment 9: Post-OB Routing + Home Gate Solo State

**Does:** Adds a solo-reachable `HomeState` that doesn't require the Desire Map. Adds the together-mode partner invite beat to the founder letter phase. Routes post-OB correctly per (mode × hesitancy).

**Done condition:** Solo user completes OB → arrives at home in a usable state (can access starter deck) without being hard-gated by the Desire Map. Together-mode user completes OB → sees invite prompt before being taken to the Desire Map gate. Both paths confirmed in simulator.

**Constraints:** Do not change the Desire Map flow for users who have paired. Do not change `FounderLetterPhase` UI — the invite beat is a director-driven dealer line after the letter completes.

- [ ] **Add `.soloUnpaired` to `HomeState` in `HomeModels.swift`**

```swift
enum HomeState: Equatable {
    case soloUnpaired   // NEW — solo user, OB complete, no partner yet; starter deck accessible
    case gated          // desire map not started (paired users)
    case postReflection // desire map done, reflection not done
    case waiting        // reflection done, partner not done
    case matchReady     // both done, reveal not triggered
    case dashboard      // fully unlocked home
}
```

- [ ] **Update `HomeStore` state computation**

In `HomeStore`, find where `homeState` is computed/set. Add the solo-unpaired path before the Desire Map gate check:

```swift
// Before checking Desire Map state, check if solo + unpaired:
if appState.appMode == .solo && !appState.isLinked {
    homeState = .soloUnpaired
    return
}
// Existing gated / desire map logic continues below...
```

- [ ] **Handle `.soloUnpaired` in `HomeRouterView.swift`**

In the `routedContent` switch, add:
```swift
case .soloUnpaired:
    // Solo home: starter deck is accessible; partner invite nudge available.
    // For now route to HomeDashboardView with a reduced feature set.
    // The full solo home surface is a separate spec.
    HomeDashboardView()  // or a placeholder — whatever exists
        .transition(.opacity)
```

- [ ] **Add together-mode invite beat to `VaylDirector.runFounderLetterEntry()`**

After the founder letter completes (before `advance()` fires — or triggered by a new `director.founderLetterDidComplete()` call from `FounderLetterPhase`), add a together-mode beat:

```swift
// At the end of the founder letter sequence, before home transition:
if onboardingData.appMode == .together {
    try? await Task.sleep(for: .milliseconds(1000))
    showDealerLine("You said this is for your relationship. Let's bring them in.")
    // Surface the pairing invite — route to PairingInviteView or equivalent.
    // Implementation of the actual invite UI is out of scope for this segment;
    // the dealer line and timing are the deliverable here.
    try? await Task.sleep(for: .milliseconds(2500))
}
// Existing home transition fires here
```

- [ ] **Build and verify both paths**

Run in simulator:
- **Solo path:** complete OB as solo → confirm home loads in `.soloUnpaired` state, not hard-gated
- **Together path:** complete OB as together → confirm dealer invite line appears after letter, then home transitions

---

## Self-Review

### Spec coverage check

| Spec requirement | Covered by |
|---|---|
| Self-only, one gender spin | Segment 5 |
| Browsing mode removed | Segment 1 + 4 |
| Dead code deleted | Segment 1 |
| Demo phase with locked card question | Segment 7 |
| Relational Context (age + tenure) | Segment 6 |
| Tenure together-only, couple-level | Segment 1 (Couple model) + Segment 6 |
| Register read — ContextPhase copy swap | Segment 3 |
| Compass removed | Segment 2 |
| evaluateOpenerDeckType → emotionalRegister | Segment 3 |
| NMStage-keyed OpenerDeckType | Segment 8 |
| Together-mode gender handoff copy | Segment 5 |
| Corner deck `.demo` card slot | Segment 7 |
| Post-OB solo home gate | Segment 9 |
| Together-mode invite beat | Segment 9 |
| Pronouns → profile settings | Not in this plan — zero OB changes needed (it's already absent) |

### Open after this plan
- Starter deck card content JSON (requires content authoring before buildDeck ships)
- Full solo home surface design (`.soloUnpaired` state routes to placeholder)
- Solo on-ramp "get ready to bring it up" loop (separate spec + plan)
- Corner deck review (confirmation phase) fan animation — spec already approved, separate plan
