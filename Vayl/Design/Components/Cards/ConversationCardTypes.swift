//
//  OBCard.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/28/26.
//

import SwiftUI

// MARK: - OB Card

struct OBCard {
    let overline: String
    let question: String
    let highlightedPhrase: String   // receives gradient treatment
    let backFace: OBCardBackFace
}

enum OBCardBackFace {
    case pills([CardRevealPill])
    case text(String)
}

enum CardRevealPill: String, CaseIterable, Identifiable {
    case ready      = "Something I'm ready for"
    case figuring   = "Something I'm still figuring out"
    case scared     = "Something that scares me"
    case almostSaid = "Something I almost said"
    case noApology  = "Something I stopped apologizing for"

    var id: String { rawValue }
}

// MARK: - Content Type

enum ConversationCardContent {
    case prompt(String)     // card text — stub until full Card integration
    case onboarding(OBCard)
}

// MARK: - Fuse Config

enum FuseConfig {
    case none
    case countdown(duration: TimeInterval, onComplete: () -> Void)
}

// MARK: - Ghost Deck Mode

enum GhostDeckMode {
    case none
    case atmospheric
    case navigable(cards: [ConversationCardContent], onAdvance: () -> Void)
}
