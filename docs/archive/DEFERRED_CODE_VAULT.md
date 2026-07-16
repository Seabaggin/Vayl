# DEFERRED CODE VAULT
## Open Lightly — MVP Simplification Preservation Document

**Created:** 2026-03-22
**Purpose:** Preserve every code block, data structure, routing path, and UX copy that exists in the codebase but is intentionally not activated in the Act 1 MVP. Nothing here is deleted. Everything here is dormant. This document is the map back in.

---

## Act Structure

| Act | Release | Scope |
|-----|---------|-------|
| **Act 1 — MVP** | V1.0 | Couples exploring non-monogamy (`.coupleNew`, `.coupleExperienced`) |
| **Act 2 — Expansion** | V1.1 | Browsing/guest mode (`.browsing`) + experienced ENM practitioners |
| **Act 3 — Solo** | V1.2+ | Solo users (`.soloSingle`, `.soloPartnered`) |

**MVP-active `ExperienceType` values:** `.coupleNew`, `.coupleExperienced`
**Deferred `ExperienceType` values:** `.browsing` (Act 2), `.soloSingle` (Act 3), `.soloPartnered` (Act 3)

---

## How to Use This Document

1. Locate the section for the feature you are restoring.
2. Read the **Current State** — every code block listed here is already in the source file, compiled, and reachable. It is not behind a `#if` flag; it is simply never routed to.
3. Follow the **Restoration Steps** to wire the path live.
4. Cross-reference the **Restoration Checklist** at the end of each Act section.

---

---

# PART 1 — DATA MODEL

---

## 1.1 — `ExplorationMode` enum
**File:** `Open Lightly/Features/Onboarding/Data/OnboardingData.swift`, lines 59–63
**Act:** `.solo` → Act 3 | `.browsing` → Act 2

### Current Code (verbatim)
```swift
enum ExplorationMode: String, CaseIterable {
    case solo
    case couple
    case browsing
}
```

### Status
All three cases compile and route. `.couple` is the only case the MVP user can reach. `.solo` and `.browsing` are present in the UI (mode cards exist in `OnboardingModeSelectView`) but should be hidden or disabled until the corresponding Act ships.

### MVP Suppression Target
In `OnboardingModeSelectView.swift`, the `.solo` and `.browsing` mode cards must be commented out or hidden to prevent premature user selection.
See §3.1 for the card code to restore.

---

## 1.2 — `RelationshipStatus` enum
**File:** `OnboardingData.swift`, lines 65–69
**Act:** Act 3 (solo only)

### Current Code
```swift
enum RelationshipStatus: String, CaseIterable {
    case single
    case partneredOpen
    case partneredHidden
}
```

### Status
Defined but not referenced by any active flow. `OnboardingData.relationshipStatus` (line 18) stores it. The solo onboarding context screen uses `RelationshipContext` instead (which has overlapping `.single`, `.partneredOpen`, `.partneredHidden` cases for the solo path). `RelationshipStatus` is a legacy standalone enum — evaluate at Act 3 whether to consolidate with `RelationshipContext` or keep separate.

---

## 1.3 — `RelationshipContext` — solo cases
**File:** `OnboardingData.swift`, lines 77–88
**Act:** Act 3

### Current Code
```swift
enum RelationshipContext: String, CaseIterable, Codable {
    // Solo contexts
    case single
    case partneredOpen
    case partneredHidden

    // Couple contexts
    case notTalked
    case talking
    case someExperience
    case needsReset
}
```

### Deferred Cases
- `.single` — solo user, no partner
- `.partneredOpen` — solo user, partner knows they're exploring
- `.partneredHidden` — solo user, partner does not know ("It's complicated")

### Active Cases (MVP)
`.notTalked`, `.talking`, `.someExperience`, `.needsReset`

### Notes
The solo cases are used in:
- `OnboardingContextView.soloOptions` (§3.2)
- `CuriosityScreenConfig` routing switch (§4.1)
- `OnboardingBuildingPathView.contextFragment` (§5.1)
- `OnboardingFlowView.deriveExperienceType` solo branch (§2.2)

Do not remove these cases. They are referenced by all four locations above.

