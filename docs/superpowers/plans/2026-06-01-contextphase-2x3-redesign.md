# ContextPhase 2×3 Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the OB `context` phase around a 2×3 (mode × experience) matrix of 24 contexts with a text-off-card hybrid detail panel and five spectrum visual accents.

**Architecture:** A pure `ContextOption` model + resolver supplies content keyed on `(AppMode, NMStage)`. Cards become number+title headlines; subtitle/detail move to a phase-owned bottom panel (subtitle live on swipe, detail on confirm). `SituationalRegister` is derived from the chosen context so the existing `VaylDirector.concludeContext` contract is unchanged. All visual accents are phase-local — no edits to the `VaylCardFace`/`ContextCardFace` signatures or shell.

**Tech Stack:** SwiftUI (iOS 26 SDK, Swift 6), XCTest (`VaylTests` target), existing design-token system (`AppColors`/`AppFonts`/`AppSpacing`/`AppGlows`/`AppAnimation`), `VaylCardCarousel` + `CarouselPhysics`, `OnboardingProgressBar`.

**Spec:** `docs/superpowers/specs/2026-06-01-contextphase-2x3-redesign-design.md`

---

## Project Build Protocol (overrides generic TDD for View/feel tasks)

Per `CLAUDE.md`: "Build succeeds is not done. Feel is correct is done." Each View task has a **done condition verified in the simulator** and a **constraints list (files it may not touch)**. The pure model task (Task 1) is genuinely unit-testable and uses real XCTest TDD.

**Build command:**
```
xcodebuild -scheme Vayl -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/vayl-dd build CODE_SIGNING_ALLOWED=NO
```

**Test command:**
```
xcodebuild test -scheme Vayl -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:VaylTests/ContextOptionTests
```

**Dev jump:** `OnboardingCanvasView` `#Preview "Full OB Flow"` toolbar jumps to the `context` phase. To exercise all 6 cells, change `appMode` / `nmStage` seed values in that preview's `OnboardingData`.

---

## File Structure

| File | Responsibility | Status |
|---|---|---|
| `Vayl/Features/Onboarding/Models/ContextOption.swift` | `ContextOption` model, `CardAccent`, resolver, `derivedRegister` | **Create** |
| `VaylTests/ContextOptionTests.swift` | Resolver + register-mapping unit tests | **Create** |
| `Vayl/Core/Models/Enums/AppEnums.swift` | `RelationshipContext` 7 → 24 cases | Modify (lines 118-129) |
| `Vayl/Features/Onboarding/Phases/ContextPhase.swift` | Data swap, layout rewrite, accents | Modify (full) |
| `Vayl/Design/Components/Cards/CardFaces/ContextCardFace.swift` | Render number + title only | Modify |

**Must NOT touch:** `VaylDirector.swift`, `OnboardingStore.swift`, `OnboardingData.swift`, `UserProfile.swift`, `VaylCardFace.swift` (shell + `.context` switch), `VaylCardContent.swift` (enum signature stays 4-param), `OnboardingProgressBar.swift`, `VaylCardCarousel.swift`, `CarouselPhysics.swift`.

> **Note on `.context` enum:** The spec §5 floated shrinking the `.context` case to `(number:title:)`. We deliberately **keep the 4-param signature** to avoid touching `VaylCardContent` and the `VaylCardFace` content switch (shell-adjacent). The phase keeps passing `subtitle`/`detail`; `ContextCardFace` simply stops rendering them.

---

## Task 1: Data model — `ContextOption`, 24-case enum, resolver, derived register

**Files:**
- Modify: `Vayl/Core/Models/Enums/AppEnums.swift` (lines 118-129)
- Create: `Vayl/Features/Onboarding/Models/ContextOption.swift`
- Modify: `Vayl/Features/Onboarding/Phases/ContextPhase.swift` (data layer only — keep existing layout so it compiles & runs)
- Test: `VaylTests/ContextOptionTests.swift`

This is one atomic task because expanding `RelationshipContext` removes the old 7 case names that `ContextPhase` currently references — so the enum, the new model, and the phase's data source must change together to keep the build green.

- [ ] **Step 1: Write the failing tests**

