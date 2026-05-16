//
//  PulseEntry.swift
//  Vayl
//
//  Location: Models/Persistence/PulseEntry.swift
//  PulseCapacityColor and PulseTier live in AppEnums.swift
//  Their color properties live in AppColors.swift as extensions
//

import Foundation

// MARK: - PulseEntry
// Plain Codable struct — stored in UserDefaults via PulseStore.
// NOT a SwiftData @Model — device-level cache, not synced.
// Shape is not final — revisit when Pulse check-in UI is built.

struct PulseEntry: Identifiable, Codable {
    var id:            UUID               = UUID()
    var date:          Date
    var capacityScore: Double              // 1.0–4.0 — clamped result of check-in math
    var glowColor:     PulseCapacityColor  // Q4 answer — maps to AppColors
    var speed:         String              // Q5 answer label

    // Q1–Q3 answers — displayed in dot summary sheet
    var nervousSystem: String              // Q1 answer label
    var focus:         String              // Q2 answer label
    var feeling:       String              // Q3 answer label
}

// MARK: - Tier convenience

extension PulseEntry {
    var tier: PulseTier {
        PulseTier.tier(for: capacityScore)
    }
}

// MARK: - Preview Data

extension PulseEntry {
    static let previews: [PulseEntry] = [
        .init(date: .daysAgo(13), capacityScore: 1.8, glowColor: .magenta, speed: "Solitude",         nervousSystem: "Overwhelmed", focus: "Deeply Inward",  feeling: "Defensive"),
        .init(date: .daysAgo(12), capacityScore: 3.4, glowColor: .cyan,    speed: "Deep Dive",        nervousSystem: "Energized",   focus: "Reaching Out",   feeling: "Adventurous"),
        .init(date: .daysAgo(11), capacityScore: 2.1, glowColor: .magenta, speed: "Just Proximity",   nervousSystem: "Exhausted",   focus: "Deeply Inward",  feeling: "Anxious"),
        .init(date: .daysAgo(10), capacityScore: 3.8, glowColor: .cyan,    speed: "Deep Dive",        nervousSystem: "Energized",   focus: "Reaching Out",   feeling: "Adventurous"),
        .init(date: .daysAgo(9),  capacityScore: 1.4, glowColor: .rose,    speed: "Solitude",         nervousSystem: "Overwhelmed", focus: "Deeply Inward",  feeling: "Defensive"),
        .init(date: .daysAgo(8),  capacityScore: 2.9, glowColor: .indigo,  speed: "Light Connection", nervousSystem: "Stable",      focus: "Balanced",       feeling: "Content"),
        .init(date: .daysAgo(7),  capacityScore: 3.6, glowColor: .cyan,    speed: "Deep Dive",        nervousSystem: "Energized",   focus: "Reaching Out",   feeling: "Adventurous"),
        .init(date: .daysAgo(6),  capacityScore: 1.6, glowColor: .rose,    speed: "Solitude",         nervousSystem: "Overwhelmed", focus: "Deeply Inward",  feeling: "Defensive"),
        .init(date: .daysAgo(5),  capacityScore: 2.4, glowColor: .indigo,  speed: "Just Proximity",   nervousSystem: "Stable",      focus: "Just Me",        feeling: "Content"),
        .init(date: .daysAgo(4),  capacityScore: 3.9, glowColor: .cyan,    speed: "Playful",          nervousSystem: "Energized",   focus: "Reaching Out",   feeling: "Adventurous"),
        .init(date: .daysAgo(3),  capacityScore: 1.2, glowColor: .rose,    speed: "Solitude",         nervousSystem: "Overwhelmed", focus: "Deeply Inward",  feeling: "Defensive"),
        .init(date: .daysAgo(2),  capacityScore: 3.2, glowColor: .cyan,    speed: "Deep Dive",        nervousSystem: "Recharging",  focus: "Reaching Out",   feeling: "Adventurous"),
        .init(date: .daysAgo(1),  capacityScore: 2.6, glowColor: .indigo,  speed: "Light Connection", nervousSystem: "Stable",      focus: "Balanced",       feeling: "Secure"),
    ]
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
