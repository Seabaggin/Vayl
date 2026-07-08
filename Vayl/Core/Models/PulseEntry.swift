//
//  PulseEntry.swift
//  Vayl
//
//  Location: Models/Persistence/PulseEntry.swift
//  PulseCapacityColor lives in AppPulseEnums.swift
//  Its color properties live in AppColors.swift as extensions
//

import Foundation

// MARK: - PulseEntry
// Plain Codable struct — stored in UserDefaults via PulseStore.
// NOT a SwiftData @Model — device-level cache, not synced.
// Shape is not final — revisit when Pulse check-in UI is built.

struct PulseEntry: Identifiable, Codable {
    var id: UUID               = UUID()
    var date: Date
    var capacityScore: Double              // kept for back-compat decode; prefer resolvedPosition.capacityScore
    var glowColor: PulseCapacityColor  // derived from Q1-3 position (pos.quadrant.capacityColor), NOT a Q4 answer
    var speed: String              // Q5 answer label

    // Q1-Q3 answers
    var nervousSystem: String              // Q1 answer label
    var focus: String              // Q2 answer label
    var feeling: String              // Q3 answer label

    /// Q4 answer label ("Empty"..."Abundant") — reflective metadata, doesn't affect
    /// position/colour. nil only for entries persisted before this field existed.
    var capacity: String?

    var position: PulsePosition?     // nil for pre-redesign entries

    /// When this day's entry was FIRST completed — distinct from `date` (the calendar
    /// day it belongs to). Anchors the edit window: PulseStore.add() carries this
    /// forward across same-day re-edits rather than resetting it, so redoing a check-in
    /// can't extend how long it stays editable. nil for entries predating this field
    /// (resolvedCreatedAt falls back to `date`, which locks them immediately — correct,
    /// since anything old enough to lack this field is definitely past the window).
    var createdAt: Date?

    /// How long a day's entry can still be redone after its first completion.
    static let editWindow: TimeInterval = 2 * 60 * 60

    var resolvedCreatedAt: Date { createdAt ?? date }

    /// Whether this entry can still be redone (re-checked-in) today. A completed
    /// check-in is a sealed snapshot of that moment, not an open diary entry — once
    /// the window passes, it's locked until a new day starts.
    var isEditable: Bool {
        Date().timeIntervalSince(resolvedCreatedAt) <= Self.editWindow
    }

    /// Effective position: stored field, or reconstructed from legacy capacityScore (openness mid).
    var resolvedPosition: PulsePosition {
        position ?? PulsePosition(energy: (capacityScore - 1) / 3, openness: 0.5)
    }

    var quadrant: PulseQuadrant { resolvedPosition.quadrant }

    /// The five stored answer labels in question order (nil for any not captured — legacy rows).
    var answerLabels: [String?] { [nervousSystem, focus, feeling, capacity, speed] }

    /// The six-space classification. Uncharted is re-derived from the stored answer labels
    /// (the flag isn't persisted). Legacy entries whose labels predate the current pill set
    /// resolve to a named/border space, never Uncharted — their labels won't match and the
    /// variance check returns false.
    var space: PulseSpace {
        PulseSpace.resolve(resolvedPosition, isUncharted: PulseAnswers.isUncharted(answerLabels))
    }
}

// MARK: - Preview Data

extension PulseEntry {
    static let previews: [PulseEntry] = {
        // Each entry carries a real 2D position computed from its full Q1-Q5 answers so the
        // circumplex field places the aura correctly even without a live check-in.
        func make(_ daysAgo: Int, _ ns: String, _ focus: String, _ feeling: String,
                  _ capacity: String, _ speed: String) -> PulseEntry {
            let answers: [String?] = [ns, focus, feeling, capacity, speed]
            let pos = PulseAnswers.position(answers)
            return PulseEntry(
                date: .daysAgo(daysAgo),
                capacityScore: pos.capacityScore,
                glowColor: pos.quadrant.capacityColor,
                speed: speed,
                nervousSystem: ns,
                focus: focus,
                feeling: feeling,
                capacity: capacity,
                position: pos
            )
        }
        return [
            make(13, "Overwhelmed", "Deeply Inward", "Sensitive", "Empty", "Solitude"),
            make(12, "Energized", "Reaching Out", "Adventurous", "Overflowing", "Deep Dive"),
            make(11, "Exhausted", "Deeply Inward", "Anxious", "Running Low", "Quietly Together"),
            make(10, "Energized", "Reaching Out", "Adventurous", "Overflowing", "Deep Dive"),
            make(9, "Overwhelmed", "Deeply Inward", "Sensitive", "Empty", "Solitude"),
            make(8, "Recharging", "Present", "Content", "Just Enough", "Light Connection"),
            make(7, "Energized", "Reaching Out", "Adventurous", "Overflowing", "Deep Dive"),
            make(6, "Overwhelmed", "Deeply Inward", "Sensitive", "Empty", "Solitude"),
            make(5, "Recharging", "Needing Space", "Content", "Just Enough", "Quietly Together"),
            make(4, "Energized", "Reaching Out", "Adventurous", "Overflowing", "Playful"),
            make(3, "Overwhelmed", "Deeply Inward", "Sensitive", "Empty", "Solitude"),
            make(2, "Recharging", "Reaching Out", "Warm", "Plenty", "Deep Dive"),
            make(1, "Centered", "Present", "Warm", "Plenty", "Light Connection")
        ]
    }()
}

// MARK: - Date Extension

extension Date {
    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        ) ?? Date()
    }
}