Create `VaylTests/ContextOptionTests.swift`:

```swift
import XCTest
@testable import Vayl

final class ContextOptionTests: XCTestCase {

    // Every cell yields exactly 4 cards (3 situations + 1 undecided).
    func test_everyCellHasFourOptions() {
        for mode in [AppMode.together, .solo, .browsing] {
            for stage in NMStage.allCases {
                XCTAssertEqual(
                    ContextOption.options(appMode: mode, stage: stage).count, 4,
                    "\(mode)/\(stage) should have 4 options"
                )
            }
        }
    }

    // Browsing falls back to the solo set for the same stage.
    func test_browsingFallsBackToSolo() {
        for stage in NMStage.allCases {
            let browsing = ContextOption.options(appMode: .browsing, stage: stage).map(\.id)
            let solo     = ContextOption.options(appMode: .solo,     stage: stage).map(\.id)
            XCTAssertEqual(browsing, solo)
        }
    }

    // The undecided card is always last.
    func test_undecidedCardIsLast() {
        let last = ContextOption.options(appMode: .solo, stage: .curious).last
        XCTAssertEqual(last?.id, "solo_curious_undecided")
        XCTAssertEqual(last?.accent, .ember)
    }

    // Derived register: the heavy/anxious contexts map correctly.
    func test_derivedRegister_anxiousContexts() {
        let anxious: [RelationshipContext] = [
            .partneredUndisclosed, .coupleAsymmetricCurious,
            .coupleStalledConversation, .coupleReorienting, .coupleEvolving,
        ]
        for ctx in anxious {
            XCTAssertEqual(register(for: ctx), .anxious, "\(ctx) should be anxious")
        }
    }

    func test_derivedRegister_excitedContexts() {
        let excited: [RelationshipContext] = [
            .singleExploring, .singleExperienced, .soloPolyIndependent,
            .coupleSolidifying, .coupleFreshIntentional, .coupleSkillBuilding,
        ]
        for ctx in excited {
            XCTAssertEqual(register(for: ctx), .excited, "\(ctx) should be excited")
        }
    }

    // All 4 undecided contexts derive to flexible (lowest-stakes routing rule).
    func test_undecidedContextsAreFlexible() {
        let undecided: [RelationshipContext] = [
            .soloCuriousUndecided, .soloExploringUndecided, .soloExperiencedUndecided,
            .coupleCuriousUndecided, .coupleExploringUndecided, .coupleExperiencedUndecided,
        ]
        for ctx in undecided {
            XCTAssertEqual(register(for: ctx), .flexible, "\(ctx) should be flexible")
        }
    }

    // The 6 cells together cover all 24 distinct contexts.
    func test_allTwentyFourContextsReachable() {
        var seen = Set<RelationshipContext>()
        for mode in [AppMode.together, .solo] {
            for stage in NMStage.allCases {
                for opt in ContextOption.options(appMode: mode, stage: stage) {
                    seen.insert(opt.context)
                }
            }
        }
        XCTAssertEqual(seen.count, 24)
    }

    // Helper — resolve a context's derivedRegister via any option carrying it.
    private func register(for ctx: RelationshipContext) -> SituationalRegister? {
        for mode in [AppMode.together, .solo] {
            for stage in NMStage.allCases {
                if let opt = ContextOption.options(appMode: mode, stage: stage)
                    .first(where: { $0.context == ctx }) {
                    return opt.derivedRegister
                }
            }
        }
        return nil
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run the test command above.
Expected: FAIL — `ContextOption` and the new `RelationshipContext` cases are undefined (compile error).

- [ ] **Step 3: Expand `RelationshipContext` to 24 cases**

In `Vayl/Core/Models/Enums/AppEnums.swift`, replace the enum body (lines 118-129) — keep the doc comment above it:

```swift
enum RelationshipContext: String, CaseIterable, Codable {
    // Solo × Curious
    case singleCurious, partneredSupportiveCurious, partneredUndisclosed, soloCuriousUndecided
    // Solo × Exploring
    case singleExploring, partneredHandsOff, multipleUndefined, soloExploringUndecided
    // Solo × Experienced
    case singleExperienced, partneredAware, soloPolyIndependent, soloExperiencedUndecided
    // Couple × Curious
    case coupleSymmetricCurious, coupleAsymmetricCurious, coupleStalledConversation, coupleCuriousUndecided
    // Couple × Exploring
    case coupleSolidifying, coupleReorienting, coupleParallelExploring, coupleExploringUndecided
    // Couple × Experienced
    case coupleFreshIntentional, coupleSkillBuilding, coupleEvolving, coupleExperiencedUndecided
}
```

- [ ] **Step 4: Create the `ContextOption` model**

Create `Vayl/Features/Onboarding/Models/ContextOption.swift`:

```swift
// Features/Onboarding/Models/ContextOption.swift
//
// Pure data model for the ContextPhase 2×3 matrix.
// Content keyed on (AppMode, NMStage). 24 contexts across 6 cells, each cell
// holding 3 concrete situations + 1 first-class "undecided" card.
//
// `context` is the routing value — all downstream branches on it.
// `accent` is decorative ONLY — never branch on it.
// `derivedRegister` keeps SituationalRegister alive so VaylDirector's exit line,
// deck weighting, and Compass "heavy context" check work unchanged.

