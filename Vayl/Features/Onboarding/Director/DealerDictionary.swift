//
//  DealerDictionary.swift
//  Vayl
//
//  Single source of truth for the Onboarding Dealer's hardcoded dialogue.
//  The Dealer addresses the user directly ("You/I"), avoiding "We/Let's".
//

import Foundation

enum DealerDictionary {
    
    // MARK: - Context Phase
    
    static func contextHeadline(appMode: AppMode) -> String {
        appMode == .together
            ? "Where are you two starting from?"
            : "Where are you starting from?"
    }
    
    static func contextResponse(for register: SituationalRegister) -> String {
        switch register {
        case .anxious:  return "I'll take this slow."
        case .excited:  return "I like that momentum."
        case .flexible: return "No need to force it."
        }
    }
    
    // MARK: - Experience Level Phase
    
    static func experienceLevelExitLine(intensity: CandleIntensity) -> String {
        switch intensity {
        case .curious:     return "You're new to the table. Best seat there is."
        case .exploring:   return "You've played a few hands. I'll help you read them better."
        case .experienced: return "You know this game well. I'll help you play it sharper."
        }
    }
    
    // MARK: - Curiosity Phase Demo
    
    static let curiosityDemoKeepInstruction = "Swipe right if a card feels true for you."
    static let curiosityDemoPassInstruction = "Left if it doesn't."
    static let curiosityDemoIntroRealHand = "Now I'll deal you the real hand."
    static let curiosityRound1Headline = "What's drawing you here?"
    static let curiosityRound2Headline = "What are you curious to try?"        // curious: first-times
    static let curiosityRound2HeadlineInIt = "What do you want more of?"        // in it: refining the lane
    static let curiosityDoneLine = "That's everything I need."
}
