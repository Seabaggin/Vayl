//
//  DesireItem.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import Foundation

// ============================================================
// DesireItem.swift
// One item on the Desire Map.
//
// WHAT THIS DOES:
// The Desire Map is a screen where each partner independently
// rates a list of intimate activities. Each item gets a DesireLevel
// from both partners privately. The app then compares ratings
// to find positive alignments — mutual interest zones only.
//
// PRIVACY RULE (critical):
// "Not For Me" ratings are NEVER revealed to the partner.
// The computeAlignment method returns the alignment result for any
// combination involving a .notForMe — the UI treats .boundary as
// "not shown". No count of hidden items is ever displayed.
// This mirrors informed consent practice: a partner's firm
// boundary is theirs alone.
//
// ALIGNMENT MATRIX (from PROJECT_SCOPE.md Section 10):
//
//   A \ B          | ExcitedAboutIt | OpenToIt     | ProbablyNot    | NotForMe
//   ────────────────────────────────────────────────────────────────────────────
//   ExcitedAboutIt | strongAlign    | aligned      | talkAboutIt    | boundary
//   OpenToIt       | aligned        | aligned      | talkAboutIt    | boundary
//   ProbablyNot    | talkAboutIt    | talkAboutIt  | mutualPass     | boundary
//   NotForMe       | boundary       | boundary     | boundary       | boundary
//
// WHY SEPARATE FROM CARD?
// Cards are conversation prompts read aloud together.
// DesireItems are private ratings done independently then compared.
// Different data, different UI, different flow.
// ============================================================

struct DesireItem: Identifiable, Codable {

    // Unique identifier
    let id: UUID

    // What this item is called — e.g. "Roleplay", "Group Play"
    let name: String

    // Short explanation shown below the name during rating
    let description: String

    // Grouping label — e.g. "Power Dynamics", "Physical", "Emotional"
    let category: String

    // Whether this item is available on the free tier
    let isFree: Bool

    // Position in the list (lower = shown earlier)
    let sortOrder: Int

    // ── Ratings ──
    // nil means that partner hasn't rated yet.
    // Both start nil. Each partner fills theirs in independently.
    // NEVER expose these to the other partner's UI.

    var ratingA: DesireLevel?
    var ratingB: DesireLevel?

    // ── Initializer ──

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        category: String,
        isFree: Bool = false,
        sortOrder: Int = 0,
        ratingA: DesireLevel? = nil,
        ratingB: DesireLevel? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.isFree = isFree
        self.sortOrder = sortOrder
        self.ratingA = ratingA
        self.ratingB = ratingB
    }
}

// ============================================================
// MARK: - Alignment Logic
//
// Implements the spec alignment matrix exactly.
// Returns nil for: any .notForMe combination, both .probablyNot,
// or incomplete ratings. nil = hidden, never shown.
// ============================================================

extension DesireItem {

    // Returns nil if either partner hasn't rated yet.
    // Uses ContentDesireItem.computeAlignment for the actual logic.
    var computeAlignment: AlignmentLevel? {
        guard let a = ratingA, let b = ratingB else { return nil }
        return ContentDesireItem.computeAlignment(partnerA: a, partnerB: b)
    }

    // Has this item been fully rated by both partners?
    var isComplete: Bool {
        ratingA != nil && ratingB != nil
    }
}

// ============================================================
// MARK: - Placeholder Content
//
// 15 items across 3 categories for development.
// First 5 marked isFree so the free tier has sample content.
// Replace with real content and sortOrder from JSON later.
// ============================================================

extension DesireItem {

    static let allPlaceholders: [DesireItem] = [

        // ── Physical ── (items 1-5, first 5 are free)
        DesireItem(name: "Light Bondage",
                 description: "Wrist restraints, scarves, or beginner cuffs",
                 category: "Physical", isFree: true, sortOrder: 1),
        DesireItem(name: "Sensation Play",
                 description: "Ice, feathers, wax — varying sensory input",
                 category: "Physical", isFree: true, sortOrder: 2),
        DesireItem(name: "Impact Play",
                 description: "Spanking, paddling — consensual striking",
                 category: "Physical", isFree: true, sortOrder: 3),
        DesireItem(name: "Roleplay",
                 description: "Taking on characters or scenarios together",
                 category: "Physical", isFree: true, sortOrder: 4),
        DesireItem(name: "Group Play",
                 description: "Sexual activity involving more than two people",
                 category: "Physical", isFree: true, sortOrder: 5),

        // ── Power Dynamics ──
        DesireItem(name: "Dominance / Submission",
                 description: "One partner leads, the other follows — negotiated",
                 category: "Power Dynamics", sortOrder: 6),
        DesireItem(name: "Service Acts",
                 description: "One partner performs tasks for the other's pleasure",
                 category: "Power Dynamics", sortOrder: 7),
        DesireItem(name: "Praise / Degradation",
                 description: "Verbal affirmation or humiliation during intimacy",
                 category: "Power Dynamics", sortOrder: 8),
        DesireItem(name: "Ownership Language",
                 description: "Using possessive terms — 'mine', 'yours', collars",
                 category: "Power Dynamics", sortOrder: 9),
        DesireItem(name: "Orgasm Control",
                 description: "One partner decides when the other is allowed to finish",
                 category: "Power Dynamics", sortOrder: 10),

        // ── Lifestyle ──
        DesireItem(name: "Watching / Being Watched",
                 description: "Voyeurism or exhibitionism with consent",
                 category: "Lifestyle", sortOrder: 11),
        DesireItem(name: "Sexting Outside Relationship",
                 description: "Explicit messaging with people outside your partnership",
                 category: "Lifestyle", sortOrder: 12),
        DesireItem(name: "Separate Bedrooms",
                 description: "Partners maintain their own sleeping spaces",
                 category: "Lifestyle", sortOrder: 13),
        DesireItem(name: "Overnight Stays",
                 description: "Spending the night at another partner's home",
                 category: "Lifestyle", sortOrder: 14),
        DesireItem(name: "Fluid Bonding",
                 description: "Unprotected sex reserved for specific partners",
                 category: "Lifestyle", sortOrder: 15),
    ]

    static func placeholders(for category: String) -> [DesireItem] {
        allPlaceholders.filter { $0.category == category }
    }

    static var placeholderCategories: [String] {
        let cats = allPlaceholders.map { $0.category }
        var seen = Set<String>()
        return cats.filter { seen.insert($0).inserted }
    }
}