import Foundation

/// Purely decorative card flair. No semantic meaning. Do not branch on this.
enum CardAccent {
    case ember, spark, flame, inferno, nova
}

struct ContextOption: Identifiable {
    let id:       String
    let context:  RelationshipContext
    let accent:   CardAccent
    let title:    String
    let subtitle: String
    let detail:   String

    /// Derived from `context`. Undecided → flexible (lowest-stakes routing).
    var derivedRegister: SituationalRegister {
        switch context {
        case .partneredUndisclosed,
             .coupleAsymmetricCurious,
             .coupleStalledConversation,
             .coupleReorienting,
             .coupleEvolving:
            return .anxious
        case .singleExploring,
             .singleExperienced,
             .soloPolyIndependent,
             .coupleSolidifying,
             .coupleFreshIntentional,
             .coupleSkillBuilding:
            return .excited
        default:
            return .flexible
        }
    }
}

extension ContextOption {

    /// Total resolver. `.browsing` falls back to the solo set.
    static func options(appMode: AppMode, stage: NMStage) -> [ContextOption] {
        switch (appMode, stage) {
        case (.together, .curious):     return coupleCurious
        case (.together, .exploring):   return coupleExploring
        case (.together, .experienced): return coupleExperienced
        case (.solo, .curious),    (.browsing, .curious):     return soloCurious
        case (.solo, .exploring),  (.browsing, .exploring):   return soloExploring
        case (.solo, .experienced),(.browsing, .experienced): return soloExperienced
        }
    }

    // MARK: Solo × Curious
    static let soloCurious: [ContextOption] = [
        .init(id: "single_curious", context: .singleCurious, accent: .spark,
              title: "I'm single", subtitle: "NM is new territory for me",
              detail: "No relationship to navigate — just you and your curiosity. We'll start with the fundamentals and let you explore at your own pace."),
        .init(id: "partnered_supportive_curious", context: .partneredSupportiveCurious, accent: .flame,
              title: "I have a partner", subtitle: "They know I'm looking into this",
              detail: "You've opened the door — we'll help you figure out what you actually want before the bigger conversations begin."),
        .init(id: "partnered_undisclosed", context: .partneredUndisclosed, accent: .inferno,
              title: "I have a partner", subtitle: "I haven't brought it up yet",
              detail: "You're still figuring out what this means to you. We'll help you get clarity before you decide whether or how to start the conversation."),
        .init(id: "solo_curious_undecided", context: .soloCuriousUndecided, accent: .ember,
              title: "I'm still finding the words", subtitle: "My situation doesn't quite fit any of these",
              detail: "That's okay — most people's lives are messier than a list of options. Start here and we'll help you figure out the rest as you go."),
    ]

