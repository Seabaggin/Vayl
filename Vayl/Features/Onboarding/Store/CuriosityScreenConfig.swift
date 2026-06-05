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
    let section3Label: String
    let section3Sublabel: String
    let section1Options: [CuriosityOption]
    let section2Options: [CuriosityOption]
    let section3Options: [CuriosityOption]
    let showSection2: Bool

    init(
        section1Label: String,
        section1Sublabel: String,
        section2Label: String = "",
        section2Sublabel: String = "",
        section3Label: String = "",
        section3Sublabel: String = "",
        section1Options: [CuriosityOption],
        section2Options: [CuriosityOption] = [],
        section3Options: [CuriosityOption] = [],
        showSection2: Bool
    ) {
        self.section1Label    = section1Label
        self.section1Sublabel = section1Sublabel
        self.section2Label    = section2Label
        self.section2Sublabel = section2Sublabel
        self.section3Label    = section3Label
        self.section3Sublabel = section3Sublabel
        self.section1Options  = section1Options
        self.section2Options  = section2Options
        self.section3Options  = section3Options
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

// MARK: - Default Config Stub

extension CuriosityScreenConfig {
    /// Placeholder used while the full appMode-based config is being rebuilt.
    static var `default`: CuriosityScreenConfig {
        CuriosityScreenConfig(
            section1Label: "What do you want to explore?",
            section1Sublabel: "Choose the topics that matter most",
            section1Options: [],
            showSection2: false
        )
    }
}

// MARK: - OnboardingData Extension

// PENDING: curiosityScreenConfig needs to be rewritten against AppMode (together / solo).

// MARK: - Static Config Instances

extension CuriosityScreenConfig {

    // MARK: Solo — Single

    static let soloSingleConfig = CuriosityScreenConfig(
        section1Label:    "What keeps coming up for you?",
        section1Sublabel: "Your relationship habits are already shaping what you need. Let's start there.",
        section2Label:    "What are you curious about?",
        section2Sublabel: "Let's put it all on the table.",
        section3Label:    "What would success look like?",
        section3Sublabel: "Pick the one that matters most.",
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
        section3Options: [],
        showSection2: true
    )

    // MARK: Solo — Partnered Open (Partner Knows)

    static let soloPartneredOpenConfig = CuriosityScreenConfig(
        section1Label:    "What are you two working on?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section3Label:    "What would success look like?",
        section3Sublabel: "Pick the one that matters most.",
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
        section3Options: [],
        showSection2: true
    )

    // MARK: Solo — Partnered Hidden (It's Complicated)

    static let soloPartneredHiddenConfig = CuriosityScreenConfig(
        section1Label:    "What's actually going on for you?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What would help you most right now?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section3Label:    "What would success look like?",
        section3Sublabel: "Pick the one that matters most.",
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
        section3Options: [],
        showSection2: true
    )

    // MARK: Couple — Haven't Really Talked

    static let coupleNotTalkedConfig = CuriosityScreenConfig(
        section1Label:    "What feels hardest right now?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section3Label:    "What would success look like?",
        section3Sublabel: "Pick the one that matters most.",
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
        section3Options: [],
        showSection2: true
    )

    // MARK: Couple — We've Been Talking

    static let coupleTalkingConfig = CuriosityScreenConfig(
        section1Label:    "Where do you want to go from here?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section3Label:    "What would success look like?",
        section3Sublabel: "Pick the one that matters most.",
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
        section3Options: [],
        showSection2: true
    )

    // MARK: Couple — We've Tried Some Things

    static let coupleSomeExperienceConfig = CuriosityScreenConfig(
        section1Label:    "What are you trying to figure out?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What do you want to figure out?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section3Label:    "What would success look like?",
        section3Sublabel: "Pick the one that matters most.",
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
        section3Options: [],
        showSection2: true
    )

    // MARK: Couple — We Need A Reset

    static let coupleNeedsResetConfig = CuriosityScreenConfig(
        section1Label:    "What needs attention right now?",
        section1Sublabel: "Pick everything that feels true.",
        section2Label:    "What would help you two find footing?",
        section2Sublabel: "These shape what you'll explore and learn.",
        section3Label:    "What would success look like?",
        section3Sublabel: "Pick the one that matters most.",
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
        section3Options: [],
        showSection2: true
    )

}

extension CuriosityScreenConfig {
    
    static func leadPhrase(for id: String) -> String {
        leadPhrases[id] ?? id
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .prefix(4)
            .joined(separator: " ")
    }
    
    private static let leadPhrases: [String: String] = [
        "not_what_accepted":           "Not what I've accepted.",
        "why_i_respond":               "Why I respond the way I do.",
        "nm_right_for_me":             "Could NM be right for me?",
        "map_desires":                 "Map my desires first.",
        "jealousy_past":               "Jealousy in past relationships.",
        "asking_what_want":            "Asking for what I actually want.",
        "same_place_diff_person":      "Same place. Different person.",
        "reactions_surprise":          "My own reactions surprise me.",
        "know_what_i_dont_want":    "I know what I don't want.",
        "same_fight":               "Same fight. Different year.",
        "blow_up_shut_down":        "I blow up. Or shut down.",
        "get_the_concept":          "I get the concept.",
        "jealousy_things":          "Jealousy has cost me.",
        "said_yes_didnt_want":      "I've said yes when I meant no.",
        "understand_myself_now":    "I'd rather understand myself now.",
        "open_structured_else":     "Open? Structured? Something else?",
        "dont_have_language":       "I don't have the language yet.",
        "how_much_mine":            "How much of this is actually mine?",
        "same_fight_couple":        "Same fight. Nothing changes.",
        "things_not_saying":        "Things I keep not saying.",
        "carry_more":               "I carry more than I show.",
        "want_to_know_agreeing":    "What are we actually agreeing to?",
        "worried_different_things": "Are we wanting the same thing?",
        "understand_together":      "I want us to figure this out together.",
        "something_needs_change":   "Something needs to change.",
        "really_well_really_badly": "Really well or really badly.",
        "never_actually_decided":   "Did we even decide to do this?",
        "what_people_figured_out":  "What did people learn the hard way?",
        "carrying_havent_said":     "I've been carrying something.",
        "unhappy_partner_or_self":  "Am I unhappy with them or myself?",
        "what_i_actually_think":    "I need to know what I think first.",
        "curious_or_just_unhappy":  "Curious, or just unhappy?",
        "comes_out_wrong":          "Every time I try, it comes out wrong.",
        "desire_unknown":           "I don't know what I want.",
        "pattern_recognition":      "Same place. Different person.",
        "initiating":               "I wouldn't know how to ask.",
        "self_awareness":           "My own reactions surprise me.",
        "situationship":            "I'm in something I can't read.",
        "desire_language":          "Not what I've accepted.",
        "attachment":               "Why I respond the way I do.",
        "cnm_style_discovery":      "Could NM be right for me?",
        "desire_map":               "Map my desires first.",
        "jealousy_history":         "Jealousy in past relationships.",
        "consent_self_advocacy":    "Asking for what I actually want.",
        "desire_mismatch":          "We want different things.",
        "reconnection":             "We've lost our connection.",
        "jealousy_stuck":           "Jealousy gets stuck.",
        "self_unknown":             "Still figuring out what I want.",
        "cnm_openness":             "Could opening up work for us?",
        "desire_map_individual":    "What we each want — separately.",
        "agreements":               "What our agreements should look like.",
        "jealousy_literacy":        "What jealousy is telling me.",
        "cnm_foundations":          "How NM actually works.",
        "consent_ongoing":          "Consent beyond yes and no.",
        "compersion":               "Feeling good about their joy.",
        "attachment_style":         "What my attachment style means.",
        "cnm_readiness":            "Could NM actually work for me?",
        "jealousy_anatomy":         "What my jealousy is made of.",
        "asymmetric_interest":      "What if one of us wants this more?",
        "s3_know_want":             "I want to know.",
        "s3_ask_need":              "I need to ask.",
        "s3_patterns":              "I keep noticing.",
        "s3_less_alone":            "I want to feel.",
    ]
    
    // MARK: - DEBUG Validation
    
#if DEBUG
    static func validateLeadPhrases() {
        let allConfigs: [CuriosityScreenConfig] = [
            .soloSingleConfig,
            .soloPartneredOpenConfig,
            .soloPartneredHiddenConfig,
            .coupleNotTalkedConfig,
            .coupleTalkingConfig,
            .coupleSomeExperienceConfig,
            .coupleNeedsResetConfig,
        ]
        for config in allConfigs {
            for opt in config.section1Options + config.section2Options + config.section3Options {
                if leadPhrases[opt.id] == nil {
                    assertionFailure(
                        "CuriosityScreenConfig: missing lead phrase for option id '\(opt.id)'"
                    )
                }
            }
        }
    }
#endif
}
