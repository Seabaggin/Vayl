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
        case (.couple, .notTalked):      return .coupleNotTalkedConfig
        case (.couple, .talking):        return .coupleTalkingConfig
        case (.couple, .someExperience): return .coupleSomeExperienceConfig
        case (.couple, .needsReset):     return .coupleNeedsResetConfig
        default:                         return .browsingConfig
        }
    }
}

// MARK: - Static Config Instances

extension CuriosityScreenConfig {

    // MARK: Solo — Single

    static let soloSingleConfig = CuriosityScreenConfig(
        section1Label:    "What's been on your mind?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "desire_unknown",      label: "I don't know what I actually want",               isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "pattern_recognition", label: "I keep ending up in the same place",              isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "initiating",          label: "I wouldn't know how to ask for it",               isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "self_awareness",      label: "My reactions in intimacy surprise me sometimes",  isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "situationship",       label: "I'm in something I can't quite read",             isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "desire_language",       label: "What I want — not what I've accepted",                                   isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "attachment",            label: "Why I respond to people the way I do",                                   isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "cnm_style_discovery",   label: "I'm curious whether non-monogamy could be right for me",                 isEmphasized: false, contentType: .quiz(.cnmStyleDiscovery)),
            CuriosityOption(id: "desire_map",            label: "I want to map my own desires before anything else",                      isEmphasized: false, contentType: .desireMap),
            CuriosityOption(id: "jealousy_history",      label: "I've felt jealousy in past relationships and want to understand it",     isEmphasized: false, contentType: .reflectionTrack),
            CuriosityOption(id: "consent_self_advocacy", label: "What it actually means to ask for what I want",                          isEmphasized: false, contentType: .educationTrack),
        ],
        showSection2: true
    )

    // MARK: Solo — Partnered Open (Partner Knows)

    static let soloPartneredOpenConfig = CuriosityScreenConfig(
        section1Label:    "What are you two working on?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "desire_mismatch", label: "We want different things sexually",          isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "initiating",      label: "I don't know how to start the conversation", isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "reconnection",    label: "We've lost some of our connection",          isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "jealousy_stuck",  label: "Jealousy comes up and gets stuck",           isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "self_unknown",    label: "I'm still figuring out what I want",         isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "desire_language",   label: "What I want — not what I've accepted",                      isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "cnm_openness",      label: "Whether opening up could work for us",                      isEmphasized: true,  contentType: .quiz(.cnmReadiness)),
            CuriosityOption(id: "desire_map",        label: "I want to map my own desires before anything else",         isEmphasized: false, contentType: .desireMap),
            CuriosityOption(id: "agreements",        label: "What our agreements should actually look like",              isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "jealousy_literacy", label: "What jealousy is actually telling me",                      isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "attachment",        label: "Why I respond to people the way I do",                      isEmphasized: false, contentType: .educationTrack),
        ],
        showSection2: true
    )

    // MARK: Solo — Partnered Hidden (It's Complicated)

    static let soloPartneredHiddenConfig = CuriosityScreenConfig(
        section1Label:    "What's actually going on for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What would help you most right now?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "self_unknown",               label: "I'm still figuring out what I want",      isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "initiating_hidden",          label: "I don't know how I'd even bring this up", isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "desire_mismatch_unilateral", label: "I think we want different things",        isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "reconnection",               label: "We've lost some of our connection",       isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "jealousy_stuck",             label: "Jealousy comes up and gets stuck",        isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "desire_language",       label: "What I want — not what I've accepted",                           isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "attachment",            label: "Why I respond to people the way I do",                           isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "cnm_style_discovery",   label: "I'm curious whether non-monogamy could be right for me",         isEmphasized: true,  contentType: .quiz(.cnmStyleDiscovery)),
            CuriosityOption(id: "desire_map",            label: "I want to map my own desires before anything else",              isEmphasized: false, contentType: .desireMap),
            CuriosityOption(id: "jealousy_literacy",     label: "What jealousy is actually telling me",                           isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "consent_self_advocacy", label: "What it actually means to ask for what I want",                  isEmphasized: false, contentType: .educationTrack),
        ],
        showSection2: true
    )

    // MARK: Couple — Haven't Really Talked

    static let coupleNotTalkedConfig = CuriosityScreenConfig(
        section1Label:    "What feels hardest right now?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "initiating",      label: "I don't know how to start the conversation", isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "self_unknown",    label: "I'm still figuring out what I want",         isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "desire_mismatch", label: "We want different things sexually",          isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "jealousy_stuck",  label: "Jealousy comes up and gets stuck",           isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "cnm_openness",          label: "Whether opening up could work for us",              isEmphasized: true,  contentType: .quiz(.cnmReadiness)),
            CuriosityOption(id: "consent_ongoing",       label: "What it actually means to ask for what I want",     isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "desire_map_individual", label: "Understanding what we each want — separately",      isEmphasized: true,  contentType: .desireMap),
            CuriosityOption(id: "agreements",            label: "What our agreements should actually look like",      isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "jealousy_literacy",     label: "What jealousy is actually telling me",              isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "attachment",            label: "Why I respond to people the way I do",              isEmphasized: false, contentType: .educationTrack),
        ],
        showSection2: true
    )

    // MARK: Couple — We've Been Talking

    static let coupleTalkingConfig = CuriosityScreenConfig(
        section1Label:    "Where do you want to go from here?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "desire_mismatch", label: "We want different things sexually",               isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "initiating",      label: "I don't know how to ask for the specific things", isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "jealousy_stuck",  label: "Jealousy comes up and gets stuck",                isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "self_unknown",    label: "I'm still figuring out what I want",              isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "reconnection",    label: "We've lost some of our connection",               isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "agreements",            label: "What our agreements should actually look like",  isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "compersion",            label: "Feeling good about what brings them joy",        isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "cnm_openness",          label: "Whether opening up could work for us",           isEmphasized: true,  contentType: .quiz(.cnmReadiness)),
            CuriosityOption(id: "desire_map_individual", label: "Understanding what we each want — separately",   isEmphasized: false, contentType: .desireMap),
            CuriosityOption(id: "jealousy_literacy",     label: "What jealousy is actually telling me",           isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "attachment",            label: "Why I respond to people the way I do",           isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "consent_ongoing",       label: "What it actually means to ask for what I want",  isEmphasized: false, contentType: .educationTrack),
        ],
        showSection2: true
    )

    // MARK: Couple — We've Tried Some Things

    static let coupleSomeExperienceConfig = CuriosityScreenConfig(
        section1Label:    "What are you trying to figure out?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "jealousy_stuck",  label: "Jealousy comes up and gets stuck",         isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "desire_mismatch", label: "We want different things sexually",        isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "self_unknown",    label: "I'm still figuring out what I want",       isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "reconnection",    label: "We've lost some of our connection",        isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "initiating",      label: "I don't know how to ask for what I want", isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "jealousy_literacy",   label: "What jealousy is actually telling me",                                        isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "compersion",          label: "Feeling good about what brings them joy",                                      isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "agreements",          label: "What our agreements should actually look like",                                isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "asymmetric_interest", label: "How to handle it if one of us wants this more than the other",                 isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "attachment",          label: "Why I respond to people the way I do",                                        isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "consent_ongoing",     label: "What it actually means to ask for what I want",                               isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "cnm_openness",        label: "Whether opening up could work for us",                                        isEmphasized: false, contentType: .quiz(.cnmReadiness)),
        ],
        showSection2: true
    )

    // MARK: Couple — We Need A Reset

    static let coupleNeedsResetConfig = CuriosityScreenConfig(
        section1Label:    "What needs attention right now?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What would help you two find footing?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section1Options: [
            CuriosityOption(id: "reconnection",    label: "We've lost some of our connection",   isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "jealousy_stuck",  label: "Jealousy comes up and gets stuck",    isEmphasized: true,  contentType: .communicationGoal),
            CuriosityOption(id: "desire_mismatch", label: "We want different things sexually",   isEmphasized: false, contentType: .communicationGoal),
            CuriosityOption(id: "self_unknown",    label: "I'm still figuring out what I want",  isEmphasized: false, contentType: .communicationGoal),
        ],
        section2Options: [
            CuriosityOption(id: "attachment",            label: "Why I respond to people the way I do",           isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "jealousy_literacy",     label: "What jealousy is actually telling me",           isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "agreements",            label: "What our agreements should actually look like",   isEmphasized: true,  contentType: .educationTrack),
            CuriosityOption(id: "desire_language",       label: "What I want — not what I've accepted",           isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "consent_ongoing",       label: "What it actually means to ask for what I want",  isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "desire_map_individual", label: "Understanding what we each want — separately",   isEmphasized: false, contentType: .desireMap),
        ],
        showSection2: true
    )

    // MARK: Browsing (no explorationMode set)

    static let browsingConfig = CuriosityScreenConfig(
        section1Label:    "What do you want to learn about?",
        section1Sublabel: "Pick everything that interests you.",
        section2Label:    "What would you like to try?",
        section2Sublabel: "These open up quizzes and personalized paths.",
        section1Options: [
            CuriosityOption(id: "cnm_foundations",   label: "How non-monogamy actually works",               isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "desire_language",   label: "Understanding desire and what shapes it",        isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "jealousy_literacy", label: "What jealousy is actually telling you",          isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "attachment",        label: "Why people respond to intimacy the way they do", isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "consent_ongoing",   label: "Consent beyond yes and no",                      isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "compersion",        label: "Feeling good about what brings a partner joy",   isEmphasized: false, contentType: .educationTrack),
        ],
        section2Options: [
            CuriosityOption(id: "agreements",          label: "How couples build agreements that hold",              isEmphasized: false, contentType: .educationTrack),
            CuriosityOption(id: "desire_map",          label: "I want to map my own desires before anything else",   isEmphasized: true,  contentType: .desireMap),
            CuriosityOption(id: "cnm_style_discovery", label: "I'm curious what kind of relationships might suit me", isEmphasized: true,  contentType: .quiz(.cnmStyleDiscovery)),
            CuriosityOption(id: "attachment_style",    label: "What my attachment style means for how I connect",    isEmphasized: false, contentType: .quiz(.attachmentStyle)),
            CuriosityOption(id: "cnm_readiness",       label: "Whether non-monogamy could actually work for me",     isEmphasized: false, contentType: .quiz(.cnmReadiness)),
            CuriosityOption(id: "jealousy_anatomy",    label: "The anatomy of jealousy — and what mine is made of",  isEmphasized: false, contentType: .quiz(.jealousyAnatomy)),
        ],
        showSection2: true
    )
}