    // MARK: Solo × Exploring
    static let soloExploring: [ContextOption] = [
        .init(id: "single_exploring", context: .singleExploring, accent: .spark,
              title: "I'm single", subtitle: "Deepening my understanding of who I am in NM",
              detail: "You've moved past curiosity — now it's about building a real sense of your identity, boundaries, and what you want from connections."),
        .init(id: "partnered_hands_off", context: .partneredHandsOff, accent: .flame,
              title: "I have a partner", subtitle: "They're supportive but not actively involved",
              detail: "Your partner is on board but this is your journey. We'll focus on your individual growth while keeping the relationship in view."),
        .init(id: "multiple_undefined", context: .multipleUndefined, accent: .inferno,
              title: "It's in-between", subtitle: "I'm dating, but nothing is fully defined yet",
              detail: "You're somewhere between single and partnered — multiple connections, no fixed structure. We'll help you figure out what you actually want before things crystallize."),
        .init(id: "solo_exploring_undecided", context: .soloExploringUndecided, accent: .ember,
              title: "Somewhere in all of that", subtitle: "My situation is hard to pin down right now",
              detail: "You know you're exploring — you're just not sure which box fits. That's fine. We'll meet you where you are and let the label catch up later."),
    ]

    // MARK: Solo × Experienced
    static let soloExperienced: [ContextOption] = [
        .init(id: "single_experienced", context: .singleExperienced, accent: .spark,
              title: "I'm single", subtitle: "I know who I am in NM",
              detail: "You've done the work. This is about staying intentional, continuing to grow, and finding the connections that fit the life you've built."),
        .init(id: "partnered_aware", context: .partneredAware, accent: .flame,
              title: "I have a partner", subtitle: "They know my NM identity — they're just not part of this",
              detail: "Your partner is aware and supportive, but your NM journey is yours to navigate. We'll focus on depth, skill, and continued self-awareness."),
        .init(id: "solo_poly_independent", context: .soloPolyIndependent, accent: .inferno,
              title: "I navigate independently", subtitle: "Multiple relationships, no anchor partnership",
              detail: "You move through connections on your own terms. We'll support the craft of that — communication, transitions, autonomy, and care without hierarchy."),
        .init(id: "solo_experienced_undecided", context: .soloExperiencedUndecided, accent: .ember,
              title: "It depends on the season", subtitle: "My structure shifts and none of these fully capture it",
              detail: "Experienced doesn't always mean settled. If your situation is genuinely fluid, start here — we'll build around what's true right now."),
    ]

    // MARK: Couple × Curious
    static let coupleCurious: [ContextOption] = [
        .init(id: "couple_symmetric_curious", context: .coupleSymmetricCurious, accent: .spark,
              title: "We're both curious", subtitle: "Neither of us has done this before",
              detail: "You're starting from the same place, which is a real advantage. We'll build shared language and give you both room to think out loud before any decisions get made."),
        .init(id: "couple_asymmetric_curious", context: .coupleAsymmetricCurious, accent: .flame,
              title: "One of us brought this up", subtitle: "The other is open, but still processing",
              detail: "The interest isn't equal yet — and that's okay. We'll help both of you find your footing without pushing anyone faster than they're ready to go."),
        .init(id: "couple_stalled_conversation", context: .coupleStalledConversation, accent: .inferno,
              title: "We've talked about it before", subtitle: "But the conversation never really went anywhere",
              detail: "Something got in the way — timing, fear, uncertainty. We'll help you pick up the thread and figure out why it stalled before trying again."),
        .init(id: "couple_curious_undecided", context: .coupleCuriousUndecided, accent: .ember,
              title: "We're not sure how to describe it", subtitle: "Our situation is a little bit of all of these",
              detail: "That's more common than you'd think. Start here — you don't need to have it figured out to begin figuring it out together."),
    ]

