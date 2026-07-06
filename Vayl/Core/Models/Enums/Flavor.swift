//
//  Flavor.swift
//  Vayl
//
//  The Map identity typology. Colours the Me Card and seeds its Title shortlist.
//  Net-new in V1 (there is no Flavor quiz yet) — chosen and edited on the card
//  itself and persisted to UserProfile.flavor. The "Drawn to" tags are derived
//  from the Desire layer, not from here.
//

import SwiftUI

enum Flavor: String, CaseIterable, Identifiable, Codable {
    case explorer, anchor, catalyst, architect

    var id: String { rawValue }

    var label: String {
        switch self {
        case .explorer:  return "Explorer"
        case .anchor:    return "Anchor"
        case .catalyst:  return "Catalyst"
        case .architect: return "Architect"
        }
    }

    /// SF Symbol for the flavor chip.
    var icon: String {
        switch self {
        case .explorer:  return "safari"
        case .anchor:    return "leaf.fill"
        case .catalyst:  return "flame.fill"
        case .architect: return "ruler.fill"
        }
    }

    /// The card's colour (spectrum tokens; bridge is the lavender anchor hue).
    var color: Color {
        switch self {
        case .explorer:  return AppColors.spectrumCyan
        case .anchor:    return AppColors.spectrumBridge
        case .catalyst:  return AppColors.spectrumMagenta
        case .architect: return AppColors.spectrumPurple
        }
    }

    /// A two-word vibe shown beside the chip.
    var essence: String {
        switch self {
        case .explorer:  return "Curious · Open"
        case .anchor:    return "Grounded · Tender"
        case .catalyst:  return "Bold · Warm"
        case .architect: return "Considered · Deliberate"
        }
    }

    /// The poetic-with-a-wink Title shortlist the user chooses from.
    var titles: [String] {
        switch self {
        case .explorer:
            return ["The Slow Burn", "The Cartographer", "Out Past the Map",
                    "Brings the Real Question", "Already Three Tabs Deep", "Certified Yes-And"]
        case .anchor:
            return ["The Steady Hand", "True North", "The Slow Yes",
                    "Needs a Minute (Worth It)", "Emotional Support Human", "Texts Back in Paragraphs"]
        case .catalyst:
            return ["The First Move", "The Spark", "The Opening Bid",
                    "Started It (Lovingly)", "Chaos With a Plan", "Will Make It Weird (Affectionately)"]
        case .architect:
            return ["The Blueprint", "The Long Game", "Measures Twice",
                    "Has a Spreadsheet for This", "Plans the Spontaneity", "Reads the Fine Print"]
        }
    }
}
