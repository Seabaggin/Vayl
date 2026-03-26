//
//  ExperienceType.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/20/26.
//


// Models/ExperienceType.swift

import Foundation

/// Represents the user's chosen experience mode.
/// Set once during onboarding, changeable via Settings → Switch Experience.
/// Persisted via UserDefaults (non-sensitive — it's a UI routing key only).
enum ExperienceType: String, CaseIterable, Codable {

    case browsing           = "browsing"
    case soloSingle         = "solo_single"
    case soloPartnered      = "solo_partnered"
    case coupleNew          = "couple_new"
    case coupleExperienced  = "couple_experienced"

    // TODO(follow-up): If ExperienceType is ever stored in SwiftData
    // (not just UserDefaults), a SchemaMigrationPlan is required for
    // any case rename or removal.

    var displayName: String {
        switch self {
        case .browsing:          return "Just Browsing"
        case .soloSingle:        return "Solo Explorer"
        case .soloPartnered:     return "Solo (with partner)"
        case .coupleNew:         return "New Couple"
        case .coupleExperienced: return "Experienced ENM"
        }
    }

    /// Tabs visible to this experience. Browsing is gate-locked to .more only.
    var availableTabs: [AppTab] {
        switch self {
        case .browsing:
            return [.more]
        case .soloSingle, .soloPartnered:
            return [.home, .meUs, .explore, .more]
        case .coupleNew, .coupleExperienced:
            return [.home, .meUs, .explore, .more]
        }
    }

    var isCoupleAccount: Bool {
        self == .coupleNew || self == .coupleExperienced
    }

    var isGuest: Bool {
        self == .browsing
    }
}