    // MARK: Couple × Exploring
    static let coupleExploring: [ContextOption] = [
        .init(id: "couple_solidifying", context: .coupleSolidifying, accent: .spark,
              title: "We've had experiences together", subtitle: "Now we want to go deeper with intention",
              detail: "You've moved past curiosity — now it's about building a shared identity in NM. We'll help you name what's working, what isn't, and where you want to go."),
        .init(id: "couple_reorienting", context: .coupleReorienting, accent: .flame,
              title: "Something has shifted", subtitle: "We're figuring out our footing again",
              detail: "Your dynamic has changed — a new connection, a boundary that isn't working, or just a feeling that things are off. We'll help you recalibrate together."),
        .init(id: "couple_parallel_exploring", context: .coupleParallelExploring, accent: .inferno,
              title: "We explore somewhat independently", subtitle: "Together, but each on our own path",
              detail: "You're a couple but your NM journeys run in parallel. We'll support both your individual growth and the connection that holds it all together."),
        .init(id: "couple_exploring_undecided", context: .coupleExploringUndecided, accent: .ember,
              title: "All of the above, honestly", subtitle: "We're somewhere between all of these right now",
              detail: "Exploring rarely looks like one clean thing. If your dynamic is layered or shifting, start here — we'll help you make sense of it as you go."),
    ]

    // MARK: Couple × Experienced
    static let coupleExperienced: [ContextOption] = [
        .init(id: "couple_fresh_intentional", context: .coupleFreshIntentional, accent: .spark,
              title: "We know what we're doing", subtitle: "We want to stay intentional and keep it alive",
              detail: "Experience doesn't make things automatic. We'll help you stay curious about each other and your dynamic without letting it run on autopilot."),
        .init(id: "couple_skill_building", context: .coupleSkillBuilding, accent: .flame,
              title: "We want to get better at the hard stuff", subtitle: "Communication, conflict, care — the meta-skills",
              detail: "You're good at NM. Now you want to be excellent at the relationship craft underneath it — the conversations, the repairs, the emotional fluency."),
        .init(id: "couple_evolving", context: .coupleEvolving, accent: .inferno,
              title: "We're thinking about changing our structure", subtitle: "Expanding, reorienting, or rebuilding our dynamic",
              detail: "Something about how you've set this up needs to evolve. We'll help you think through what that means and how to move through it without losing what matters."),
        .init(id: "couple_experienced_undecided", context: .coupleExperiencedUndecided, accent: .ember,
              title: "We're past labels, honestly", subtitle: "We just want to keep growing in whatever way fits",
              detail: "That's a legitimate place to be. You don't need a category — we'll focus on what's useful and let you steer."),
    ]
}
```

- [ ] **Step 5: Swap `ContextPhase`'s data source to the new model**

In `Vayl/Features/Onboarding/Phases/ContextPhase.swift`:

(a) Delete the private `ContextCardData` struct + its `solo`/`together` arrays (current lines ~257-304).

(b) Replace the `options` storage type and `init` resolution:

```swift
    private let appMode: AppMode
    private let options: [ContextOption]

    @State private var physics: CarouselPhysics
    // ... (other @State unchanged)

    init(director: VaylDirector, screenSize: CGSize) {
        self.director   = director
        self.screenSize = screenSize
        let data = director.onboardingData
        self.appMode = data.appMode
        self.options = ContextOption.options(appMode: data.appMode, stage: data.nmStage)
        _physics = State(initialValue: CarouselPhysics(count: options.count, wraps: true))
    }
```

(c) Update the carousel content closure to compute the number positionally and use the new field names (keep the 4-param `.context` call):

```swift
                content: { index, isFront in
                    let o = options[index]
                    VaylCardFace(
                        content: .context(
                            number:   String(format: "%02d", index + 1),
                            title:    o.title,
                            subtitle: o.subtitle,
                            detail:   o.detail
                        ),
                        isFront: isFront
                    )
                },
```

(d) Update `a11yLabel` to drop the removed `number` field:

```swift
    private var a11yLabel: String {
        let o = options[physics.currentIndex]
        return "\(o.title). \(o.subtitle). \(o.detail)"
    }
```

(e) Update `handleExit` to use `option.context` / `option.derivedRegister`:

```swift
            director.concludeContext(
                relationshipContext: option.context,
                situationalRegister: option.derivedRegister
            )
