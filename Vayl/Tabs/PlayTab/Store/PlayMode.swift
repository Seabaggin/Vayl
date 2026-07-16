//  PlayMode.swift
//  Vayl — Play

import Foundation

/// The arcade dial's detents. Launch ships `.cards` only; `.simulator` is a
/// stubbed Act-2 destination kept behind a flag so the dial ENGINE is built
/// once now and the 2nd game drops in by flipping `simulatorEnabled`.
enum PlayMode: String, CaseIterable, Identifiable {
    case cards
    case simulator

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cards:     return "Cards"
        case .simulator: return "Simulator"
        }
    }
}

/// Compile-time feature gates for the Play tab.
enum PlayFeatureFlags {
    /// Reveal the Simulator detent + its world. false at launch (Cards only).
    static let simulatorEnabled = false

    /// The dial's live detents, derived from the flag.
    static var enabledModes: [PlayMode] {
        simulatorEnabled ? PlayMode.allCases : [.cards]
    }
}
