# LLM Audit Context — Open Lightly · Onboarding Screens

> **Scope: All onboarding screens, data layer, atmosphere, design system.**
>
> Flow sequence:
>   0   StatView       — trust trigger stat
>   0.5 BrandView      — animated brand reveal
>   1   NameView       — name + pronouns
>   2   ModeSelectView — solo / couple + NM stage
>   3   ContextView    — relationship context
>   4   CuriosityPicker— interest + intent [WIP]
>   6   BuildingPath   — processing animation
>   6.5 CardReveal     — tap-to-flip + pill selection
>   7   GroundRules    — ethical framing, no skip
>
> Generated: 2026-04-04 13:33:46 PDT

---

## Table of Contents

  1. [`Open Lightly/Features/Onboarding/Data/OnboardingData.swift`](#file-open-lightly-features-onboarding-data-onboardingdata-swift)
  2. [`Open Lightly/Features/Onboarding/Data/CuriosityScreenConfig.swift`](#file-open-lightly-features-onboarding-data-curiosityscreenconfig-swift)
  3. [`Open Lightly/Features/Onboarding/Design/OnboardingAtmosphere.swift`](#file-open-lightly-features-onboarding-design-onboardingatmosphere-swift)
  4. [`Open Lightly/Features/Onboarding/Views/OnboardingFlowView.swift`](#file-open-lightly-features-onboarding-views-onboardingflowview-swift)
  5. [`Open Lightly/Features/Onboarding/Views/OnboardingStatView.swift`](#file-open-lightly-features-onboarding-views-onboardingstatview-swift)
  6. [`Open Lightly/Features/Onboarding/Views/OnboardingBrandView.swift`](#file-open-lightly-features-onboarding-views-onboardingbrandview-swift)
  7. [`Open Lightly/Features/Onboarding/Views/OnboardingNameView.swift`](#file-open-lightly-features-onboarding-views-onboardingnameview-swift)
  8. [`Open Lightly/Features/Onboarding/Views/OnboardingModeSelectView.swift`](#file-open-lightly-features-onboarding-views-onboardingmodeselectview-swift)
  9. [`Open Lightly/Features/Onboarding/Views/OnboardingContextView.swift`](#file-open-lightly-features-onboarding-views-onboardingcontextview-swift)
  10. [`Open Lightly/Features/Onboarding/Views/OnboardingCuriosityPickerView.swift`](#file-open-lightly-features-onboarding-views-onboardingcuriositypickerview-swift)
  11. [`Open Lightly/Features/Onboarding/Views/OnboardingBuildingPathView.swift`](#file-open-lightly-features-onboarding-views-onboardingbuildingpathview-swift)
  12. [`Open Lightly/Features/Onboarding/Views/OnboardingCardRevealView.swift`](#file-open-lightly-features-onboarding-views-onboardingcardrevealview-swift)
  13. [`Open Lightly/Features/Onboarding/Views/OnboardingGroundRulesView.swift`](#file-open-lightly-features-onboarding-views-onboardinggroundrulesview-swift)
  14. [`Open Lightly/App/Theme/AppColors.swift`](#file-open-lightly-app-theme-appcolors-swift)
  15. [`Open Lightly/App/Theme/AppFonts.swift`](#file-open-lightly-app-theme-appfonts-swift)

---

## File: `Open Lightly/Features/Onboarding/Data/OnboardingData.swift` {#file-open-lightly-features-onboarding-data-onboardingdata-swift}

```swift
//
// OnboardingData.swift
// Open Lightly
//

import Foundation

struct OnboardingData {
    // Screen 1 — Name + Gender Identity
    var displayName: String = ""
    // Raw string value from the gender identity picker.
    // nil = not provided or "Prefer not to say".
    var genderIdentity: String? = nil
    // Solo path only — captured in ContextView when
    // user selects a card implying a partner exists.
    // Couple path does not use this field —
    // partner sets their own gender in NameView.
    // nil = not provided or not applicable.
    var partnerPronouns: String? = nil

    // Screen 2 — Mode Select
    var explorationMode: ExplorationMode?

    // Screen 3 — Relationship Status (solo only)
    var relationshipStatus: RelationshipStatus?

    // Screen 4 — Relationship Context (branches on explorationMode)
    var relationshipContext: RelationshipContext?

    // Screen 4 — Personalize
    var nmStage: NMStage?

    // Screen 5 — Curiosity Picker
    var communicationGoals: [String] = []    // Section 1 selections
    var learningGoals: [String] = []         // Section 2 selections
    var curiositySelections: [String] = []   // Derived: communicationGoals + learningGoals

    // Screen 7 — Building Path (derived from nmStage)
    // Derived from nmStage — read by BuildingPathView.
    // Not stored. Returns "warm" if nmStage is nil.
    var defaultDifficulty: String {
        switch nmStage {
        case .curious:     return "warm"
        case .exploring:   return "medium"
        case .experienced: return "hot"
        case .none:        return "warm"
        }
    }

    // Screen 7.5 — Card Reveal (pill selection for archetype routing)
    // nil when user skips — archetype routing uses fallback.
    var nmCardResponse: String? = nil

    // Screen 8 — Ground Rules + completion
    var groundRulesAcceptedAt: Date?
    var onboardingComplete: Bool = false
    var completedAt: Date?
}

```

---

## File: `Open Lightly/Features/Onboarding/Data/CuriosityScreenConfig.swift` {#file-open-lightly-features-onboarding-data-curiosityscreenconfig-swift}

```swift
//
//  CuriosityScreenConfig.swift
//  Open Lightly
//
//  Drives OnboardingCuriosityPickerView.
//  Config is derived from OnboardingData — never hardcode mode checks in the view.
//

import Foundation

// MARK: - CuriosityScreenConfig

struct CuriosityScreenConfig {
    let section1Label: String
    let section1Sublabel: String
    let section2Label: String
    let section2Sublabel: String
    let section1Options: [CuriosityOption]
    let section2Options: [CuriosityOption]
    let showSection2: Bool

    init(
        section1Label: String,
        section1Sublabel: String,
        section2Label: String = "",
        section2Sublabel: String = "",
        section1Options: [CuriosityOption],
        section2Options: [CuriosityOption] = [],
        showSection2: Bool
    ) {
        self.section1Label    = section1Label
        self.section1Sublabel = section1Sublabel
        self.section2Label    = section2Label
        self.section2Sublabel = section2Sublabel
        self.section1Options  = section1Options
        self.section2Options  = section2Options
        self.showSection2     = showSection2
    }
}

// MARK: - CuriosityOption

struct CuriosityOption: Identifiable {
    let id: String
    let label: String
    let isEmphasized: Bool
    let contentType: LearningContentType
}

// MARK: - LearningContentType

enum LearningContentType {
    case communicationGoal
    case educationTrack
    case quiz(QuizType)
    case desireMap
    case reflectionTrack
}

// MARK: - QuizType

enum QuizType {
    case cnmStyleDiscovery
    case cnmReadiness
    case attachmentStyle
    case jealousyAnatomy
}

// MARK: - OnboardingData Extension

extension OnboardingData {
    /// Derives the correct screen config from explorationMode + relationshipContext.
    var curiosityScreenConfig: CuriosityScreenConfig {
        switch (explorationMode, relationshipContext) {
        case (.solo, .single):           return .soloSingleConfig
        case (.solo, .partneredOpen):    return .soloPartneredOpenConfig
        case (.solo, .partneredHidden):  return .soloPartneredHiddenConfig
        case (.solo, nil):               return .soloSingleConfig
        case (.couple, .notTalked):      return .coupleNotTalkedConfig
        case (.couple, .talking):        return .coupleTalkingConfig
        case (.couple, .someExperience): return .coupleSomeExperienceConfig
        case (.couple, .needsReset):     return .coupleNeedsResetConfig
        case (.couple, nil):             return .coupleNotTalkedConfig
        default:                         return .browsingConfig
        }
    }
}

// MARK: - Static Config Instances

extension CuriosityScreenConfig {

    // MARK: Solo — Single
    // Set 1: full emotional spectrum — excited through scared
    // Set 2: flavor, timing with new people, emotional entanglement,
    //         sexual health, where to find people open to this

    static let soloSingleConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "solo_s1_excited",
                label: "I've wanted to explore this for a long time and I'm finally doing something about it",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "solo_s1_curious",
                label: "I keep thinking about it and I want to understand what that means",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "solo_s1_neutral",
                label: "I'm not sure how I feel about it yet — I just know I'm not done thinking about it",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "solo_s1_nervous",
                label: "I want this but I don't know if I'm the kind of person who can actually handle it",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "solo_s1_scared",
                label: "I'm worried I'll want something my future partner won't",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "solo_s2_flavor",
                label: "I don't know which type of non-monogamy actually fits how I'm wired",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "solo_s2_timing",
                label: "I don't know when to bring it up with someone new",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "solo_s2_feelings",
                label: "I want to know how to explore this without catching feelings that complicate things",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "solo_s2_sti",
                label: "I want to understand sexual health and what actually being responsible looks like",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "solo_s2_find_people",
                label: "I want to know where people who are open to this actually are",
                isEmphasized: false,
                contentType: .educationTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Solo — Partnered Open (Partner Knows)
    // Set 1: full emotional spectrum — shared curiosity through fear of feelings
    // Set 2: flavor for me individually, how to start exploring, emotional boundaries,
    //         sexual health with more people involved, conversations to have first

    static let soloPartneredOpenConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "partopen_s1_excited",
                label: "My partner knows and we're both genuinely curious — I want to understand it better",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "partopen_s1_curious",
                label: "I keep coming back to certain ideas and I want to explore them more",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "partopen_s1_neutral",
                label: "I'm open to it but I'm still figuring out what I actually want from it",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "partopen_s1_nervous",
                label: "I want to explore but I don't want to do anything that damages what we have",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "partopen_s1_scared",
                label: "I'm worried about what happens if I feel something for someone else",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "partopen_s2_flavor",
                label: "I want to understand which type of non-monogamy actually fits me",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "partopen_s2_explore",
                label: "I want to know how to start exploring without it feeling like I'm going behind my partner's back",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "partopen_s2_emotional",
                label: "I want to understand what emotional boundaries actually look like in practice",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "partopen_s2_sti",
                label: "I want to know what sexual health looks like when more than two people are involved",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "partopen_s2_conversations",
                label: "I want to know what conversations my partner and I should be having before anything happens",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        showSection2: true
    )

    // MARK: Solo — Partnered Hidden (It's Complicated)
    // Set 1: full emotional spectrum — desire present, situation unspoken
    // Set 2: understanding options before saying anything, how to bring it up,
    //         emotional risk, sexual health, figuring out if this is real curiosity

    static let soloPartneredHiddenConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "parthidden_s1_excited",
                label: "The idea genuinely excites me — I just don't know what to do with that yet",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "parthidden_s1_curious",
                label: "I keep coming back to this and I can't tell if it's something real or just a fantasy",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "parthidden_s1_neutral",
                label: "I'm not unhappy. I'm just curious about something and I don't know what that means",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "parthidden_s1_nervous",
                label: "I want to say something but I don't know how to bring it up without changing everything",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "parthidden_s1_scared",
                label: "I'm worried that wanting this means something is wrong with me or my relationship",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "parthidden_s2_flavor",
                label: "I want to understand what non-monogamy actually looks like before I say anything to anyone",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "parthidden_s2_conversation",
                label: "I want to know how people bring this up with a partner without it going sideways",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "parthidden_s2_emotional",
                label: "I want to understand the emotional risks before I open any of this up",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "parthidden_s2_sti",
                label: "I want to know what responsible sexual health looks like if this ever becomes real",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "parthidden_s2_real",
                label: "I want to figure out if what I'm feeling is curiosity or something I actually want to pursue",
                isEmphasized: false,
                contentType: .reflectionTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Couple — Haven't Really Talked
    // Set 1: full emotional spectrum — one or both arriving at different readiness levels
    // Set 2: how to start the conversation, flavor for me individually,
    //         emotional risk, sexual health, what other people learned first

    static let coupleNotTalkedConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "couple_nottalk_s1_excited",
                label: "We've been thinking about this and I'm genuinely excited to actually explore it",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_nottalk_s1_curious",
                label: "I keep thinking about it and I want to understand what's actually drawing me to it",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_nottalk_s1_neutral",
                label: "I'm open to exploring — I just want to make sure we do it thoughtfully",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_nottalk_s1_nervous",
                label: "I want this but I'm not sure I know how to handle the parts that are going to be hard",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_nottalk_s1_scared",
                label: "I'm worried about what happens to us if something doesn't go the way we planned",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "couple_nottalk_s2_conversation",
                label: "I don't know how to start the conversation without it going sideways",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_nottalk_s2_flavor",
                label: "I want to understand which type of non-monogamy actually fits me",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "couple_nottalk_s2_emotional",
                label: "I want to understand the emotional risks and how to actually navigate them",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_nottalk_s2_sti",
                label: "I need to actually think through sexual health — not just assume we're fine",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_nottalk_s2_learned",
                label: "I want to know what other people figured out before we try to figure it out ourselves",
                isEmphasized: false,
                contentType: .educationTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Couple — We've Been Talking
    // Set 1: full emotional spectrum — talking has happened, readiness varies
    // Set 2: flavor for me, what conversations we should have, emotional navigation,
    //         sexual health, keeping new connections from threatening what we have

    static let coupleTalkingConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "couple_talking_s1_excited",
                label: "We've been talking about this for a while and I'm genuinely excited to go deeper into it",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_talking_s1_curious",
                label: "I keep thinking about it and I want to understand what's actually drawing me to it",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_talking_s1_neutral",
                label: "I'm open to it — I just want to make sure I know what I'm actually agreeing to",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_talking_s1_nervous",
                label: "I want this but I'm not sure I know how to handle the parts that are going to be hard",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_talking_s1_scared",
                label: "I'm worried about what happens to us if something doesn't go the way we planned",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "couple_talking_s2_flavor",
                label: "I want to understand which type of non-monogamy actually fits me",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "couple_talking_s2_conversations",
                label: "I want to know what conversations my partner and I should be having before anything happens",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_talking_s2_emotional",
                label: "I want to understand the emotional risks and how to actually navigate them",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_talking_s2_sti",
                label: "I need to actually think through sexual health — not just assume we're fine",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_talking_s2_entanglement",
                label: "I want to understand how to keep new connections from threatening what my partner and I have",
                isEmphasized: false,
                contentType: .educationTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Couple — We've Tried Some Things
    // Set 1: full emotional spectrum — experience exists, processing what happened
    // Set 2: flavor for me, what went wrong, emotional navigation,
    //         sexual health, handling asymmetric desire

    static let coupleSomeExperienceConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "couple_exp_s1_excited",
                label: "We've done some of this and I want to keep going — smarter this time",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_exp_s1_curious",
                label: "Something came up that I didn't expect and I want to understand it better",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_exp_s1_neutral",
                label: "It went okay. I want to understand what would make it go better",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_exp_s1_nervous",
                label: "Something got harder than I expected and I'm not sure what to do with that",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_exp_s1_scared",
                label: "Something happened that I'm still processing and I don't know if we're okay",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "couple_exp_s2_flavor",
                label: "I want to understand which type of non-monogamy actually fits me",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "couple_exp_s2_went_wrong",
                label: "I want to understand what went sideways and why",
                isEmphasized: true,
                contentType: .reflectionTrack
            ),
            CuriosityOption(
                id: "couple_exp_s2_emotional",
                label: "I want to understand the emotional risks and how to actually navigate them",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_exp_s2_sti",
                label: "I need to actually think through sexual health — not just assume we're fine",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_exp_s2_asymmetric",
                label: "I want to understand what to do when one person wants this more than the other",
                isEmphasized: false,
                contentType: .educationTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Couple — We Need A Reset
    // Set 1: full emotional spectrum — something broke or drifted, range of where people land
    // Set 2: flavor for me now, how to rebuild the conversation, emotional repair,
    //         sexual health revisited, understanding what went wrong

    static let coupleNeedsResetConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "couple_reset_s1_hopeful",
                label: "I still believe in what we're trying to build — I just think we need to rebuild the foundation",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_reset_s1_curious",
                label: "I want to understand what actually went wrong before we try anything again",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_reset_s1_neutral",
                label: "I'm not ready to give up on it — I just think we need a different approach",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_reset_s1_nervous",
                label: "I want to try again but I'm scared of ending up in the same place",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_reset_s1_scared",
                label: "I'm not sure we can come back from what happened and I don't know what that means",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "couple_reset_s2_flavor",
                label: "I want to understand which type of non-monogamy actually fits me — separately from what we tried",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "couple_reset_s2_conversation",
                label: "I want to know how to have this conversation again without it going the same way",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "couple_reset_s2_emotional",
                label: "I want to understand the emotional risks and what we missed the first time",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_reset_s2_sti",
                label: "I want to revisit what sexual health actually looks like and make sure we're on the same page",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "couple_reset_s2_went_wrong",
                label: "I want to understand what went wrong so we don't repeat it",
                isEmphasized: false,
                contentType: .reflectionTrack
            ),
        ],
        showSection2: true
    )

    // MARK: Browsing
    // Set 1: general curiosity — no assumed relationship situation
    // Set 2: educational — all major googlable topics represented

    static let browsingConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "These shape what you'll explore first.",
        section1Options: [
            CuriosityOption(
                id: "browsing_s1_excited",
                label: "I've been curious about this for a while and I want to actually understand it",
                isEmphasized: true,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "browsing_s1_curious",
                label: "I keep coming back to certain ideas and I'm not sure what to do with that",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "browsing_s1_neutral",
                label: "I don't know how I feel about it yet — I just want to understand it better",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "browsing_s1_nervous",
                label: "I'm interested but I'm not sure I'm the kind of person who could actually do this",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "browsing_s1_scared",
                label: "The idea appeals to me but something about it also scares me",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
        ],
        section2Options: [
            CuriosityOption(
                id: "browsing_s2_flavor",
                label: "I want to understand the different types of non-monogamy and which might fit me",
                isEmphasized: true,
                contentType: .quiz(.cnmStyleDiscovery)
            ),
            CuriosityOption(
                id: "browsing_s2_conversation",
                label: "I want to know how people actually start these conversations",
                isEmphasized: false,
                contentType: .communicationGoal
            ),
            CuriosityOption(
                id: "browsing_s2_feelings",
                label: "I want to understand how people manage feelings for more than one person",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "browsing_s2_sti",
                label: "I want to understand what sexual health actually looks like when more people are involved",
                isEmphasized: false,
                contentType: .educationTrack
            ),
            CuriosityOption(
                id: "browsing_s2_readiness",
                label: "I want to know if this is actually something I could do — or if I'm just curious",
                isEmphasized: false,
                contentType: .quiz(.cnmReadiness)
            ),
        ],
        showSection2: true
    )
}

// MARK: - Lead Phrase Map
// Short display label shown in summary/preview contexts.
// Key matches CuriosityOption.id.

extension CuriosityScreenConfig {

    static func leadPhrase(for id: String) -> String {
        leadPhrases[id] ?? id
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .prefix(4)
            .joined(separator: " ")
    }

    private static let leadPhrases: [String: String] = [

        // Solo Single — Set 1
        "solo_s1_excited":              "Finally doing something about it.",
        "solo_s1_curious":              "I keep thinking about it.",
        "solo_s1_neutral":              "Not done thinking about it.",
        "solo_s1_nervous":              "Can I actually handle it?",
        "solo_s1_scared":               "What if they don't want this?",

        // Solo Single — Set 2
        "solo_s2_flavor":               "Which type actually fits me?",
        "solo_s2_timing":               "When do I bring it up?",
        "solo_s2_feelings":             "Without catching the wrong feelings.",
        "solo_s2_sti":                  "What does being responsible look like?",
        "solo_s2_find_people":          "Where are these people?",

        // Solo Partnered Open — Set 1
        "partopen_s1_excited":          "We're both curious.",
        "partopen_s1_curious":          "I keep coming back to this.",
        "partopen_s1_neutral":          "Still figuring out what I want.",
        "partopen_s1_nervous":          "I don't want to damage what we have.",
        "partopen_s1_scared":           "What if I feel something for someone?",

        // Solo Partnered Open — Set 2
        "partopen_s2_flavor":           "Which type actually fits me?",
        "partopen_s2_explore":          "Without it feeling like a betrayal.",
        "partopen_s2_emotional":        "What do emotional boundaries look like?",
        "partopen_s2_sti":              "Sexual health with more people involved.",
        "partopen_s2_conversations":    "What should we talk about first?",

        // Solo Partnered Hidden — Set 1
        "parthidden_s1_excited":        "I just don't know what to do with it.",
        "parthidden_s1_curious":        "Real or just a fantasy?",
        "parthidden_s1_neutral":        "I'm not unhappy. Just curious.",
        "parthidden_s1_nervous":        "What if saying it changes everything?",
        "parthidden_s1_scared":         "Does wanting this mean something is wrong?",

        // Solo Partnered Hidden — Set 2
        "parthidden_s2_flavor":         "What does this even look like?",
        "parthidden_s2_conversation":   "How do people bring this up?",
        "parthidden_s2_emotional":      "What are the emotional risks?",
        "parthidden_s2_sti":            "What does responsible look like?",
        "parthidden_s2_real":           "Curiosity or something I want to pursue?",

        // Couple Not Talked — Set 1
        "couple_nottalk_s1_excited":    "I'm genuinely excited.",
        "couple_nottalk_s1_curious":    "What's drawing me to this?",
        "couple_nottalk_s1_neutral":    "Let's do this thoughtfully.",
        "couple_nottalk_s1_nervous":    "Can I handle the hard parts?",
        "couple_nottalk_s1_scared":     "What if something goes wrong?",

        // Couple Not Talked — Set 2
        "couple_nottalk_s2_conversation": "How do I start without it going sideways?",
        "couple_nottalk_s2_flavor":     "Which type actually fits me?",
        "couple_nottalk_s2_emotional":  "What are the emotional risks?",
        "couple_nottalk_s2_sti":        "Let's actually think through sexual health.",
        "couple_nottalk_s2_learned":    "What did others figure out first?",

        // Couple Talking — Set 1
        "couple_talking_s1_excited":    "Ready to go deeper.",
        "couple_talking_s1_curious":    "What's actually drawing me to this?",
        "couple_talking_s1_neutral":    "What am I actually agreeing to?",
        "couple_talking_s1_nervous":    "Can I handle the hard parts?",
        "couple_talking_s1_scared":     "What if something goes wrong?",

        // Couple Talking — Set 2
        "couple_talking_s2_flavor":     "Which type actually fits me?",
        "couple_talking_s2_conversations": "What should we talk about first?",
        "couple_talking_s2_emotional":  "What are the emotional risks?",
        "couple_talking_s2_sti":        "Let's actually think through sexual health.",
        "couple_talking_s2_entanglement": "How do I protect what we have?",

        // Couple Some Experience — Set 1
        "couple_exp_s1_excited":        "Smarter this time.",
        "couple_exp_s1_curious":        "Something I didn't expect.",
        "couple_exp_s1_neutral":        "What would make it go better?",
        "couple_exp_s1_nervous":        "Harder than I expected.",
        "couple_exp_s1_scared":         "Still processing what happened.",

        // Couple Some Experience — Set 2
        "couple_exp_s2_flavor":         "Which type actually fits me?",
        "couple_exp_s2_went_wrong":     "What went sideways and why?",
        "couple_exp_s2_emotional":      "What are the emotional risks?",
        "couple_exp_s2_sti":            "Let's actually think through sexual health.",
        "couple_exp_s2_asymmetric":     "What if one of us wants this more?",

        // Couple Reset — Set 1
        "couple_reset_s1_hopeful":      "Still believe in what we're building.",
        "couple_reset_s1_curious":      "What actually went wrong?",
        "couple_reset_s1_neutral":      "Different approach, not giving up.",
        "couple_reset_s1_nervous":      "Scared of the same outcome.",
        "couple_reset_s1_scared":       "Can we come back from this?",

        // Couple Reset — Set 2
        "couple_reset_s2_flavor":       "Which type actually fits me now?",
        "couple_reset_s2_conversation": "How do I have this conversation again?",
        "couple_reset_s2_emotional":    "What did we miss the first time?",
        "couple_reset_s2_sti":          "Are we actually on the same page?",
        "couple_reset_s2_went_wrong":   "What went wrong so we don't repeat it.",

        // Browsing — Set 1
        "browsing_s1_excited":          "Finally understanding it.",
        "browsing_s1_curious":          "I keep coming back to this.",
        "browsing_s1_neutral":          "Just want to understand it better.",
        "browsing_s1_nervous":          "Could I actually do this?",
        "browsing_s1_scared":           "Appeals to me and scares me.",

        // Browsing — Set 2
        "browsing_s2_flavor":           "Which type might fit me?",
        "browsing_s2_conversation":     "How do people start these conversations?",
        "browsing_s2_feelings":         "Managing feelings for more than one person.",
        "browsing_s2_sti":              "Sexual health with more people involved.",
        "browsing_s2_readiness":        "Curious or actually ready?",
    ]
}

```

---

## File: `Open Lightly/Features/Onboarding/Design/OnboardingAtmosphere.swift` {#file-open-lightly-features-onboarding-design-onboardingatmosphere-swift}

```swift
// OnboardingAtmosphere.swift
// Open Lightly
//
// Unified atmospheric background for the entire onboarding flow.
// Consolidates OnboardingGlowField (dark) and AuroraGlowField (light)
// into one component with one config system covering both modes.
//
// Architecture:
//   - Lives in OnboardingFlowView's ZStack, below the screen switch.
//   - Never leaves the hierarchy — screens render on top of it.
//   - Light mode: AuroraGlowField morphs between per-screen configs via
//     its built-in .animation(.easeInOut(duration: 1.0), value: config).
//   - Dark mode: OnboardingGlowField is self-contained, no config needed.
//   - SparkField is light mode only — folded in here, not a separate call.
//
// BrandView exit contract:
//   OnboardingBrandView fires onAtmosphereExit() at t=4780ms.
//   FlowView receives this and sets atmosphereOpacity = 0 (easeIn 400ms).
//   FlowView owns atmosphereOpacity and passes it in here.
//   BrandView owns the timing. FlowView owns the state. Neither reaches
//   into the other's domain.
//
// Usage:
//   OnboardingAtmosphere(
//       config: auroraConfig,
//       sparkConfig: sparkConfig,
//       opacity: atmosphereOpacity
//   )
//   .ignoresSafeArea()
//   .allowsHitTesting(false)
//   .accessibilityHidden(true)

import SwiftUI

// MARK: - AtmosphereConfig
//
// One config per screen. Each config carries both light and dark
// intensity values so they live next to each other and can be
// tuned in one place.
//
// Light values carry over from the existing AuroraConfig presets.
// Dark values are tuned separately — dark mode amplifies color
// differently than cream does so the same multipliers would overblow.

struct AtmosphereConfig: Equatable {
    var light: AtmosphereIntensity
    var dark:  AtmosphereIntensity

    // ── Per-screen presets ────────────────────────────────────────────

    static let stat = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.40, bottom: 1.15, global: 0.85),
        dark:  AtmosphereIntensity(top: 1.00, mid: 0.50, bottom: 1.00, global: 0.70)
    )

    static let brand = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.35, bottom: 0.70, global: 0.78),
        dark:  AtmosphereIntensity(top: 1.00, mid: 0.45, bottom: 0.80, global: 0.65)
    )

    static let name = AtmosphereConfig(
        light: AtmosphereIntensity(top: 1.00, mid: 0.10, bottom: 1.15, global: 0.60),
        dark:  AtmosphereIntensity(top: 0.80, mid: 0.20, bottom: 0.90, global: 0.55)
    )

    static let modeSelect = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.10, mid: 0.30, bottom: 1.15, global: 0.70),
        dark:  AtmosphereIntensity(top: 0.15, mid: 0.35, bottom: 1.00, global: 0.60)
    )

    static let contextSelect = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.40, mid: 0.20, bottom: 0.85, global: 0.50),
        dark:  AtmosphereIntensity(top: 0.30, mid: 0.25, bottom: 0.75, global: 0.45)
    )

    static let curiosityPicker = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.30, mid: 0.10, bottom: 0.75, global: 0.40),
        dark:  AtmosphereIntensity(top: 0.20, mid: 0.15, bottom: 0.65, global: 0.35)
    )

    // buildingPath reuses curiosityPicker —
    // de-energised atmosphere, content is the focus.
    static let buildingPath   = AtmosphereConfig.curiosityPicker

    // CardReveal — quiet reflective moment. Significantly reduced
    // from curiosityPicker to let the single card hold full attention.
    static let cardReveal = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.10, mid: 0.05, bottom: 0.40, global: 0.25),
        dark:  AtmosphereIntensity(top: 0.08, mid: 0.08, bottom: 0.35, global: 0.22)
    )

    static let groundRules = AtmosphereConfig(
        light: AtmosphereIntensity(top: 0.15, mid: 0.20, bottom: 1.05, global: 0.50),
        dark:  AtmosphereIntensity(top: 0.10, mid: 0.20, bottom: 0.90, global: 0.45)
    )
}

// MARK: - AtmosphereIntensity

struct AtmosphereIntensity: Equatable {
    var top:    Double
    var mid:    Double
    var bottom: Double
    var global: Double
}

// MARK: - OnboardingAtmosphere

struct OnboardingAtmosphere: View {

    var config:      AtmosphereConfig      = .stat
    var sparkConfig: SparkConfiguration    = .statView
    var opacity:     Double                = 1.0

    @Environment(\.colorScheme) private var colorScheme

    // Map AtmosphereConfig → AuroraConfig so AuroraGlowField
    // continues to receive the typed value it expects.
    // This bridge is internal — callers only deal with AtmosphereConfig.
    private var auroraConfig: AuroraConfig {
        let i = colorScheme == .light ? config.light : config.dark
        return AuroraConfig(
            topOpacityMult:    i.top,
            midOpacityMult:    i.mid,
            bottomOpacityMult: i.bottom,
            globalOpacity:     i.global
        )
    }

    var body: some View {
        Group {
            if colorScheme == .light {
                ZStack {
                    AuroraGlowField(config: auroraConfig)
                    SparkField(config: sparkConfig)
                }
            } else {
                // Dark mode: applies global opacity per screen config.
                // Per-blob intensity control is not yet implemented —
                // OnboardingGlowField does not accept intensity params.
                // Full dark mode config responsiveness requires extending
                // OnboardingGlowField to accept AtmosphereIntensity.
                OnboardingGlowField()
                    .opacity(config.dark.global)
                    .animation(.easeInOut(duration: 1.0), value: config)
            }
        }
        .opacity(opacity)
    }
}
// MARK: - Previews

#Preview("Stat — Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.dark)
}

#Preview("Stat — Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingFlowView.swift` {#file-open-lightly-features-onboarding-views-onboardingflowview-swift}

```swift
// Features/Onboarding/OnboardingFlowView.swift

import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.openlightly.app", category: "OnboardingFlowView")

// Step order is intentional and load-bearing.
// cardReveal precedes buildingPath: CardReveal collects
// nmCardResponse, which BuildingPath reads for its fourth
// orbit row and personalised exit copy. Do not reorder.
enum OnboardingStep: Int, CaseIterable {
    case stat
    case brand
    case name
    case modeSelect
    case contextSelect
    case curiosityPicker
    case cardReveal
    case buildingPath
    case groundRules
}

struct OnboardingFlowView: View {

    init(startAt: OnboardingStep = .stat) {
        _currentStep = State(initialValue: startAt)
    }

    @State private var currentStep: OnboardingStep
    @State private var onboardingData = OnboardingData()

    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // ── Shared background ─────────────────────────────────────
            (colorScheme == .light ? AppColors.lightPageBg : AppColors.pageBg)
                .ignoresSafeArea()

            // ── Persistent atmosphere ─────────────────────────────────
            OnboardingAtmosphere(
                config:      atmosphereConfig,
                sparkConfig: sparkConfig
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            // ── Screen switch ─────────────────────────────────────────
            switch currentStep {

            case .stat:
                OnboardingStatView(onContinue: {
                    advance(to: .brand, animation: .easeInOut(duration: 0.35))
                })
                .transition(.opacity)

            case .brand:
                OnboardingBrandView(
                    onFinished: {
                        advance(to: .name)
                    }
                )

            // No onBack — NameView is the first data-entry screen.
            // BrandView (the previous screen) auto-advances and
            // cannot be safely navigated back to. Back is suppressed
            // to prevent a BrandView → NameView loop.
            case .name:
                OnboardingNameView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .modeSelect) }
                )

            case .modeSelect:
                OnboardingModeSelectView(
                    data:       $onboardingData,
                    onContinue: {
                        if onboardingData.explorationMode == .browsing {
                            advance(to: .curiosityPicker)
                        } else {
                            advance(to: .contextSelect)
                        }
                    },
                    onBack: { advance(to: .name) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .contextSelect:
                OnboardingContextView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .curiosityPicker) },
                    onBack:     { advance(to: .modeSelect) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .curiosityPicker:
                OnboardingCuriosityPickerView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .cardReveal) },
                    onBack: {
                        if onboardingData.explorationMode == .browsing {
                            advance(to: .modeSelect)
                        } else {
                            advance(to: .contextSelect)
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .buildingPath:
                OnboardingBuildingPathView(
                    data:       $onboardingData,
                    onFinished: { advance(to: .groundRules) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))

            case .cardReveal:
                OnboardingCardRevealView(
                    data:       $onboardingData,
                    onContinue: { advance(to: .buildingPath) }
                )
                .transition(.opacity)

            case .groundRules:
                OnboardingGroundRulesView(
                    data:       $onboardingData,
                    onFinished: {
                        let experience = deriveExperienceType(from: onboardingData)
                        appState.experienceType = experience
                        logger.info("Onboarding complete — experienceType: \(experience.rawValue)")
                        hasCompletedOnboarding = true
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Atmosphere config per step

    private var atmosphereConfig: AtmosphereConfig {
        switch currentStep {
        case .stat:            return .stat
        case .brand:           return .brand
        case .name:            return .name
        case .modeSelect:      return .modeSelect
        case .contextSelect:   return .contextSelect
        case .curiosityPicker: return .curiosityPicker
        case .buildingPath:    return .buildingPath
        case .cardReveal:      return .cardReveal
        case .groundRules:     return .groundRules
        }
    }

    // MARK: - Spark config per step (light mode only)

    private var sparkConfig: SparkConfiguration {
        switch currentStep {
        case .stat:            return .statView
        case .brand:           return .statView
        case .name:            return .nameView
        case .modeSelect:      return .modeSelectView
        case .contextSelect:   return .contextView
        case .curiosityPicker: return .curiosityPickerView
        case .buildingPath:    return .curiosityPickerView
        case .cardReveal:      return .cardRevealView
        case .groundRules:     return .groundRulesView
        }
    }

    // MARK: - Navigation

    private func advance(
        to step: OnboardingStep,
        animation: Animation = .spring(response: 0.35, dampingFraction: 0.8)
    ) {
        withAnimation(animation) {
            currentStep = step
        }
    }

    // MARK: - Experience Type Derivation

    private func deriveExperienceType(from data: OnboardingData) -> ExperienceType {
        switch data.explorationMode {
        case .browsing:
            return .browsing
        case .solo:
            switch data.relationshipContext {
            case .partneredOpen, .partneredHidden:
                return .soloPartnered
            default:
                return .soloSingle
            }
        case .couple:
            // Routes to coupleExperienced if the user has signalled
            // prior experience via nmStage OR relationship context.
            // .someExperience = "We've tried some things"
            // .needsReset = "We need a reset" — implies prior history,
            //   needs repair/advanced content, not foundational.
            // .exploring nmStage intentionally routes to coupleNew —
            //   the app is conservative; exploring users benefit from
            //   foundational content before advanced tools surface.
            let isExperienced = data.nmStage == .experienced
                || data.relationshipContext == .someExperience
                || data.relationshipContext == .needsReset
            return isExperienced ? .coupleExperienced : .coupleNew
        case .none:
            logger.warning("deriveExperienceType: explorationMode nil — defaulting to soloSingle")
            return .soloSingle
        }
    }
}

// MARK: - Previews

#Preview("Full Flow — Dark") {
    OnboardingFlowView()
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Full Flow — Light") {
    OnboardingFlowView()
        .environment(AppState())
        .preferredColorScheme(.light)
}

#Preview("Jump → Curiosity Picker") {
    OnboardingFlowView(startAt: .curiosityPicker)
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Jump → Brand") {
    OnboardingFlowView(startAt: .brand)
        .environment(AppState())
        .preferredColorScheme(.dark)
}

#Preview("Jump → Name") {
    OnboardingFlowView(startAt: .name)
        .environment(AppState())
        .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingStatView.swift` {#file-open-lightly-features-onboarding-views-onboardingstatview-swift}

```swift
import SwiftUI

// MARK: - Layout constants
private let kReferenceHeight: CGFloat = 844

// MARK: - Spacing Scale (8pt grid)
private enum Spacing {
    // Base unit
    static let unit: CGFloat = 8

    // Fixed steps
    static let xs:  CGFloat = 8   // 1×
    static let sm:  CGFloat = 16  // 2×
    static let md:  CGFloat = 24  // 3×
    static let lg:  CGFloat = 32  // 4×
    static let xl:  CGFloat = 48  // 6×

    // Screen-relative top padding
    // Keeps hero vertically centred on every device
    //
    //  iPhone SE  (568pt) → ~10%  = 56pt  (feels tight, so floor at 8%)
    //  iPhone 14  (844pt) → 10%  = 84pt
    //  iPhone 14+ (926pt) → 10%  = 92pt
    //  iPhone 15 Pro Max (932pt) → 10% = 93pt
    static func topPad(for h: CGFloat) -> CGFloat {
        let pct: CGFloat = h <= 700 ? 0.08 : 0.10
        return (h * pct).rounded()
    }

    // Space between stat and body copy
    // Larger screens get more air; SE gets minimum viable
    static func statToBody(scale: CGFloat) -> CGFloat {
        (24 * scale).rounded()   // 24pt @ 844  →  ~16pt @ SE
    }

    // Body copy → citation pill
    // These are *related* items so keep them close (sm)
    static func bodyToCite(scale: CGFloat) -> CGFloat {
        (16 * scale).rounded()
    }

    // Citation pill → ethos line
    // Slightly more air — different semantic group
    static func citeToEthos(scale: CGFloat) -> CGFloat {
        (28 * scale).rounded()
    }

    // Bottom safe area under home bar
    static let homeBarBottom: CGFloat = 8

    // Horizontal page margin — matches HIG (16pt min, 20pt comfortable)
    static let hPad: CGFloat = 24
}

// MARK: - Main Onboarding View
struct OnboardingStatView: View {
    
    var onContinue: (() -> Void)? = nil
    
    @State private var holoShiftPhase: CGFloat = -0.35
    @State private var holoFlashOffset: CGFloat = 2.5
    @State private var glowPulseHigh = false
    @State private var castPulseHigh = false
    
    @State private var showStatLabel = false
    @State private var showCiteTap   = false
    @State private var showEthos     = false
    @State private var showCTA       = false
    
    @State private var citeOpen = false
    @State private var hasAnimated = false
    @State private var hasAdvanced = false
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var isLight: Bool { colorScheme == .light }
    
    var body: some View {
        GeometryReader { geo in
            let screenH = geo.size.height
            let scale   = screenH / kReferenceHeight
            let screenW = geo.size.width
            let statFontSize: CGFloat = screenH <= 700
            ? 100
            : (screenW > 390 ? 164 : 140)
            
            ZStack {
                Color.clear.ignoresSafeArea()
                
                if !isLight {
                    Ellipse()
                        .fill(RadialGradient(stops: [
                            .init(color: Color.purple.opacity(0.12), location: 0),
                            .init(color: Color.blue.opacity(0.06),   location: 0.5),
                            .init(color: .clear,                     location: 1)
                        ], center: .center, startRadius: 0, endRadius: 240))
                        .frame(width: 380, height: 220)
                        .blur(radius: 90)
                    // ✦ SPACING — keep cast glow anchored below stat block
                        .offset(y: 260 * scale)
                        .allowsHitTesting(false)
                }
                
                VStack(spacing: 0) {
                    
                    // ──────────────────────────────────────────
                    // TOP PADDING
                    // Screen-relative so hero sits at ~golden
                    // ratio on every device size.
                    // ──────────────────────────────────────────
                    Spacer(minLength: Spacing.topPad(for: screenH))
                    
                    // ──────────────────────────────────────────
                    // HERO BLOCK
                    // All content items are *related*, so they
                    // share a single VStack with explicit,
                    // intentional gaps rather than Spacers.
                    // ──────────────────────────────────────────
                    VStack(spacing: 0) {
                        
                        StatNumberView(
                            holoShiftPhase:  holoShiftPhase,
                            holoFlashOffset: holoFlashOffset,
                            glowPulseHigh:   glowPulseHigh,
                            castPulseHigh:   castPulseHigh,
                            fontSize:        statFontSize,
                            isLight:         isLight
                        )
                        // ✦ stat → body: 24pt scaled (related, but different type)
                        .padding(.bottom, Spacing.statToBody(scale: scale))
                        
                        Text("Americans have engaged in consensual non\u{2011}monogamy at some point in their lives.")
                            .font(AppFonts.body(18))
                            .lineSpacing(10.8)
                            .foregroundStyle(isLight
                                             ? AppColors.lightCardTitle
                                             : AppColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 300)
                            .opacity(showStatLabel ? 1 : 0)
                            .offset(y: showStatLabel ? 0 : 14)
                        
                        // ✦ body → citation pill: 16pt scaled (tightly related)
                        CitationTapView(citeOpen: $citeOpen)
                            .padding(.top, Spacing.bodyToCite(scale: scale))
                            .opacity(showCiteTap ? 1 : 0)
                            .offset(y: showCiteTap ? 0 : 14)
                        
                        // ✦ citation → ethos: 28pt scaled (new semantic group)
                        EthosTextView()
                            .padding(.top, Spacing.citeToEthos(scale: scale))
                            .opacity(showEthos ? 1 : 0)
                            .offset(y: showEthos ? 0 : 8)
                    }
                    .padding(.horizontal, Spacing.hPad)
                    
                    // ──────────────────────────────────────────
                    // FLEXIBLE SPACE
                    // Single Spacer between content and CTA so
                    // the button is always visually anchored to
                    // the bottom on every screen height.
                    // ──────────────────────────────────────────
                    Spacer(minLength: Spacing.lg)
                    
                    // ──────────────────────────────────────────
                    // CTA — anchored to bottom
                    // ──────────────────────────────────────────
                    HoloCTAButton(
                        title: "Explore",
                        isEnabled: true,
                        action: {
                            guard !hasAdvanced else { return }
                            hasAdvanced = true
#if DEBUG
                            assert(onContinue != nil,
                                   "OnboardingStatView: onContinue not injected — wire from coordinator.")
#endif
                            onContinue?()
                        },
                        cornerRadius: 100,
                        height: 56,
                        lightModeGradient: isLight ? LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.0),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.0),
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        ) : nil
                    )
                    .padding(.horizontal, Spacing.hPad)
                    .opacity(showCTA ? 1 : 0)
                    .offset(y: showCTA ? 0 : 10)
                    
                  
                    
                    
                }
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true
            startAllAnimations()
        }
        .onDisappear {
            hasAnimated = false
            // hasAdvanced intentionally NOT reset.
            // It is a one-way latch to prevent double-fire of onContinue.
            // If the view reappears before the coordinator has advanced,
            // the latch prevents firing onContinue() again.
        }
    }
    
    // MARK: - Animation Orchestration
    private func startAllAnimations() {
        
        // Reduce Motion: set static values, no repeatForever loops
        if reduceMotion {
            holoShiftPhase  = 0.3          // static midpoint, no sweep
            holoFlashOffset = 0            // no flash
            glowPulseHigh   = true         // glow at full opacity, static
            castPulseHigh   = true         // cast at full opacity, static
        } else {
            // Full motion: holographic sweep and glow pulses
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                holoShiftPhase = 0.65
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                holoFlashOffset = -0.5
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                glowPulseHigh = true
            }
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                castPulseHigh = true
            }
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.5))  { showStatLabel = true }
        withAnimation(.easeOut(duration: 0.6).delay(0.7))  { showCiteTap   = true }
        withAnimation(.easeOut(duration: 0.5).delay(1.0))  { showEthos     = true }
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.82).delay(1.05)) {
            showCTA = true
        }
    }
    
    // MARK: - Stat Number (Holographic "1 in 5")
    private struct StatNumberView: View {
        let holoShiftPhase: CGFloat
        let holoFlashOffset: CGFloat
        let glowPulseHigh: Bool
        let castPulseHigh: Bool
        
        var fontSize: CGFloat = 140
        var isLight: Bool = false
        
        private let txt = "1 in 5"
        
        private var fnt:  Font    { AppFonts.display(fontSize, weight: .bold) }
        private var trk:  CGFloat { -3.2 * (fontSize / 140) }
        
        private var castWidth:  CGFloat { 300 * (fontSize / 140) }
        private var castHeight: CGFloat { 55  * (fontSize / 140) }
        private var castOffset: CGFloat { 70  * (fontSize / 140) }
        
        private var holoStops: [Gradient.Stop] {
            [
                .init(color: AppColors.cyan,    location: 0.00),
                .init(color: AppColors.purple,  location: 0.25),
                .init(color: AppColors.magenta, location: 0.50),
                .init(color: AppColors.pink,    location: 0.65),
                .init(color: AppColors.purple,  location: 0.80),
                .init(color: AppColors.cyan,    location: 1.00),
            ]
        }
        
        private var warmStops: [Gradient.Stop] {
            [
                .init(color: AppColors.magenta,   location: 0.00),
                .init(color: AppColors.orangeHot, location: 0.55),
                .init(color: AppColors.gold,      location: 1.00),
            ]
        }
        
        private var holoGradient: LinearGradient {
            LinearGradient(
                stops:      holoStops,
                startPoint: UnitPoint(x: -holoShiftPhase, y: -0.2),
                endPoint:   UnitPoint(x:  2.0 - holoShiftPhase, y: 1.2)
            )
        }
        
        private var warmGradient: LinearGradient {
            LinearGradient(
                stops:      warmStops,
                startPoint: UnitPoint(x: -holoShiftPhase, y: -0.2),
                endPoint:   UnitPoint(x:  2.0 - holoShiftPhase, y: 1.2)
            )
        }
        
        private var activeGradient: LinearGradient {
            isLight ? warmGradient : holoGradient
        }
        
        private var baseText: some View {
            Text(txt).font(fnt).tracking(trk)
        }
        
        var body: some View {
            ZStack {
                baseText
                    .foregroundStyle(.clear)
                    .overlay { activeGradient.mask { baseText } }
                    .blur(radius: 12)
                    .opacity(glowPulseHigh ? 0.40 : 0.25)
                    .padding(-6)
                
                Ellipse()
                    .fill(RadialGradient(stops: [
                        .init(color: isLight
                              ? AppColors.magenta.opacity(0.18)
                              : AppColors.purple.opacity(0.18), location: 0),
                        .init(color: isLight
                              ? AppColors.gold.opacity(0.10)
                              : AppColors.cyan.opacity(0.10),   location: 0.4),
                        .init(color: .clear, location: 0.7)
                    ], center: .center, startRadius: 0, endRadius: 150))
                    .frame(width: castWidth, height: castHeight)
                    .blur(radius: 20)
                    .scaleEffect(x: castPulseHigh ? 1.12 : 1.0, y: 1.0)
                    .opacity(castPulseHigh ? 1.0 : 0.7)
                    .offset(y: castOffset)
                
                baseText
                    .foregroundStyle(.clear)
                    .overlay { activeGradient.mask { baseText } }
                
                baseText
                    .foregroundStyle(.clear)
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: .clear,                     location: 0.00),
                                .init(color: .clear,                     location: 0.30),
                                .init(color: Color.white.opacity(0.30),  location: 0.38),
                                .init(color: Color.white.opacity(0.00),  location: 0.42),
                                .init(color: .clear,                     location: 0.50),
                                .init(color: Color.white.opacity(0.18),  location: 0.60),
                                .init(color: .clear,                     location: 0.65),
                                .init(color: .clear,                     location: 1.00),
                            ],
                            startPoint: UnitPoint(x: -0.1, y:  1.0),
                            endPoint:   UnitPoint(x:  1.1, y: -0.25)
                        )
                        .frame(width: 800)
                        .offset(x: holoFlashOffset * 320)
                        .mask { baseText }
                    }
                    .clipped()
            }
            .fixedSize()
        }
    }
    
    // MARK: - Citation Tap
    private struct CitationTapView: View {
        @Binding var citeOpen: Bool
        
        @Environment(\.colorScheme) private var colorScheme
        private var isLight: Bool { colorScheme == .light }
        
        private func citationBody() -> AttributedString {
            var result = AttributedString()
            
            var first = AttributedString("Two nationally representative studies")
            first.font = AppFonts.body(11.5, weight: .semibold)
            result.append(first)
            
            var second = AttributedString(" of 8,718 single adults. Roughly 1 in 5 reported engaging in CNM \u{2014} consistent across age, income, religion, race, political affiliation, and region.")
            second.font = AppFonts.body(11.5, weight: .regular)
            result.append(second)
            
            return result
        }
        
        var body: some View {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.35)) {
                        citeOpen.toggle()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(isLight
                                             ? AppColors.magenta
                                             : AppColors.cyanLight)
                        Text("About this research")
                            .font(AppFonts.body(11, weight: .medium))
                            .foregroundStyle(isLight
                                             ? AppColors.lightCardTitle
                                             : AppColors.textPrimary)
                            .tracking(0.3)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 10)
                    .background {
                        Capsule()
                            .fill(isLight
                                  ? Color.white.opacity(0.08)
                                  : Color.white.opacity(0.06))
                            .overlay {
                                Capsule()
                                    .stroke(
                                        isLight
                                        ? AppColors.lightBorder
                                        : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            }
                    }
                }
                .buttonStyle(.plain)
                // ✦ NO top padding here — parent VStack owns the gap above
                
                if citeOpen {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(citationBody())
                            .foregroundColor(isLight
                                             ? AppColors.lightTextPrimary
                                             : AppColors.textPrimary)
                            .lineSpacing(11.5 * 0.7)
                        
                        Text("Haupert et al., 2017 · Journal of Sex Research")
                            .font(AppFonts.body(10).italic())
                            .foregroundColor(isLight
                                             ? AppColors.lightTextSecondary
                                             : AppColors.textSecondary)
                            .padding(.top, Spacing.xs)   // 8pt — tight, same group
                    }
                    .frame(maxWidth: 300, alignment: .leading)
                    .padding(.vertical,   Spacing.sm)    // 16pt
                    .padding(.horizontal, Spacing.sm)    // 16pt
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isLight
                                  ? AppColors.lightCardFill
                                  : AppColors.cardBg)
                            .overlay(RoundedRectangle(cornerRadius: 14)
                                .stroke(isLight
                                        ? AppColors.lightBorder
                                        : AppColors.borderActive,
                                        lineWidth: 1))
                    )
                    .shadow(color: isLight
                            ? AppColors.lightShadowPurple
                            : Color.black.opacity(0.5),
                            radius: isLight ? 16 : 20,
                            y:      isLight ?  4 :  6)
                    .padding(.top, Spacing.sm)           // 16pt — card floats below pill
                    .transition(.opacity.combined(with: .scale(scale: 0.97, anchor: .top)))
                }
            }
        }
    }
    
    // MARK: - Ethos Text
    private struct EthosTextView: View {
        @Environment(\.colorScheme) private var colorScheme
        private var isLight: Bool { colorScheme == .light }
        
        var body: some View {
            if isLight {
                HStack(spacing: 0) {
                    Text("You're not alone.")
                        .font(AppFonts.body(14, weight: .semibold))
                        .foregroundStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.00),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.00),
                            ],
                            startPoint: .leading,
                            endPoint:   .trailing
                        ))
                    Text(" And this isn't new.")
                        .font(AppFonts.body(14, weight: .medium))
                        .tracking(0.2)
                        .foregroundColor(AppColors.lightCardTitle)
                }
                .lineSpacing(14 * 0.6)
                .multilineTextAlignment(.center)
            } else {
                HStack(spacing: 0) {
                    Text("You're not alone.")
                        .font(AppFonts.body(14, weight: .semibold))
                        .foregroundStyle(LinearGradient(
                            colors: [
                                AppColors.cyan.opacity(0.90),
                                AppColors.purple.opacity(0.80),
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        ))
                    Text(" And this isn't new.")
                        .font(AppFonts.body(14, weight: .medium))
                        .tracking(0.2)
                        .foregroundColor(.white)
                }
                .lineSpacing(14 * 0.6)
                .multilineTextAlignment(.center)
            }
        }
    }
    
}
#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
        OnboardingStatView(onContinue: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(config: .stat, sparkConfig: .statView, opacity: 1.0)
            .ignoresSafeArea()
        OnboardingStatView(onContinue: {})
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingBrandView.swift` {#file-open-lightly-features-onboarding-views-onboardingbrandview-swift}

```swift
import SwiftUI
import Combine

struct OnboardingBrandView: View {

    var onFinished: (() -> Void)? = nil

    // MARK: - Accessibility

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Screen geometry

    @State private var screenW: CGFloat = 393
    @State private var screenH: CGFloat = 852

    // MARK: - Canvas bloom state

    @State private var bl1Width: CGFloat = 6
    @State private var bl1Opacity: Double = 0.8
    @State private var hotWidth: CGFloat = 3
    @State private var hotOpacity: Double = 0.6
    @State private var thickWidth: CGFloat = 0
    @State private var thickOpacity: Double = 0
    @State private var centerGlowOpacity: Double = 0
    @State private var centerGlowScale: CGFloat = 1.0
    @State private var wisp1Opacity: Double = 0
    @State private var wisp2Opacity: Double = 0
    @State private var wisp3Opacity: Double = 0
    @State private var wisp1Offset: CGSize = .zero
    @State private var wisp1Scale: CGFloat = 1.0
    @State private var wisp2Offset: CGSize = .zero
    @State private var wisp2Scale: CGFloat = 1.0
    @State private var wisp3Offset: CGSize = .zero
    @State private var wisp3Scale: CGFloat = 1.0
    @State private var floorWidth: CGFloat = 0
    @State private var floorOpacity: Double = 0
    @State private var floorScaleX: CGFloat = 1.0

    // MARK: - Holo gradient sweep state

    @State private var holoPhase: CGFloat = 0
    @State private var holoPhaseB: CGFloat = 0

    // MARK: - Wordmark per-word state

    @State private var openOpacity: Double = 0
    @State private var openScale: CGFloat = 0.90
    @State private var openOffsetY: CGFloat = 12
    @State private var lightlyOpacity: Double = 0
    @State private var lightlyScale: CGFloat = 0.92
    @State private var lightlyOffsetY: CGFloat = 10
    @State private var wordmarkBreath: CGFloat = 1.0

    // MARK: - Tagline state
    //
    // taglineOpacity is EXIT-ONLY — starts at 1.0, only animated to 0 on exit.
    // No positional animation on the container — always at final position.
    //
    // Line 1 enters t=1950ms easeOut(0.22) → done t=2170ms
    // Line 2 enters t=2150ms easeOut(0.22) → done t=2370ms
    // Stagger gap (200ms) > duration × 0.7 (154ms) — reading beat honoured.
    // Exit does not begin until t=4500ms — 2130ms+ of settled dwell.

    @State private var taglineOpacity: Double = 1.0
    @State private var taglineBreath: Double = 0.55
    @State private var line1Opacity: Double = 0
    @State private var line2Opacity: Double = 0

    // MARK: - Global state

    @State private var autoAdvanceFired = false
    @State private var filamentStarted = false
    @State private var glowFieldOpacity: Double = 0
    @State private var sceneEntryOpacity: Double = 0
    @State private var ambientLoopsActive = false

    // NOTE: fadeOutOpacity REMOVED — coordinator owns the cover.

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let w = screenW
            let h = screenH

            ZStack {
                Color.clear.ignoresSafeArea()

                wisps(w: w, h: h)
                    .allowsHitTesting(false)

                centerGlow()
                    .allowsHitTesting(false)

                floorReflection(h: h)
                    .allowsHitTesting(false)

                if filamentStarted {
                    FilamentView(size: screenW, mode: .solo, speed: 1.0, showConnections: false)
                        .frame(width: screenW, height: screenW)
                        .position(x: w / 2, y: h * 0.46)
                        .allowsHitTesting(false)
                }

                wordmark
                    .scaleEffect(wordmarkBreath)
                    .position(x: w / 2 + 8, y: h * 0.46)
                    .accessibilityHidden(true)

                taglineView
                    .position(x: w / 2, y: h * 0.571)
                    .accessibilityHidden(true)

                // NOTE: No fadeOutOpacity cover layer here.
                // The coordinator's cover sits above this entire view.

                #if DEBUG
                VStack {
                    Spacer()
                Button("↺ Replay") { replay() }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.4))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .padding(.bottom, 48)
                }
                #endif

                // Accessibility: invisible, VoiceOver only.
                VStack(spacing: 4) {
                    Text("Open Lightly")
                    Text("Hard Conversations, Made Easier.")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Open Lightly. Hard Conversations, Made Easier.")
                .opacity(0)
                .allowsHitTesting(false)
            }
            .opacity(sceneEntryOpacity)
            .drawingGroup()
        }
        .ignoresSafeArea()
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { size in
            screenW = size.width
            screenH = size.height
        }
        .onAppear { startEverything() }
        .onDisappear {
            filamentStarted   = false
            ambientLoopsActive = false
            // autoAdvanceFired intentionally NOT reset here.
            // It is a one-way latch to prevent double-fire of the 5.20s handoff timer.
            // If the view reappears before the timer fires, the latch prevents
            // the timer from firing onFinished() twice. If the view cycles
            // (appear → disappear → reappear), startEverything() resets it explicitly
            // on the next onAppear, breaking the latch for a clean restart.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                wisp1Opacity      = 0
                wisp2Opacity      = 0
                wisp3Opacity      = 0
                centerGlowOpacity = 0
                floorOpacity      = 0
                glowFieldOpacity  = 0
                holoPhase         = 0
                holoPhaseB        = 0
                wordmarkBreath    = 1.0
                taglineBreath     = 0.55
            }
        }
    }

    // MARK: - Background layers

    private func bleedInit(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear,                          location: 0.02),
                        .init(color: AppColors.cyan.opacity(0.12),    location: 0.12),
                        .init(color: AppColors.purple.opacity(0.22),  location: 0.30),
                        .init(color: AppColors.magenta.opacity(0.20), location: 0.50),
                        .init(color: AppColors.purple.opacity(0.18),  location: 0.70),
                        .init(color: AppColors.pink.opacity(0.10),    location: 0.88),
                        .init(color: .clear,                          location: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: bl1Width, height: h)
            .opacity(bl1Opacity)
    }

    private func bleedThick(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: .clear,                           location: 0.05),
                        .init(color: AppColors.magenta.opacity(0.14),  location: 0.20),
                        .init(color: AppColors.purple.opacity(0.20),   location: 0.40),
                        .init(color: AppColors.cyan.opacity(0.12),     location: 0.60),
                        .init(color: AppColors.pink.opacity(0.14),     location: 0.80),
                        .init(color: .clear,                           location: 0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: thickWidth, height: h)
            .blur(radius: 40)
            .opacity(thickOpacity)
    }

    private func bleedHot(h: CGFloat) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.10),
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.10),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: hotWidth, height: h * 0.8)
            .opacity(hotOpacity)
    }

    private func centerGlow() -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: AppColors.purple.opacity(0.10),  location: 0),
                        .init(color: AppColors.magenta.opacity(0.06), location: 0.40),
                        .init(color: .clear,                          location: 0.70)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 150
                )
            )
            .frame(width: 250, height: 150)
            .scaleEffect(centerGlowScale)
            .blur(radius: 50)
            .opacity(centerGlowOpacity)
    }

    private func wisps(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            Ellipse()
                .fill(AppColors.cyan.opacity(0.06))
                .frame(width: 120, height: 80)
                .blur(radius: 35)
                .scaleEffect(wisp1Scale)
                .offset(wisp1Offset)
                .offset(x: -w * 0.15, y: -h * 0.12)
                .opacity(wisp1Opacity)

            Ellipse()
                .fill(AppColors.magenta.opacity(0.05))
                .frame(width: 80, height: 120)
                .blur(radius: 35)
                .scaleEffect(wisp2Scale)
                .offset(wisp2Offset)
                .offset(x: w * 0.18, y: h * 0.02)
                .opacity(wisp2Opacity)

            Ellipse()
                .fill(AppColors.purple.opacity(0.06))
                .frame(width: 100, height: 90)
                .blur(radius: 35)
                .scaleEffect(wisp3Scale)
                .offset(wisp3Offset)
                .offset(x: -w * 0.05, y: h * 0.18)
                .opacity(wisp3Opacity)
        }
    }

    private func floorReflection(h: CGFloat) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    stops: [
                        .init(color: AppColors.magenta.opacity(0.10), location: 0),
                        .init(color: AppColors.purple.opacity(0.08),  location: 0.40),
                        .init(color: .clear,                          location: 0.70)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: floorWidth * 0.5
                )
            )
            .frame(width: floorWidth, height: 90)
            .scaleEffect(x: floorScaleX, y: 1.0)
            .blur(radius: 35)
            .opacity(floorOpacity)
            .offset(y: h * 0.36)
    }

    // MARK: - Wordmark

    private var wordmark: some View {
        VStack(spacing: screenH < 700 ? -10 : -16) {
            Text("Open")
                .font(.custom("Zodiak-Extrabold", size: 58))
                .tracking(-1.5)
                .italic()
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.purple)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.cyan, AppColors.purple],
                            startPoint: UnitPoint(
                                x: -0.5 + holoPhase * 0.4,
                                y:  0.0 + holoPhase * 0.2
                            ),
                            endPoint: UnitPoint(
                                x:  1.5 + holoPhase * 0.4,
                                y:  1.0 + holoPhase * 0.2
                            )
                          ))
                )
                .opacity(openOpacity)
                .scaleEffect(openScale)
                .offset(y: openOffsetY)

            Text("Lightly")
                .font(.custom("Zodiak-Bold", size: 54))
                .tracking(2)
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(AppColors.orangeHot)
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.magenta, AppColors.pink, AppColors.pink],
                            startPoint: UnitPoint(
                                x: -0.5 + holoPhaseB * 0.4,
                                y:  0.0 + holoPhaseB * 0.2
                            ),
                            endPoint: UnitPoint(
                                x:  1.5 + holoPhaseB * 0.4,
                                y:  1.0 + holoPhaseB * 0.2
                            )
                          ))
                )
                .opacity(lightlyOpacity)
                .scaleEffect(lightlyScale)
                .offset(y: lightlyOffsetY)
        }
        .multilineTextAlignment(.center)
    }

    // MARK: - Tagline

    private var taglineView: some View {
        VStack(spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Hard")
                    .font(.custom("Switzer-Regular", size: 18))
                    .foregroundColor(
                        isLight
                            ? AppColors.wineDark
                            : Color.white
                    )
                Text("Conversations")
                    .font(.custom("Switzer-Light", size: 18))
                    .foregroundStyle(
                        isLight
                            ? AnyShapeStyle(LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.55),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.cyan,
                                    AppColors.purpleLight,
                                    AppColors.magenta,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                    )
            }
            .opacity(line1Opacity)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Made")
                    .font(.custom("Switzer-Regular", size: 18))
                    .foregroundColor(
                        isLight
                            ? AppColors.wineDark
                            : Color.white
                    )
                Text("Easier")
                    .font(.custom("Switzer-Light", size: 18))
                    .foregroundStyle(
                        isLight
                            ? AnyShapeStyle(LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.55),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.cyan,
                                    AppColors.purpleLight,
                                    AppColors.magenta,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                    )
            }
            .opacity(line2Opacity)
        }
        .font(.custom("Switzer-Light", size: 18))
        .tracking(0.3)
        .multilineTextAlignment(.center)
        .opacity(taglineOpacity)
    }

    // MARK: - Replay (DEBUG only)

    private func replay() {
        #if DEBUG
        if autoAdvanceFired {
            print("[OnboardingBrandView] ⚠️ replay() called after " +
                  "ambient loops started — cancelling in-flight loops.")
        }
        #endif

        // Cancel any in-flight ambient loops before restarting
        withAnimation(.default) {
            ambientLoopsActive = false
        }

        bl1Width          = 6
        bl1Opacity        = 0.8
        hotWidth          = 3
        hotOpacity        = 0.6
        thickWidth        = 0
        thickOpacity      = 0
        centerGlowOpacity = 0
        centerGlowScale   = 1.0
        wisp1Opacity      = 0
        wisp2Opacity      = 0
        wisp3Opacity      = 0
        wisp1Offset       = .zero
        wisp2Offset       = .zero
        wisp3Offset       = .zero
        wisp1Scale        = 1.0
        wisp2Scale        = 1.0
        wisp3Scale        = 1.0
        floorWidth        = 0
        floorOpacity      = 0
        floorScaleX       = 1.0
        holoPhase         = 0
        holoPhaseB        = 0
        openOpacity       = 0
        openScale         = 0.90
        openOffsetY       = 12
        lightlyOpacity    = 0
        lightlyScale      = 0.92
        lightlyOffsetY    = 10
        wordmarkBreath    = 1.0
        taglineOpacity    = 1.0
        taglineBreath     = 0.55
        line1Opacity      = 0
        line2Opacity      = 0
        glowFieldOpacity  = 0
        sceneEntryOpacity = 0
        filamentStarted   = false
        autoAdvanceFired  = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            startEverything()
        }
    }

    // MARK: - Animation timeline
    //
    // FINAL TIMELINE (v7 — Layered Dissolve) total runtime ~5020ms to handoff:
    //
    //   t=0ms       Canvas bloom begins
    //   t=300ms     Filament starts (skipped if reduceMotion)
    //   t=600ms     "Open" lands
    //   t=900ms     "Lightly" lands
    //   t=1000ms    Glow field begins (dark: 2.5s creep / light: 0.6s)
    //   t=1800ms    Atmospheric loops begin (skipped if reduceMotion)
    //   t=2000ms    Wordmark gradient sweep begins
    //   t=2200ms    Wordmark breath begins
    //   t=1950ms    Line 1 fades in — easeOut(0.22) done t=2170ms
    //   t=2150ms    Line 2 fades in — easeOut(0.22) done t=2370ms
    //   t=2370ms–4500ms  Fully settled dwell (~2130ms)
    //   t=4500ms    Tagline exits     — easeIn(160ms)  done t=4660ms
    //   t=4700ms    Wordmark exits    — easeIn(280ms)  done t=4980ms
    //   t=4780ms    Atmosphere exits  — easeIn(400ms)  done t=5180ms
    //   t=5020ms    onFinished() fires — coordinator takes over
    //
    //   COORDINATOR then:
    //   +0ms    NextScreen renders under cover (already opaque)
    //   +50ms   Cover lifts — easeOut(320ms)
    //   +410ms  Cover gone, NextScreen fully visible
    //   +450ms  BrandView removed from hierarchy

    private func startEverything() {

        // ── Scene entry fade ──────────────────────
        withAnimation(.easeOut(duration: 0.4)) {
            sceneEntryOpacity = 1.0
        }

        // ── Phase 1: Canvas bloom (0ms) ──────────────────────────────────

        withAnimation(.easeOut(duration: 1.2)) {
            bl1Width   = 420
            bl1Opacity = 0.18
        }
        withAnimation(.easeOut(duration: 0.8)) {
            hotWidth   = 200
            hotOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.easeOut(duration: 1.4)) {
                thickWidth   = 420
                thickOpacity = 0.22
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.8)) {
                wisp1Opacity      = 1.0
                wisp2Opacity      = 1.0
                wisp3Opacity      = 1.0
                centerGlowOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 1.0)) {
                floorWidth   = 360
                floorOpacity = 0.4
            }
        }

        // ── Glow field ────────────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 2.5)) {
                glowFieldOpacity = 1.0
            }
        }

        // ── Phase 2: "Open" lands (600ms) ────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.60) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                openOpacity = 1.0
                openScale   = 1.0
                openOffsetY = 0
            }
        }

        // ── Filament (300ms) ─────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            if !reduceMotion {
                filamentStarted = true
            }
        }

        // ── Phase 2b: "Lightly" lands (900ms) ────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.82)) {
                lightlyOpacity = 1.0
                lightlyScale   = 1.0
                lightlyOffsetY = 0
            }
        }

        // ── Ambient loops — staggered ignition (v7) ───────────────────────
        //
        // Three separate dispatch times prevent the "loop bomb" where all
        // repeatForever transactions fire on the same RunLoop tick:
        //
        //   t=1800ms  Atmospheric layer (wisps, glow, floor)
        //   t=2000ms  Gradient sweep (holoPhase, holoPhaseB)
        //   t=2200ms  Wordmark breath (wordmarkBreath, taglineBreath)
        //
        // 200ms micro-stagger is sub-perceptual as a pause but spreads
        // GPU transaction load across frames.
        //
        // ambientLoopsActive gate prevents competing animations on view
        // recycle (appear → disappear → reappear). When disabled in
        // onDisappear, any in-flight repeatForever loops are cancelled.
        // replay() explicitly cancels ambientLoopsActive before replay.

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.80) {
            guard !reduceMotion else { return }
            withAnimation(
                ambientLoopsActive
                    ? .easeInOut(duration: 6).repeatForever(autoreverses: true)
                    : .default
            ) {
                ambientLoopsActive = true
                wisp1Offset     = CGSize(width: 20,  height: -15)
                wisp1Scale      = 1.10
                wisp2Offset     = CGSize(width: -18, height: 18)
                wisp2Scale      = 1.12
                wisp3Offset     = CGSize(width: 12,  height: 15)
                wisp3Scale      = 1.08
                centerGlowScale = 1.2
                floorScaleX     = 1.06
                floorOpacity    = 0.6
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.00) {
            guard !reduceMotion else { return }
            withAnimation(
                ambientLoopsActive
                    ? .easeInOut(duration: 5.2).repeatForever(autoreverses: true)
                    : .default
            ) {
                holoPhase  = 1.0
                holoPhaseB = 1.0
            }
            withAnimation(
                ambientLoopsActive
                    ? .easeInOut(duration: 5.5).repeatForever(autoreverses: true)
                    : .default
            ) {
                taglineBreath = 0.72
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.20) {
            guard !reduceMotion else { return }
            withAnimation(
                ambientLoopsActive
                    ? .easeInOut(duration: 5.0).repeatForever(autoreverses: true)
                    : .default
            ) {
                wordmarkBreath = 1.02
            }
        }

        // ── Tagline entrance ──────────────────────────────────────────────
        //
        // Stagger gap (200ms) > duration × 0.7 (154ms) — Line 1 fully
        // opaque before Line 2 starts. Reading beat is honoured.

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.95) {
            withAnimation(.easeOut(duration: 0.22)) {
                line1Opacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.15) {
            withAnimation(.easeOut(duration: 0.22)) {
                line2Opacity = 1.0
            }
        }

        // ── Settled dwell: t=2370ms → t=4500ms (~2130ms) ─────────────────

        // ── Phase 4: Exit sequence ────────────────────────────────────────
        //
        // Beat 1 — Tagline dissolves (t=4500ms, 160ms)
        // Beat 2 — Wordmark contracts+fades (t=4700ms, 280ms)
        //          Starts 40ms after tagline done (4660ms + 40ms buffer)
        // Beat 3 — Atmosphere fades (t=4780ms, 400ms)
        //          Overlaps wordmark tail — bg layer has lower priority
        // Handoff — onFinished() at t=5020ms
        //          40ms before atmosphere fully done (5180ms)
        //          Coordinator receives and starts cover lift

        // Beat 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.50) {
            withAnimation(.easeIn(duration: 0.16)) {
                taglineOpacity = 0
            }
        }

        // Beat 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.70) {
            withAnimation(.easeIn(duration: 0.28)) {
                openOpacity    = 0
                openScale      = 0.96
                lightlyOpacity = 0
                lightlyScale   = 0.96
            }
        }

        // Beat 3
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.78) {
            withAnimation(.easeIn(duration: 0.40)) {
                glowFieldOpacity  = 0
                centerGlowOpacity = 0
                wisp1Opacity      = 0
                wisp2Opacity      = 0
                wisp3Opacity      = 0
                floorOpacity      = 0
            }
        }

        // ── Handoff (5020ms) ─────────────────────────────────────────────

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.85) {
            withAnimation(.easeIn(duration: 0.35)) {
                sceneEntryOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.20) {
            guard !autoAdvanceFired else { return }
            autoAdvanceFired = true
            #if DEBUG
            assert(
                onFinished != nil,
                "OnboardingBrandView: onFinished not injected — " +
                "wire this callback from the coordinator."
            )
            #endif
            onFinished?()
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .brand,
            sparkConfig: .statView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
        OnboardingBrandView(onFinished: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .brand,
            sparkConfig: .statView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
        OnboardingBrandView(onFinished: {})
    }
    .preferredColorScheme(.light)
}
 

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingNameView.swift` {#file-open-lightly-features-onboarding-views-onboardingnameview-swift}

```swift


// OnboardingNameView.swift
// Open Lightly
//
// Screen 1: Name + Pronouns

import SwiftUI

// MARK: - Main View

struct OnboardingNameView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack:     (() -> Void)?

    // Form state
    @State private var displayName:       String         = ""
    @State private var selectedGender:    String? = nil
    @State private var customGenderText:  String = ""
    @State private var showCustomGenderField: Bool = false
    @FocusState private var nameFieldFocused: Bool

    // Atmosphere
    @State private var hasAnimated: Bool      = false

    // Entrance
    @State private var headerVisible = false
    @State private var cardVisible   = false
    @State private var ctaVisible    = false

    // Greeting response
    @State private var greetingVisible = false
    @State private var greetingOwnsName: Bool = false
    @State private var nameTextOpacity: Double = 1.0
    @State private var fieldCollapsed: Bool = false
    @State private var typingDebounce: DispatchWorkItem? = nil
    @State private var focusTask: Task<Void, Never>? = nil

    // Gender section
    @State private var genderSectionVisible = false

    // Validation Bloom
    @State private var isButtonGlowing: Bool = false

    // Pulse Animation
    @State private var glowPulse: Bool = false

    // Environment
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Surface tokens

    private var kFieldBG: Color {
        colorScheme == .light
            ? AppColors.lightSurfaceBg
            : Color.white.opacity(0.07)
    }

    private var kGlassBorder: Color {
        colorScheme == .light
            ? AppColors.lightBorder
            : Color.white.opacity(0.09)
    }

    private var kFieldBorderActive: some ShapeStyle {
        if colorScheme == .light {
            return AnyShapeStyle(AppColors.warmAuroraBorder)
        } else {
            return AnyShapeStyle(AppColors.spectrumBorder)
        }
    }

    private var kFloatingLabelFocused: Color {
        colorScheme == .light
            ? AppColors.lightLabelFocused
            : AppColors.purpleLight
    }

    private var kFloatingLabelUnfocused: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle.opacity(0.40)
            : AppColors.textTertiary
    }

    private var kTextPrimary: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle
            : .white
    }

    private var kPronounLabel: Color {
        colorScheme == .light
            ? AppColors.lightCardTitle.opacity(0.65)
            : .white.opacity(0.75)
    }

    private var kPronounHint: Color {
        colorScheme == .light
            ? AppColors.lightHintText
            : AppColors.textTertiary
    }

    private var kCustomPillFill: Color {
        colorScheme == .light
            ? AppColors.lightFrostPillCustom
            : AppColors.surfaceBg
    }

    private var kCustomPillBorder: Color {
        colorScheme == .light
            ? AppColors.lightBorder
            : AppColors.borderHover
    }

    private var isValid: Bool {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 1 && trimmed.count <= 30
              else { return false }
        guard let gender = selectedGender else { return false }
        if gender == "Something else" {
            return !customGenderText
                .trimmingCharacters(in: .whitespaces)
                .isEmpty
        }
        return true
    }

    // MARK: - Name Field

    @ViewBuilder
    private var nameField: some View {
        ZStack(alignment: .leading) {

            // Floating label
            Text("What should we call you?")
                .font(displayName.isEmpty && !nameFieldFocused
                      ? AppFonts.display(22, weight: .semibold)
                      : AppFonts.overline)
                .foregroundStyle(
                    displayName.isEmpty && !nameFieldFocused
                        ? (colorScheme == .light
                            ? AnyShapeStyle(AppColors.lightTextSecondary)
                            : AnyShapeStyle(AppColors.textSecondary))
                        : (colorScheme == .light
                            ? AnyShapeStyle(AppColors.lightLabelFocused)
                            : AnyShapeStyle(AppColors.purpleLight))
                )
                .offset(y: displayName.isEmpty && !nameFieldFocused ? 0 : -36)
                .animation(.easeInOut(duration: 0.35), value: nameFieldFocused)
                .animation(.easeInOut(duration: 0.35), value: displayName.isEmpty)
                .opacity(fieldCollapsed ? 0 : 1)
                .animation(.easeInOut(duration: 0.25).delay(0.05), value: fieldCollapsed)
                .accessibilityHidden(true)

            TextField("", text: $displayName)
                .font(AppFonts.display(28, weight: .semibold))
                .foregroundColor(
                    (colorScheme == .light
                        ? AppColors.lightCardTitle
                        : AppColors.textPrimary)
                    .opacity(nameTextOpacity)
                )
                .tint(colorScheme == .light
                    ? AppColors.lightLabelFocused
                    : AppColors.cyan)
                .offset(y: 10)
                .focused($nameFieldFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .onSubmit {
                    nameFieldFocused = false
                    triggerCollapse()
                }
                .opacity(fieldCollapsed ? 0 : 1)
                .animation(.easeInOut(duration: 0.3), value: fieldCollapsed)
                .disabled(fieldCollapsed)
                .onChange(of: displayName) { _, newValue in
                    let trimmed = newValue
                        .trimmingCharacters(in: .whitespaces)
                    if trimmed.count > 30 {
                        displayName = String(trimmed.prefix(30))
                    }

                    let hasContent = !trimmed
                        .isEmpty

                    withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                        genderSectionVisible = hasContent
                    }

                    typingDebounce?.cancel()

                    guard !trimmed.isEmpty else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                        return
                    }

                    let work = DispatchWorkItem {
                        triggerCollapse()
                    }
                    typingDebounce = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
                }
                .onChange(of: nameFieldFocused) { _, isFocused in
                    if isFocused && greetingOwnsName {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                    }
                }
                .accessibilityLabel("What should we call you?")
        }
        .frame(height: 72)
        .padding(.bottom, 4)
        .overlay(alignment: .bottom) {
            ZStack {
                // Base line — always visible
                Rectangle()
                    .fill(
                        nameFieldFocused || !displayName.isEmpty
                            ? (colorScheme == .light
                                ? AnyShapeStyle(AppColors.warmAuroraBorder)
                                : AnyShapeStyle(AppColors.spectrumBorder))
                            : (colorScheme == .light
                                ? AnyShapeStyle(AppColors.lightBorder)
                                : AnyShapeStyle(AppColors.border))
                    )
                    .frame(height: nameFieldFocused ? 3 : 2)
                    .animation(.easeInOut(duration: 0.3), value: nameFieldFocused)

                // Gradient glow line — appears when focused or has content
                if nameFieldFocused || !displayName.isEmpty {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .light
                                    ? [
                                        AppColors.magenta.opacity(0.6),
                                        AppColors.pink.opacity(0.9),
                                        AppColors.purple.opacity(0.7),
                                        AppColors.magenta.opacity(0.6)
                                      ]
                                    : [
                                        AppColors.cyan.opacity(0.6),
                                        AppColors.purple.opacity(0.9),
                                        AppColors.pink.opacity(0.8),
                                        AppColors.cyan.opacity(0.6)
                                      ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 3)
                        .blur(radius: 4)
                        .opacity(nameFieldFocused ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 0.3), value: nameFieldFocused)

                    // Outer soft glow
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: colorScheme == .light
                                    ? [
                                        AppColors.magenta.opacity(0.2),
                                        AppColors.pink.opacity(0.35),
                                        AppColors.purple.opacity(0.25),
                                        AppColors.magenta.opacity(0.2)
                                      ]
                                    : [
                                        AppColors.cyan.opacity(0.2),
                                        AppColors.purple.opacity(0.35),
                                        AppColors.pink.opacity(0.3),
                                        AppColors.cyan.opacity(0.2)
                                      ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 8)
                        .blur(radius: 6)
                        .opacity(nameFieldFocused ? 0.9 : 0.4)
                        .animation(.easeInOut(duration: 0.3), value: nameFieldFocused)
                }
            }
            .opacity(fieldCollapsed ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: fieldCollapsed)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height

            ZStack {
                // ── Background ───────────────────────────────────────────
                Color.clear.ignoresSafeArea()

                // ── Atmosphere ellipse ────────────────────────────────────
                if colorScheme == .dark {
                    Ellipse()
                        .fill(RadialGradient(stops: [
                            .init(color: Color.purple.opacity(0.22), location: 0),
                            .init(color: Color.blue.opacity(0.12),   location: 0.5),
                            .init(color: .clear,                     location: 1)
                        ], center: .center, startRadius: 0, endRadius: 240))
                        .frame(width: geo.size.width, height: h * 0.31)
                        .blur(radius: 80)
                        .offset(y: h * 0.30)
                        .allowsHitTesting(false)
                }

                // ── Content ───────────────────────────────────────────────
                VStack(alignment: .leading, spacing: 0) {

                    OnboardingNavBar(currentStep: 1, totalSteps: 6, onBack: onBack)
                        .padding(.top, geo.safeAreaInsets.top > 50 ? 8 : 20)
                        .padding(.bottom, 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Let's get")
                            .font(AppFonts.display(28, weight: .semibold))
                            .foregroundColor(kTextPrimary)
                        LivingText(text: "acquainted.")
                    }
                    .opacity(headerVisible ? 1 : 0)
                    .scaleEffect(headerVisible ? 1.0 : 0.95)
                    .padding(.bottom, 28)

                    // ── Name field ────────────────────────────────────────
                    nameField
                        .padding(.bottom, 20)
                        .opacity(cardVisible ? 1 : 0)
                        .scaleEffect(cardVisible ? 1.0 : 0.95)

                    // ── Greeting ──────────────────────────────────────────
                    // FIX: corrected brace structure
                    HStack(alignment: .firstTextBaseline, spacing: 7.5) {
                        Spacer()

                        Text("Hi ")
                            .font(AppFonts.display(32, weight: .bold))
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightHeadlineDarkRose
                                : AppColors.textPrimary.opacity(0.94))

                        Text(displayName.trimmingCharacters(in: .whitespaces))
                            .font(AppFonts.display(32, weight: .bold))
                            .foregroundStyle(colorScheme == .light
                                ? AppColors.lightHeadlineDarkRose
                                : AppColors.textPrimary)
                            .modifier(GlowUnderline(isLight: colorScheme == .light))

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(greetingVisible ? 1 : 0)
                    .offset(y: greetingVisible ? -65 : 16)
                    .animation(
                        .spring(response: 1.1, dampingFraction: 0.88),
                        value: greetingVisible
                    )
                    .padding(.top, 8)
                    .padding(.bottom, 28)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            greetingVisible = false
                            greetingOwnsName = false
                        }
                        withAnimation(.easeInOut(duration: 0.3).delay(0.15)) {
                            fieldCollapsed = false
                            nameTextOpacity = 1.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            nameFieldFocused = true
                        }
                    }
                    .accessibilityLabel("Edit name")
                    .accessibilityHint("Tap to change what we call you")
                    .accessibilityAddTraits(.isButton)

                    Text("tap to edit")
                        .font(AppFonts.caption)
                        .foregroundColor(colorScheme == .light
                            ? AppColors.lightTextTertiary
                            : AppColors.textTertiary)
                        .padding(.top, 4)
                        .opacity(greetingVisible ? 0.7 : 0)
                        .animation(.easeInOut(duration: 0.3), value: greetingVisible)

                    Rectangle()
                        .fill(colorScheme == .light
                              ? AppColors.lightBorder
                              : Color.white.opacity(0.05))
                        .frame(height: 1)
                        .padding(.bottom, 18)
                        .opacity(cardVisible && !fieldCollapsed ? 1 : 0)
                        .scaleEffect(cardVisible ? 1.0 : 0.95)
                        .animation(.easeInOut(duration: 0.3), value: fieldCollapsed)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.85).delay(0.23),
                            value: cardVisible
                        )

                    genderSection
                        .opacity(cardVisible && genderSectionVisible ? 1 : 0)
                        .scaleEffect(cardVisible && genderSectionVisible ? 1.0 : 0.95)

                    Spacer(minLength: OL.spacerMin(h))

                    // ── CTA ───────────────────────────────────────────────
                    ZStack {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(LinearGradient(
                                colors: [
                                    AppColors.pink.opacity(0.30),
                                    AppColors.purple.opacity(0.25),
                                    AppColors.magenta.opacity(0.20)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(maxWidth: .infinity)
                            .frame(height: 80)
                            .blur(radius: 36)
                            .opacity(isButtonGlowing ? 1.0 : 0.0)
                            .animation(
                                reduceMotion ? .none : .easeInOut(duration: 0.6),
                                value: isButtonGlowing
                            )
                            .allowsHitTesting(false)

                        HoloCTAButton(
                            title: "Next",
                            isEnabled: isValid
                        ) {
                            triggerHaptic(.medium)
#if DEBUG
                            assert(onContinue != nil,
                                   "OnboardingNameView: onContinue not injected — " +
                                   "wire this callback from the coordinator.")
#endif
                            commitData()
                            onContinue?()
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(
                            color: isButtonGlowing
                                ? AppColors.pink.opacity(
                                    reduceMotion ? 0.30 : (glowPulse ? 0.40 : 0.20)
                                )
                                : .clear,
                            radius: isButtonGlowing
                                ? (reduceMotion ? 12 : (glowPulse ? 18 : 8))
                                : 0,
                            x: 0, y: 0
                        )
                    }
                    .opacity(ctaVisible ? 1 : 0)
                    .scaleEffect(ctaVisible ? 1.0 : 0.95)

                    OnboardingFooter()
                        .opacity(ctaVisible ? 1 : 0)
                        .scaleEffect(ctaVisible ? 1.0 : 0.95)
                }
                .padding(.horizontal, 28)
            }
            .frame(width: geo.size.width, alignment: .topLeading)
            .onAppear {
                restoreStateIfNeeded()

                if isValid {
                    isButtonGlowing = true
                    if !reduceMotion {
                        withAnimation(
                            .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true)
                            .delay(0.6)
                        ) { glowPulse = true }
                    }
                }

                guard !hasAnimated else { return }
                hasAnimated = true

                let entranceSpring = Animation.spring(response: 0.5, dampingFraction: 0.85)

                if reduceMotion {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        headerVisible = true
                        cardVisible   = true
                        ctaVisible    = true
                    }
                } else {
                    withAnimation(entranceSpring.delay(0.08)) { headerVisible = true }
                    withAnimation(entranceSpring.delay(0.23)) { cardVisible = true }
                    withAnimation(entranceSpring.delay(0.38)) { ctaVisible = true }
                }

                if !reduceMotion {
                    focusTask = Task {
                        try? await Task.sleep(nanoseconds: 750_000_000)
                        guard !Task.isCancelled else { return }
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                nameFieldFocused = true
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onDisappear {
                typingDebounce?.cancel()
                typingDebounce = nil
                focusTask?.cancel()
                focusTask = nil
                hasAnimated      = false
                headerVisible    = false
                cardVisible      = false
                ctaVisible       = false
                isButtonGlowing  = false
                glowPulse        = false
                greetingOwnsName = false
                nameTextOpacity  = 1.0
                fieldCollapsed   = false
            }
            .onChange(of: isValid) { _, newValue in
                if newValue {
                    triggerHaptic(.medium)
                    if reduceMotion {
                        isButtonGlowing = true
                    } else {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            isButtonGlowing = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            withAnimation(
                                .easeInOut(duration: 2.5)
                                .repeatForever(autoreverses: true)
                            ) { glowPulse = true }
                        }
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        isButtonGlowing = false
                    }
                    glowPulse = false
                }
            }
        }
    }

    // MARK: - Gender Section

    private var genderSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Gender identity")
                .font(AppFonts.body(13, weight: .medium))
                .foregroundColor(kPronounLabel)
            
            Text("Helps us personalise your prompts and tone")
                .font(AppFonts.caption)
                .foregroundColor(kPronounHint)
                .padding(.top, 2)
                .padding(.bottom, 12)

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    SelectablePill(
                        label: "Man",
                        isSelected: selectedGender == "Man",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Man" ? nil : "Man"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    SelectablePill(
                        label: "Woman",
                        isSelected: selectedGender == "Woman",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Woman" ? nil : "Woman"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
                HStack(spacing: 10) {
                    SelectablePill(
                        label: "Non-binary",
                        isSelected: selectedGender == "Non-binary",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Non-binary" ? nil : "Non-binary"
                            showCustomGenderField = false
                            customGenderText = ""
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    SelectablePill(
                        label: "Something else",
                        isSelected: selectedGender == "Something else",
                        showFlame: false
                    ) {
                        nameFieldFocused = false
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedGender = selectedGender == "Something else"
                                ? nil : "Something else"
                            showCustomGenderField = selectedGender == "Something else"
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }

                // Full-width and visually prominent by design.
                // Shame reduction architecture: the option to decline
                // should never feel hidden or harder to find than
                // providing the data. See PROJECT_SCOPE Section 6.
                SelectablePill(
                    label: "Prefer not to say",
                    isSelected: selectedGender == "Prefer not to say",
                    showFlame: false
                ) {
                    nameFieldFocused = false
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedGender = selectedGender == "Prefer not to say"
                            ? nil : "Prefer not to say"
                        showCustomGenderField = false
                        customGenderText = ""
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                .frame(maxWidth: .infinity)

                if showCustomGenderField {
                    TextField("Describe your gender identity",
                              text: $customGenderText)
                        .font(AppFonts.body(16, weight: .regular))
                        .foregroundColor(kTextPrimary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(kCustomPillFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(kCustomPillBorder,
                                                lineWidth: 1)
                                )
                        )
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .padding(.top, 8)
                        .transition(.opacity.combined(
                            with: .scale(scale: 0.97, anchor: .top)))
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Gender identity — optional")
    }

    // MARK: - Haptic

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    // MARK: - Helpers

    private func triggerCollapse() {
        let trimmed = displayName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        typingDebounce?.cancel()
        withAnimation(.easeInOut(duration: 0.35)) {
            nameTextOpacity = 0
            fieldCollapsed = true
        }
        withAnimation(
            .spring(response: 0.6, dampingFraction: 0.85)
            .delay(0.28)
        ) {
            greetingVisible = true
            greetingOwnsName = true
        }
    }

    private func dismissCustomIfNeeded() {
        if showCustomGenderField {
            withAnimation(.easeInOut(duration: 0.3)) {
                showCustomGenderField = false
                customGenderText = ""
            }
        }
    }

    // MARK: - State Restoration

    private func restoreStateIfNeeded() {
        if !data.displayName.isEmpty {
            displayName = data.displayName
            genderSectionVisible = true
        }
        if let savedGender = data.genderIdentity {
            selectedGender = savedGender
            // If "Something else" was stored and it's a custom value,
            // we cannot reconstruct the custom field — leave as-is.
        }
    }

    // MARK: - Commit

    private func commitData() {
        data.displayName = displayName.trimmingCharacters(in: .whitespaces)
        if selectedGender == "Something else" {
            let custom = customGenderText
                .trimmingCharacters(in: .whitespaces)
            if !custom.isEmpty {
                data.genderIdentity = custom
            }
            // If somehow empty, do not write "Something else"
        } else if let selected = selectedGender,
                  selected != "Something else" {
            data.genderIdentity = selected
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName = "Jordan"
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Dark — empty state") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — empty state") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .name,
            sparkConfig: .nameView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingNameView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingModeSelectView.swift` {#file-open-lightly-features-onboarding-views-onboardingmodeselectview-swift}

```swift
import SwiftUI

// MARK: - Main View

struct OnboardingModeSelectView: View {
    @Binding var data: OnboardingData
    var onContinue: () -> Void
    var onBack: (() -> Void)?

    @State private var titleVisible  = false
    @State private var navVisible    = false
    @State private var cardsVisible  = false
    @State private var hasAnimated   = false

    // Breathing atmosphere — one phase per tile, offset so they never sync
    @State private var soloBreath:    CGFloat = 0
    @State private var coupleBreath:  CGFloat = 0
    @State private var browseBreath:  CGFloat = 0
    @State private var breathTask: Task<Void, Never>? = nil

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private var selectionMade: Bool {
        guard let mode = data.explorationMode else {
            return false
        }
        if mode == .browsing { return true }
        return data.nmStage != nil
    }

    // COPYWRITING REVIEW: S5-E2
    // Current descriptors read as a progression (rungs on a ladder) rather than
    // three equally valid positions. "New to this" → "dipped my toes in" → "part of my life"
    // inadvertently implies a hierarchy. Consider reframing as parallel states:
    // "Still figuring out if this is for me." / "I've had experiences. Learning as I go." /
    // "I know this territory. Here to go deeper." This removes hierarchical language while
    // maintaining clarity. Also note: "No judgment" can paradoxically highlight judgment concerns.
    private var experienceDescriptor: String? {
        switch data.nmStage {
        case .curious:    return "New to this — maybe I've read about it or know people who do it."
        case .exploring:  return "I've dipped my toes in. A few real experiences."
        case .experienced:return "This has been part of my life for a while."
        case .none:       return nil
        }
    }

    private var atmosphereColors: (primary: Color, secondary: Color) {
        switch data.explorationMode {
        case .solo:     return (AppColors.cyan,    AppColors.deepBlue)
        case .couple:   return (AppColors.magenta, AppColors.purple)
        case .browsing: return (AppColors.gold,    AppColors.orangeHot)
        case .none:     return (AppColors.purple,  AppColors.deepBlue)
        }
    }

    private func handleSelection(_ mode: ExplorationMode) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            if data.explorationMode == mode {
                data.explorationMode = nil
                data.nmStage = nil
            } else {
                if data.explorationMode != nil {
                    data.nmStage = nil
                }
                data.explorationMode = mode
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @ViewBuilder
    private func selectedBorder(
        isSelected:   Bool,
        cornerRadius: CGFloat
    ) -> some View {
        if isSelected {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isLight ? AppColors.warmAuroraBorder : AppColors.spectrumGradient,
                        lineWidth: 2
                    )
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        isLight ? AppColors.warmAuroraBorder : AppColors.spectrumGradient,
                        lineWidth: 3
                    )
                    .blur(radius: 4)
                    .opacity(0.25)
            }
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(
                    isLight ? AppColors.lightBorder : AppColors.border,
                    lineWidth: 1.5
                )
        }
    }

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width

            let sectionSpacing: CGFloat = h < 700
                ? max(8.0, h * 0.012)
                : max(12.0, h * 0.018)

            ZStack {
                Color.clear.ignoresSafeArea()

                if !isLight {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                atmosphereColors.primary.opacity(0.30),
                                atmosphereColors.secondary.opacity(0.15),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 30,
                            endRadius: 360
                        ))
                        .frame(width: OL.atmosW(w), height: OL.atmosH(h))
                        .offset(y: -h * 0.09)
                        .blur(radius: 80)
                        .animation(
                            .easeOut(duration: 0.45),
                            value: data.explorationMode?.rawValue ?? "none"
                        )
                        .allowsHitTesting(false)
                        .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    OnboardingNavBar(
                        currentStep: 2,
                        totalSteps:  6,
                        onBack:      onBack
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, max(8.0, h * 0.014))
                    .opacity(navVisible ? 1.0 : 0.0)

                    ViewThatFits(in: .vertical) {
                        VStack(spacing: 0) {
                            contentBlock(sectionSpacing: sectionSpacing, geo: geo)
                            Spacer(minLength: 0)
                            ctaBlock.padding(.horizontal, 24)
                        }
                        VStack(spacing: 0) {
                            ScrollView(showsIndicators: false) {
                                contentBlock(sectionSpacing: sectionSpacing, geo: geo)
                            }
                            ctaBlock.padding(.horizontal, 24)
                        }
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onAppear {
                guard !hasAnimated else {
                    titleVisible = true
                    cardsVisible = true
                    navVisible   = true
                    return
                }
                hasAnimated = true
                withAnimation(.easeOut(duration: 0.4).delay(0.15)) { titleVisible = true }
                withAnimation(.easeOut(duration: 0.4).delay(0.35)) { cardsVisible = true }
                withAnimation(.easeOut(duration: 0.3).delay(0.35)) { navVisible   = true }

                breathTask = Task {
                    // Solo — immediate
                    withAnimation(.easeInOut(duration: 4.0)
                        .repeatForever(autoreverses: true)) {
                        soloBreath = 1.0
                    }
                    // Couple — 0.8s delay
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 5.0)
                        .repeatForever(autoreverses: true)) {
                        coupleBreath = 1.0
                    }
                    // Browsing — additional 0.8s
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    guard !Task.isCancelled else { return }
                    withAnimation(.easeInOut(duration: 6.0)
                        .repeatForever(autoreverses: true)) {
                        browseBreath = 1.0
                    }
                }
            }
            .onDisappear {
                breathTask?.cancel()
                breathTask = nil
                hasAnimated  = false
                soloBreath   = 0
                coupleBreath = 0
                browseBreath = 0
            }
        }
    }

    // MARK: - Content Block

    private func contentBlock(
        sectionSpacing: CGFloat,
        geo:            GeometryProxy
    ) -> some View {
        let h = geo.size.height
        let tileH: CGFloat = max(130, h * 0.195)
        
        return VStack(alignment: .leading, spacing: sectionSpacing) {
            
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("How are you")
                        .font(AppFonts.heroTitle)
                        .foregroundStyle(isLight
                                         ? AppColors.lightTextPrimary
                                         : AppColors.textPrimary)
                    LivingText(text: "exploring?", font: AppFonts.heroTitle)
                }
                Text(data.displayName.trimmingCharacters(
                         in: .whitespaces).isEmpty
                    ? "There's no wrong way to start."
                    : "There's no wrong answer, \(data.displayName.trimmingCharacters(in: .whitespaces))."
                )
                .font(AppFonts.caption)
                .foregroundStyle(isLight
                                 ? AppColors.lightTextSecondary
                                 : AppColors.textSecondary)
            }
            .opacity(titleVisible ? 1 : 0)
            .offset(y: titleVisible ? 0 : 12)
            
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    bentoCentered(mode: .solo,   tileH: tileH)
                    bentoCentered(mode: .couple, tileH: tileH)
                }
                bentoBar(mode: .browsing)
            }
            .opacity(cardsVisible ? 1 : 0)
            .offset(y: cardsVisible ? 0 : 16)
            
            if let mode = data.explorationMode {
                let teaserText: String = {
                    switch mode {
                    case .solo:     return "Starts with what you actually want."
                    case .couple:   return "Starts with the conversation you've been circling."
                    case .browsing: return "No commitment. Just curiosity."
                    }
                }()
                
                let operationalContext: String? = {
                    switch mode {
                    case .solo:     return "You can connect with a partner later."
                    case .couple:   return "Pairing happens after you both set up."
                    case .browsing: return nil
                    }
                }()
                
                LivingText(
                    text: teaserText,
                    font: AppFonts.body(17, weight: .semibold)
                )
                .id(mode)
                .transition(.opacity)
                .frame(maxWidth: .infinity)
                
                if let context = operationalContext {
                    Text(context)
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                                         ? AppColors.lightTextSecondary
                                         : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .transition(.opacity)
                }
            }
            
            let expVisible = data.explorationMode != nil
                && data.explorationMode != .browsing
            
            if expVisible {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your experience")
                            .font(AppFonts.caption)
                            .foregroundStyle(isLight
                                             ? AppColors.lightTextSecondary
                                             : AppColors.textSecondary)
                        Spacer()
                        Text("No judgment")
                            .font(AppFonts.overline)
                            .foregroundStyle(isLight
                                             ? AppColors.lightTextTertiary
                                             : AppColors.textTertiary)
                    }
                    
                    HStack(spacing: 10) {
                        SelectablePill(
                            label:      "Curious",
                            isSelected: data.nmStage == .curious,
                            intensity:  .dim,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .curious
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        SelectablePill(
                            label:      "Exploring",
                            isSelected: data.nmStage == .exploring,
                            intensity:  .warm,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .exploring
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                        SelectablePill(
                            label:      "Experienced",
                            isSelected: data.nmStage == .experienced,
                            intensity:  .alive,
                            height:     44,
                            fontSize:   15
                        ) {
                            data.nmStage = .experienced
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Group {
                        if let descriptor = experienceDescriptor {
                            Text(descriptor)
                                .font(AppFonts.caption)
                                .foregroundStyle(isLight
                                                 ? AppColors.lightTextSecondary
                                                 : AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                                .id(data.nmStage)
                                .accessibilityAddTraits(.updatesFrequently)
                        } else {
                            Color.clear.frame(height: 18)
                        }
                    }
                    .animation(.easeOut(duration: 0.25), value: data.nmStage?.rawValue ?? "")
                    
                    Text("You can always change these later.")
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                                         ? AppColors.lightTextTertiary
                                         : AppColors.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, sectionSpacing)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: data.explorationMode?.rawValue ?? "none")
    }

    // MARK: - CTA Block

    private var ctaBlock: some View {
        VStack(spacing: 0) {
            HoloCTAButton(title: "Next", isEnabled: selectionMade) {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onContinue()
            }
            OnboardingFooter(text: "Your data is encrypted and always stays yours.")
        }
    }

    // MARK: - Bento Centered Tile
    @ViewBuilder
    private func bentoCentered(
        mode:  ExplorationMode,
        tileH: CGFloat
    ) -> some View {
        let isSelected    = data.explorationMode == mode
        let somethingElse = data.explorationMode != nil && !isSelected
        let filamentSize: CGFloat = min(tileH * 0.52, 88)

        // Per-tile color and breath values
        let tileColor: Color = {
            switch mode {
            case .solo:   return AppColors.cyan
            case .couple: return AppColors.magenta
            default:      return AppColors.purple
            }
        }()

        let breathValue: CGFloat = {
            switch mode {
            case .solo:   return soloBreath
            case .couple: return coupleBreath
            case .browsing: return browseBreath
            }
        }()

        // Glow opacity: low at rest, amplified on selection
        let glowOpacity: Double = isSelected
            ? 0.18 + Double(breathValue) * 0.10
            : 0.06 + Double(breathValue) * 0.04

        let headline: String = {
            switch mode {
            case .solo:   return "Solo Discovery"
            case .couple: return "Shared Journey"
            default:      return ""
            }
        }()

        let subtitle: String = {
            switch mode {
            case .solo:   return "I want clarity\nfor myself first."
            case .couple: return "Starting the conversation\ntogether."
            default:      return ""
            }
        }()

        Button {
            handleSelection(mode)
        } label: {
            VStack(spacing: 6) {
                Spacer(minLength: 0)

                // CHANGE: always active, speed idles at 0.28, accelerates on selection
                TileOrbitView(
                    orbitCount: mode == .solo ? 1 : 2,
                    isActive:   true,
                    speed:      isSelected ? 1.0 : 0.28,
                    size:       filamentSize
                )
                .frame(width: filamentSize, height: filamentSize)
                // CHANGE: always visible, dims when not selected
                .opacity(isSelected ? 1.0 : 0.35)
                .animation(.easeInOut(duration: 0.4), value: isSelected)

                Text(headline)
                    .font(AppFonts.display(17, weight: .semibold))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextPrimary
                        : AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(AppFonts.caption)
                    .foregroundStyle(isLight
                        ? AppColors.lightTextSecondary
                        : AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .frame(height: tileH)
            .background(
                ZStack {
                    // Base fill — unchanged
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isLight
                            ? (isSelected ? AppColors.lightFrostCard : AppColors.lightFrostPill)
                            : AppColors.cardBg)

                    // CHANGE: breathing radial atmosphere — exists at rest, amplifies on selection
                    if !isLight {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        tileColor.opacity(glowOpacity),
                                        tileColor.opacity(glowOpacity * 0.3),
                                        Color.clear,
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: tileH * 0.6
                                )
                            )
                            .blur(radius: 20)
                            .allowsHitTesting(false)
                    }
                }
            )
            .overlay(
                ZStack {
                    selectedBorder(isSelected: isSelected, cornerRadius: 20)

                    // CHANGE: left-edge glow accent on selected tile
                    if isSelected && !isLight {
                        HStack {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            tileColor.opacity(0.7),
                                            Color.clear,
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 2)
                                .padding(.vertical, 12)
                            Spacer()
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .allowsHitTesting(false)
                    }
                }
            )
            .shadow(
                color: isSelected
                    ? (isLight
                        ? AppColors.lightShadowMagenta
                        : AppColors.purple.opacity(0.28))
                    : .clear,
                radius: 8
            )
            .shadow(
                color: isSelected
                    ? (isLight
                        ? AppColors.lightShadowPurple
                        : AppColors.cyan.opacity(0.18))
                    : .clear,
                radius: 16
            )
            .shadow(
                color: isSelected
                    ? AppColors.magenta.opacity(isLight ? 0.06 : 0.10)
                    : .clear,
                radius: 28
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : (somethingElse ? 0.965 : 1.0))
        .opacity(somethingElse ? 0.55 : 1.0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: data.explorationMode?.rawValue ?? "none"
        )
        .accessibilityLabel(headline)
        .accessibilityHint(isSelected ? "Selected" : "Double-tap to select \(headline)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - Bento Bar
    
    // COPYWRITING REVIEW: S5-E1
    // The "Safe Learning" label is aspirational but may not authentically represent
    // users who choose browsing to defer Solo/Couple selection (e.g., uncertain about
    // relationship status, not ready to answer honestly). Consider "Just Browsing" or
    // "Not Sure Yet" as alternatives. Update accessibilityLabel if changed.
    
    @ViewBuilder
    private func bentoBar(mode: ExplorationMode) -> some View {
        let isSelected    = data.explorationMode == mode
        let somethingElse = data.explorationMode != nil && !isSelected
        let filamentSize: CGFloat = 56

        let glowOpacity: Double = isSelected
            ? 0.18 + Double(browseBreath) * 0.08
            : 0.05 + Double(browseBreath) * 0.03

        Button {
            handleSelection(mode)
        } label: {
            HStack(spacing: 14) {
                // CHANGE: always active at idle speed
                TileOrbitView(
                    orbitCount: 3,
                    isActive:   true,
                    speed:      isSelected ? 1.0 : 0.22,
                    size:       filamentSize
                )
                .frame(width: filamentSize, height: filamentSize)
                // CHANGE: always visible, dims when not selected
                .opacity(isSelected ? 1.0 : 0.30)
                .animation(.easeInOut(duration: 0.4), value: isSelected)

                VStack(alignment: .leading, spacing: 3) {
                    Text("Safe Learning")
                        .font(AppFonts.display(17, weight: .semibold))
                        .foregroundStyle(isLight
                            ? AppColors.lightTextPrimary
                            : AppColors.textPrimary)
                    Text("Just looking around for now.")
                        .font(AppFonts.caption)
                        .foregroundStyle(isLight
                            ? AppColors.lightTextSecondary
                            : AppColors.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 72)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isLight
                            ? (isSelected ? AppColors.lightFrostCard : AppColors.lightFrostPill)
                            : AppColors.cardBg)

                    // CHANGE: breathing gold atmosphere on browsing bar
                    if !isLight {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppColors.gold.opacity(glowOpacity),
                                        AppColors.gold.opacity(glowOpacity * 0.25),
                                        Color.clear,
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 80
                                )
                            )
                            .blur(radius: 16)
                            .allowsHitTesting(false)
                    }
                }
            )
            .overlay(selectedBorder(isSelected: isSelected, cornerRadius: 20))
            .shadow(
                color: isSelected
                    ? AppColors.gold.opacity(isLight ? 0.20 : 0.28)
                    : .clear,
                radius: 8
            )
            .shadow(
                color: isSelected
                    ? AppColors.gold.opacity(isLight ? 0.12 : 0.18)
                    : .clear,
                radius: 16
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : (somethingElse ? 0.97 : 1.0))
        .opacity(somethingElse ? 0.55 : 1.0)
        .animation(
            .spring(response: 0.35, dampingFraction: 0.7),
            value: data.explorationMode?.rawValue ?? "none"
        )
        .accessibilityLabel("Safe Learning")
        .accessibilityHint(isSelected ? "Selected" : "Double-tap to select Safe Learning")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Previews

#Preview("Dark — no selection") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Solo selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .solo
        d.nmStage         = .curious
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Couple selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .couple
        d.nmStage         = .exploring
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Dark — Browsing selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .browsing
        d.nmStage         = .curious
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — no selection") {
    @Previewable @State var data = OnboardingData()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Light — Couple selected") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.explorationMode = .couple
        d.nmStage         = .exploring
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config:      .modeSelect,
            sparkConfig: .modeSelectView,
            opacity:     1.0
        )
        .ignoresSafeArea()
        OnboardingModeSelectView(data: $data, onContinue: {}, onBack: {})
    }
    
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingContextView.swift` {#file-open-lightly-features-onboarding-views-onboardingcontextview-swift}

```swift
// Features/Onboarding/Views/OnboardingContextView.swift
//
// Screen 4: Relationship Context — branches on explorationMode
// Solo: 3 cards  |  Couple: 4 cards

import SwiftUI

struct OnboardingContextView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    @State private var headerVisible      = false
    @State private var cardsVisible       = false
    @State private var reassuranceVisible = false
    @State private var hasAnimated        = false

    @State private var selection: ContextOption? = nil
    @State private var autoAdvanceFired          = false

    // FIXED: Extracted from body to avoid preview type-checker timeout.
    // `let isLight` inside body was captured across 6+ nested result-builder
    // closure scopes (foregroundStyle ternaries + background Group if/else).
    private var isLight: Bool { colorScheme == .light } // FIXED: was `let isLight` in body

    // MARK: - Option Data

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
        // COPYWRITING REVIEW: S6-E1
        // .partneredHidden covers a wider range than "I haven't brought it up yet":
        // - Partner doesn't know about curiosity (pre-conversation)
        // - Partner is not supportive (conversation went badly)
        // - Complicated relationship status
        // Current title+subtitle narrow the card to pre-conversation users only.
        // Consider broader framing: "It's complicated" / "The conversation is... sensitive"
        // or keep current title but broaden subtitle: "I haven't figured out how to bring it up"
        ContextOption(
            id: "partnered_hidden", context: .partneredHidden, intensity: .blaze,
            title: "I haven't brought it up yet",
            subtitle: "Curious, but the conversation hasn't happened",
            detail: "That's exactly what this is for. We'll help you find the words."
        ),
    ]

    private let coupleOptions: [ContextOption] = [
        ContextOption(
            id: "not_talked", context: .notTalked, intensity: .ember,
            title: "Haven't really talked about it",
            subtitle: "One or both of us is curious",
            detail: "We'll start with the basics — language, comfort levels, and small openings."
        ),
        ContextOption(
            id: "talking", context: .talking, intensity: .flame,
            title: "We've been talking",
            subtitle: "No experience yet, but we're on the same page",
            detail: "Great foundation. We'll build on your shared curiosity with structured prompts."
        ),
        ContextOption(
            id: "some_experience", context: .someExperience, intensity: .inferno,
            title: "We've tried some things",
            subtitle: "Real experiences — good, bad, or somewhere in between",
            detail: "We'll help you process what happened and decide what comes next."
        ),
        ContextOption(
            id: "needs_reset", context: .needsReset, intensity: .nova,
            title: "We need a reset",
            subtitle: "Something's off and we want to find our footing again",
            detail: "We'll focus on repair, reconnection, and rebuilding trust first."
        ),
    ]

    private var options: [ContextOption] {
        data.explorationMode == .couple ? coupleOptions : soloOptions
    }

    private var restoredCardIndex: Int {
        guard let context = data.relationshipContext else {
            return 0
        }
        return options.firstIndex(where: {
            $0.context == context
        }) ?? 0
    }

    private var headlineText: String {
        let name = data.displayName.trimmingCharacters(in: .whitespaces)
        let hasName = !name.isEmpty
        if data.explorationMode == .couple {
            return hasName
                ? "\(name), you're exploring this together."
                : "You're exploring this together."
        } else {
            return hasName
                ? "\(name), you're exploring on your own."
                : "You're exploring on your own."
        }
    }

    private var subheadText: String {
        // NOTE: The solo subhead intentionally ends with an em dash.
        // The card stack below completes the implied sentence — each
        // card title is the answer to "one thing that helps us
        // personalize." This is a deliberate stylistic choice.
        // Change only after user testing confirms it reads as an error
        // rather than an intentional grammatical pause.
        data.explorationMode == .couple
            ? "Where are you two at?"
            : "One thing that helps us personalize —"
    }

    // COPYWRITING REVIEW: S6-E2
    // Couple reassurance text "Every starting point is valid" is generic encouragement
    // that doesn't acknowledge the emotional weight of selected cards, particularly
    // high-shame contexts like "We need a reset" (.inferno/.nova intensity).
    // Solo text "No judgment on any answer" is well-targeted to shame reduction.
    // Consider dynamic reassurance based on selected card intensity:
    // - .ember/.flame: "Every starting point is valid."
    // - .inferno/.nova: "Naming this is the first step."
    // Or single copy covering all: "We've seen every starting point lead somewhere good."
    private var reassuranceText: String {
        data.explorationMode == .couple
            ? "Every starting point is valid."
            : "No judgment on any answer."
    }

    // FIXED: Extracted from body — inline AnyShapeStyle ternary with LinearGradient
    // inside .foregroundStyle() exceeded the preview type-checker's inference budget.
    private var reassuranceGradientStyle: AnyShapeStyle { // FIXED: extracted from body
        if isLight {
            // RULE B — magenta→gold for all display gradient text in light
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: AppColors.magenta,   location: 0.00),
                    .init(color: AppColors.orangeHot, location: 0.55),
                    .init(color: AppColors.gold,      location: 1.00),
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            // Dark path — byte-for-byte unchanged
            return AnyShapeStyle(LinearGradient(
                colors: [AppColors.cyan, AppColors.purple],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }

    private var headlineStyle: AnyShapeStyle { // FIXED: extracted from body
        isLight
            ? AnyShapeStyle(AppColors.lightCardTitle)
            : AnyShapeStyle(AppColors.textPrimary)
    }

    private var subheadStyle: AnyShapeStyle { // FIXED: extracted from body
        isLight
            ? AnyShapeStyle(AppColors.lightCardTitle.opacity(0.65))
            : AnyShapeStyle(AppColors.textSecondary)
    }

    private var pronounLabelStyle: AnyShapeStyle { // FIXED: extracted from body
        isLight
            ? AnyShapeStyle(AppColors.lightTextTertiary)
            : AnyShapeStyle(AppColors.textTertiary)
    }

    // MARK: - Accessibility

    // Provides a spoken summary of the current front card
    // for VoiceOver users who cannot see the visual stack.
    private var accessibilityStackLabel: String {
        guard let current = selection ?? options.first else {
            return "Relationship context selection. \(options.count) options available."
        }
        return "\(current.title). \(current.subtitle). \(current.detail)"
    }

    // Allows VoiceOver swipe-up / swipe-down to navigate the
    // card stack without requiring drag gestures.
    // Note: direction parameter type is inferred — AccessibilityAdjustableAction
    // is not available as a standalone named type in SwiftUI.

    // MARK: - Extracted Decoration Layers
    //
    // FIXED: Extracted from body modifier chain to reduce result-builder
    // expression depth, same pattern as OnboardingGroundRulesView.

    // LAYOUT-FIX: converted from var to func(size:) so the atmosphere ellipse
    // can receive proportional dimensions from the GeometryReader in body.
    private func backgroundLayer(size: CGSize) -> some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            // Dark mode screen-specific accent — kept, not atmosphere
            if !isLight {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.3),
                            AppColors.deepBlue.opacity(0.15),
                            Color.clear
                        ],
                        center: .top,
                        startRadius: 30,
                        endRadius: 360
                    ))
                    .frame(width: OL.atmosW(size.width), height: OL.atmosH(size.height)) // LAYOUT-FIX: was 600×500
                    .offset(y: -size.height * 0.09)                                       // LAYOUT-FIX: was -80
                    .blur(radius: 80)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in // LAYOUT-FIX: single GeometryReader for proportional spacing
        let h = geo.size.height
        VStack(spacing: 0) {

            OnboardingNavBar(currentStep: 3, totalSteps: 6, onBack: onBack)
                .padding(.top, OL.navTop(h))        // LAYOUT-FIX: was 12 hardcoded
                .padding(.bottom, OL.navBottom(h))  // LAYOUT-FIX: was 20 hardcoded
                .padding(.horizontal, 24)
                .opacity(headerVisible ? 1 : 0)
                .offset(y: headerVisible ? 0 : -8)

            VStack(alignment: .leading, spacing: OL.compact(h)) { // LAYOUT-FIX: was 8 hardcoded
                Text(headlineText)
                    .font(AppFonts.heroTitle)
                    .foregroundStyle(headlineStyle)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subheadText)
                    .font(AppFonts.caption)
                    .foregroundStyle(subheadStyle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .opacity(headerVisible ? 1 : 0)
            .offset(y: headerVisible ? 0 : 12)

            Spacer(minLength: OL.spacerMin(h)) // LAYOUT-FIX: unbounded above, min prevents crowding on SE

            ContextCardStack(
                selection: $selection,
                options: options,
                onAdvance: handleAdvance,
                initialIndex: restoredCardIndex
            )
            .opacity(cardsVisible ? 1 : 0)
            .offset(y: cardsVisible ? 0 : 16)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityStackLabel)
            .accessibilityHint("Swipe left or right to browse options. Double-tap to select the current card.")
            .accessibilityValue(selection?.title ?? "No selection")
            .accessibilityAdjustableAction { direction in
                let currentIndex = options.firstIndex(where: {
                    $0.id == (selection ?? options.first)?.id
                }) ?? 0
                let newIndex: Int
                switch direction {
                case .increment:
                    newIndex = min(currentIndex + 1, options.count - 1)
                case .decrement:
                    newIndex = max(currentIndex - 1, 0)
                @unknown default:
                    return
                }
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                    selection = options[newIndex]
                }
            }
            .accessibilityAction(named: "Select") {
                handleAdvance()
            }

            Spacer(minLength: OL.spacerMin(h)) // LAYOUT-FIX: unbounded above, min prevents crowding on SE

            Text(reassuranceText)
                .font(AppFonts.caption)
                .foregroundStyle(reassuranceGradientStyle) // FIXED: uses pre-resolved property
                .frame(maxWidth: .infinity, alignment: .center)
                .opacity(reassuranceVisible ? 1 : 0)
                .offset(y: reassuranceVisible ? 0 : 8)
                .accessibilityAddTraits(.isStaticText)
                .accessibilityLabel(reassuranceText)

            OnboardingFooter(text: "Your data is encrypted and always stays yours.")
                .padding(.horizontal, 24)
                .accessibilityHidden(true)
        }
        .background { backgroundLayer(size: geo.size) } // LAYOUT-FIX: passes live size for proportional atmosphere
        // RULE D — .preferredColorScheme(.dark) removed;
        // screen now responds to system appearance.
        // BrandView and BuildingPathView remain permanently dark.
        .onAppear {
            #if DEBUG
            // Log only — do not assert in onAppear. assert() in a SwiftUI
            // lifecycle modifier causes EXC_BREAKPOINT, crashing the entire
            // preview process (not just this preview).
            if data.explorationMode != .solo && data.explorationMode != .couple {
                print("[OnboardingContextView] ⚠️ unexpected explorationMode: " +
                      "\(String(describing: data.explorationMode))")
            }
            #endif
            restoreSelectionIfNeeded()
            guard !hasAnimated else { return }
            hasAnimated = true
            runEntranceAnimations()
        }
        .onDisappear {
            // Reset so back navigation can re-advance
            autoAdvanceFired = false
        }
        } // LAYOUT-FIX: end GeometryReader
    }

    // MARK: - Actions

    private func handleAdvance() {
        guard !autoAdvanceFired else { return }
        guard let confirmedContext = selection?.context else {
            // selection is nil — ContextCardStack fired onAdvance
            // before a card was confirmed. Do not advance.
            // This should never happen in production.
            #if DEBUG
            print("[OnboardingContextView] ⚠️ handleAdvance() called with nil selection")
            #endif
            return
        }
        autoAdvanceFired = true
        data.relationshipContext = confirmedContext
        #if DEBUG
        assert(onContinue != nil,
            "OnboardingContextView: onContinue not injected — " +
            "wire this callback from the coordinator.")
        #endif
        onContinue?()
    }

    // MARK: - State Restoration

    private func restoreSelectionIfNeeded() {
        // Restore confirmed selection from the binding on back navigation.
        // Only restores if data has a committed value — safe on first appear
        // (data.relationshipContext will be nil, no-op).
        guard let context = data.relationshipContext else { return }
        if selection?.context != context {
            selection = options.first(where: { $0.context == context })
        }
    }

    // MARK: - Animations

    private func runEntranceAnimations() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            headerVisible      = true
            cardsVisible       = true
            reassuranceVisible = true
            return
        }
        #endif
        withAnimation(.easeOut(duration: 0.5).delay(0.15)) { headerVisible      = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.30)) { cardsVisible       = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.55)) { reassuranceVisible = true }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .couple
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .contextSelect,
            sparkConfig: .contextView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingContextView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .contextSelect,
            sparkConfig: .contextView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingContextView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

// MARK: - Changes applied
// ISSUE 1:  ContextCardStack — added .accessibilityElement,
//           .accessibilityLabel (accessibilityStackLabel computed
//           property), .accessibilityHint, .accessibilityValue,
//           .accessibilityAdjustableAction (accessibilityNavigate),
//           and .accessibilityAction("Select"); VoiceOver users
//           can now navigate and confirm cards without gestures
// ISSUE 2:  Added @State hasAnimated guard; added
//           restoreSelectionIfNeeded() call before guard in
//           onAppear; prevents re-animation on back navigation
// ISSUE 3:  Added restoreSelectionIfNeeded() — restores selection
//           from data.relationshipContext on every appear;
//           card stack shows confirmed state on back navigation
// ISSUE 4:  handleAdvance() — added guard let confirmedContext
//           defensive nil check with assertionFailure for
//           ContextCardStack contract violation
// ISSUE 5:  Added #if DEBUG assert in onAppear verifying
//           explorationMode is .solo or .couple; guards against
//           browsing users being routed here incorrectly
// ISSUE 6:  headlineText — updated to prepend data.displayName
//           when non-empty; falls back to original copy when
//           displayName is empty; first use of name in the flow
// ISSUE 7:  handleAdvance() — added #if DEBUG assert for missing
//           onContinue callback, mirroring Screens 1–3 pattern
// ISSUE 8:  Reassurance Text — added .accessibilityAddTraits +
//           .accessibilityLabel; OnboardingFooter marked
//           .accessibilityHidden(true) to reduce VoiceOver noise
// ISSUE 9:  Added explanatory comment on subheadText documenting
//           the intentional em dash; copy unchanged
// ISSUE 10: Added two new #Preview variants: "Solo — with name"
//           and "Couple — with name" to verify ISSUE 6 behavior
// ISSUE 11: Light mode pass — removed .preferredColorScheme(.dark);
//           added @Environment(\.colorScheme); branched background
//           to lightPageBg + AuroraGlowField + SparkField(.contextView)
//           in light; headlineText → lightTextPrimary in light;
//           subheadText → lightTextSecondary in light; reassurance
//           gradient → magenta→gold in light (dark path unchanged);
//           added 4 light preview variants alongside existing 4 dark
// ISSUE 12: Preview fix — extracted `let isLight` from body to
//           `private var isLight: Bool`; extracted background ZStack
//           to `backgroundLayer` property; extracted reassurance
//           gradient to `reassuranceGradientStyle` property.
//           Root cause: 6+ closure captures of `let isLight` inside
//           @ViewBuilder body exceeded preview type-checker budget.
// ISSUE 13: Revert NavArrow integration in OnboardingContextView:
//           restore top bar onBack, remove NavArrow block from bottom
// ISSUE 14: Added headlineStyle, subheadStyle, and pronounLabelStyle
//           as extracted computed properties below reassuranceGradientStyle

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingCuriosityPickerView.swift` {#file-open-lightly-features-onboarding-views-onboardingcuriositypickerview-swift}

```swift
//
//  OnboardingCuriosityPickerView.swift
//  Open Lightly
//

import SwiftUI

private enum ClusterPhase: Equatable {
    case set1Active
    case set2Active
    case exiting
}

// Scatter slots — 2-column organic layout with hand-tuned positions
private struct ScatterSlot {
    let xFrac:    CGFloat
    let yPt:      CGFloat
    let baseRot:  Double
    let scale:    CGFloat
}

private let set1Slots: [ScatterSlot] = [
    ScatterSlot(xFrac: 0.05,  yPt:  70,  baseRot: -1.2, scale: 1.00),
    ScatterSlot(xFrac: 0.52,  yPt:  55,  baseRot:  0.8, scale: 0.97),
    ScatterSlot(xFrac: 0.05,  yPt: 230,  baseRot:  0.5, scale: 1.02),
    ScatterSlot(xFrac: 0.52,  yPt: 215,  baseRot: -0.7, scale: 0.98),
    ScatterSlot(xFrac: 0.28,  yPt: 375,  baseRot: -0.8, scale: 1.00),
]

private let set2Slots: [ScatterSlot] = [
    ScatterSlot(xFrac: 0.05,  yPt:  65,  baseRot:  1.1, scale: 0.98),
    ScatterSlot(xFrac: 0.52,  yPt:  48,  baseRot: -0.9, scale: 1.01),
    ScatterSlot(xFrac: 0.05,  yPt: 230,  baseRot: -0.6, scale: 1.00),
    ScatterSlot(xFrac: 0.52,  yPt: 218,  baseRot:  1.3, scale: 0.97),
    ScatterSlot(xFrac: 0.28,  yPt: 385,  baseRot:  0.6, scale: 1.00),
]

struct OnboardingCuriosityPickerView: View {
    @Binding var data: OnboardingData
    var onContinue: (() -> Void)?
    var onBack:     (() -> Void)?

    // MARK: - Selection
    @State private var selectedSet1: Set<String> = []
    @State private var selectedSet2: Set<String> = []
    @State private var clusterPhase: ClusterPhase = .set1Active
    @State private var hasAdvanced: Bool = false

    // MARK: - Scroll
    @State private var scrollOffset: CGFloat = 0
    @State private var seam:         CGFloat = 0

    // MARK: - UI
    @State private var headerVisible:    Bool    = false
    @State private var cardsVisible:     Bool    = false
    @State private var navHeaderHeight:  CGFloat = 230
    @State private var headerMeasured:   Bool    = false

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var isLight: Bool { colorScheme == .light }

    // MARK: - Atmosphere progress 0→1 as user scrolls set1→set2
    private var atmosphereProgress: CGFloat {
        guard seam > 0 else { return 0 }
        return max(0, min(1, scrollOffset / seam))
    }

    private var atmosphereCyanOpacity:    Double { Double(1 - atmosphereProgress) * (isLight ? 0.10 : 0.20) }
    private var atmosphereMagentaOpacity: Double { Double(atmosphereProgress)     * (isLight ? 0.10 : 0.20) }

    // MARK: - Flash intensity — bell curve peaking at crossfade midpoint
    // Essentially zero by progress=0.25 and progress=0.75
    private var flashIntensity: CGFloat {
        guard seam > 0 else { return 0 }
        let p = atmosphereProgress
        return exp(-18 * pow(p - 0.5, 2))
    }

    // MARK: - Responsive font sizes
    private var headerTitleSize: CGFloat {
        UIScreen.main.bounds.width <= 375 ? 18 : 22
    }

    private var headerSubtitleSize: CGFloat {
        UIScreen.main.bounds.width <= 375 ? 12 : 14
    }

    // MARK: - Helpers
    private var hasSelection: Bool  { !selectedSet1.isEmpty && !selectedSet2.isEmpty }
    private var totalSelected: Int  { selectedSet1.count + selectedSet2.count }
    private var config: CuriosityScreenConfig { data.curiosityScreenConfig }

    // MARK: - LivingText gradient stops — single source of truth
    private var livingGradientColors: [Color] {
        isLight
            ? [AppColors.magenta, AppColors.orangeHot, AppColors.gold]
            : [AppColors.cyan, AppColors.purpleVivid, AppColors.magenta]
    }

    // MARK: - Device-adaptive scaling
    private func scaledSlots(_ slots: [ScatterSlot], screenW: CGFloat) -> [ScatterSlot] {
        // Only scale DOWN for small screens — large screens don't need bigger gaps
        let yScale = min(max(screenW / 390, 0.85), 1.0)
        return slots.map { slot in
            ScatterSlot(
                xFrac:   slot.xFrac,
                yPt:     slot.yPt * yScale,
                baseRot: slot.baseRot,
                scale:   slot.scale
            )
        }
    }

    // MARK: - Card specs
    private enum CardSet { case set1, set2 }

    private struct CardSpec: Identifiable {
        let id:         String
        let lead:       String
        let full:       String
        let slot:       ScatterSlot
        let floatPhase: Double
        let set:        CardSet
    }

    private func cardSpecs(screenH: CGFloat, screenW: CGFloat) -> [CardSpec] {
        let s1slots = scaledSlots(set1Slots, screenW: screenW)
        let s2slots = scaledSlots(set2Slots, screenW: screenW)
        let s1 = Array(config.section1Options.prefix(5))
        let s2 = Array(config.section2Options.prefix(5))
        var out: [CardSpec] = []
        for (i, opt) in s1.enumerated() {
            out.append(CardSpec(
                id:         opt.id,
                lead:       CuriosityScreenConfig.leadPhrase(for: opt.id),
                full:       opt.label,
                slot:       s1slots[i % s1slots.count],
                floatPhase: Double(i) * 0.8,
                set:        .set1
            ))
        }
        for (i, opt) in s2.enumerated() {
            out.append(CardSpec(
                id:         opt.id + "_set2",
                lead:       CuriosityScreenConfig.leadPhrase(for: opt.id),
                full:       opt.label,
                slot:       s2slots[i % s2slots.count],
                floatPhase: Double(i) * 0.8 + 0.4,
                set:        .set2
            ))
        }
        return out
    }

    private func isSelected(_ spec: CardSpec) -> Bool {
        switch spec.set {
        case .set1: return selectedSet1.contains(spec.id)
        case .set2:
            let raw = spec.id.hasSuffix("_set2")
                ? String(spec.id.dropLast(5))
                : spec.id
            return selectedSet2.contains(raw)
        }
    }

    // MARK: - Selection Logic
    private let maxPerSection = 3

    private func toggle(_ spec: CardSpec) {
        guard clusterPhase != .exiting else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch spec.set {
        case .set1:
            if selectedSet1.contains(spec.id) {
                selectedSet1.remove(spec.id)
            } else if selectedSet1.count < maxPerSection {
                selectedSet1.insert(spec.id)
            } else {
                // Max reached — provide haptic warning, no change
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.warning)
            }
        case .set2:
            let raw = spec.id.hasSuffix("_set2")
                ? String(spec.id.dropLast(5))
                : spec.id
            if selectedSet2.contains(raw) {
                selectedSet2.remove(raw)
            } else if selectedSet2.count < maxPerSection {
                selectedSet2.insert(raw)
            } else {
                // Max reached — provide haptic warning, no change
                UINotificationFeedbackGenerator()
                    .notificationOccurred(.warning)
            }
        }
    }

    // MARK: - Float
    // More amplitude (3→5pt Y, 0.2→0.35 rot)
    // Each card gets its own tick multiplier offset — never in sync
    private func floatY(_ spec: CardSpec, tick: Double) -> CGFloat {
        guard !reduceMotion else { return 0 }
        let speedVariance = 0.009 + (spec.floatPhase.truncatingRemainder(dividingBy: 3)) * 0.002
        return CGFloat(sin(spec.floatPhase + tick * speedVariance) * 5)
    }

    private func floatRot(_ spec: CardSpec, tick: Double) -> Double {
        guard !reduceMotion else { return 0 }
        let speedVariance = 0.006 + (spec.floatPhase.truncatingRemainder(dividingBy: 2)) * 0.002
        return sin(spec.floatPhase + tick * speedVariance) * 0.35
    }

    private func gravity(_ spec: CardSpec) -> CGSize {
        guard isSelected(spec) else { return .zero }
        return CGSize(width: spec.slot.xFrac > 0.4 ? 10 : -10, height: 0)
    }

    // MARK: - Card width
    private func cardW(for spec: CardSpec, canvasW: CGFloat) -> CGFloat {
        canvasW * 0.44 * spec.slot.scale
    }

    // MARK: - Tint / border
    private func cardTint(_ spec: CardSpec) -> Color {
        switch spec.set {
        case .set1: return AppColors.cyan.opacity(isLight ? 0.04 : 0.05)
        case .set2: return AppColors.magenta.opacity(isLight ? 0.04 : 0.05)
        }
    }
    private func cardBorder(_ spec: CardSpec) -> Color {
        guard !isSelected(spec) else { return .clear }
        switch spec.set {
        case .set1: return AppColors.cyan.opacity(isLight ? 0.18 : 0.14)
        case .set2: return AppColors.magenta.opacity(isLight ? 0.18 : 0.14)
        }
    }

    // MARK: - Data / continue
    private func commitData() {
        data.communicationGoals = config.section1Options
            .filter { selectedSet1.contains($0.id) }.map(\.id).sorted()
        data.learningGoals = config.section2Options
            .filter { selectedSet2.contains($0.id) }.map(\.id).sorted()
        data.curiositySelections = data.communicationGoals + data.learningGoals
    }

    private func handleContinue() {
        guard !hasAdvanced else { return }
        hasAdvanced = true
        commitData()
        withAnimation(.easeInOut(duration: 0.3)) { clusterPhase = .exiting }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { onContinue?() }
    }

    // MARK: - Dimensions
    private func sectionHeight(screenW: CGFloat) -> CGFloat {
        let scale = min(max(screenW / 390, 0.85), 1.0)
        return (385 + 90 + 95) * scale  // lastYPt + cardH + buffer for seam/margin
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            let h   = geo.size.height
            let w   = geo.size.width
            let top = geo.safeAreaInsets.top
            let bot = geo.safeAreaInsets.bottom

            ZStack(alignment: .top) {

                // ── Atmosphere ────────────────────────────────────────
                ZStack {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [AppColors.cyan.opacity(atmosphereCyanOpacity), .clear],
                            center: .center, startRadius: 0, endRadius: 300
                        ))
                        .frame(width: w * 1.3, height: h * 0.55)
                        .position(x: w * 0.5, y: h * 0.25)
                        .blur(radius: 70)
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [AppColors.magenta.opacity(atmosphereMagentaOpacity), .clear],
                            center: .center, startRadius: 0, endRadius: 300
                        ))
                        .frame(width: w * 1.3, height: h * 0.55)
                        .position(x: w * 0.5, y: h * 0.78)
                        .blur(radius: 70)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)

                // ── Scroll canvas ─────────────────────────────────────
                infiniteCanvas(w: w, h: h, top: top)
                    .frame(width: w, height: h)
                    .ignoresSafeArea()

                // ── Fixed nav + header ────────────────────────────────
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        OnboardingNavBar(
                            currentStep: 4,
                            totalSteps:  6,
                            onBack:      onBack
                        )
                        .padding(.horizontal, 24)
                        .padding(.top, top + 8)
                        .padding(.bottom, OL.navBottom(h))

                        headerBlock
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)
                            .opacity(headerVisible ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.1), value: headerVisible)
                    }
                    .background(
                        GeometryReader { navGeo in
                            Color.clear.onAppear {
                                guard !headerMeasured else { return }
                                headerMeasured  = true
                                navHeaderHeight = navGeo.size.height + 20
                            }
                        }
                    )

                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)

                // ── Selection count pill — top right, below nav ───────────
                VStack {
                    HStack {
                        Spacer()
                        selectionPill
                            .padding(.top, top + 14)
                            .padding(.trailing, 24)
                    }
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)
                .zIndex(20)

                // ── Fixed CTA ─────────────────────────────────────────
                VStack(spacing: 0) {
                    Spacer()
                    bottomZone
                        .padding(.horizontal, 24)
                        .padding(.bottom, bot + 8)
                        .background(
                            LinearGradient(
                                colors: [
                                    (isLight ? AppColors.lightPageBg : AppColors.pageBg).opacity(0),
                                    (isLight ? AppColors.lightPageBg : AppColors.pageBg).opacity(0.96),
                                ],
                                startPoint: .top,
                                endPoint:   .bottom
                            )
                            .ignoresSafeArea()
                        )
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.4).delay(0.15)) { headerVisible = true }
                withAnimation(.easeOut(duration: 0.4).delay(0.30)) { cardsVisible  = true }
            }
            .onDisappear {
                // Preserve partial selections so back navigation
                // restores the user's progress.
                if !selectedSet1.isEmpty || !selectedSet2.isEmpty {
                    commitData()
                }
                hasAdvanced = false
            }
        }
    }

    // MARK: - Infinite canvas

    @ViewBuilder
    private func infiniteCanvas(w: CGFloat, h: CGFloat, top: CGFloat) -> some View {
        let secH     = sectionHeight(screenW: w)
        let seamGap: CGFloat = -90  // was 60
        let topPad:  CGFloat = navHeaderHeight
        let totalH   = topPad + secH + seamGap + secH + 10

        ScrollView(.vertical, showsIndicators: false) {
            ZStack(alignment: .topLeading) {

                // ── Scroll tracker ────────────────────────────────────
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            Task { @MainActor in
                                // Seam position: scroll distance to the visual boundary between Set 1 and Set 2
                                // Calculated as the end of Set 1 panel plus half of seamGap to center at the visual seam
                                if seam == 0 { seam = secH + CGFloat(seamGap) / 2 }
                            }
                        }
                        .onChange(of: proxy.frame(in: .named("scroll")).minY) { _, currentY in
                            scrollOffset = max(0, -currentY)
                            // Keep clusterPhase in sync for card hit-testing
                            let inSet2 = scrollOffset >= seam
                            let target: ClusterPhase = inSet2 ? .set2Active : .set1Active
                            if clusterPhase != target && clusterPhase != .exiting {
                                clusterPhase = target
                            }
                        }
                }
                .frame(width: w, height: 0)

                // ── Animated cards ────────────────────────────────────
                TimelineView(.animation(minimumInterval: 1/30,
                                        paused: clusterPhase == .exiting || reduceMotion)) { tl in
                    let tick = tl.date.timeIntervalSinceReferenceDate * 60

                    ZStack(alignment: .topLeading) {
                        Color.clear.frame(width: w, height: totalH)

                        // Set 1
                        ForEach(cardSpecs(screenH: h, screenW: w).filter { $0.set == .set1 }) { spec in
                            let cw = cardW(for: spec, canvasW: w)
                            let cx = spec.slot.xFrac * w + cw / 2
                            let cy = topPad + spec.slot.yPt
                            cardView(spec: spec, tick: tick, cw: cw)
                                .position(x: cx, y: cy)
                        }

                        // Set 2
                        let set2Origin = topPad + secH + seamGap
                        ForEach(cardSpecs(screenH: h, screenW: w).filter { $0.set == .set2 }) { spec in
                            let cw = cardW(for: spec, canvasW: w)
                            let cx = spec.slot.xFrac * w + cw / 2
                            let cy = set2Origin + spec.slot.yPt
                            cardView(spec: spec, tick: tick, cw: cw)
                                .position(x: cx, y: cy)
                        }
                    }
                    .frame(width: w, height: totalH)
                }
            }
        }
        .coordinateSpace(name: "scroll")
        .frame(width: w, height: h)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.00),
                    .init(color: .black, location: 0.15),
                    .init(color: .black, location: 1.00),
                ],
                startPoint: .top,
                endPoint:   .bottom
            )
        )
        .opacity(cardsVisible ? 1 : 0)
    }

    // MARK: - Individual card

    @ViewBuilder
    private func cardView(spec: CardSpec, tick: Double, cw: CGFloat) -> some View {
        let selected = isSelected(spec)
        let opacity: Double = clusterPhase == .exiting ? 0 : 1

        ZStack {
            FloatingCard(
                spec: FloatingCardSpec(
                    id:         spec.id,
                    lead:       spec.lead,
                    full:       spec.full,
                    xFrac:      Double(spec.slot.xFrac),
                    yFrac:      Double(spec.slot.yPt),
                    floatPhase: spec.floatPhase
                ),
                isSelected:    selected,
                floatY:        floatY(spec, tick: tick),
                floatRot:      floatRot(spec, tick: tick),
                gravity:       gravity(spec),
                tick:          tick,
                targetOpacity: opacity,
                cardWidth:     cw,
                tintColor:     cardTint(spec),
                onTap:         { toggle(spec) }
            )

            // ...existing code...
        }
        .allowsHitTesting(opacity > 0.3)
        .animation(.easeInOut(duration: 0.35), value: clusterPhase)
    }

    // MARK: - Fixed header

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack(alignment: .topLeading) {

                // Flash bloom — uses LivingText palette, direction-aware
                // cyan-weighted entering, magenta-weighted exiting
                LinearGradient(
                    colors: [
                        AppColors.cyan.opacity(flashIntensity * (1 - atmosphereProgress) * 0.25),
                        AppColors.purpleVivid.opacity(flashIntensity * 0.25),
                        AppColors.magenta.opacity(flashIntensity * atmosphereProgress * 0.25),
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
                .blur(radius: 10 + flashIntensity * 14)
                .frame(height: 50)
                .padding(.horizontal, -16)
                .padding(.vertical, -12)
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 0) {

                    // Title crossfade with living gradient flash
                    ZStack(alignment: .topLeading) {
                        liveLabelTitle(
                            config.section1Label,
                            opacity: 1 - atmosphereProgress,
                            flash:   flashIntensity * (1 - atmosphereProgress)
                        )
                        liveLabelTitle(
                            config.section2Label,
                            opacity: atmosphereProgress,
                            flash:   flashIntensity * atmosphereProgress
                        )
                    }
                    .frame(height: 32)
                    .scaleEffect(1 + flashIntensity * 0.012, anchor: .leading)
                    .clipped()

                    // Subtitle crossfade — plain opacity, no gradient needed
                    ZStack(alignment: .topLeading) {
                        liveLabelSubtitle(config.section1Sublabel,
                                          opacity: 1 - atmosphereProgress)
                        liveLabelSubtitle(config.section2Sublabel,
                                          opacity: atmosphereProgress)
                    }
                    .frame(height: 22)
                    .padding(.top, 5)
                    .clipped()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Title label

    @ViewBuilder
    private func liveLabelTitle(_ text: String,
                                opacity: CGFloat,
                                flash: CGFloat) -> some View {
        ZStack {
            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(isLight
                    ? AppColors.lightTextPrimary
                    : AppColors.textPrimary)
                .opacity(1 - flash)

            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    colors: livingGradientColors,
                    startPoint: .leading,
                    endPoint:   .trailing
                ))
                .blur(radius: flash * 5)
                .opacity(flash * 0.40)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    colors: livingGradientColors,
                    startPoint: .leading,
                    endPoint:   .trailing
                ))
                .blur(radius: flash * 2)
                .opacity(flash * 0.80)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Text(text)
                .font(AppFonts.display(headerTitleSize, weight: .semibold))
                .foregroundStyle(LinearGradient(
                    colors: livingGradientColors,
                    startPoint: .leading,
                    endPoint:   .trailing
                ))
                .opacity(flash)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
        .modifier(GlowUnderline(isLight: isLight, flash: flash))
        .opacity(opacity)
    }

    // MARK: - Subtitle label

    @ViewBuilder
    private func liveLabelSubtitle(_ text: String, opacity: CGFloat) -> some View {
        Text(text)
            .font(AppFonts.body(headerSubtitleSize, weight: .regular))
            .foregroundStyle(isLight
                ? AppColors.lightTextSecondary
                : AppColors.textSecondary)
            .opacity(opacity)
    }

    // MARK: - Selection count pill
    private var selectionPill: some View {
        HStack(spacing: 6) {
            Text("\(totalSelected)")
                .font(AppFonts.body(16, weight: .semibold))
                .foregroundStyle(isLight ? AppColors.wineDark : Color.white)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: totalSelected)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isLight ? AppColors.lightFrostPill : AppColors.surfaceBg)
        .overlay {
            if isLight {
                LightModeShimmer(duration: 4.0, usePillColors: true)
                    .opacity(0.72)
                    .allowsHitTesting(false)
            } else {
                HolographicShimmer(duration: 4.0)
                    .opacity(0.72)
                    .allowsHitTesting(false)
            }
        }
        .clipShape(Capsule())
        .overlay {
            if isLight {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: livingGradientColors.map { $0.opacity(0.78) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.0
                    )
            } else {
                Capsule()
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1.5)
            }
        }
        .shadow(color: isLight
            ? AppColors.magenta.opacity(0.18)
            : AppColors.purple.opacity(0.25),
                radius: 12, x: 0, y: 4)
        .opacity(totalSelected > 0 ? 1 : 0)
        .scaleEffect(totalSelected > 0 ? 1 : 0.85, anchor: .topTrailing)
        .animation(.spring(response: 0.4, dampingFraction: 0.72), value: totalSelected > 0)
    }

    // MARK: - Bottom zone

    private var bottomZone: some View {
        VStack(spacing: 8) {
            CuriosityPanelNudge(
                s1Empty: selectedSet1.isEmpty,
                s2Empty: selectedSet2.isEmpty,
                isLight: isLight
            )

            HoloCTAButton(
                title:     "Continue",
                isEnabled: hasSelection,
                action:    { handleContinue() }
            )
            .animation(.easeInOut(duration: 0.4), value: hasSelection)

            OnboardingFooter()
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

// MARK: - Previews

#Preview("Dark — Solo") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.relationshipContext = .single
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker, sparkConfig: .curiosityPickerView, opacity: 1.0
        )
        .ignoresSafeArea().allowsHitTesting(false)
        OnboardingCuriosityPickerView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light — Solo") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.relationshipContext = .single
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker, sparkConfig: .curiosityPickerView, opacity: 1.0
        )
        .ignoresSafeArea().allowsHitTesting(false)
        OnboardingCuriosityPickerView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.light)
}

#Preview("Dark — Couple") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.relationshipContext = .notTalked
        d.explorationMode = .couple
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .curiosityPicker, sparkConfig: .curiosityPickerView, opacity: 1.0
        )
        .ignoresSafeArea().allowsHitTesting(false)
        OnboardingCuriosityPickerView(data: $data, onContinue: {}, onBack: {})
    }
    .preferredColorScheme(.dark)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingBuildingPathView.swift` {#file-open-lightly-features-onboarding-views-onboardingbuildingpathview-swift}

```swift
// Features/Onboarding/Views/OnboardingBuildingPathView.swift
//
// REVISION 3 — fixes persistent rightward layout offset.
//
// ROOT CAUSE (correct diagnosis):
//
// Revisions 1 and 2 correctly identified that .ignoresSafeArea() children
// were involved, but applied the wrong fix (.frame on the ZStack). The
// actual mechanism: when multiple children inside a ZStack use
// .ignoresSafeArea(), the ZStack computes its internal alignment origin
// from the UNION of all children's frames — including safe-area-extended
// frames. This shifts the alignment center rightward (and/or downward),
// dragging all content with it. .frame(width:height:) on the ZStack only
// constrains its external reported size; it does NOT override the internal
// alignment computation.
//
// FIX:
//
// All .ignoresSafeArea() layers (pageBg, atmosphere, OnboardingGlowField,
// fade overlay) are moved OUT of the ZStack into .background() and
// .overlay() modifiers. These modifiers render content behind/above the
// ZStack respectively but do NOT participate in the ZStack's alignment
// computation. The ZStack now contains ONLY non-ignoresSafeArea children
// (fragmentLayer, mainContent, skipAffordance, accessibility overlay),
// so its alignment origin is the true center of its frame.
//
// fragmentLayer()'s .ignoresSafeArea() is also removed — it was
// unnecessary since the parent ZStack already covers the full screen
// via the outer GeometryReader's .ignoresSafeArea().
//
// All BUG-1 through BUG-7 and R-BUG-1 through R-BUG-3 fixes from
// prior revisions are preserved where still applicable.

import SwiftUI

// MARK: - Supporting Types

private enum BPIndicatorState: Equatable {
case pending
case processing
case complete
}

private struct BPBuildItem {
let category: String
let resolved: String
}

private struct BPFragmentState {
var visible: Bool = false
var fading:  Bool = false
}

// MARK: - Main View

struct OnboardingBuildingPathView: View {
@Binding var data: OnboardingData
var onFinished: (() -> Void)? = nil



@Environment(\.colorScheme) private var colorScheme

@State private var screenW: CGFloat = 393
@State private var screenH: CGFloat = 852

@State private var hasAnimated = false
@State private var atmosphericVisible = false
@State private var glowPeak           = false
@State private var overlabelVisible   = false
@State private var nameVisible        = false
@State private var taglineVisible     = false

@State private var indicatorStates: [BPIndicatorState] = [
    .pending, .pending, .pending, .pending
]
@State private var fragmentStates: [BPFragmentState] = [
    BPFragmentState(), BPFragmentState(), BPFragmentState()
]

@State private var itemsFadingOut   = false
@State private var fadeOutVisible   = false
@State private var autoAdvanceFired = false
@State private var skipAvailable    = false
@State private var skipVisible      = false

private var reduceMotion: Bool {
    UIAccessibility.isReduceMotionEnabled
}

/// Physical top safe-area inset (Dynamic Island / notch / status bar)
/// read directly from the UIKit key window.
///
/// geo.safeAreaInsets.top returns 0 in this view because the outer
/// GeometryReader uses .ignoresSafeArea() — which zeroes the proxy's
/// inset values. The UIKit window always reports the true physical
/// insets regardless of SwiftUI's modifier chain.
private var deviceTopInset: CGFloat {
    guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive })
                as? UIWindowScene,
          let window = scene.windows.first(where: { $0.isKeyWindow })
    else { return 0 }
    return window.safeAreaInsets.top
}

// MARK: - Computed: Build Items

private var resolvedBuildItems: [BPBuildItem] {
    [        BPBuildItem(category: "Starting point",     resolved: stageLabel),        BPBuildItem(category: "Your situation",     resolved: contextLabel),        BPBuildItem(category: "First to explore",   resolved: goalsLabel),        BPBuildItem(category: "How you'll explore", resolved: modeLabel),    ]
}

private var stageLabel: String {
    switch data.nmStage {
    case .curious:     return "Beginning from curiosity"
    case .exploring:   return "Building on what you've tried"
    case .experienced: return "Starting from experience"
    default:           return "Your starting point"
    }
}

private var contextLabel: String {
    switch data.relationshipContext {
    case .partneredOpen:   return "Navigating openness together"
    case .partneredHidden: return "Finding words for the unspoken"
    case .notTalked:       return "Opening the conversation"
    case .talking:         return "Growing shared curiosity"
    case .single:          return "Your journey, your pace"
    case .someExperience:  return "Processing what's happened"
    case .needsReset:      return "Rebuilding from here"
    default:               return "Your situation"
    }
}

private var goalsLabel: String {
    let source = data.communicationGoals.first(where: { !$0.isEmpty })
        ?? data.learningGoals.first(where: { !$0.isEmpty })
    guard let s = source else { return "What you want to explore" }
    let phrase = CuriosityScreenConfig.leadPhrase(for: s)
    return phrase.count > 32 ? String(phrase.prefix(32)) + "…" : phrase
}

private var modeLabel: String {
    switch data.explorationMode {
    case .solo:   return "At your own pace"
    case .couple: return "Together, step by step"
    default:      return "Your conversation style"
    }
}

// MARK: - Computed: Fragments

private var stageFragment: String {
    switch data.nmStage {
    case .curious:     return "Starting fresh"
    case .exploring:   return "Building on what you know"
    case .experienced: return "Going deeper"
    default:           return "Starting fresh"
    }
}

private var contextFragment: String? {
    switch data.relationshipContext {
    case .single:          return "Your journey"
    case .partneredOpen:   return "With transparency"
    case .partneredHidden: return "Finding the words"
    case .notTalked:       return "Starting together"
    case .talking:         return "Shared curiosity"
    case .someExperience:  return "Processing this"
    case .needsReset:      return "Rebuilding"
    default:               return nil
    }
}

// R-BUG-3 FIX: Fragment strings are kept short (≤20 chars) so they
// never exceed their capped frame width and bleed off-screen.

private var selectionFragment: String? {
    let source = data.communicationGoals.first(where: { !$0.isEmpty })
        ?? data.learningGoals.first(where: { !$0.isEmpty })
    guard let s = source else { return nil }
    let phrase = CuriosityScreenConfig.leadPhrase(for: s)
    return phrase.count > 20 ? String(phrase.prefix(20)) + "…" : phrase
}

// MARK: - Computed: Personalization

private var trimmedName: String {
    data.displayName.trimmingCharacters(in: .whitespaces)
}

private var hasPersonalName: Bool { !trimmedName.isEmpty }

private var exitLine: String {
    hasPersonalName
        ? "\(trimmedName), here's your first step."
        : "Here's where you begin."
}

// MARK: - Accessibility

private var accessibilitySummary: String {
    let items = resolvedBuildItems
    let owner = hasPersonalName ? "\(trimmedName)'s" : "your"
    return "Building \(owner) path. " +
           "Assembling \(items[0].resolved), " +
           "\(items[1].resolved), " +
           "\(items[2].resolved), " +
           "and \(items[3].resolved). " +
           exitLine
}

// MARK: - Helpers

private func cacheSize(_ size: CGSize) {
    guard screenW != size.width || screenH != size.height else { return }
    DispatchQueue.main.async {
        screenW = size.width
        screenH = size.height
    }
}

private func schedule(_ seconds: Double, _ action: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: action)
}

private func deriveDefaultDifficulty() {
    // defaultDifficulty is now a computed property derived from nmStage.
    // This function is kept for future use if additional logic is needed.
}

private func completeAndAdvance() {
    guard !autoAdvanceFired else { return }
    autoAdvanceFired = true
    deriveDefaultDifficulty()
    #if DEBUG
    assert(
        onFinished != nil,
        "OnboardingBuildingPathView: onFinished not injected."
    )
    #endif
    onFinished?()
}

// MARK: - Body

var body: some View {
    GeometryReader { geo in
        let _ = cacheSize(geo.size)
        // geo.safeAreaInsets.top is ZERO here because
        // .ignoresSafeArea() on the GeometryReader zeroes the
        // proxy's inset values. Read the real physical inset
        // from the UIKit key window instead.
        let topInset = deviceTopInset

        ZStack {
            // ── Floating fragments ───────────────────────────
            fragmentLayer(topInset: topInset)

            // ── Main content ─────────────────────────────────
            mainContent(topInset: topInset)

            // ── Skip affordance ──────────────────────────────
            skipAffordance()

            // ── VoiceOver overlay ────────────────────────────
            Text(accessibilitySummary)
                .opacity(0)
                .frame(width: 0, height: 0)
                .accessibilityLabel(accessibilitySummary)
                .accessibilityAddTraits(.updatesFrequently)
        }
        .frame(width: geo.size.width, height: geo.size.height)
        // LAYOUT FIX: Atmospheric layers (.ignoresSafeArea()) are
        // moved to .background() so they cannot distort the ZStack's
        // internal alignment origin. When .ignoresSafeArea() children
        // sit inside a ZStack, the ZStack computes its alignment
        // center from the union of all children's frames — including
        // safe-area-extended frames — which shifts the origin
        // rightward and drags all content with it.
        .background(
            ZStack {
                // Dark: near-black | Light: warm cream
                (colorScheme == .dark ? AppColors.pageBg : AppColors.lightPageBg)
                atmosphere()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                OnboardingGlowField()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .ignoresSafeArea()
        )
        // LAYOUT FIX: Fade overlay also isolated via .overlay()
        // for the same reason — its .ignoresSafeArea() must not
        // participate in ZStack alignment.
        .overlay(
            (colorScheme == .dark ? AppColors.pageBg : AppColors.lightPageBg)
                .opacity(fadeOutVisible ? 1 : 0)
                .animation(.easeIn(duration: 0.4), value: fadeOutVisible)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        )
        .clipped()
        .contentShape(Rectangle())
        .onTapGesture { handleSkip() }
    }
    .ignoresSafeArea()
    .preferredColorScheme(.dark)
    .onAppear {
        guard !hasAnimated else { return }
        hasAnimated = true
        startAnimation()
    }
}

// MARK: - Skip

private func handleSkip() {
    guard skipAvailable, !autoAdvanceFired else { return }
    autoAdvanceFired = true
    deriveDefaultDifficulty()
    withAnimation(.easeIn(duration: 0.25)) { fadeOutVisible = true }
    schedule(0.30) { onFinished?() }
}

@ViewBuilder
private func skipAffordance() -> some View {
    VStack {
        Spacer()
        HStack {
            Spacer()
            if skipVisible {
                Text("Continue →")
                    .font(AppFonts.caption)
                    .foregroundStyle(colorScheme == .dark
                        ? AppColors.textTertiary
                        : AppColors.lightTextTertiary)
                    .opacity(0.55)
                    .padding(.trailing, 28)
                    .padding(.bottom, 40)
                    .transition(.opacity)
                    .accessibilityLabel("Skip loading and continue")
                    .accessibilityAddTraits(.isButton)
            }
        }
    }
    .animation(.easeIn(duration: 0.4), value: skipVisible)
    .allowsHitTesting(skipAvailable)
}

// MARK: - Fragment Layer
//
// topInset: the physical top safe-area inset from UIKit's key window.
//
// The inner GeometryReader does NOT use .ignoresSafeArea() (removed
// in Rev 3 to fix the layout origin). Its geo.size.height is the
// safe-area-inset region — shorter than the physical screen by topInset.
//
// fullH = geo.size.height + topInset reconstructs the physical screen
// height from live geometry on every frame (unlike the @State screenH
// which may hold its initial value of 852 on the first render frame).
// midY is computed in inset-region coordinates, then each position
// adds topInset back for the correct physical screen position.

@ViewBuilder
private func fragmentLayer(topInset: CGFloat) -> some View {
    GeometryReader { geo in
        // fullH reconstructs the physical screen height from live geometry.
        // geo.size.height excludes topInset (no .ignoresSafeArea here).
        // screenH is cached and may hold its initial value of 852 on the
        // first render frame — using it caused fragments to jump position.
        // geo.size.height + topInset is always accurate on every frame.
        let fullH        = geo.size.height + topInset
        let midX         = geo.size.width / 2
        // midY in inset-region coordinates:
        //   physical center = fullH / 2
        //   inset-region y  = physical y − topInset
        let midY         = (fullH / 2) - topInset
        let fragmentMaxW = geo.size.width / 2 - 24

        ZStack {
            // Fragment 0 — stage — upper left of center
            BPFloatingFragment(
                text:          stageFragment,
                targetOpacity: 0.60,
                isVisible:     fragmentStates[0].visible,
                isFading:      fragmentStates[0].fading
            )
            .frame(maxWidth: fragmentMaxW)
            .position(
                x: midX - screenW * 0.22,
                y: midY - fullH * 0.28 + topInset
            )

            // Fragment 1 — context — upper right of center
            if let f1 = contextFragment {
                BPFloatingFragment(
                    text:          f1,
                    targetOpacity: 0.55,
                    isVisible:     fragmentStates[1].visible,
                    isFading:      fragmentStates[1].fading
                )
                .frame(maxWidth: fragmentMaxW)
                .position(
                    x: midX + screenW * 0.22,
                    y: midY - fullH * 0.32 + topInset
                )
            }

            // Fragment 2 — selection — centered above name
            if let f2 = selectionFragment {
                BPFloatingFragment(
                    text:          f2,
                    targetOpacity: 0.50,
                    isVisible:     fragmentStates[2].visible,
                    isFading:      fragmentStates[2].fading
                )
                .frame(maxWidth: fragmentMaxW)
                .position(
                    x: midX,
                    y: midY - fullH * 0.38 + topInset
                )
            }
        }
        .frame(width: geo.size.width, height: geo.size.height)
    }
    .allowsHitTesting(false)
    .accessibilityHidden(true)
}

// MARK: - Main Content
//
// topInset: the physical top safe-area inset (Dynamic Island / notch /
// status bar height) read from UIKit's key window.
//
// WHY geo.safeAreaInsets.top DOES NOT WORK HERE:
//
// The outer GeometryReader uses .ignoresSafeArea(). When a view opts
// out of safe areas, SwiftUI zeroes the GeometryProxy's safeAreaInsets
// — the proxy reports 0 for all edges because the view has declared it
// doesn't care about safe areas. Every prior attempt that captured
// geo.safeAreaInsets.top was capturing 0, producing padding equal to
// just OL.progressTop (~24pt) — well within the ~59pt Dynamic Island.
//
// The fix: deviceTopInset reads UIApplication → UIWindowScene →
// UIWindow.safeAreaInsets.top, which always reports the real physical
// inset regardless of SwiftUI's modifier chain. This value is passed
// as topInset to mainContent and fragmentLayer.

@ViewBuilder
private func mainContent(topInset: CGFloat) -> some View {
    let completeCount = indicatorStates.filter { $0 == .complete }.count

    VStack(alignment: .center, spacing: 0) {

        // Progress bar
        //
        // .padding(.top) = topInset (Dynamic Island / notch clearance,
        //                   from UIKit key window — NOT geo.safeAreaInsets)
        //                 + OL.progressTop (design spacing below island).
        OnboardingProgressBar(
            currentStep:          completeCount,
            totalSteps:           5
        )
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, topInset + OL.progressTop(screenH))
        .padding(.bottom, OL.progressBottom(screenH))
        .accessibilityHidden(true)

        Spacer()

        // Overline — BUG-3 FIX retained
        Text("BUILDING YOUR PATH")
            .font(AppFonts.overline)
            .foregroundStyle(colorScheme == .dark
                ? LinearGradient(
                    colors: [AppColors.purple, AppColors.magenta],
                    startPoint: .leading, endPoint: .trailing)
                : LinearGradient(stops: [
                    .init(color: AppColors.magenta, location: 0.00),
                    .init(color: AppColors.pink,    location: 0.45),
                    .init(color: AppColors.gold,    location: 1.00),
                  ],
                  startPoint: .leading, endPoint: .trailing))
            .tracking(2.5)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(overlabelVisible ? 1 : 0)
            .offset(y: overlabelVisible ? 0 : 8)
            .animation(.easeOut(duration: 1.0), value: overlabelVisible)
            .padding(.bottom, 10)
            .accessibilityHidden(true)

        // Name headline — BUG-1 downstream fix retained
        nameHeadline
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(nameVisible ? 1 : 0)
            .offset(y: nameVisible ? 0 : 14)
            .animation(.easeOut(duration: 1.2), value: nameVisible)
            .padding(.bottom, OL.loose(screenH))
            .accessibilityHidden(true)

        // Build item list — BUG-1 FIX retained: no .fixedSize(horizontal:)
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(resolvedBuildItems.enumerated()), id: \.offset) { i, item in
                BPBuildItemRow(
                    item:           item,
                    indicatorState: indicatorStates[i],
                    isVisible:      indicatorStates[i] != .pending && !itemsFadingOut,
                    isComplete:     indicatorStates[i] == .complete && !itemsFadingOut
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityHidden(true)

        // Exit tagline — BUG-5 FIX retained
        Text(exitLine)
            .font(AppFonts.body(18, weight: .medium))
            .foregroundStyle(colorScheme == .dark
                ? AppColors.textPrimary
                : AppColors.lightCardTitle)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(taglineVisible ? 1 : 0)
            .offset(y: taglineVisible ? 0 : 10)
            .animation(.easeOut(duration: 1.2), value: taglineVisible)
            .padding(.top, OL.loose(screenH))
            .accessibilityHidden(true)

        // BUG-7 FIX retained
        Spacer(minLength: 40)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    // BUG-6 FIX retained: single source of horizontal inset.
    .padding(.horizontal, 36)
    // BUG-7 FIX retained: home indicator clearance
    .padding(.bottom, 34)
}

// MARK: - Name Headline

@ViewBuilder
private var nameHeadline: some View {
    if hasPersonalName {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(trimmedName)
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.textPrimary
                    : AppColors.lightCardTitle)
            Text(".")
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.spectrumBorder
                    : AppColors.warmAuroraBorder)
        }
        .font(AppFonts.heroTitle)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    } else {
        Text("Your path.")
            .font(AppFonts.heroTitle)
            .foregroundStyle(colorScheme == .dark
                ? AppColors.textPrimary
                : AppColors.lightCardTitle)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }
}

// MARK: - Atmospheric Layer
// Unchanged — atmosphere() renders correctly once the ZStack frame
// is pinned (R-BUG-1 fix). Orb offsets are screen-relative and correct.

// Dark:  cool spectrum — purple / cyan / magenta orbs
// Light: warm aurora  — purple / gold / magenta orbs (no cyan)
private var atmosAccent: Color {
    colorScheme == .dark ? AppColors.cyan : AppColors.gold
}

private func atmosphere() -> some View {
    ZStack {
        Ellipse()
            .fill(RadialGradient(
                colors: [AppColors.purple.opacity(0.40),
                         atmosAccent.opacity(0.20),
                         Color.clear],
                center: .top, startRadius: 30, endRadius: 380))
            .frame(width: OL.atmosW(screenW), height: OL.atmosH(screenH))
            .offset(y: -screenH * 0.42)
            .blur(radius: 90)
            .opacity(atmosphericVisible ? 1 : 0)
            .animation(.easeInOut(duration: 2.0), value: atmosphericVisible)

        Ellipse()
            .fill(atmosAccent.opacity(0.12))
            .frame(width: 180, height: 180)
            .blur(radius: 55)
            .offset(x: -screenW * 0.32, y: -screenH * 0.22)
            .opacity(glowPeak ? 0.90 : 0.40)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(AppColors.magenta.opacity(0.10))
            .frame(width: 140, height: 140)
            .blur(radius: 50)
            .offset(x: screenW * 0.32, y: -screenH * 0.26)
            .opacity(glowPeak ? 0.85 : 0.28)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(AppColors.purple.opacity(0.14))
            .frame(width: 240, height: 240)
            .blur(radius: 80)
            .opacity(glowPeak ? 1.00 : 0.45)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(atmosAccent.opacity(0.08))
            .frame(width: 110, height: 110)
            .blur(radius: 42)
            .offset(x: -screenW * 0.38, y: screenH * 0.22)
            .opacity(glowPeak ? 0.75 : 0.18)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(AppColors.magenta.opacity(0.08))
            .frame(width: 150, height: 150)
            .blur(radius: 60)
            .offset(x: screenW * 0.38, y: screenH * 0.18)
            .opacity(glowPeak ? 0.85 : 0.22)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Ellipse()
            .fill(RadialGradient(
                colors: [AppColors.purple.opacity(0.18),
                         atmosAccent.opacity(0.10),
                         Color.clear],
                center: .center, startRadius: 0, endRadius: 200))
            .frame(width: 400, height: 400)
            .blur(radius: 70)
            .scaleEffect(glowPeak ? 1.0 : 0.36)
            .opacity(glowPeak ? 1.0 : 0)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)

        Rectangle()
            .fill(LinearGradient(
                colors: [AppColors.purple.opacity(0.10), Color.clear],
                startPoint: .bottom, endPoint: .top))
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .opacity(glowPeak ? 1.0 : 0)
            .animation(.easeInOut(duration: 2.0), value: glowPeak)
    }
    .drawingGroup()
}

    // MARK: - Animation (startFullAnimation replacement)
    //
    // BUG-1 FIX: the #if DEBUG / XCODE_RUNNING_FOR_PREVIEWS block
    // previously hard-jumped to indicatorStates = [.complete × 4] and
    // returned early. This meant BPOrbitCanvas was NEVER mounted in any
    // preview — the .processing state was skipped entirely, so the comet
    // orbit was invisible.
    //
    // BUG-2 FIX (downstream): BPBuildItemRow.isVisible is computed as
    // indicatorStates[i] != .pending. When the DEBUG block set states to
    // .complete before the animation sequence ran, the rows started
    // invisible (opacity 0) and stayed there because no animation ever
    // fired to transition them in.
    //
    // FIX: the preview path now runs a real but fast (0.4× speed) animation
    // sequence using the same schedule() calls as the device path. This
    // ensures every state — pending → processing → complete — is visited,
    // all rows animate in, and the comet orbit is visible.
    //
    // The instanceID UUID toggle in the preview re-creates the view from
    // scratch on each Reset tap, which resets hasAnimated = false and
    // replays the sequence.
    
    private func startAnimation() {
        if reduceMotion { startReducedMotionAnimation(); return }
        schedule(0.15) { startFullAnimation() }
    }
    
    private func startReducedMotionAnimation() {
        overlabelVisible = true
        nameVisible      = true
        indicatorStates  = [.complete, .complete, .complete, .complete]
        taglineVisible   = true
        schedule(2.00) { completeAndAdvance() }
    }

    private func startFullAnimation() {
        #if DEBUG
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            // Preview-fast path: same sequence as below but at 0.4× wall-clock
            // time so the full pending → processing → complete flow is visible
            // without waiting 4+ seconds per canvas reload.
            //
            // Multiplier 0.4 maps the real-device schedule (0s–4.6s) into
            // approximately 0s–1.85s in the preview canvas.
            let k = 0.4
            schedule(0.00 * k) {
                withAnimation(.easeInOut(duration: 1.6 * k)) { atmosphericVisible = true }
            }
            schedule(0.00 * k) {
                withAnimation(.easeOut(duration: 0.8 * k)) { overlabelVisible = true }
            }
            schedule(0.10 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[0].visible = true }
            }
            schedule(0.40 * k) {
                withAnimation(.easeOut(duration: 0.9 * k)) { nameVisible = true }
            }
            schedule(0.40 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[0] = .processing }
            }
            schedule(0.70 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[1] = .processing }
            }
            schedule(1.00 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[2] = .processing }
            }
            schedule(1.10 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[1].visible = true }
            }
            schedule(1.30 * k) {
                withAnimation(.easeOut(duration: 0.4 * k)) { indicatorStates[3] = .processing }
            }
            schedule(1.50 * k) { skipAvailable = true }
            schedule(1.80 * k) {
                withAnimation(.easeIn(duration: 0.4 * k)) { skipVisible = true }
            }
            schedule(1.80 * k) {
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[0].fading = true }
            }
            schedule(1.90 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[0] = .complete }
            }
            schedule(2.00 * k) {
                withAnimation(.easeInOut(duration: 0.9 * k)) { fragmentStates[2].visible = true }
            }
            schedule(2.20 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[1] = .complete }
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[1].fading = true }
            }
            schedule(2.50 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[2] = .complete }
            }
            schedule(2.80 * k) {
                withAnimation(.easeOut(duration: 0.7 * k)) { indicatorStates[3] = .complete }
                withAnimation(.easeInOut(duration: 1.4 * k)) { glowPeak = true }
            }
            schedule(2.90 * k) {
                withAnimation(.easeIn(duration: 0.8 * k)) { fragmentStates[2].fading = true }
            }
            schedule(3.20 * k) {
                withAnimation(.easeOut(duration: 0.9 * k)) { taglineVisible = true }
            }
            // Do NOT auto-advance in preview — leave the final state on screen.
            return
        }
        #endif

        // ── Real-device timing (unchanged) ───────────────────────────────
        schedule(0.00) {
            withAnimation(.easeInOut(duration: 1.6)) { atmosphericVisible = true }
        }
        schedule(0.00) {
            withAnimation(.easeOut(duration: 0.8)) { overlabelVisible = true }
        }
        schedule(0.10) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[0].visible = true }
        }
        schedule(0.40) {
            withAnimation(.easeOut(duration: 0.9)) { nameVisible = true }
        }
        schedule(0.40) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[0] = .processing }
        }
        schedule(0.70) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[1] = .processing }
        }
        schedule(1.00) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[2] = .processing }
        }
        schedule(1.10) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[1].visible = true }
        }
        schedule(1.30) {
            withAnimation(.easeOut(duration: 0.4)) { indicatorStates[3] = .processing }
        }
        schedule(1.50) { skipAvailable = true }
        schedule(1.80) {
            withAnimation(.easeIn(duration: 0.4)) { skipVisible = true }
        }
        schedule(1.80) {
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[0].fading = true }
        }
        schedule(1.90) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[0] = .complete }
        }
        schedule(2.00) {
            withAnimation(.easeInOut(duration: 0.9)) { fragmentStates[2].visible = true }
        }
        schedule(2.20) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[1] = .complete }
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[1].fading = true }
        }
        schedule(2.50) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[2] = .complete }
        }
        schedule(2.80) {
            withAnimation(.easeOut(duration: 0.7)) { indicatorStates[3] = .complete }
            withAnimation(.easeInOut(duration: 1.4)) { glowPeak = true }
        }
        schedule(2.90) {
            withAnimation(.easeIn(duration: 0.8)) { fragmentStates[2].fading = true }
        }
        schedule(3.20) {
            withAnimation(.easeOut(duration: 0.9)) { taglineVisible = true }
        }
        schedule(3.80) {
            withAnimation(.easeIn(duration: 0.4)) {
                overlabelVisible = false
                nameVisible      = false
                itemsFadingOut   = true
            }
        }
        schedule(3.90) {
            withAnimation(.easeIn(duration: 0.4)) { taglineVisible = false }
        }
        schedule(4.20) {
            withAnimation(.easeIn(duration: 0.3)) { fadeOutVisible = true }
        }
    schedule(4.60) { completeAndAdvance() }
}
}

// MARK: - BPBuildItemRow
// BUG-4 + BUG-6 fixes retained: .frame(maxWidth: .infinity) on both
// the label VStack and the outer HStack. lineLimit + truncationMode on
// both Text nodes. fixedSize(horizontal: false, vertical: true) on
// the resolved text for graceful two-line wrap.

private struct BPBuildItemRow: View {
let item:           BPBuildItem
let indicatorState: BPIndicatorState
let isVisible:      Bool
let isComplete:     Bool



@Environment(\.colorScheme) private var colorScheme

var body: some View {
    HStack(spacing: 14) {
        // Fixed-size indicator — never grows
        BPOrbitIndicator(state: indicatorState)
            .fixedSize()

        VStack(alignment: .leading, spacing: 2) {
            Text(item.category.uppercased())
                .font(AppFonts.overline)
                .foregroundStyle(colorScheme == .dark
                    ? AppColors.textTertiary
                    : AppColors.lightCardTitle.opacity(0.40))
                .tracking(1.5)
                .lineLimit(1)
                .truncationMode(.tail)

            Text(item.resolved)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(isComplete
                    ? (colorScheme == .dark ? AppColors.textPrimary : AppColors.lightCardTitle)
                    : (colorScheme == .dark ? AppColors.textSecondary : AppColors.lightCardTitle.opacity(0.55)))
                .animation(.easeOut(duration: 0.7), value: isComplete)
                .lineLimit(2)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
        }
        // Fill remaining width after the indicator + spacing
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    // Fill the padded column width
    .frame(maxWidth: .infinity, alignment: .leading)
    .opacity(isVisible ? 1 : 0)
    .offset(y: isVisible ? 0 : 10)
    .animation(.easeOut(duration: 0.8), value: isVisible)
}
}

// MARK: - BPOrbitIndicator (unchanged)

private struct BPOrbitIndicator: View {
let state: BPIndicatorState
private let size: CGFloat = 22



@Environment(\.colorScheme) private var colorScheme

var body: some View {
    ZStack {
        Circle()
            .strokeBorder(
                colorScheme == .dark ? AppColors.border : AppColors.lightBorder,
                lineWidth: 1.5)
            .opacity(state == .pending ? 1 : 0)
            .animation(.easeOut(duration: 0.3), value: state == .pending)

        if state == .processing {
            BPOrbitCanvas(size: size, colorScheme: colorScheme)
                .transition(.opacity)
        }

        Circle()
            .fill(LinearGradient(
                colors: colorScheme == .dark
                    ? [AppColors.cyan, AppColors.purple, AppColors.magenta]
                    : [AppColors.purple, AppColors.magenta, AppColors.gold],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .opacity(state == .complete ? 1 : 0)
            .animation(.easeOut(duration: 0.7), value: state == .complete)
            .shadow(
                color: colorScheme == .dark
                    ? AppColors.glowCyan : AppColors.lightShadowPurple,
                radius: colorScheme == .dark ? 12 : 7)
            .shadow(
                color: colorScheme == .dark
                    ? AppColors.glowMagenta : AppColors.lightShadowMagenta,
                radius: colorScheme == .dark ? 24 : 14)
    }
    .frame(width: size, height: size)
}
}

// MARK: - BPOrbitCanvas (unchanged)

private struct BPOrbitCanvas: View {
let size: CGFloat
let colorScheme: ColorScheme
private let revolutionDuration: TimeInterval = 1.4



// RGB triples resolved from AppColors tokens per colorScheme.
// Dark:  cyan → purple → magenta
// Light: purple → magenta → gold
private var primaryRGB:   (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.cyan : AppColors.purple)
}
private var secondaryRGB: (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.purple : AppColors.magenta)
}
private var tertiaryRGB:  (r: Double, g: Double, b: Double) {
    components(of: colorScheme == .dark ? AppColors.magenta : AppColors.gold)
}

var body: some View {
    let pRGB = primaryRGB
    let sRGB = secondaryRGB
    let tRGB = tertiaryRGB
    let borderColor: Color = colorScheme == .dark
        ? AppColors.borderHover
        : AppColors.lightBorderHover
    let sparkOuter = AppColors.magenta
    let sparkInner: Color = colorScheme == .dark ? AppColors.cyan : AppColors.purple

    TimelineView(.animation) { timeline in
        Canvas { context, canvasSize in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
                .truncatingRemainder(dividingBy: revolutionDuration)
            let progress = elapsed / revolutionDuration
            drawOrbit(
                context: context, size: canvasSize, progress: progress,
                pRGB: pRGB, sRGB: sRGB, tRGB: tRGB,
                sparkOuter: sparkOuter, sparkInner: sparkInner,
                borderColor: borderColor
            )
        }
        .frame(width: size, height: size)
    }
}

private func drawOrbit(
    context:     GraphicsContext,
    size:        CGSize,
    progress:    Double,
    pRGB:        (r: Double, g: Double, b: Double),
    sRGB:        (r: Double, g: Double, b: Double),
    tRGB:        (r: Double, g: Double, b: Double),
    sparkOuter:  Color,
    sparkInner:  Color,
    borderColor: Color
) {
    let cx     = size.width  / 2
    let cy     = size.height / 2
    let radius = size.width  / 2 - 2.0
    let steps  = 28

    let headAngle = progress * .pi * 2 - .pi / 2
    let tailArc   = Double.pi * 0.88

    var borderPath = Path()
    borderPath.addEllipse(in: CGRect(
        x: cx - radius, y: cy - radius,
        width: radius * 2, height: radius * 2))
    context.stroke(
        borderPath,
        with: .color(borderColor),
        lineWidth: 1.5)

    for i in 0..<steps {
        let t         = Double(i) / Double(steps - 1)
        let dotAngle  = headAngle - tailArc * (1.0 - t)
        let x         = cx + cos(dotAngle) * radius
        let y         = cy + sin(dotAngle) * radius
        let alpha     = t * 0.58
        let dotRadius = 0.9 + t * 0.65

        let color: Color
        if t < 0.4 {
            let blend = t / 0.4
            color = Color(
                red:   lerp(pRGB.r, sRGB.r, blend),
                green: lerp(pRGB.g, sRGB.g, blend),
                blue:  lerp(pRGB.b, sRGB.b, blend))
        } else {
            let blend = (t - 0.4) / 0.6
            color = Color(
                red:   lerp(sRGB.r, tRGB.r, blend),
                green: lerp(sRGB.g, tRGB.g, blend),
                blue:  lerp(sRGB.b, tRGB.b, blend))
        }

        var dotPath = Path()
        dotPath.addEllipse(in: CGRect(
            x: x - dotRadius, y: y - dotRadius,
            width: dotRadius * 2, height: dotRadius * 2))
        context.fill(dotPath, with: .color(color.opacity(alpha)))
    }

    let hx = cx + cos(headAngle) * radius
    let hy = cy + sin(headAngle) * radius

    var outerPath = Path()
    outerPath.addEllipse(in: CGRect(
        x: hx - 5.5, y: hy - 5.5, width: 11, height: 11))
    context.fill(outerPath, with: .color(sparkOuter.opacity(0.45)))

    var innerPath = Path()
    innerPath.addEllipse(in: CGRect(
        x: hx - 3, y: hy - 3, width: 6, height: 6))
    context.fill(innerPath, with: .color(sparkInner.opacity(0.55)))

    var corePath = Path()
    corePath.addEllipse(in: CGRect(
        x: hx - 1.8, y: hy - 1.8, width: 3.6, height: 3.6))
    context.fill(corePath, with: .color(.white.opacity(0.96)))
}

private func components(of color: Color) -> (r: Double, g: Double, b: Double) {
    let uiColor = UIColor(color)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
    return (Double(r), Double(g), Double(b))
}

private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
    a + (b - a) * t
}
}

// MARK: - BPFloatingFragment
// R-BUG-3 FIX: .fixedSize() removed from inside the component.
// Width is now controlled by the .frame(maxWidth: fragmentMaxW) applied
// by the caller in fragmentLayer(). Removing .fixedSize() here means the
// Text respects the width cap and wraps rather than overflowing right.
// .lineLimit(1) ensures it stays single-line and truncates cleanly.

private struct BPFloatingFragment: View {
let text:          String
let targetOpacity: Double
let isVisible:     Bool
let isFading:      Bool



@Environment(\.colorScheme) private var colorScheme

var body: some View {
    Text(text.uppercased())
        .font(AppFonts.overline)
        .foregroundStyle(colorScheme == .dark
            ? AppColors.textSecondary
            : AppColors.lightTextSecondary)
        .tracking(2.5)
        .multilineTextAlignment(.center)
        // R-BUG-3 FIX: .fixedSize() removed. Width is capped by caller.
        // .lineLimit(1) ensures single-line with clean truncation.
        .lineLimit(1)
        .truncationMode(.tail)
        .opacity(isVisible && !isFading ? targetOpacity : 0)
        .offset(y: isVisible && !isFading ? -4 : 0)
        .animation(.easeInOut(duration: 1.0), value: isVisible)
        .animation(.easeIn(duration: 0.8), value: isFading)
        .allowsHitTesting(false)
}
}

// MARK: - Previews
//
// Each preview uses a @Previewable UUID that is toggled by a Reset button.
// Changing the id re-creates the view from scratch — hasAnimated resets to
// false — so the full entrance animation replays on every canvas reset.

#Preview("Dark Mode") {
@Previewable @State var data: OnboardingData = {
var d = OnboardingData()
d.displayName         = "Jordan"
d.explorationMode     = .couple
d.nmStage             = .curious
d.relationshipContext = .notTalked
d.communicationGoals  = ["Talking about fantasies"]
return d
}()
// Changing this id destroys and recreates the view, restarting animation.
@Previewable @State var instanceID = UUID()
ZStack(alignment: .bottomTrailing) {
OnboardingBuildingPathView(data: $data, onFinished: {})
.id(instanceID)
Button("↺ Reset") { instanceID = UUID() }
.font(.system(size: 13, weight: .semibold))
.foregroundStyle(.white)
.padding(.horizontal, 14)
.padding(.vertical, 8)
.background(.ultraThinMaterial)
.clipShape(Capsule())
.padding(20)
}
.preferredColorScheme(.dark)
}

#Preview("Light Mode") {
@Previewable @State var data: OnboardingData = {
var d = OnboardingData()
d.displayName         = "Alex"
d.explorationMode     = .solo
d.nmStage             = .experienced
d.relationshipContext = .needsReset
d.communicationGoals  = ["Rebuilding intimacy"]
return d
}()
@Previewable @State var instanceID = UUID()
ZStack(alignment: .bottomTrailing) {
OnboardingBuildingPathView(data: $data, onFinished: {})
.id(instanceID)
Button("↺ Reset") { instanceID = UUID() }
.font(.system(size: 13, weight: .semibold))
.foregroundStyle(.primary)
.padding(.horizontal, 14)
.padding(.vertical, 8)
.background(.ultraThinMaterial)
.clipShape(Capsule())
.padding(20)
}
.preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingCardRevealView.swift` {#file-open-lightly-features-onboarding-views-onboardingcardrevealview-swift}

```swift
//Features/Onboarding/Views/OnboardingCardRevealView.swift
//
// Screen 7.5 — Card Reveal
//
// INTERACTION ARC
// ───────────────
//  t=0            Scene fades in. Card floats up spring(0.42, 0.78).
//                 AtmosphericGhostDeck drifts passively behind.
//  t=0.8s         Card breath begins — scale 1.000 ↔ 1.006, 3.0s sine.
//  t=tap          Flip fires. Ghost deck fades.
//                 3D flip: spring(0.58, 0.84), perspective 0.6.
//                 Front/back cross-fade over 12° window at 90°.
//  t=flip+~320ms  Back face visible. Heading enters, pills stagger up.
//  t=select       Three-beat post-selection sequence:
//                   Beat 1 (0ms):    Pill breathes — scale → 1.06.
//                   Beat 2 (+500ms): Border blooms — lineWidth → 3.0.
//                   Beat 3 (+900ms): Unselected pills sink and fade.
//  t=select+1.3s  Card exits upward, opacity 0, over 450ms.
//  t=select+1.65s Encouragement fades in from below.
//  t=select+1.83s Typewriter begins at 38 cps.
//                 Plain text in body color. Accent in static color.
//                 LivingText crossfades in once accent fully typed.
//                 Cursor blinks ×3 after last char, then fades.
//  t=typing+0.9s  Scene fades to pageBg over 500ms → onContinue().
//
// TRANSITION TO GROUNDRULES
// ──────────────────────────
//  This view owns its exit — sceneOpacity fades to 0, then onContinue()
//  fires. FlowView's spring transition cross-dissolves to GroundRulesView.
//  OnboardingAtmosphere persists in FlowView's ZStack, morphing from
//  .cardReveal to .groundRules config — no background flash.
//
// SKIP
// ────
//  "Continue when ready →" appears at 25s idle.
//  Stores data.nmCardResponse = nil and fades out.

import SwiftUI

// MARK: - Phase

private enum CardRevealPhase: Equatable {
   case idle
   case flipping
   case flipped
   case selected
   case encouragement
   case exiting
}

// MARK: - Main View

struct OnboardingCardRevealView: View {

   @Binding var data: OnboardingData
   var onContinue: (() -> Void)?

   @Environment(\.colorScheme) private var colorScheme
   @Environment(\.accessibilityReduceMotion) private var reduceMotion
   private var isLight: Bool { colorScheme == .light }

   // ── Phase ─────────────────────────────────────────────────────────
   @State private var phase: CardRevealPhase = .idle
   @State private var selectedPill: CardRevealPill? = nil
   @State private var hasAdvanced = false

   // ── Entrance ───────────────────────────────────────────────────────
   @State private var hasAnimated       = false
   @State private var sceneOpacity:     Double  = 0
   @State private var cardOffsetY: CGFloat = 40
   @State private var cardEntryOpacity: Double  = 0

   // ── Float ────────────────────────────────────────────────────
   @State private var isFloating:  Bool    = false
   @State private var floatOffset: CGFloat = 0

   // ── Glow pulse ────────────────────────────────────────────────────
   @State private var glowOpacity: Double = 0.4
   @State private var hasBeenTapped: Bool = false

   // ── Ghost deck ────────────────────────────────────────────────────
   @State private var ghostOpacity: Double = 0

   // ── Flip ──────────────────────────────────────────────────────────
   @State private var flipDegrees:  Double = 180
   @State private var backRevealed: Bool   = false

   // ── Post-selection beat ────────────────────────────────────────────
   @State private var selectedPillScale:      CGFloat = 1.0
   @State private var selectedBorderWidth:    CGFloat = 2.0
   @State private var unselectedPillsVisible: Bool    = true

   // ── Card exit ─────────────────────────────────────────────────────
   @State private var cardExiting: Bool = false

   // ── Encouragement ─────────────────────────────────────────────────
   @State private var encouragementVisible: Bool = false
   @State private var typingComplete:       Bool = false

   // ── Arrow ─────────────────────────────────────────────────────────
   @State private var arrowTriggered: Bool = false
   @State private var sitWithThisVisible: Bool = false
   @State private var tapHintVisible: Bool = false

   // ── Skip ──────────────────────────────────────────────────────────
   // Skip affordance removed

   @State private var fuseVisible:   Bool = false
   @State private var fuseCompleted: Bool = false
   @State private var flipHintActive:  Bool   = false
   @State private var flipHintDegrees: Double = 0
   @State private var fuseBurnProgress: Double = 0
   @State private var fuseBurnStartDate: Date? = nil

   @State private var questionVisible: Bool = false
   @State private var pillsVisible:    Bool = false

   // ── Scene exit ────────────────────────────────────────────────────
   @State private var exitingToNext: Bool = false

   // MARK: - Constants

    private let cardSize = CardLayout.size
   private let cardCornerRadius = CardLayout.cornerRadius
   private let fuseDuration:  TimeInterval = 15.0
   private let fuseDelay:     TimeInterval = 3.0
   private let fuseLineWidth: CGFloat      = 2.5

   // MARK: - Body

   var body: some View {
       ZStack {
           Color.clear.ignoresSafeArea()

           // Card stage and encouragement share the same region.
           // Card exits upward; encouragement rises from below.
           VStack {
               Spacer()   // greedy — pushes card DOWN
               ZStack {
                   cardStage

                   if encouragementVisible || typingComplete {
                       EncouragementView(
                           isLight:      isLight,
                           active:       encouragementVisible,
                           reduceMotion: reduceMotion,
                           selectedPill: selectedPill,
                           onComplete:   handleTypingComplete
                       )
                       .transition(
                           .opacity.combined(with: .offset(y: 16))
                       )
                   }
               }
               .frame(width: cardSize.width, height: cardSize.height)

               Text("sit with this")
                   .font(AppFonts.body(16, weight: .regular))
                   .italic()
                   .foregroundStyle(Color.white)
                   .opacity(sitWithThisVisible && phase != .selected && phase != .encouragement && phase != .exiting ? 0.75 : 0)
                   .blur(radius: sitWithThisVisible ? 0 : 4)
                   .offset(y: sitWithThisVisible ? 0 : 6)
                   .padding(.top, 12)

               Text("tap when ready")
                   .font(AppFonts.caption)
                   .foregroundStyle(Color.white.opacity(0.35))
                   .opacity(tapHintVisible && phase != .selected && phase != .encouragement && phase != .exiting ? 1 : 0)
                   .padding(.top, 4)

               Color.clear.frame(height: 160)   // fixed — stops card going too low
           }
           .frame(maxWidth: .infinity)

       }
       .opacity(sceneOpacity)
       .animation(
           exitingToNext
               ? .easeIn(duration: 0.5)
               : .easeOut(duration: 0.45),
           value: exitingToNext
       )
       .accessibilityElement(children: .ignore)
       .accessibilityLabel(
           backRevealed
               ? "Something came up. What's it closest to? Choose from: \(CardRevealPill.allCases.map(\.rawValue).joined(separator: ", "))"
               : "What would you desire if nobody, not even you, would judge the answer? Tap to reflect."
       )
       .accessibilityAction(named: "Flip card") {
           if phase == .idle { handleCardTap() }
       }
       .accessibilityAction(named: "Skip") { handleSkip() }
       .onAppear {
           guard !hasAnimated else { return }
           hasAnimated = true
           startEntrance()
       }
       .onDisappear {
           // Skip affordance removed
       }
   }

   // MARK: - Card Stage

   private var cardStage: some View {
       TimelineView(.animation(paused: !fuseVisible || fuseCompleted)) { timeline in
           ZStack {
               // AtmosphericGhostDeck handles its own drift animation internally.
               // We only control its opacity (fades out on flip).
               AtmosphericGhostDeck(
                   cardSize:     cardSize,
                   cornerRadius: cardCornerRadius
               )
               .opacity(ghostOpacity)
               .animation(.easeOut(duration: 0.7), value: ghostOpacity)

               // Main card — entrance offset + float + exit transform
               ZStack {
                   flipContainer
               }
               .shadow(
                   color: phase == .idle && !hasBeenTapped
                       ? AppColors.cyan.opacity(glowOpacity * 0.55)
                       : .clear,
                   radius: 28
               )
               .shadow(
                   color: phase == .idle && !hasBeenTapped
                       ? AppColors.magenta.opacity(glowOpacity * 0.35)
                       : .clear,
                   radius: 40
               )
               .animation(.easeInOut(duration: 2.8), value: glowOpacity)
               .offset(y: cardExiting ? -36 : cardOffsetY + floatOffset)
               .opacity(cardExiting ? 0 : cardEntryOpacity)
               .animation(
                   cardExiting
                       ? .timingCurve(0.4, 0, 0.6, 1, duration: 0.45)
                       : .spring(response: 0.42, dampingFraction: 0.78),
                   value: cardExiting
               )
               .animation(.easeOut(duration: 0.45), value: cardEntryOpacity)
               .onTapGesture {
                   handleCardTap()
               }
           }
           .frame(width: cardSize.width, height: cardSize.height)
           .onChange(of: timeline.date) { _, date in
               updateFuseProgress(at: date)
           }
       }
   }

   // MARK: - Flip Container

   private var flipContainer: some View {
       let _phase = phase

       return ZStack {

           // CardFrontView — question text, fuse, pills, tap target
           CardFrontView(
               cardSize:           cardSize,
               cornerRadius:       cardCornerRadius,
               isLight:            isLight,
               arrowTriggered:     arrowTriggered,
               sitWithThisVisible: sitWithThisVisible,
               onTap:              handleCardTap,
               fuseProgress:       fuseBurnProgress,
               questionVisible:    _phase == .flipped || _phase == .selected,
               pillsVisible:       pillsVisible,
               onPillSelected:     handlePillSelected
           )
           .opacity(frontFaceOpacity)
           .allowsHitTesting(true)

           // CuriosityCardBack — maze pattern, shown face-down
           // Visible during idle (arrival + float) phase only
           CuriosityCardBack(isActive: _phase == .idle)
               .opacity(idleBackFaceOpacity)
               .rotation3DEffect(
                   Angle.degrees(180),
                   axis: (x: 0, y: 1, z: 0)
               )
       }
       .rotation3DEffect(
           Angle.degrees(flipDegrees + flipHintDegrees),
           axis: (x: 0, y: 1, z: 0),
           perspective: 0.6
       )
   }

   // MARK: - Cross-fade opacity
   // Replaces binary < 90° threshold with a 12° overlap window.
   // Both faces are partially visible at 78°–90° where the card
   // is edge-on — the overlap is imperceptible at that angle.

   private var frontFaceOpacity: Double {
       Double(max(0, min(1, (90.0 - flipDegrees) / 12.0)))
   }

   private var backFaceOpacity: Double {
       Double(max(0, min(1, (flipDegrees - 78.0) / 12.0)))
   }

   // idleBackFaceOpacity — maze back face
   // Full opacity when face-down, fades as card rotates
   // toward front during entrance flip
   private var idleBackFaceOpacity: Double {
       Double(max(0, min(1, (flipDegrees - 78.0) / 12.0)))
   }

   // MARK: - Entrance

   private func startEntrance() {
       if reduceMotion {
           sceneOpacity     = 1
           cardOffsetY      = 0
           cardEntryOpacity = 1
           ghostOpacity     = 1
           arrowTriggered   = true
           return
       }

       // Scene fade
       withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
           sceneOpacity = 1
       }

       // Card rises slowly — user sees the back face
       withAnimation(.spring(response: 1.4, dampingFraction: 0.78).delay(0.3)) {
           cardOffsetY = 0
       }
       withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
           cardEntryOpacity = 1
       }

       // Float begins after card fully settles — user enjoys the back face
       DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
           startFloat()
           startGlowPulse()
       }

       // Float for 2 full cycles then auto-flip
       DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
           guard self.phase == .idle else { return }
           self.performAutoFlip()
       }
   }

   // MARK: - Float

   private func startFloat() {
       guard !reduceMotion else { return }
       isFloating = true
       tickFloat()
   }

   private func tickFloat() {
       guard isFloating, phase == .idle else {
           withAnimation(.easeOut(duration: 0.3)) { floatOffset = 0 }
           return
       }
       withAnimation(.easeInOut(duration: 3.0)) {
           floatOffset = floatOffset < -2 ? 0 : -4
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { tickFloat() }
   }

   private func stopFloat() {
       isFloating = false
       withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
           floatOffset = 0
       }
   }

   // MARK: - Glow Pulse

   private func startGlowPulse() {
       guard !reduceMotion else { return }
       tickGlowPulse()
   }

   private func tickGlowPulse() {
       guard phase == .idle, !hasBeenTapped else { return }
       withAnimation(.easeInOut(duration: 2.8)) {
           glowOpacity = glowOpacity < 0.7 ? 1.0 : 0.4
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
           tickGlowPulse()
       }
   }

   // MARK: - Auto-flip

   private func performAutoFlip() {
       guard phase == .idle else { return }
       phase = .flipping
       stopFloat()
       UIImpactFeedbackGenerator(style: .light).impactOccurred()

       withAnimation(.easeOut(duration: 0.4)) {
           ghostOpacity = 0
       }

       withAnimation(.spring(response: 0.58, dampingFraction: 0.84)) {
           flipDegrees = 0
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
           backRevealed = true
           phase        = .flipped
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
           withAnimation(.easeOut(duration: 0.35)) {
               self.questionVisible = true
           }
           // Ghost deck materializes as question appears
           withAnimation(.easeOut(duration: 1.56)) {
               self.ghostOpacity = 1
           }
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
           self.fuseBurnStartDate = Date()
           withAnimation(.easeIn(duration: 0.4)) {
               self.fuseVisible = true
           }
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
           guard self.phase == .flipped else { return }
           self.startShake()
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
           withAnimation(.easeOut(duration: 0.9)) {
               self.sitWithThisVisible = true
           }
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
           guard self.phase == .flipped, !self.pillsVisible else { return }
           withAnimation(.easeOut(duration: 0.6)) {
               self.tapHintVisible = true
           }
       }
   }

   private func startShake() {
       guard !reduceMotion else { return }
       let sequence: [(Double, Double)] = [
           (8,  0.55),
           (-6, 0.55),
           (4,  0.55),
           (-2, 0.55),
           (0,  0.55),
       ]
       var delay = 0.0
       for (angle, duration) in sequence {
           DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
               withAnimation(
                   .easeInOut(duration: duration)
               ) {
                   flipHintDegrees = angle
               }
           }
           delay += duration
       }
   }

   // MARK: - Flip

   private func handleCardTap() {
       guard phase == .flipped, !pillsVisible else { return }
       UIImpactFeedbackGenerator(style: .light).impactOccurred()
       withAnimation(.easeInOut(duration: 0.45)) {
           pillsVisible = true
           tapHintVisible = false
       }
   }

   // MARK: - Pill Selection

   private func handlePillSelected(_ pill: CardRevealPill) {
       guard phase == .flipped, selectedPill == nil else { return }
       selectedPill = pill
       phase        = .selected
       UIImpactFeedbackGenerator(style: .light).impactOccurred()

       ghostOpacity = 0

       // Beat 1 — immediate: selected pill breathes
       withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
           selectedPillScale = 1.06
       }

       // Beat 2 — t+500ms: border blooms
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           withAnimation(.easeInOut(duration: 0.3)) {
               selectedBorderWidth = 3.0
           }
           UIImpactFeedbackGenerator(style: .light).impactOccurred()
       }

       // Beat 3 — t+900ms: unselected pills sink
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
           withAnimation(.easeIn(duration: 0.35)) {
               unselectedPillsVisible = false
           }
       }

       // t+1.3s — card exits upward
       DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
           withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.45)) {
               cardExiting = true
           }
       }

       // t+1.65s — encouragement rises into vacated space
       DispatchQueue.main.asyncAfter(deadline: .now() + 1.65) {
           phase = .encouragement
           withAnimation(.easeOut(duration: 0.4)) {
               encouragementVisible = true
           }
       }
   }

   // MARK: - Typing complete → advance

   private func handleTypingComplete() {
       guard !hasAdvanced else { return }
       typingComplete = true
       DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
           commitAndAdvance()
       }
   }

   private func commitAndAdvance() {
       guard !hasAdvanced else { return }
       hasAdvanced         = true
       data.nmCardResponse = selectedPill?.rawValue
       phase               = .exiting

       withAnimation(.easeIn(duration: 0.5)) {
           exitingToNext = true
           sceneOpacity  = 0
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           onContinue?()
       }
   }

   // MARK: - Skip

   private func handleSkip() {
       fuseBurnProgress  = 0
       fuseBurnStartDate = nil
       fuseVisible   = false
       fuseCompleted = true
       flipHintActive  = false
       flipHintDegrees = 0
       tapHintVisible  = false
       guard phase == .idle, !hasAdvanced else { return }
       hasAdvanced         = true
       data.nmCardResponse = nil

       withAnimation(.easeIn(duration: 0.5)) {
           exitingToNext = true
           sceneOpacity  = 0
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           onContinue?()
       }
   }

   private func handleFuseComplete() {
       guard phase == .flipped, !fuseCompleted else { return }
       fuseCompleted = true
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
           self.startFlipHint()
       }
   }

   private func startFlipHint() {
       guard phase == .flipped || phase == .idle else { return }
       flipHintActive = true
       pulseFlipHint()
   }

   private func pulseFlipHint() {
       guard flipHintActive, phase == .idle else {
           flipHintDegrees = 0
           return
       }
       withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
           flipHintDegrees = 12
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
           withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
               self.flipHintDegrees = 0
           }
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
           self.pulseFlipHint()
       }
   }

   private func updateFuseProgress(at date: Date) {
       guard fuseVisible, !fuseCompleted,
             let start = fuseBurnStartDate else { return }
       let elapsed      = date.timeIntervalSince(start)
       fuseBurnProgress = min(elapsed / fuseDuration, 1.0)
       if fuseBurnProgress >= 1.0 { handleFuseComplete() }
   }
}

// MARK: - Card Front



// MARK: - Card Views
// CardFrontView and CardBackView have been extracted to Design/Components/Cards/

// MARK: - Card Back

// MARK: - Encouragement View
//
// Typewriter reveal at 38 cps using AttributedString — no Text + Text.
//
// Sequence:
//   1. Plain text types in body color
//   2. Accent types in a static single color (cyan dark / magenta light)
//      matching LivingText's leading gradient stop
//   3. Once accent is fully typed, LivingText crossfades in over the
//      static accent — the glow "wakes up" invisibly since both start
//      at the same leading color
//   4. Cursor ("|") blinks × 3 then fades
//   5. onComplete() fires → parent waits 900ms → commitAndAdvance()

private struct EncouragementView: View {

   let isLight:      Bool
   let active:       Bool
   let reduceMotion: Bool
   let selectedPill: CardRevealPill?
   let onComplete:   () -> Void

   private var plainText: String {
       selectionPhrase + " "
   }
   private let accentText = "You're in good company."
   private var fullText: String { plainText }

   // MARK: - Personalized Selection Phrase

   private var selectionPhrase: String {
       switch selectedPill {
       case .ready:      return "Knowing what you're ready for is rare."
       case .figuring:   return "Staying with the not-knowing takes courage."
       case .scared:     return "Naming what scares you is the harder move."
       case .almostSaid: return "Speaking what almost stayed silent matters."
       case .noApology:  return "That kind of honesty is what this is built for."
       case nil:         return "This journey asks a lot of the people it's meant for."
       }
   }

   private let charsPerSecond: Double = 18

   @State private var visibleCharCount:  Int    = 0
   @State private var cursorOn:          Bool   = true
   @State private var cursorDone:        Bool   = false
   @State private var accentFullyTyped:  Bool   = false
   @State private var livingTextOpacity: Double = 0
   @State private var livingTextOffsetY: CGFloat = 8
   @State private var typingTask: DispatchWorkItem? = nil

   var body: some View {
       VStack(spacing: 0) {
           Spacer()
           composedText
               .multilineTextAlignment(.center)
               .padding(.horizontal, 40)
           Spacer()
       }
       .frame(width: 300, height: 400)
       .onAppear   { if active { beginTyping() } }
       .onChange(of: active) { _, isActive in
           if isActive { beginTyping() }
       }
   }

   @ViewBuilder
   private var composedText: some View {
       VStack(spacing: 0) {
           // Plain sentence — typewriter until fully typed,
           // then static (cursor gone, accent has arrived)
           Text(buildAttributedString(
               plain:      String(plainText.prefix(visibleCharCount)),
               accent:     "",
               showCursor: !cursorDone && cursorOn
           ))
           .fixedSize(horizontal: false, vertical: true)
           .multilineTextAlignment(.center)

           // Accent — fades in all at once once plain is done.
           // opacity 0 until livingTextOpacity animates to 1.
           LivingText(
               text: accentText,
               font: AppFonts.body(20, weight: .bold)
           )
           .opacity(livingTextOpacity)
           .offset(y: livingTextOffsetY)
       }
   }

   private func buildAttributedString(
       plain:      String,
       accent:     String,
       showCursor: Bool
   ) -> AttributedString {
       // Plain portion
       var result = AttributedString(plain)
       result.font            = AppFonts.body(20, weight: .medium)
       result.foregroundColor = isLight ? AppColors.lightCardTitle : AppColors.textPrimary

       // Accent portion — single color matching LivingText's leading stop
       if !accent.isEmpty {
           var accentAttr = AttributedString(accent)
           accentAttr.font            = AppFonts.body(20, weight: .bold)
           accentAttr.foregroundColor = isLight ? AppColors.magenta : AppColors.cyan
           result.append(accentAttr)
       }

       // Cursor
       if showCursor {
           var cursor = AttributedString("|")
           cursor.font            = AppFonts.body(20, weight: .thin)
           cursor.foregroundColor = isLight ? AppColors.magenta : AppColors.cyan
           result.append(cursor)
       }

       return result
   }

   // MARK: Typing sequence

   private func beginTyping() {
       guard visibleCharCount == 0 else { return }

       if reduceMotion {
           visibleCharCount  = fullText.count
           accentFullyTyped  = true
           cursorDone        = true
           livingTextOpacity = 1
           livingTextOffsetY = 0
           onComplete()
           return
       }

       typeNextChar()
   }

   private func typeNextChar() {
       guard visibleCharCount < fullText.count else {
           blinkCursor(count: 0)
           return
       }

       let item = DispatchWorkItem {
           visibleCharCount += 1

           // Detect when plain text becomes fully visible
           if !accentFullyTyped && visibleCharCount == fullText.count {
               accentFullyTyped = true
               // Cursor fades out first (150ms), then LivingText arrives
               DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                   cursorDone = true
                   // Opacity and rise arrive together — easeOut so it
                   // decelerates into its final position, not springs
                   withAnimation(.easeOut(duration: 1.0)) {
                       livingTextOpacity  = 1
                       livingTextOffsetY  = 0
                   }
               }
           }

           typeNextChar()
       }
       typingTask = item
       DispatchQueue.main.asyncAfter(
           deadline: .now() + 1.0 / charsPerSecond,
           execute: item
       )
   }

   private func blinkCursor(count: Int) {
       guard count < 6 else {
           cursorOn   = false
           cursorDone = true
           withAnimation(.easeOut(duration: 1.0)) {
               livingTextOpacity = 1
           }
           DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
               onComplete()
           }
           return
       }
       DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
           cursorOn = !cursorOn
           blinkCursor(count: count + 1)
       }
   }
}

// MARK: - Previews

#Preview("Dark") {
   @Previewable @State var data = OnboardingData()
   ZStack {
       AppColors.pageBg.ignoresSafeArea()
       OnboardingAtmosphere(
           config:      .cardReveal,
           sparkConfig: .curiosityPickerView,
           opacity:     1.0
       )
       .ignoresSafeArea()
       OnboardingCardRevealView(data: $data, onContinue: {})
   }
   .preferredColorScheme(.dark)
}

#Preview("Light") {
   @Previewable @State var data = OnboardingData()
   ZStack {
       AppColors.lightPageBg.ignoresSafeArea()
       OnboardingAtmosphere(
           config:      .cardReveal,
           sparkConfig: .curiosityPickerView,
           opacity:     1.0
       )
       .ignoresSafeArea()
       OnboardingCardRevealView(data: $data, onContinue: {})
   }
   .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/Features/Onboarding/Views/OnboardingGroundRulesView.swift` {#file-open-lightly-features-onboarding-views-onboardinggroundrulesview-swift}

```swift
//Features/Onboarding/Views/OnboardingGroundRulesView.swift
//
// Screen 8: Before you dive in — honest framing of what this journey is and isn't.
// Must-acknowledge. No back button. No skipping.
// Writes data.groundRulesAcceptedAt, data.onboardingComplete, and data.completedAt
// on acknowledgment then calls onFinished.
//
// Layout strategy:
// - All devices use FlipPromiseCards — title front, detail back on tap
// - Card height scales: SE 72pt → mid 80pt → large 88pt
// - ScrollView with minHeight: fits without scroll on tall devices, scrolls on short ones

import SwiftUI

// MARK: - Main View

struct OnboardingGroundRulesView: View {
    @Binding var data: OnboardingData
    var onFinished: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion // ANIM-STD-31

    @State private var hasAnimated        = false
    @State private var atmosphereVisible  = false
    @State private var progressVisible    = false
    @State private var overlineVisible    = false
    @State private var subtextVisible     = false
    @State private var rulesVisible: Set<Int> = []
    @State private var frameVisible       = false
    @State private var ctaVisible         = false
    @State private var isPeeking          = false
    @State private var hasAcknowledged    = false

    // MARK: - Pill Data

    private struct PillContent: Identifiable {
        let id: Int
        let icon: String
        let iconBg: AnyShapeStyle
        let title: String
        let detail: String
    }

    private var pills: [PillContent] {
        let pill2: PillContent = data.explorationMode == .couple
            ? PillContent(
                id: 1,
                icon: "heart.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.orangeHot, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This works best when you're both curious.",
                detail: "If one of you is pushing and the other is being dragged, this will surface that faster than it resolves it. Come in open — both of you."
              )
            : PillContent(
                id: 1,
                icon: "figure.walk",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.orangeHot, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This won't resolve things you're running from.",
                detail: "The best it can do is help you understand what you're running toward."
              )
        return [
            PillContent(
                id: 0,
                icon: "lightbulb.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.magenta, AppColors.orangeHot],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "They say money shows you more of who you are.",
                detail: "This journey will do more of the same. The people who go deepest with it are the ones who surprise themselves."
            ),
            pill2,
            PillContent(
                id: 2,
                icon: "hand.raised.fill",
                iconBg: AnyShapeStyle(LinearGradient(
                    colors: [AppColors.magenta, AppColors.gold],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )),
                title: "This is not therapy, and it's not trying to be.",
                detail: "Not every journey into this territory requires clinical support — but if yours does, the resources are here whenever you need them."
            ),
        ]
    }

    // MARK: - Computed helpers

    private var isLight: Bool { colorScheme == .light }

    private var subheadSuffix: String {
        ", the most important questions about who you are and what you want rarely come with a roadmap — this was built to help you find your way."
    }

    private var subheadFallback: String {
        "The most important questions about who you are and what you want rarely come with a roadmap — this was built to help you find your way."
    }

    private var subheadTextColor: Color {
        isLight ? AppColors.lightCardTitle : AppColors.textPrimary
    }

    private var italicLineStyle: AnyShapeStyle {
        if isLight {
            return AnyShapeStyle(LinearGradient(
                stops: [
                    .init(color: AppColors.magenta,   location: 0.00),
                    .init(color: AppColors.orangeHot, location: 0.55),
                    .init(color: AppColors.gold,      location: 1.00),
                ],
                startPoint: .leading,
                endPoint: .trailing
            ))
        } else {
            return AnyShapeStyle(LinearGradient(
                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                startPoint: .leading,
                endPoint: .trailing
            ))
        }
    }

    // MARK: - Subhead View

    @ViewBuilder
    private func subheadView(h: CGFloat) -> some View {
        let font: Font = h < 700
            ? AppFonts.display(18)
            : h < 760
                ? AppFonts.display(20)
                : h < 820
                    ? AppFonts.display(21)
                    : AppFonts.screenTitle

        if data.displayName.isEmpty {
            Text(subheadFallback)
                .font(font)
                .foregroundStyle(subheadTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text("\(data.displayName)\(subheadSuffix)")
                .font(font)
                .foregroundStyle(subheadTextColor)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let w = geo.size.width
            let isCompact = h < 720
            let isMid     = h >= 720 && h < 760
            let cardPad: CGFloat = isCompact ? 12 : isMid ? 10 : 14
            let cardGap: CGFloat = isCompact
                ? OL.compact(h)
                : isMid
                    ? OL.compact(h) * 0.7
                    : OL.compact(h)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    contentBlock(
                        h: h, w: w,
                        isCompact: isCompact,
                        isMid: isMid,
                        cardPad: cardPad,
                        cardGap: cardGap
                    )
                    Spacer(minLength: 0)
                    ctaBlock(geo: geo)
                        .padding(.horizontal, 24)
                }
                .frame(minHeight: geo.size.height)
            }
            .safeAreaPadding(.bottom, 8)
            .background {
                ZStack {
                    Color.clear.ignoresSafeArea()
                    atmosphereLayer
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
                .ignoresSafeArea()
            }
            .accessibilityLabel("Before you dive in. Screen 8 of 8.")
            .accessibilityAction(named: "I'm ready") { handleAcknowledge() }
            .onAppear {
                guard !hasAnimated else { return }
                hasAnimated = true
                #if DEBUG
                if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                    atmosphereVisible = true
                    progressVisible   = true
                    overlineVisible   = true
                    subtextVisible    = true
                    rulesVisible      = [0, 1, 2]
                    frameVisible      = true
                    ctaVisible        = true
                    return
                }
                #endif
                startAnimation()
            }
        }
    }

    // MARK: - Content Block

    @ViewBuilder
    private func contentBlock(
        h: CGFloat,
        w: CGFloat,
        isCompact: Bool,
        isMid: Bool,
        cardPad: CGFloat,
        cardGap: CGFloat
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Progress bar
            OnboardingProgressBar(
                currentStep:          6,
                totalSteps:           6,
                progressDescription:  "Onboarding",
                showCompletionEffect: true
            )
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, isCompact
                ? OL.navTop(h) + OL.compact(h)
                : OL.navTop(h) + OL.standard(h))
            .padding(.bottom, isCompact
                ? OL.compact(h)
                : OL.standard(h))
            .opacity(progressVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.6), value: progressVisible)
            .accessibilityHidden(true)

            // Overline
            Group {
                if isLight {
                    Text("BEFORE YOU DIVE IN")
                        .font(AppFonts.overline)
                        .tracking(2)
                        .overlay(
                            LinearGradient(
                                stops: [
                                    .init(color: AppColors.magenta,   location: 0.00),
                                    .init(color: AppColors.orangeHot, location: 0.55),
                                    .init(color: AppColors.gold,      location: 1.00),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .mask(
                                Text("BEFORE YOU DIVE IN")
                                    .font(AppFonts.overline)
                                    .tracking(2)
                            )
                        )
                } else {
                    Text("BEFORE YOU DIVE IN")
                        .font(AppFonts.overline)
                        .foregroundStyle(AppColors.cyanLight)
                        .tracking(2)
                }
            }
            .opacity(overlineVisible ? 1 : 0) // ANIM-STD-32
            .scaleEffect(overlineVisible ? 1.0 : 0.95) // ANIM-STD-32
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: overlineVisible)
            .padding(.horizontal, 24)
            .padding(.bottom, OL.compact(h))
            .accessibilityHidden(true)

            // Headline
            subheadView(h: h)
                .opacity(subtextVisible ? 1 : 0) // ANIM-STD-32
                .scaleEffect(subtextVisible ? 1.0 : 0.95) // ANIM-STD-32
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: subtextVisible)
                .padding(.horizontal, 24)
                .padding(.bottom, isCompact
                    ? OL.compact(h)
                    : isMid
                        ? OL.compact(h)
                        : OL.standard(h))

            // Promise Cards — all devices use FlipPromiseCard
            VStack(spacing: cardGap) {
                ForEach(pills) { pill in
                    let isVisible = rulesVisible.contains(pill.id)
                    let cardView = FlipPromiseCard(
                        icon:         pill.icon,
                        iconGradient: pill.iconBg,
                        title:        pill.title,
                        detail:       pill.detail,
                        verticalPad:  cardPad,
                        cardHeight:   isCompact ? 72 : isMid ? 80 : 88
                    )
                    .opacity(isVisible ? 1 : 0) // ANIM-STD-33
                    .scaleEffect(isVisible ? 1.0 : 0.95) // ANIM-STD-33
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isVisible)
                    
                    if pill.id == 0 {
                        cardView
                            .rotation3DEffect(
                                .degrees(isPeeking ? 15 : 0),
                                axis: (x: 1, y: 0, z: 0),
                                perspective: 0.5
                            )
                    } else {
                        cardView
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.bottom, isCompact
                ? OL.compact(h)
                : isMid
                    ? OL.compact(h)
                    : OL.standard(h))
        }
        // NO Spacer, NO maxHeight frame, NO backgrounds
    }

    // MARK: - CTA Block

    private func ctaBlock(geo: GeometryProxy) -> some View {
        let h = geo.size.height
        let isCompact = h < 720
        let isMid = h >= 720 && h < 760
        let lifeguardFont: Font = isCompact
            ? AppFonts.body(16, weight: .medium)
            : isMid
                ? AppFonts.body(17, weight: .medium)
                : AppFonts.body(18, weight: .medium)
        return VStack(spacing: 0) {
            Text("Think of us as the lifeguard at the edge of the pool — not to keep you from the deep end, but to throw you a lifesaver if you need one.")
                .font(lifeguardFont)
                .italic()
                .foregroundStyle(italicLineStyle)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .opacity(frameVisible ? 1 : 0) // ANIM-STD-34
                .scaleEffect(frameVisible ? 1.0 : 0.95) // ANIM-STD-34
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: frameVisible)
                .padding(.horizontal, 24)
                .padding(.bottom, OL.compact(h))
            
            Text("When you're ready, we'll get started.")
                .font(AppFonts.caption)
                .foregroundStyle(isLight
                    ? AppColors.lightTextSecondary
                    : AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .opacity(ctaVisible ? 1 : 0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.82),
                    value: ctaVisible
                )
                .padding(.bottom, 16)
            
            HoloCTAButton(title: "I'm ready", isEnabled: true) {
                handleAcknowledge()
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 24)
            .opacity(ctaVisible ? 1 : 0)
            .animation(
                .spring(response: 0.5, dampingFraction: 0.82),
                value: ctaVisible
            )
        }
    }

    // MARK: - Atmospheric Layer

    private var atmosphereLayer: some View {
        GeometryReader { geo in
            ZStack {
                if isLight {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                AppColors.magenta.opacity(0.12),
                                AppColors.gold.opacity(0.06),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 20,
                            endRadius: 360
                        ))
                        .frame(
                            width:  OL.atmosW(geo.size.width),
                            height: OL.atmosH(geo.size.height)
                        )
                        .position(x: geo.size.width / 2, y: -20)
                        .blur(radius: 80)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                    Rectangle()
                        .fill(LinearGradient(
                            colors: [AppColors.purple.opacity(0.08), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(width: geo.size.width, height: 200)
                        .position(x: geo.size.width / 2, y: geo.size.height - 100)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                } else {
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                AppColors.purple.opacity(0.30),
                                AppColors.cyan.opacity(0.12),
                                Color.clear,
                            ],
                            center: .top,
                            startRadius: 20,
                            endRadius: 360
                        ))
                        .frame(
                            width:  OL.atmosW(geo.size.width),
                            height: OL.atmosH(geo.size.height)
                        )
                        .position(x: geo.size.width / 2, y: -20)
                        .blur(radius: 80)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)

                    Rectangle()
                        .fill(LinearGradient(
                            colors: [AppColors.magenta.opacity(0.08), Color.clear],
                            startPoint: .bottom,
                            endPoint: .top
                        ))
                        .frame(width: geo.size.width, height: 200)
                        .position(x: geo.size.width / 2, y: geo.size.height - 100)
                        .opacity(atmosphereVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 2.0), value: atmosphereVisible)
                }
            }
        }
    }

    // MARK: - Animation Timeline

    private func startAnimation() {
        // ANIM-STD-35: Reduce Motion fallback
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.2)) {
                atmosphereVisible = true
                progressVisible   = true
                overlineVisible   = true
                subtextVisible    = true
                rulesVisible      = [0, 1, 2]
                frameVisible      = true
                ctaVisible        = true
            }
            return
        }

        // ANIM-STD-36: Standardized three-slot spring cascade
        // Slot A (header — progress + overline + subtext): 0ms, 50ms, 100ms cascade
        // Slot B (body  — cards, staggered within slot):  100ms, 150ms, 200ms
        // Slot C (CTA   — lifeguard line + button):       300ms (after all cards visible)
        let spring = Animation.spring(response: 0.35, dampingFraction: 0.8)

        withAnimation(.easeInOut(duration: 2.0)) { atmosphereVisible = true }

        // Slot A — cascade the header elements
        withAnimation(spring) { progressVisible = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(spring) { overlineVisible = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(spring) { subtextVisible = true }
        }

        // Slot B — cards staggered within the 100ms slot window
        // Card 0 at 100ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(spring) { _ = rulesVisible.insert(0) }
        }
        // Card 1 at 150ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(spring) { _ = rulesVisible.insert(1) }
        }
        // Card 2 at 200ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(spring) { _ = rulesVisible.insert(2) }
        }

        // Slot C — CTA appears after all cards (300ms)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            withAnimation(spring) { frameVisible = true }
            withAnimation(spring) { ctaVisible = true }
        }

        // Peek effect — ambient, runs after entrance settles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { isPeeking = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isPeeking = false }
        }
    }

    // MARK: - Acknowledge

    private func handleAcknowledge() {
        guard !hasAcknowledged else { return }
        hasAcknowledged = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        data.groundRulesAcceptedAt = Date()
        data.onboardingComplete    = true
        data.completedAt           = Date()
        #if DEBUG
        assert(onFinished != nil,
            "OnboardingGroundRulesView: onFinished not injected — wire from coordinator.")
        #endif
        onFinished?()
    }
}

// MARK: - FlipPromiseCard

private struct FlipPromiseCard: View {
    let icon:         String
    let iconGradient: AnyShapeStyle
    let title:        String
    let detail:       String
    var verticalPad:  CGFloat = 8
    var cardHeight:   CGFloat = 72

    @State private var isFlipped = false
    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                iconBadge
                Text(title)
                    .font(AppFonts.bodyMedium)
                    .foregroundStyle(isLight ? AppColors.lightCardTitle : AppColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                Image(systemName: "arrow.turn.up.left")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isLight
                        ? AppColors.lightTextTertiary
                        : AppColors.textTertiary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, verticalPad)
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(isFlipped ? 180 : 0),
                axis: (x: 0, y: 1, z: 0)
            )

            Text(detail)
                .font(AppFonts.caption)
                .foregroundStyle(isLight ? AppColors.lightCardDetail : AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, verticalPad)
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(maxWidth: .infinity, minHeight: cardHeight)
        .cardSurface(isLight: isLight)
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped.toggle()
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFlipped ? detail : title)
        .accessibilityHint(isFlipped ? "Tap to show title" : "Tap to read more")
        .accessibilityAddTraits(.isButton)
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    isLight
                        ? iconGradient
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan.opacity(0.20), AppColors.purple.opacity(0.16)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
                .opacity(isLight ? 0.18 : 1.0)
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    isLight
                        ? AnyShapeStyle(LinearGradient(
                            stops: [
                                .init(color: AppColors.magenta,   location: 0.00),
                                .init(color: AppColors.orangeHot, location: 0.55),
                                .init(color: AppColors.gold,      location: 1.00),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                        : AnyShapeStyle(LinearGradient(
                            colors: [AppColors.cyan, AppColors.purple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                          ))
                )
        }
        .frame(width: 32, height: 32)
        .fixedSize()
        .accessibilityHidden(true)
    }
}

// MARK: - Card Surface

private struct CardSurface: ViewModifier {
    let isLight: Bool
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isLight ? AppColors.lightCardFill : Color.white.opacity(0.05))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: AppColors.magenta.opacity(isLight ? 0.07 : 0),
                radius: 8, x: 0, y: 2
            )
            .modifier(PromiseCardBorder(isLight: isLight))
    }
}

private extension View {
    func cardSurface(isLight: Bool) -> some View {
        modifier(CardSurface(isLight: isLight))
    }
}

// MARK: - PromiseCardBorder

private struct PromiseCardBorder: ViewModifier {
    let isLight: Bool
    func body(content: Content) -> some View {
        if isLight {
            content
                .magentaGoldBorder(cornerRadius: 20, lineWidth: 1.5, glowRadius: 3, opacity: 0.55)
        } else {
            content
                .pillBorder(cornerRadius: 20, lineWidth: 1, glowRadius: 3, opacity: 0.45)
        }
    }
}

// MARK: - Previews

#Preview("Dark") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .groundRules,
            sparkConfig: .groundRulesView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingGroundRulesView(data: $data, onFinished: {})
    }
    .preferredColorScheme(.dark)
}

#Preview("Light") {
    @Previewable @State var data: OnboardingData = {
        var d = OnboardingData()
        d.displayName     = "Jordan"
        d.explorationMode = .solo
        return d
    }()
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        OnboardingAtmosphere(
            config: .groundRules,
            sparkConfig: .groundRulesView,
            opacity: 1.0
        )
        .ignoresSafeArea()
        OnboardingGroundRulesView(data: $data, onFinished: {})
    }
    .preferredColorScheme(.light)
}

```

---

## File: `Open Lightly/App/Theme/AppColors.swift` {#file-open-lightly-app-theme-appcolors-swift}

```swift
//
//  AppColors.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&int) else {
            self = .black
            return
        }
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            self = .black
            return
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ──────────────────────────────────────────────
// AppColors.swift
// Open Lightly
//
// Design System: Hot Border × Clash Display × Gradient Keywords
// Card intensity scales 1–8 with prompt difficulty
// ──────────────────────────────────────────────────────

// MARK: - App Colors

struct AppColors {

    // ─────────────────────────────────────────────
    // MARK: Core Spectrum
    // The 3 anchor colors — used for borders,
    // gradient text highlights, glows
    // Gradient direction: 135° (top-left -> bottom-right)
    // ─────────────────────────────────────────────

    static let cyan       = Color(hex: "00C2FF")
    static let purple     = Color(hex: "6C3AE0")
    static let magenta    = Color(hex: "FF006A")

    /// Soft magenta variant — used in shimmer gradients and atmospheric fills
    static let pink       = Color(hex: "FF2D8A")

    /// Deep atmospheric blue — used in glow field floor washes
    static let deepBlue   = Color(hex: "0078FF")

    /// Violet — between purple and blue, used in warm-tier pill gradients
    static let violet = Color(hex: "7C3AED")
    static let electricViolet = Color(hex: "8B5CF6")
    
    
    /// Electric purple — vivid gradient midpoint, LivingText only
    static let purpleVivid = Color(hex: "9333EA")
    
    static let purpleBright = Color(hex: "C084FC")

    // Lighter variants — gradient text on keywords, badges
    static let cyanLight    = Color(hex: "4DD8FF")
    static let purpleLight  = Color(hex: "A78BFA")
    static let magentaLight = Color(hex: "FF4D94")

    // Darker variants — tinted backgrounds, deep accents
    static let cyanDark    = Color(hex: "0891B2")
    static let purpleDark  = Color(hex: "1A1A5E")
    static let magentaDark = Color(hex: "BE185D")

    // ─────────────────────────────────────────────
    // MARK: Backgrounds
    // Page -> Card -> Surface (lightest)
    // ─────────────────────────────────────────────

    /// Main app background
    static let pageBg = Color(hex: "030305")

    /// Default card interior (levels 1–4)
    // DARK-FILL-FIX: was #050507 — only 2/255 delta from pageBg.
    // At disabled opacity 0.45 the button was invisible.
    // #12111A holds shape identity at 0.45 while staying dark.
    static let cardBg = Color(hex: "12111A")

    /// Elevated surfaces, sheets, modals
    // DARK-FILL-FIX: was #08080C — 5/255 delta from pageBg.
    // Invisible at 0.45 opacity. #1A1825 holds pill shape.
    static let surfaceBg = Color(hex: "1A1825")

    /// Slightly raised elements (input fields, etc)
    static let surfaceRaised = Color(hex: "0C0C10")

    // Tinted card backgrounds (for intensity levels 5–8)
    static let tintCyan    = Color(hex: "061018")
    static let tintPurple  = Color(hex: "080614")
    static let tintMagenta = Color(hex: "120610")
    static let tintNavy    = Color(hex: "0A1018")
    static let tintIndigo  = Color(hex: "0A0820")
    static let tintPlum    = Color(hex: "180818")

    // Supernova (ultimate) gradient layers — deepest possible darks
    static let tintSupernovaA = Color(hex: "081420")
    static let tintSupernovaB = Color(hex: "0C0624")
    static let tintSupernovaC = Color(hex: "1A0620")
    static let tintSupernovaD = Color(hex: "1C0818")

    // ─────────────────────────────────────────────
    // MARK: Text
    // ─────────────────────────────────────────────

    /// Primary text — prompt content, headings
    static let textPrimary   = Color(hex: "E8E8F0")

    /// Secondary text — descriptions, labels
    static let textSecondary = Color(hex: "AAAABC")

    /// Tertiary text — timestamps, meta
    static let textTertiary  = Color(hex: "666680")

    /// Quaternary text — pronoun hint, subtle placeholders
    static let textQuaternary = Color(red: 0.42, green: 0.42, blue: 0.50)

    /// Muted text — disabled states, subtle hints
    static let textMuted     = Color.white.opacity(0.20)

    /// Bright near-white for small labels that need to survive
    /// a purple-tinted ambient background (status strip counts,
    /// overline labels, etc). Device-absolute — cannot be tinted.
    static let textBright = Color(white: 0.90)

    /// Muted body text — sublabels inside cards.
    /// Use when textSecondary reads below threshold on deep backgrounds.
    static let textMutedBody = Color(white: 0.62)

    /// Badge/tag text
    static let textBadge     = Color(hex: "5BB8CC")

    // ─────────────────────────────────────────────
    // MARK: Borders
    // ─────────────────────────────────────────────

    /// Default subtle border
    static let border        = Color.white.opacity(0.06)

    /// Hover/active border
    static let borderHover   = Color.white.opacity(0.10)

    /// Prominent border
    static let borderActive  = Color.white.opacity(0.15)

    // ─────────────────────────────────────────────
    // MARK: UI Elements
    // ─────────────────────────────────────────────

    /// Badge background
    static let badgeBg       = cyan.opacity(0.08)

    /// Ghost button border
    static let btnGhostBorder = Color.white.opacity(0.06)

    /// Ghost button text
    static let btnGhostText   = Color(hex: "444444")

    /// Toggle / switch active
    static let toggleActive   = cyan

    /// Destructive / warning
    static let destructive    = Color(hex: "FF4444")

    /// Success / confirmed
    static let success        = Color(hex: "00CC88")

    /// Off-spectrum utility — safety only (safe word, hard no, cool off)
    /// Gold usage rule:
    /// At full or near-full opacity: safety signals only
    /// (safe word button, warnings, hard stop actions).
    /// Never decorative at visible opacity.
    /// Aurora atmospheric use at ≤8% opacity is acceptable
    /// because it cannot be read as a directional signal
    /// at that opacity level. If it is visible enough to be
    /// noticed as gold, it is too opaque for non-safety use.
    static let gold       = Color(hex: "C8960A")
    static let goldLight  = Color(hex: "E2B93B")
    static let goldDark   = Color(hex: "8B6914")
    static let glowGold   = gold
    // ── Warm Amber — Light Mode Progress Bar ──────────────────────────
    // Used in OnboardingProgressBar fill and bloom layers in light mode only.
    // Source: HTML section 9A stat gradient — #E07020 "amber" stop.
    // Do NOT use these in aurora blobs — those use gold (#C8960A).
    /// Hot orange-amber — bright fill leading stop and bloom core
    static let orangeHot  = Color(hex: "E07020")
    /// Deep orange-amber — fill trailing anchor and bloom atmosphere
    static let orangeDeep = Color(hex: "C8710A")
    // ────

    /// Glow aliases — reference the canonical spectrum tokens
    static let glowCyan    = cyan
    static let glowMagenta = magenta
    static let glowPurple  = purple

    /// Shadow colors
    static let shadowDeep  = Color.black.opacity(0.50)
    static let shadowLight = Color.black.opacity(0.25)

    // ─────────────────────────────────────────────
    // MARK: Gradients
    // ─────────────────────────────────────────────

    /// Card border gradient — the "Hot Border"
    /// Used on every prompt card at full opacity
    static let spectrumBorder = LinearGradient(
        colors: [cyan, purple, magenta],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Keyword highlight gradient — applied to select words
    /// Use with .foregroundStyle() on Text views
    static let spectrumText = LinearGradient(
        colors: [cyan, purpleLight, magenta],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Primary button fill — subtle gradient
    static let btnPrimaryFill = LinearGradient(
        colors: [
            cyan.opacity(0.12),
            magenta.opacity(0.10)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Max-intensity CTA — used sparingly (level 8, special)
    static let btnMaxFill = LinearGradient(
        colors: [cyan, purple, magenta],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Top-edge ambient wash (cards level 2+)
    static let topCyanWash = LinearGradient(
        colors: [
            cyan.opacity(0.04),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .center
    )

    // MARK: - Canonical Aliases (Batch 6 spec)
    static var card: Color { cardBg }
    static var background: Color { pageBg }
    static var cardElevated: Color { surfaceRaised }

    // MARK: - Spectrum Gradient (Batch 6 spec)
    static var spectrumGradient: LinearGradient {
        LinearGradient(
            colors: [cyan, purple, magenta],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // ─────────────────────────────────────────────
    // MARK: Light Mode — Warm Aurora
    //
    // Background: #F8F6EE (warm cream — never change)
    // Aurora palette: Magenta / Purple / Gold — no cyan
    // All tokens prefixed with light* or aurora* to
    // prevent any collision with dark mode tokens.
    // ─────────────────────────────────────────────

    // Backgrounds
    /// Warm cream — the one true light mode page background
    static let lightPageBg    = Color(hex: "F8F6EE")

    /// Pure white — card interiors lift off the cream naturally
    static let lightCardBg    = Color(hex: "FFFFFF")

    /// Inset fields — slightly deeper than page, clearly recessed
    static let lightSurfaceBg = Color(hex: "F2EFE6")

    // Text
    /// Near-black — primary headings and body on cream
    static let lightTextPrimary   = Color(hex: "1A1A1E")

    /// Mid-tone label text on cream — labels, descriptions.
    /// Opaque equivalent of Color(hex:"1A1A1E").opacity(0.50) on #F8F6EE.
    static let lightTextSecondary = Color(hex: "8C8C94")

    /// Subtle meta text on cream — timestamps, hints, tertiary labels.
    /// Opaque equivalent of Color(hex:"1A1A1E").opacity(0.30) on #F8F6EE.
    static let lightTextTertiary  = Color(hex: "B3B3BA")

    // Borders
    /// Default subtle border on cream surfaces
    static let lightBorder      = Color.black.opacity(0.06)

    /// Hover / focus border on cream surfaces
    static let lightBorderHover = Color.black.opacity(0.10)

    // Frosted glass fills
    // Used with .background + backdrop blur in SwiftUI.
    // These are NOT opaque — the aurora bleeds through intentionally.
    /// Glass card fill — 58% white over aurora
    // OPACITY-FIX: was Color.white.opacity(0.58)
    static let lightFrostCard    = Color(red: 0.989, green: 0.985, blue: 0.972)

    /// Pill fill — unselected state on cream
    // OPACITY-FIX: was Color.white.opacity(0.55) — semi-transparent
    // whites multiply with container opacity causing pills to vanish
    // at disabled 0.45. Opaque equivalent preserves identical appearance
    // at full opacity and holds at any container opacity.
    // TINT-FIX: was (0.988, 0.984, 0.970) near-white — shimmer had nothing
    // to push against. Now a soft lavender-blush sits visibly on
    // lightPageBg (#F8F6EE). Parallel role to surfaceBg (#1A1825) in dark.
    // PILL-FILL-FIX: was (0.945, 0.925, 0.960) — near-white, indistinguishable
    // from lightPageBg (#F8F6EE). Shimmer had nothing to push against.
    // Now a visible lavender — parallel role to surfaceBg (#1A1825) in dark mode.
    // The shimmer sweeps over this tinted base the same way HolographicShimmer
    // sweeps over the deep purple surfaceBg.
    static let lightFrostPill    = Color(red: 0.910, green: 0.875, blue: 0.945)

    /// Selected pill fill — slightly more opaque for legibility
    // PILL-FILL-FIX: was (0.950, 0.922, 0.968) — barely distinguishable from
    // lightFrostPill. Selected state had no visual lift over unselected.
    // Now a visible rose-blush — selected reads richer and warmer than unselected.
    // Contrast between selected/unselected mirrors dark mode's surfaceBg delta.
    static let lightFrostPillSel = Color(red: 0.958, green: 0.875, blue: 0.925)

    // MARK: - Pill Tokens

    /// Unselected pill interior — dark mode.
    /// Sits ~15% brighter than cardBg so pill labels have a
    /// contrast floor against the purple ambient atmosphere.
    static let pillSurface = Color(red: 0.10, green: 0.09, blue: 0.16)
    static let pillSurfaceBottom = Color(red: 0.08, green: 0.07, blue: 0.13)

    /// Selected pill interior tint multiplier base.
    /// View applies .opacity() on top of this.
    static let pillSurfaceSelected = Color(red: 0.051, green: 0.043, blue: 0.122)

    /// Ambient lift shadow applied to every pill in dark mode.
    /// Keeps pills visually separated from the background without
    /// a directional light source.
    static let pillGlow = Color(white: 1.0).opacity(0.04)

    /// CTA button fill — frosted, never fully opaque
    // OPACITY-FIX: was Color.white.opacity(0.70)
    static let lightFrostCTA     = Color(red: 0.992, green: 0.990, blue: 0.980)

    /// CTA button base fill — opaque rose so button reads
    /// correctly at both full and 0.45 disabled opacity.
    /// Harmonises with LightModeShimmer's purple/magenta/gold tints.
    static let lightCTAFill      = Color(red: 0.98, green: 0.91, blue: 0.93)

    // Floating label colors
    /// Focused floating label — magentaDark reads well on cream, still spectrum
    static let lightLabelFocused  = magentaDark  // #BE185D

    /// Hint text — "so we get it right", helper copy
    // TODO: replace with opaque equivalent
    static let lightHintText      = magentaDark.opacity(0.50)

    // Aurora atmosphere blobs
    // Four colors that pool in corners behind frosted cards.
    // Opacity intentionally low — these are felt, not seen.
    static let auroraBlob1 = magenta.opacity(0.09)    // magenta — top right
    static let auroraBlob2 = purple.opacity(0.08)     // purple  — bottom left
    static let auroraBlob3 = gold.opacity(0.07)       // gold at 7% — below signal threshold, atmospheric use only. See gold usage rule above.
    static let auroraBlob4 = pink.opacity(0.06)       // pink    — mid left

    // Aurora shadow spread
    // On light surfaces, shadow IS the glow.
    // These replace the cyan/magenta bloom shadows from dark mode.
    static let lightShadowMagenta = magenta.opacity(0.18)
    static let lightShadowPurple  = purple.opacity(0.12)
    static let lightShadowGold    = gold.opacity(0.07)

    // MARK: - Light Mode Card Text
    // Warm wine-toned text tokens for OnboardingGroundRulesView cards.
    // Used for card title and detail body on rose-blush fill in light mode only.

    /// Dark rose — deep wine for headlines on rose fill (#3D1A26)
    static let lightHeadlineDarkRose = Color(red: 0.24, green: 0.10, blue: 0.15)

    /// Wine dark — card title on rose fill (#5C1F35)
    static let lightCardTitle  = Color(red: 0.36, green: 0.12, blue: 0.21)

    /// Mid wine — card detail body on rose fill (#7A2D45)
    static let lightCardDetail = Color(red: 0.478, green: 0.176, blue: 0.271)

    /// Icon badge background — magenta tint (18% opacity)
    static let lightIconBgMagenta = Color(red: 1.00, green: 0.00, blue: 0.42).opacity(0.18)

    /// Icon badge background — orangeHot tint (14% opacity)
    static let lightIconBgOrange  = Color(red: 1.00, green: 0.30, blue: 0.00).opacity(0.14)

    /// Icon badge background — gold tint (14% opacity)
    static let lightIconBgGold    = Color(red: 0.78, green: 0.59, blue: 0.04).opacity(0.14)

    /// Card fill — barely blush (#FFF4F6)
    static let lightCardFill = Color(red: 1.0, green: 0.957, blue: 0.965)

    static let lightFrostPillCustom = Color(red: 0.868, green: 0.848, blue: 0.908)
    /// Card shadow — warm amber mid
    static let lightCardShadowMagenta = Color(red: 0.78, green: 0.39, blue: 0.20)

    /// Card shadow — warm orange
    static let lightCardShadowOrange  = Color(red: 1.00, green: 0.39, blue: 0.20)

    /// Wine dark — unselected pill / CTA label on light surfaces (#703040)
    static let wineDark = Color(red: 0.44, green: 0.07, blue: 0.18)

    // ─────────────────────────────────────────────
    // MARK: Universal Gradient Border
    //
    // One gradient border used on ALL screens in both
    // dark and light mode. Replaces per-mode branching
    // on borders — the gradient works on both surfaces.
    //
    // Dark:  full spectrum (cyan → purple → magenta)
    // Light: warm aurora  (purple → magenta → gold)
    //        No cyan — cyan reads too clinical on cream.
    //
    // Usage: .pillBorder() calls this via PillBorder.swift
    //        .warmAuroraBorder() calls the light variant
    //        Both live in PillBorder.swift
    // ─────────────────────────────────────────────

    /// Light mode border gradient — warm aurora
    /// purple → magentaLight → gold, topLeading → bottomTrailing
    /// Matches the aurora atmosphere palette exactly
    static let warmAuroraBorder = LinearGradient(
        colors: [purple, magenta, gold],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Light mode gradient text — for "acquainted." and keyword highlights
    /// purple → purpleLight → magentaLight
    /// Stays within the purple-original blend, warm but not jarring on cream
    static let warmAuroraText = LinearGradient(
        colors: [purple, purpleLight, magentaLight],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Light mode shimmer sweep colors — used in LightModeShimmer.swift
    /// Same warm palette at low opacity — not the full spectrum blast
    static let lightShimmerColors: [Color] = [
        purple.opacity(0.22),
        magenta.opacity(0.20),
        gold.opacity(0.18),
        magenta.opacity(0.18),
        purple.opacity(0.22),
    ]

    // lightPillShimmerColors — higher opacity than
    // lightShimmerColors. Used on interactive surfaces
    // (selected pills, active input borders) where the
    // shimmer needs to be as visible as HolographicShimmer
    // is in dark mode. lightShimmerColors remains unchanged
    // for background wash usage.
    static let lightPillShimmerColors: [Color] = [
        AppColors.magenta.opacity(0.50),
        AppColors.gold.opacity(0.55),
        AppColors.magenta.opacity(0.45),
        AppColors.goldLight.opacity(0.50),
        AppColors.magenta.opacity(0.50),
    ]

    // ─────────────────────────────────────────────
    // MARK: Light-mode surface tokens
    // ─────────────────────────────────────────────

    /// Slightly off-white field background for light mode.
    /// Sits above cardSurfaceLight without blending in.
    /// Parallel to dark-mode kFieldBG = white.opacity(0.07).
    static let fieldBgLight     = Color.white.opacity(0.82)

    /// Structural 1pt border for cards and fields in light mode.
    /// opacity(0.14) mirrors LivingText static shadow opacity(0.18) —
    /// visual weight matches LT-G-03: structural, not atmospheric.
    static let borderLight      = purple.opacity(0.14)

    /// Frosted white lift for the glass card surface in light mode.
    /// 0.72 lets the light atmosphere ellipse breathe through without
    /// muddying field fills inside the card.
    static let cardSurfaceLight = Color.white.opacity(0.72)

    /// Semantic blue — used in dark-mode atmosphere ellipse gradient.
    static let blue             = Color.blue
}

// MARK: - ──────────────────────────────────────────────
// Card Intensity System
// Maps prompt difficulty -> visual intensity
// ──────────────────────────────────────────────────────

enum CardIntensity: Int, CaseIterable, Identifiable {
    case void        = 1
    case deepOcean   = 2
    case emberFloor  = 3
    case split       = 4
    case nebula      = 5
    case auroraBand  = 6
    case deepSpace   = 7
    case supernova   = 8

    var id: Int { rawValue }

    // ─────────────────────────────────────────────
    // MARK: Mapping from prompt data
    // ─────────────────────────────────────────────

    static func from(difficulty: String) -> CardIntensity {
        switch difficulty.lowercased() {
        case "easy":        return .void
        case "light":       return .deepOcean
        case "medium":      return .split
        case "deep":        return .nebula
        case "sensitive":   return .deepSpace
        case "ultimate":    return .supernova
        default:            return .deepOcean
        }
    }

    static func from(score: Int) -> CardIntensity {
        switch score {
        case 1...2:  return .void
        case 3:      return .deepOcean
        case 4:      return .emberFloor
        case 5:      return .split
        case 6:      return .nebula
        case 7:      return .auroraBand
        case 8:      return .deepSpace
        case 9...10: return .supernova
        default:     return .deepOcean
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Background
    // ─────────────────────────────────────────────

    var backgroundColor: Color {
        switch self {
        case .void, .deepOcean, .emberFloor, .split, .auroraBand:
            return AppColors.cardBg
        case .nebula:
            return AppColors.tintCyan
        case .deepSpace:
            return AppColors.tintNavy
        case .supernova:
            return AppColors.tintIndigo
        }
    }

    var backgroundGradient: LinearGradient? {
        switch self {
        case .void, .deepOcean, .emberFloor, .split, .auroraBand:
            return nil
        case .nebula:
            return LinearGradient(
                colors: [AppColors.tintCyan, AppColors.tintPurple, AppColors.tintMagenta],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .deepSpace:
            return LinearGradient(
                colors: [AppColors.tintNavy, AppColors.tintIndigo, AppColors.tintPlum],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .supernova:
            return LinearGradient(
                colors: [
                    AppColors.tintSupernovaA,
                    AppColors.tintSupernovaB,
                    AppColors.tintSupernovaC,
                    AppColors.tintSupernovaD
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var usesGradientBackground: Bool {
        rawValue >= 5
    }

    // ─────────────────────────────────────────────
    // MARK: Radial Wash Overlays
    // ─────────────────────────────────────────────

    var cyanWash: (x: CGFloat, y: CGFloat, opacity: Double)? {
        switch self {
        case .void:         return nil
        case .deepOcean:    return (x: 0.0, y: 1.0, opacity: 0.08)
        case .emberFloor:   return nil
        case .split:        return (x: 0.1, y: 0.0, opacity: 0.07)
        case .nebula:       return (x: 0.15, y: 0.2, opacity: 0.06)
        case .auroraBand:   return nil
        case .deepSpace:    return (x: 0.2, y: 0.1, opacity: 0.08)
        case .supernova:    return (x: 0.1, y: 0.0, opacity: 0.10)
        }
    }

    var magentaWash: (x: CGFloat, y: CGFloat, opacity: Double)? {
        switch self {
        case .void, .deepOcean: return nil
        case .emberFloor:       return (x: 0.5, y: 1.1, opacity: 0.09)
        case .split:            return (x: 0.9, y: 1.0, opacity: 0.06)
        case .nebula:           return (x: 0.85, y: 0.8, opacity: 0.05)
        case .auroraBand:       return nil
        case .deepSpace:        return (x: 0.8, y: 0.9, opacity: 0.07)
        case .supernova:        return (x: 0.9, y: 1.0, opacity: 0.09)
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Glow / Shadow
    // ─────────────────────────────────────────────

    var glowRadius: CGFloat {
        switch self {
        case .void, .deepOcean, .emberFloor:  return 30
        case .split, .nebula, .auroraBand:    return 40
        case .deepSpace:                       return 45
        case .supernova:                       return 60
        }
    }

    var glowMultiplier: Double {
        switch self {
        case .void:        return 0.6
        case .deepOcean:   return 0.8
        case .emberFloor:  return 0.8
        case .split:       return 0.9
        case .nebula:      return 1.0
        case .auroraBand:  return 0.9
        case .deepSpace:   return 1.1
        case .supernova:   return 1.3
        }
    }

    var cyanGlowOpacity: Double    { 0.08 * glowMultiplier }
    var magentaGlowOpacity: Double { 0.06 * glowMultiplier }

    // ─────────────────────────────────────────────
    // MARK: Display Helpers
    // ─────────────────────────────────────────────

    var displayName: String {
        switch self {
        case .void:        return "Void"
        case .deepOcean:   return "Deep Ocean"
        case .emberFloor:  return "Ember Floor"
        case .split:       return "Split"
        case .nebula:      return "Nebula"
        case .auroraBand:  return "Aurora Band"
        case .deepSpace:   return "Deep Space"
        case .supernova:   return "Supernova"
        }
    }

    var difficultyLabel: String {
        switch self {
        case .void, .deepOcean:         return "Easy"
        case .emberFloor, .split:       return "Medium"
        case .nebula, .auroraBand:      return "Deep"
        case .deepSpace:                return "Sensitive"
        case .supernova:                return "Ultimate"
        }
    }
}

```

---

## File: `Open Lightly/App/Theme/AppFonts.swift` {#file-open-lightly-app-theme-appfonts-swift}

```swift
//  AppFonts.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

struct AppFonts {
    // MARK: - Display Font (Clash Display)
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        switch weight {
        case .bold:
            return Font.custom("ClashDisplay-Bold", size: size)
        case .semibold:
            return Font.custom("ClashDisplay-Semibold", size: size)
        case .medium:
            return Font.custom("ClashDisplay-Medium", size: size)
        default:
            assertionFailure(
                "AppFonts.display: unsupported weight \(weight). " +
                "Supported: .bold, .semibold, .medium"
            )
            return Font.custom("ClashDisplay-Bold", size: size)
        }
    }

    // MARK: - Body Font (Switzer)
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .regular:
            return Font.custom("Switzer-Regular", size: size)
        case .medium:
            return Font.custom("Switzer-Medium", size: size)
        case .semibold:
            return Font.custom("Switzer-Semibold", size: size)
        case .bold:
            return Font.custom("Switzer-Bold", size: size)
        default:
            return Font.system(size: size, weight: .regular, design: .default)
        }
    }

    // MARK: - Semantic Tokens

    // --- Display Scale (Clash Display) ---
    static var heroTitle: Font           { display(42, weight: .bold) }           // 42pt Bold
    static var displayHero: Font         { display(64, weight: .bold) }           // 64pt Bold
    static var scoreDisplay: Font        { display(32, weight: .bold) }           // 32pt Bold
    static var screenTitle: Font         { display(24, weight: .semibold) }       // 24pt Semibold
    static var cardTitle: Font           { display(22, weight: .semibold) }       // 22pt Semibold
    static var sectionHeading: Font      { display(20, weight: .medium) }         // 20pt Medium
    static var sectionLabelSmall: Font   { display(13, weight: .medium) }         // 13pt Medium
    static var prompt: Font              { display(17, weight: .medium) }         // 17pt Medium
    static var promptHighlight: Font     { display(17, weight: .semibold) }       // 17pt Semibold

    // --- Body Scale (Switzer) ---
    static var ctaLabel: Font            { body(16, weight: .semibold) }          // 16pt Semibold
    static var bodyText: Font            { body(16, weight: .regular) }           // 16pt Regular
    static var bodyMedium: Font          { body(15, weight: .medium) }            // 15pt Medium
    static var buttonLabel: Font         { body(14, weight: .semibold) }          // 14pt Semibold
    static var caption: Font             { body(13, weight: .regular) }           // 13pt Regular
    static var overline: Font            { body(11, weight: .semibold) }          // 11pt Semibold
    static var buttonLabelSmall: Font    { body(11, weight: .medium) }            // 11pt Medium
    static var tabLabel: Font            { body(10, weight: .medium) }            // 10pt Medium
    static var label: Font               { body(10, weight: .semibold) }          // 10pt Semibold
    static var badge: Font               { body(10, weight: .medium) }            // 10pt Medium
    static var meta: Font                { body(10, weight: .regular) }           // 10pt Regular

    // MARK: - Debug Font List
    static func debugFontList() {
        for family in UIFont.familyNames.sorted() {
            print("\n\(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  \(name)")
            }
        }
    }
}

```

---