```

- [ ] **Step 6: Run tests to verify they pass**

Run the test command.
Expected: PASS — all 7 `ContextOptionTests` green.

- [ ] **Step 7: Build and verify on device (data resolves)**

Run the build command, launch in simulator, jump to `context` via the Full OB Flow preview. With `appMode = .solo, nmStage = .curious` confirm the 4 solo-curious cards appear; change the seed to `.together / .experienced` and confirm the 4 couple-experienced cards appear (last card = "We're past labels, honestly").
**Done condition:** correct cell content shows for at least 2 of the 6 cells; existing browse/confirm/exit still works.

- [ ] **Step 8: Commit**

```bash
git add Vayl/Core/Models/Enums/AppEnums.swift Vayl/Features/Onboarding/Models/ContextOption.swift Vayl/Features/Onboarding/Phases/ContextPhase.swift VaylTests/ContextOptionTests.swift
git commit -m "feat(context): 2×3 ContextOption model + 24-case RelationshipContext + derived register

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Simplify the card face to a number+title headline

**Files:**
- Modify: `Vayl/Design/Components/Cards/CardFaces/ContextCardFace.swift`

**Constraints — may NOT touch:** `VaylCardFace.swift`, `VaylCardContent.swift` (keep the 4-param `.context` case), `ContextPhase.swift`, any other phase.

- [ ] **Step 1: Render number + title only**