---

## 1.4 — `OnboardingData` — solo-specific fields
**File:** `OnboardingData.swift`, lines 43–46
**Act:** Act 3

### Current Code
```swift
// Solo Reflection
var firstReflection: String?
var firstReflectionCompleted: Bool = false
var firstReflectionTimestamp: Date?
```

Also relevant:
```swift
// Screen 3 — Relationship Status (solo only)
var relationshipStatus: RelationshipStatus?
```

### Notes
`firstReflection`, `firstReflectionCompleted`, `firstReflectionTimestamp` are reserved for the post-onboarding solo reflection prompt (a screen that doesn't exist yet). They are stored in `OnboardingData` but never written to during the MVP flow.

`relationshipStatus` is never set in the MVP flow. It was the precursor to using `RelationshipContext` for solo — see §1.2 note on consolidation.

---

## 1.5 — `ExperienceType` — deferred cases
**File:** `Open Lightly/Models/Enums/ExperienceType.swift`, lines 16–56
**Act:** `.browsing` → Act 2 | `.soloSingle`, `.soloPartnered` → Act 3

### Current Code (full enum)
```swift
enum ExperienceType: String, CaseIterable, Codable {
    case browsing           = "browsing"
    case soloSingle         = "solo_single"
    case soloPartnered      = "solo_partnered"
    case coupleNew          = "couple_new"
    case coupleExperienced  = "couple_experienced"
}
```

### `availableTabs` — deferred cases
```swift
var availableTabs: [AppTab] {
    switch self {
    case .browsing:
        return [.more]                                 // Act 2: gate-locked to .more
    case .soloSingle, .soloPartnered:
        return [.home, .meUs, .explore, .more]         // Act 3
    case .coupleNew, .coupleExperienced:
        return [.home, .meUs, .explore, .more]         // Act 1 — ACTIVE
    }
}
```

### `displayName` — deferred values
```swift
case .browsing:          return "Just Browsing"        // Act 2
case .soloSingle:        return "Solo Explorer"        // Act 3
case .soloPartnered:     return "Solo (with partner)"  // Act 3
```

### Notes
The `.browsing` case has special handling in `HomeView` (defensive fallback to `MoreView`) and in `ContentView` (guest shell gate — not audited here but referenced in `HomeView` comments). At Act 2, the full guest experience replaces this fallback.

---

---

# PART 2 — ROUTING (OnboardingFlowView)

---

## 2.1 — Browsing branch: skip `contextSelect`
**File:** `Open Lightly/Features/Onboarding/Views/OnboardingFlowView.swift`, lines 75–80
**Act:** Act 2

### Current Code
```swift
case .modeSelect:
    OnboardingModeSelectView(
        data: $onboardingData,
        onContinue: {
            // Browsing users skip contextSelect — they have no relationship context to declare
            if onboardingData.explorationMode == .browsing {
                advance(to: .curiosityPicker)
            } else {
                advance(to: .contextSelect)
            }
        },
        ...
    )
```

### Status
Code is live. The branch fires only when `.browsing` is selected on ModeSelectView. Since the `.browsing` mode card is suppressed in MVP (§3.1), this branch is never reached. No changes needed to activate at Act 2 — simply show the `.browsing` mode card.

---

## 2.2 — `deriveExperienceType` — solo and browsing branches
**File:** `OnboardingFlowView.swift`, lines 146–170
**Act:** `.browsing` → Act 2 | `.solo` branches → Act 3

### Current Code (full function)
```swift
private func deriveExperienceType(from data: OnboardingData) -> ExperienceType {
    switch data.explorationMode {
    case .browsing:
        return .browsing

    case .solo:
        switch data.relationshipContext {
        case .partneredOpen, .partneredHidden:
            return .soloPartnered
        default:
            // .single, nil, or any unrecognised context
            return .soloSingle
        }

    case .couple:
        let isExperienced = data.nmStage == .experienced
            || data.relationshipContext == .someExperience
        return isExperienced ? .coupleExperienced : .coupleNew

    case .none:
        logger.warning("deriveExperienceType: explorationMode is nil — defaulting to soloSingle")
        return .soloSingle
    }
}
```

### Active Branches (MVP)
`.couple` branch only — produces `.coupleNew` or `.coupleExperienced`.

### Deferred Branches
- `.browsing` → `.browsing` (Act 2)
- `.solo` + `.partneredOpen`/`.partneredHidden` → `.soloPartnered` (Act 3)
- `.solo` + anything else → `.soloSingle` (Act 3)
- `.none` fallback → `.soloSingle` (defensive; no Act)

### Notes
The `coupleExperienced` derivation rule:
`nmStage == .experienced || relationshipContext == .someExperience`
This means a couple who selected "We've tried some things" (`someExperience`) gets routed to `HomeViewCoupleExp` even if they selected "Curious" for nmStage. Intentional. Verify at Act 2 user testing.

---

## 2.3 — CuriosityPicker back-navigation — browsing branch
**File:** `OnboardingFlowView.swift`, lines 98–105
**Act:** Act 2

### Current Code
```swift
case .curiosityPicker:
    OnboardingCuriosityPickerView(
        ...
        onBack: {
            // Browsing users went modeSelect → curiosityPicker, so back goes to modeSelect
            if onboardingData.explorationMode == .browsing {
                advance(to: .modeSelect)
            } else {
                advance(to: .contextSelect)
            }
        }
    )
```

### Status
Live code, dormant for same reason as §2.1.

---

---

# PART 3 — MODE SELECT VIEW

---

## 3.1 — Solo and Browsing mode cards
**File:** `Open Lightly/Features/Onboarding/Views/OnboardingModeSelectView.swift`, lines 84–103
**Act:** `.solo` → Act 3 | `.browsing` → Act 2

### Current Code (all three cards)
```swift
VStack(spacing: 14) {
    modeCard(
        icon: "✦",
        title: "On my own",
        subtitle: "Figure out what you want first",
        mode: .solo
    )
    modeCard(
        icon: "✦",
        title: "With a partner",
        subtitle: "Start the conversation together",
        mode: .couple
    )
    modeCard(
        icon: "✦",
        title: "Just browsing",
        subtitle: "Explore the app before deciding",
        mode: .browsing
    )
}
```

### MVP Suppression
Comment out or remove the `.solo` and `.browsing` `modeCard(...)` calls. The `modeCard` function itself handles both modes generically — no per-mode changes needed.

### Restoration
Restore the commented-out calls in the correct Act. No other changes to `OnboardingModeSelectView` are needed — all supporting logic (selection tracking, experience level pills, routing, back navigation) is already mode-agnostic.

### Supporting: `selectionMade` computed property
```swift
private var selectionMade: Bool {
    data.explorationMode != nil && data.nmStage != nil
}
```
Already handles all three modes. No changes needed.

### Supporting: `#if DEBUG` assert comment in `onContinue`
```swift
#if DEBUG
assert(true,
    "OnboardingModeSelectView: verify coordinator routing " +
    "handles all three modes: .solo, .couple, .browsing")
#endif
```
This assert is a lint reminder for the implementer. It is intentionally always-true. Remove at Act 3 completion once all paths are verified.

---

---

# PART 4 — CONTEXT VIEW (OnboardingContextView)

---

## 4.1 — Solo option data
**File:** `Open Lightly/Features/Onboarding/Views/OnboardingContextView.swift`, lines 30–48
**Act:** Act 3

### Current Code
```swift
private let soloOptions: [ContextOption] = [
    ContextOption(
        id: "single", context: .single, intensity: .ember,
        title: "I'm single",
        subtitle: "No partner in the picture",
        detail: "Your journey is yours alone — we'll tailor everything to individual exploration."
    ),
    ContextOption(
        id: "partnered_open", context: .partneredOpen, intensity: .spark,
        title: "I have a partner",
        subtitle: "They know I'm exploring",
        detail: "We'll include prompts that help you navigate with transparency."
    ),
    ContextOption(
        id: "partnered_hidden", context: .partneredHidden, intensity: .blaze,
        title: "It's complicated",
        subtitle: "I'm not sure how to bring it up",
        detail: "No pressure. We'll start with self-understanding before any conversations."
    ),
]
```

### Status
Compiled. The `options` computed property already routes to `soloOptions` when `explorationMode == .solo`:
```swift
private var options: [ContextOption] {
    data.explorationMode == .couple ? coupleOptions : soloOptions
}
```
Restoring solo navigation automatically shows these cards.

---

## 4.2 — Solo headline, subhead, and reassurance copy
**File:** `OnboardingContextView.swift`, lines 82–112
**Act:** Act 3

### `headlineText` — solo branch
```swift
private var headlineText: String {
    ...
    } else {
        return hasName
            ? "\(name), you're exploring on your own."
            : "You're exploring on your own."
    }
}
```

### `subheadText` — solo branch
```swift
private var subheadText: String {
    data.explorationMode == .couple
        ? "Where are you two at?"
        : "One thing that helps us personalize —"
        // NOTE: The solo subhead intentionally ends with an em dash.
        // The card stack below completes the implied sentence — each
        // card title is the answer to "one thing that helps us
        // personalize." This is a deliberate stylistic choice.
}
```

### `reassuranceText` — solo branch
```swift
private var reassuranceText: String {
    data.explorationMode == .couple
        ? "Every starting point is valid."
        : "No judgment on any answer."
}
```

### Notes
All three ternaries are already branching correctly in the live code. No restoration work needed here — these activate automatically when `explorationMode == .solo` is set.

---

## 4.3 — Debug assert for browsing guard
**File:** `OnboardingContextView.swift`, line 295–302

```swift
#if DEBUG
assert(
    data.explorationMode == .solo || data.explorationMode == .couple,
    "OnboardingContextView: received explorationMode " +
    "\(String(describing: data.explorationMode)) — " +
    "this screen should only be presented for .solo or .couple. " +
    "Browsing users must be routed to CuriosityPickerView."
)
#endif
```

**Status:** Live. Fires if routing ever sends a `.browsing` user to `ContextView`. This is the correct behavior — keep this assert through all Acts.

---

---

# PART 5 — CURIOSITY PICKER CONFIGS (CuriosityScreenConfig)

---

## 5.1 — Routing switch — solo and browsing cases
**File:** `Open Lightly/Features/Onboarding/Data/CuriosityScreenConfig.swift`, lines 74–84
**Act:** `.solo` cases → Act 3 | `.browsing` default → Act 2

### Current Code
```swift
var curiosityScreenConfig: CuriosityScreenConfig {
    switch (explorationMode, relationshipContext) {
    case (.solo, .single):           return .soloSingleConfig
    case (.solo, .partneredOpen):    return .soloPartneredOpenConfig
    case (.solo, .partneredHidden):  return .soloPartneredHiddenConfig
    case (.couple, .notTalked):      return .coupleNotTalkedConfig
    case (.couple, .talking):        return .coupleTalkingConfig
    case (.couple, .someExperience): return .coupleSomeExperienceConfig
    case (.couple, .needsReset):     return .coupleNeedsResetConfig
    default:                         return .browsingConfig
    }
}
```

### Deferred Routes
- `.solo` + `.single` → `soloSingleConfig` (Act 3)
- `.solo` + `.partneredOpen` → `soloPartneredOpenConfig` (Act 3)
- `.solo` + `.partneredHidden` → `soloPartneredHiddenConfig` (Act 3)
- `default` (catches `.browsing` or nil mode) → `browsingConfig` (Act 2)

---

## 5.2 — `soloSingleConfig`
**File:** `CuriosityScreenConfig.swift`, lines 93–114
**Act:** Act 3

### Section 1 Options (communicationGoals)
| id | label | emphasized |
|----|-------|-----------|
| `desire_unknown` | "I don't know what I actually want" | ✓ |
| `pattern_recognition` | "I keep ending up in the same place" | ✓ |
| `initiating` | "I wouldn't know how to ask for it" | |
| `self_awareness` | "My reactions in intimacy surprise me sometimes" | |
| `situationship` | "I'm in something I can't quite read" | |

### Section 2 Options (learningGoals)
| id | label | contentType |
|----|-------|-------------|
| `desire_language` | "What I want — not what I've accepted" | `.educationTrack` |
| `attachment` | "Why I respond to people the way I do" | `.educationTrack` |
| `cnm_style_discovery` | "I'm curious whether non-monogamy could be right for me" | `.quiz(.cnmStyleDiscovery)` |
| `desire_map` | "I want to map my own desires before anything else" | `.desireMap` |
| `jealousy_history` | "I've felt jealousy in past relationships and want to understand it" | `.reflectionTrack` |
| `consent_self_advocacy` | "What it actually means to ask for what I want" | `.educationTrack` |

`showSection2: true`

---

## 5.3 — `soloPartneredOpenConfig`
**File:** `CuriosityScreenConfig.swift`, lines 118–139
**Act:** Act 3

### Section 1 Label
"What are you two working on?" / "Pick everything that feels true."

### Section 1 Options
| id | label | emphasized |
|----|-------|-----------|
| `desire_mismatch` | "We want different things sexually" | ✓ |
| `initiating` | "I don't know how to start the conversation" | ✓ |
| `reconnection` | "We've lost some of our connection" | |
| `jealousy_stuck` | "Jealousy comes up and gets stuck" | |
| `self_unknown` | "I'm still figuring out what I want" | |

### Section 2 Label
"What do you want to figure out?" / "These shape what you'll explore and learn."

### Section 2 Options
| id | label | contentType |
|----|-------|-------------|
| `desire_language` | "What I want — not what I've accepted" | `.educationTrack` |
| `cnm_openness` | "Whether opening up could work for us" | `.quiz(.cnmReadiness)` |
| `desire_map` | "I want to map my own desires before anything else" | `.desireMap` |
| `agreements` | "What our agreements should actually look like" | `.educationTrack` |
| `jealousy_literacy` | "What jealousy is actually telling me" | `.educationTrack` |
| `attachment` | "Why I respond to people the way I do" | `.educationTrack` |

`showSection2: true`

---

## 5.4 — `soloPartneredHiddenConfig`
**File:** `CuriosityScreenConfig.swift`, lines 143–164
**Act:** Act 3

### Section 1 Label
"What's actually going on for you?" / "Pick everything that feels true."

### Section 1 Options
| id | label | emphasized |
|----|-------|-----------|
| `self_unknown` | "I'm still figuring out what I want" | ✓ |
| `initiating_hidden` | "I don't know how I'd even bring this up" | ✓ |
| `desire_mismatch_unilateral` | "I think we want different things" | |
| `reconnection` | "We've lost some of our connection" | |
| `jealousy_stuck` | "Jealousy comes up and gets stuck" | |

### Section 2 Label
"What would help you most right now?" / "These shape what you'll explore and learn."

### Section 2 Options
| id | label | contentType |
|----|-------|-------------|
| `desire_language` | "What I want — not what I've accepted" | `.educationTrack` |
| `attachment` | "Why I respond to people the way I do" | `.educationTrack` |
| `cnm_style_discovery` | "I'm curious whether non-monogamy could be right for me" | `.quiz(.cnmStyleDiscovery)` (emphasized) |
| `desire_map` | "I want to map my own desires before anything else" | `.desireMap` |
| `jealousy_literacy` | "What jealousy is actually telling me" | `.educationTrack` |
| `consent_self_advocacy` | "What it actually means to ask for what I want" | `.educationTrack` |

`showSection2: true`

---

## 5.5 — `browsingConfig`
**File:** `CuriosityScreenConfig.swift`, lines 268–282
**Act:** Act 2

### Section 1 Label
"What do you want to learn about?" / "Pick everything that interests you."

### Section 1 Options (no emphasized, all `.educationTrack`)
| id | label |
|----|-------|
| `cnm_foundations` | "How non-monogamy actually works" |
| `desire_language` | "Understanding desire and what shapes it" |
| `jealousy_literacy` | "What jealousy is actually telling you" |
| `attachment` | "Why people respond to intimacy the way they do" |
| `consent_ongoing` | "Consent beyond yes and no" |
| `compersion` | "Feeling good about what brings a partner joy" |
| `agreements` | "How couples build agreements that hold" |
| `cnm_style_discovery` | "I'm curious what kind of relationships might suit me" (`.quiz(.cnmStyleDiscovery)`) |

`showSection2: false` — browsing users get one section only.

---

---

# PART 6 — BUILDING PATH VIEW

---

## 6.1 — Solo context fragments
**File:** `Open Lightly/Features/Onboarding/Views/OnboardingBuildingPathView.swift`, lines 76–87
**Act:** Act 3

### Current Code
```swift
private var contextFragment: String? {
    switch data.relationshipContext {
    case .single:          return "Your journey, your pace"
    case .partneredOpen:   return "Navigating with transparency"
    case .partneredHidden: return "Finding the words"
    case .notTalked:       return "Starting the conversation"
    case .talking:         return "Building on shared curiosity"
    case .someExperience:  return "Processing what happened"
    case .needsReset:      return "Rebuilding from here"
    default:               return nil
    }
}
```

### Active Cases (MVP)
`.notTalked`, `.talking`, `.someExperience`, `.needsReset`

### Deferred Cases
`.single` → "Your journey, your pace" (Act 3)
`.partneredOpen` → "Navigating with transparency" (Act 3)
`.partneredHidden` → "Finding the words" (Act 3)

### Notes
Browsing users (`explorationMode == .browsing`) have no `relationshipContext` → falls through to `default: return nil` → `contextFragment` is `nil` → `frag1` is never shown. This is correct behavior for Act 2 with no restoration work needed.

---

## 6.2 — Browsing preview
**File:** `OnboardingBuildingPathView.swift`, lines 644–656

```swift
#Preview("Browsing — no context — no selections") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Sam"
        d.nmStage = .curious
        d.explorationMode = .browsing
        d.relationshipContext = nil
        d.communicationGoals = []
        d.learningGoals = []
        return d
    }()
    OnboardingBuildingPathView(data: $data, onFinished: {})
}
```

**Status:** Preview exists. Validates that browsing users get the correct (minimal fragment) animation path.

---

---

# PART 7 — HOME VIEW ROUTING

---

## 7.1 — HomeView — deferred routes
**File:** `Open Lightly/Features/Home/HomeView.swift`, lines 21–41
**Act:** `.soloSingle`, `.soloPartnered` → Act 3 | `.browsing` → Act 2

### Current Code (full switch)
```swift
switch appState.experienceType {
case .soloSingle:
    HomeViewSingle()
case .soloPartnered:
    HomeViewSolo()
case .coupleNew:
    HomeViewCoupleNew()
case .coupleExperienced:
    HomeViewCoupleExp()
case .browsing:
    // Defensive fallback — guest users are gated in ContentView.
    MoreView()
        .onAppear {
            logger.warning("HomeView reached with .browsing experienceType — guest should be gated in ContentView")
        }
}
```

### Active Cases (MVP)
`.coupleNew` → `HomeViewCoupleNew()` ✓
`.coupleExperienced` → `HomeViewCoupleExp()` ✓

### Deferred Cases
`.soloSingle` → `HomeViewSingle()` (Act 3) — stub view, file exists
`.soloPartnered` → `HomeViewSolo()` (Act 3) — stub view, file exists
`.browsing` → `MoreView()` fallback (Act 2) — guest shell TBD

---

## 7.2 — HomeViewSingle stub
**File:** `Open Lightly/Features/Home/HomeViewSingle.swift`
**Act:** Act 3

### Current Code
```swift
struct HomeViewSingle: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("HomeViewSingle")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}
```

**Status:** Stub only. Full implementation is Act 3 scope. The struct compiles and routes correctly — `HomeView` will display this stub for any user who somehow reaches `.soloSingle`. Add a `GuestBannerView` or similar guard if this is reachable before Act 3 ships.

---

## 7.3 — HomeViewSolo stub
**File:** `Open Lightly/Features/Home/HomeViewSolo.swift`
**Act:** Act 3

### Current Code
```swift
struct HomeViewSolo: View {
    var body: some View {
        ZStack {
            AppColors.pageBg.ignoresSafeArea()
            Text("HomeViewSolo")
                .font(AppFonts.screenTitle)
                .foregroundStyle(AppColors.textPrimary)
        }
        .preferredColorScheme(.dark)
    }
}
```

**Status:** Stub only. Full implementation is Act 3 scope. `HomeViewSolo` serves users with `ExperienceType.soloPartnered` (solo user whose partner knows or doesn't know they're exploring).

---

---

# PART 8 — EXPERIENCE TYPE DERIVATION — coupleExperienced

---

## 8.1 — `coupleExperienced` derivation rule
**File:** `OnboardingFlowView.swift`, lines 161–163
**Act:** Act 1 (MVP-active but worth documenting for V1.1 review)

### Current Code
```swift
case .couple:
    let isExperienced = data.nmStage == .experienced
        || data.relationshipContext == .someExperience
    return isExperienced ? .coupleExperienced : .coupleNew
```

### Rule
A couple is routed to `HomeViewCoupleExp` if **either**:
- They selected "Experienced" on the nmStage pills, **OR**
- They selected "We've tried some things" (`someExperience`) as their relationship context

### Design Intent
A couple who says they have real ENM experiences but didn't select "Experienced" nmStage (e.g., selected "Exploring") still gets the experienced home. This is intentional — the context card is a more direct signal of actual experience than the NM stage self-assessment.

### Act 2 Review Item
At Act 2, verify whether `coupleExperienced` content depth is appropriate for all user combinations that route to it, particularly `exploring + someExperience`.

---

---

# PART 9 — COPY INVENTORY — Deferred UX Strings

---

## 9.1 — Mode card copy (OnboardingModeSelectView)

| Mode | Title | Subtitle |
|------|-------|----------|
| `.solo` | "On my own" | "Figure out what you want first" |
| `.couple` | "With a partner" | "Start the conversation together" |
| `.browsing` | "Just browsing" | "Explore the app before deciding" |

**MVP shows:** "With a partner" only (after suppressing the other two cards).

---

## 9.2 — Context card copy — solo (OnboardingContextView)

| Context | Title | Subtitle | Detail |
|---------|-------|----------|--------|
| `.single` | "I'm single" | "No partner in the picture" | "Your journey is yours alone — we'll tailor everything to individual exploration." |
| `.partneredOpen` | "I have a partner" | "They know I'm exploring" | "We'll include prompts that help you navigate with transparency." |
| `.partneredHidden` | "It's complicated" | "I'm not sure how to bring it up" | "No pressure. We'll start with self-understanding before any conversations." |

---

## 9.3 — BuildingPath floating fragments — solo

| Context | Fragment |
|---------|----------|
| `.single` | "Your journey, your pace" |
| `.partneredOpen` | "Navigating with transparency" |
| `.partneredHidden` | "Finding the words" |

---

## 9.4 — ExperienceType display names

| Value | Display Name |
|-------|-------------|
| `.browsing` | "Just Browsing" |
| `.soloSingle` | "Solo Explorer" |
| `.soloPartnered` | "Solo (with partner)" |
| `.coupleNew` | "New Couple" |
| `.coupleExperienced` | "Experienced ENM" |

---

---

# RESTORATION CHECKLISTS

---

## Act 2 Restoration Checklist (V1.1 — Browsing / Experienced ENM)

### Prerequisites
- [ ] Act 1 shipped, analytics instrumented on couple flow
- [ ] Guest home shell (`HomeViewBrowsing` or equivalent) designed

### Onboarding
- [ ] Restore `.browsing` mode card in `OnboardingModeSelectView` (§3.1)
- [ ] Verify `OnboardingFlowView` browsing branch routes to `curiosityPicker` (§2.1) — code is live, no change needed
- [ ] Verify `curiosityPicker.onBack` for browsing routes to `modeSelect` (§2.3) — code is live, no change needed
- [ ] Verify `browsingConfig` renders correctly with `showSection2: false` (§5.5)
- [ ] Verify `BuildingPathView` browsing preview matches intended animation (§6.2)

### Home
- [ ] Implement `HomeViewBrowsing` (or convert `.browsing` fallback in `HomeView` from `MoreView` to real guest shell)
- [ ] Update `ContentView` browsing gate to render new guest shell
- [ ] Verify `ExperienceType.browsing.availableTabs == [.more]` enforced in tab bar

### Experience Derivation
- [ ] Verify `deriveExperienceType` `.browsing` case returns `.browsing` (§2.2) — code is live

### Settings
- [ ] Add "Switch to couple mode" CTA in `.more` tab for browsing users
- [ ] Ensure "Switch Experience" in Settings handles `.browsing → .coupleNew` upgrade path

---

## Act 3 Restoration Checklist (V1.2+ — Solo)

### Prerequisites
- [ ] Act 2 shipped and stable
- [ ] Solo home screen (`HomeViewSingle`, `HomeViewSolo`) fully designed and content-populated

### Data Model
- [ ] Decide whether to consolidate `RelationshipStatus` enum with `RelationshipContext` solo cases, or keep both (§1.2)
- [ ] Implement `firstReflection` prompt and write `firstReflection`, `firstReflectionCompleted`, `firstReflectionTimestamp` during solo post-onboarding (§1.4)

### Onboarding
- [ ] Restore `.solo` mode card in `OnboardingModeSelectView` (§3.1)
- [ ] Verify `OnboardingContextView` renders `soloOptions` when `explorationMode == .solo` — code is live (§4.1)
- [ ] Verify solo headline/subhead/reassurance copy (§4.2) — code is live
- [ ] Verify `CuriosityScreenConfig` routes `.solo` combinations correctly (§5.1) — code is live
- [ ] Verify `soloSingleConfig` Section 1 + Section 2 options (§5.2)
- [ ] Verify `soloPartneredOpenConfig` Section 1 + Section 2 options (§5.3)
- [ ] Verify `soloPartneredHiddenConfig` Section 1 + Section 2 options (§5.4)
- [ ] Verify `BuildingPathView` solo context fragments render (§6.1)
- [ ] Verify `deriveExperienceType` solo branches (§2.2) — code is live

### Home
- [ ] Implement `HomeViewSingle` — replace stub with full solo-single home experience (§7.2)
- [ ] Implement `HomeViewSolo` — replace stub with full solo-partnered home experience (§7.3)
- [ ] Verify `HomeView` routes `.soloSingle → HomeViewSingle` and `.soloPartnered → HomeViewSolo` — code is live (§7.1)

### Settings
- [ ] Add "Switch Experience" flow for solo → couple upgrade path
- [ ] Handle `relationshipContext` solo cases in any Settings screens that display context label

### Content
- [ ] Audit `ContentCategory`, `ContentCard`, and `Prompt` models for solo-specific content requirements
- [ ] Verify `.reflectionTrack` `LearningContentType` (used in `soloSingleConfig`, `jealousy_history`) has content wired

---

---

## Quick Reference: What Ships in Each Act

### Act 1 MVP Ships With:
- `ExplorationMode.couple` only
- `RelationshipContext`: `.notTalked`, `.talking`, `.someExperience`, `.needsReset`
- `ExperienceType`: `.coupleNew`, `.coupleExperienced`
- Mode card: "With a partner" only
- CuriosityConfig: `coupleNotTalkedConfig`, `coupleTalkingConfig`, `coupleSomeExperienceConfig`, `coupleNeedsResetConfig`
- Home: `HomeViewCoupleNew`, `HomeViewCoupleExp`

### Act 2 Adds:
- `ExplorationMode.browsing`
- `ExperienceType.browsing`
- Mode card: "Just browsing"
- CuriosityConfig: `browsingConfig` (Section 1 only, 8 options)
- Home: Full `HomeViewBrowsing` guest shell (currently stub → `MoreView` fallback)

### Act 3 Adds:
- `ExplorationMode.solo`
- `RelationshipContext`: `.single`, `.partneredOpen`, `.partneredHidden`
- `ExperienceType`: `.soloSingle`, `.soloPartnered`
- Mode card: "On my own"
- CuriosityConfig: `soloSingleConfig`, `soloPartneredOpenConfig`, `soloPartneredHiddenConfig`
- Home: Full `HomeViewSingle`, `HomeViewSolo` (currently stubs)
- Data: `firstReflection` prompt activation

---

*End of DEFERRED_CODE_VAULT.md*
