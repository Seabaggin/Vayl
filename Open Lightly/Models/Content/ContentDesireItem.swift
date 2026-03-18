//
//  DesireItem.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// DesireItem.swift
// A read-only content model representing one item on the
// Desire Map — a private rating exercise where each partner
// independently rates desires, boundaries, and relationship dynamics.
//
// This struct is decoded from JSON bundled in the app.
// It is never modified at runtime.
//
// PRIVACY RULE (critical):
// "Not For Me" ratings (DesireLevel.notForMe) are NEVER revealed
// to the partner. The alignment engine returns .boundary for any
// combination involving a notForMe — the UI treats .boundary as
// "not shown in detail". Only a count of boundaries is displayed.
// This mirrors informed consent practice: a partner's firm
// boundary is theirs alone.
// ============================================================

struct ContentDesireItem: Identifiable, Codable {

    // MARK: - Properties

    let id: String              // unique identifier (e.g. "desire_mfm_threesome")
    let name: String            // short display name (e.g. "MFM Threesome")
    let description: String     // 1-2 sentence explanation shown during rating
    let category: String        // "nm_structures", "sexual", "dynamics"
    let subcategory: String?    // e.g. "swinging", "polyamory", "emotional"
    let layer: String           // "core", "discovery", "deep_dive"
    let sortOrder: Int          // position within the desire map
    let isFree: Bool            // whether this item is available in the free tier
    let sensitivityLevel: Int   // 1-3: how much primer framing is needed

    // MARK: - Alignment Logic

    /// Computes alignment between two partners' desire levels.
    /// .boundary items are NEVER shown to partners in detail.
    static func computeAlignment(
        partnerA: DesireLevel,
        partnerB: DesireLevel
    ) -> AlignmentLevel {

        // SACRED RULE: Either partner = notForMe → boundary
        if partnerA == .notForMe || partnerB == .notForMe {
            return .boundary
        }

        let gap = abs(partnerA.rawValue - partnerB.rawValue)
        let minimum = min(partnerA.rawValue, partnerB.rawValue)

        // Both low (probablyNot) → mutual pass
        if minimum <= 2 && gap == 0 {
            return .mutualPass
        }

        // Gap 0-1 with at least one partner openToIt or above
        if gap <= 1 && minimum >= 3 {
            if partnerA == .excitedAboutIt && partnerB == .excitedAboutIt {
                return .strongAlignment
            }
            return .aligned
        }

        // Gap 0-1 but lower ratings (2+3 or 2+2)
        if gap <= 1 {
            return .mutualPass
        }

        // Gap 2+ (max possible without notForMe: 4 vs 2 = 2)
        return .talkAboutIt
    }

    /// Returns the gap size for bridge card template selection
    static func gapSize(partnerA: DesireLevel, partnerB: DesireLevel) -> Int {
        return abs(partnerA.rawValue - partnerB.rawValue)
    }

    /// Whether this alignment needs a primer card before the bridge card
    static func needsPrimer(alignment: AlignmentLevel, sensitivityLevel: Int) -> Bool {
        switch alignment {
        case .talkAboutIt: return true
        case .aligned: return sensitivityLevel >= 3
        default: return false
        }
    }

    // MARK: - Preview Helpers

    static let example = ContentDesireItem(
        id: "desire_mfm_threesome",
        name: "MFM Threesome",
        description: "A sexual experience involving two men and one woman",
        category: "nm_structures",
        subcategory: "swinging",
        layer: "discovery",
        sortOrder: 1,
        isFree: true,
        sensitivityLevel: 2
    )
}