Replace the `body` of `ContextCardFace` (keep the struct's stored props — `subtitle`/`detail`/`isFront` stay in the signature but go unused; this preserves the `VaylCardFace` call site):

```swift
    var body: some View {
        GeometryReader { geo in
            let w   = geo.size.width
            let pad = w * 0.10

            VStack(alignment: .leading, spacing: w * 0.04) {
                Spacer(minLength: 0)

                // Position number — small spectrum overline
                Text(number)
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.spectrumText)
                    .opacity(0.55)

                // Title — the headline; fills the card
                Text(title)
                    .font(AppFonts.display(26, weight: .semibold, relativeTo: .title))
                    .foregroundStyle(AppColors.spectrumText)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(pad)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
        }
    }
```

Then delete the now-unused `@State private var detailVisible`, `@State private var hasAppeared`, the `revealDetail(...)` method, and the `.onChange`/`.onAppear` modifiers (they only drove the removed detail block). Keep the `reduceMotion` env var only if still referenced — if not, remove it to avoid an unused-warning.

- [ ] **Step 2: Update the preview**

The existing `#Preview` passes `subtitle`/`detail` — leave the call as-is (4-param `.context` still valid). No change needed unless it fails to compile.

- [ ] **Step 3: Build and verify on device**

Run the build command; open the `ContextCardFace` `#Preview "Context face — front"` and jump to the `context` phase in the Full OB Flow preview.
**Done condition:** the card shows only the number + a large title, vertically balanced — reads as a punchy headline with no leftover subtitle/detail text on the card. Feel confirmed by human.

- [ ] **Step 4: Commit**

```bash
git add Vayl/Design/Components/Cards/CardFaces/ContextCardFace.swift
git commit -m "feat(context): card face renders number+title headline only

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 3: Phase layout — progress line + hybrid detail panel

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/ContextPhase.swift`

**Constraints — may NOT touch:** `OnboardingProgressBar.swift`, `VaylCardCarousel.swift`, `CarouselPhysics.swift`, `VaylCardFace.swift`, `VaylDirector.swift`.

- [ ] **Step 1: Add the progress line above the carousel**

In `body`, immediately before the `VaylCardCarousel`, inside the top `VStack`, add (replacing the leading `Spacer()` with this header region):

```swift
            Spacer()

            // Spectrum progress line — fills the top void, grounds position.
            OnboardingProgressBar(
                currentStep: physics.currentIndex + 1,
                totalSteps:  options.count,
                totalWidth:  screenSize.width * 0.34,
                barHeight:   ProgressBarConstants.defaultBarHeight
            )
            .padding(.bottom, AppSpacing.xl)
            .opacity(entered && !exiting ? 1 : 0)
            .animation(AppAnimation.standard, value: physics.currentIndex)
            .accessibilityHidden(true)
```

- [ ] **Step 2: Replace the single reassurance line with the hybrid detail panel**

Replace the existing bottom block (the `Spacer()` + `Text(reassuranceText)` after the carousel) with:

```swift
            Spacer().frame(height: AppSpacing.xxl)

            // Hybrid detail panel.
            // Subtitle: live on swipe.  Detail: revealed only after confirm.
            let current = options[physics.currentIndex]
            VStack(spacing: AppSpacing.sm) {
                Text(current.subtitle)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(AppColors.textBody)
                    .multilineTextAlignment(.center)
                    .id("subtitle-\(physics.currentIndex)")
                    .transition(.opacity)

                Text(confirmedIndex != nil ? options[confirmedIndex!].detail : " ")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .opacity(confirmedIndex != nil ? 1 : 0)
            }
            .padding(.horizontal, AppSpacing.lg)
            .frame(minHeight: screenSize.height * 0.14, alignment: .top)
            .opacity(entered && !exiting ? 1 : 0)
            .animation(AppAnimation.standard, value: physics.currentIndex)
            .animation(AppAnimation.standard, value: confirmedIndex)

            Spacer()

            Text(reassuranceText)
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.spectrumText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xl)
                .opacity(entered && !exiting ? 1 : 0)
                .accessibilityAddTraits(.isStaticText)
```

- [ ] **Step 3: Add tactile browse haptic**

On the outer container modifier chain (next to the existing `.sensoryFeedback(.impact(weight: .light), trigger: confirmedIndex)`), add:

```swift
        .sensoryFeedback(.selection, trigger: physics.currentIndex)
```

- [ ] **Step 4: Build and verify on device**

Run the build command, jump to `context`.
**Done condition:** the progress line fills as you swipe; the subtitle crossfades live on each swipe; the detail paragraph stays hidden until a card is tapped, then appears below the subtitle; selection rises with the existing ring/glow and the card does **not** resize. Feel confirmed by human.

- [ ] **Step 5: Commit**

```bash
git add Vayl/Features/Onboarding/Phases/ContextPhase.swift
git commit -m "feat(context): progress line + hybrid live/confirm detail panel

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 4: Visual accents — accent glow, divider, undecided softness, confirm pulse

**Files:**
- Modify: `Vayl/Features/Onboarding/Phases/ContextPhase.swift`

**Constraints — may NOT touch:** `VaylCardFace.swift`, `ContextCardFace.swift`, `VaylDirector.swift`, `AppGlows.swift`. All accents are phase-local.

- [ ] **Step 1: Add an accent→spectrum tint helper**

Add to `ContextPhase` (private). Maps the decorative `CardAccent` to existing spectrum tokens (no raw colors):

```swift
    private func tint(for accent: CardAccent) -> Color {
        switch accent {
        case .ember:   return AppColors.spectrumCyan
        case .spark:   return AppColors.spectrumCyan
        case .flame:   return AppColors.spectrumPurple
        case .inferno: return AppColors.spectrumMagenta
        case .nova:    return AppColors.spectrumMagenta
        }
    }
```

- [ ] **Step 2: Add the live accent glow behind the hero card**

Add `@State private var confirmPulse: Bool = false` near the other state. In `body`, place the glow as the first child of the outer `ZStack` (behind everything), driven by the current card's accent and a one-shot confirm boost:

```swift
        ZStack {
            // Live accent glow — tinted by the front card's accent, crossfades on swipe.
            RadialGradient(
                colors: [
                    tint(for: options[physics.currentIndex].accent)
                        .opacity(confirmPulse ? 0.42 : 0.26),
                    Color.clear,
                ],
                center: .center,
                startRadius: 0,
                endRadius: cardSize.width * (confirmPulse ? 1.5 : 1.2)
            )
            .frame(width: cardSize.width * 2.2, height: cardSize.width * 2.2)
            .blur(radius: cardSize.width * 0.20)
            .offset(y: -cardSize.height * 0.10)
            .opacity(entered && !exiting ? 1 : 0)
            .animation(AppAnimation.standard, value: physics.currentIndex)
            .animation(AppAnimation.spring, value: confirmPulse)
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                // ... existing content (progress line, carousel, panel, reassurance)
            }
            // ... existing ProjectedTextView block
        }
```

- [ ] **Step 3: Add the divider that glows on confirm**

Inside the bottom detail-panel `VStack`, above the subtitle, add a spectrum hairline that lights up on confirm:

```swift
                Rectangle()
                    .fill(LinearGradient(
                        colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .frame(width: screenSize.width * 0.34, height: 1)
                    .opacity(0.5)
                    .spectrumBorderGlow(intensity: confirmedIndex != nil ? 0.72 : 0)
                    .padding(.bottom, AppSpacing.xs)
                    .animation(AppAnimation.standard, value: confirmedIndex)
```

- [ ] **Step 4: Soften the undecided card (phase-local)**

In the carousel content closure, dim the last (undecided) card. Compute `isUndecided` and apply opacity to the `VaylCardFace`:

```swift
                content: { index, isFront in
                    let o = options[index]
                    let isUndecided = (index == options.count - 1)
                    VaylCardFace(
                        content: .context(
                            number:   String(format: "%02d", index + 1),
                            title:    o.title,
                            subtitle: o.subtitle,
                            detail:   o.detail
                        ),
                        isFront: isFront
                    )
                    .opacity(isUndecided ? 0.82 : 1.0)
                },
```

- [ ] **Step 5: Fire the confirm pulse**

In `handleConfirm(_:)`, after setting `confirmedIndex`, add a one-shot pulse:

```swift
    private func handleConfirm(_ index: Int) {
        guard !exiting else { return }
        withAnimation(AppAnimation.spring) { confirmedIndex = index }
        startConfirmTug()
        guard !reduceMotion else { return }
        Task { @MainActor in
            withAnimation(AppAnimation.spring) { confirmPulse = true }
            try? await Task.sleep(for: .milliseconds(450))
            withAnimation(AppAnimation.slow) { confirmPulse = false }
        }
    }
```

In `handleUnconfirm()`, reset the pulse so re-selection behaves: add `withAnimation(AppAnimation.spring) { confirmPulse = false }`.

- [ ] **Step 6: Build and verify on device**

Run the build command, jump to `context`.
**Done condition:** a soft tinted glow sits behind the hero card and shifts color as you swipe; the divider lights up the instant a card is confirmed; the undecided (last) card reads visibly softer; confirming triggers a single gentle glow pulse (and Reduce Motion disables the pulse). Feel confirmed by human.

- [ ] **Step 7: Commit**

```bash
git add Vayl/Features/Onboarding/Phases/ContextPhase.swift
git commit -m "feat(context): accent glow, confirm divider, undecided softness, confirm pulse

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 5: Full-flow verification

**Files:** none (verification only).

- [ ] **Step 1: Run the unit tests once more**

Run the test command. Expected: PASS (7 tests).

- [ ] **Step 2: Build clean**

Run the build command. Expected: BUILD SUCCEEDED, no new warnings beyond the pre-existing 2.

- [ ] **Step 3: Verify the full phase on device for all 6 cells**

For each `(appMode, nmStage)` combination seeded in the Full OB Flow preview: enter `context`, browse all 4 cards (subtitle live, progress fills), confirm one (detail reveals, divider glows, pulse fires), swipe up to exit.
**Done condition for each cell:** correct content; exit advances to `.compass`; no crash. Spot-check via logging that `onboardingData.relationshipContext` and `.situationalRegister` are written (e.g., confirming an anxious context like `partneredUndisclosed` writes `situationalRegister == "anxious"`).

- [ ] **Step 4: Final confirmation**

Human confirms the phase feel is correct end-to-end. "Build succeeds is not done. Feel is correct is done."

---

## Self-Review Notes

- **Spec coverage:** matrix/24-cases (Task 1) · undecided card (Task 1 data + Task 4 softness) · derived register (Task 1) · card headline (Task 2) · progress line (Task 3) · hybrid panel (Task 3) · 5 accents (Task 3 progress line + Task 4 glow/divider/softness/pulse) · unchanged downstream contract (Task 1 Step 5e) · browsing fallback (Task 1 resolver). All covered.
- **Deviation from spec §5:** `.context` enum signature kept 4-param (lower blast radius); documented in File Structure note.
- **Type consistency:** `ContextOption.options(appMode:stage:)`, `.context`, `.derivedRegister`, `CardAccent`, `confirmPulse`, `tint(for:)` used consistently across tasks.
```
