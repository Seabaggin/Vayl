//
//  PulseCapacityColor.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/6/26.
//


// Models/PulseEntry.swift
// Open Lightly

import SwiftUI

// MARK: - PulseCapacityColor

enum PulseCapacityColor: String, Codable, CaseIterable {
    case rose    // Q4: Empty    — tier 1
    case magenta // Q4: Low      — tier 2
    case indigo  // Q4: Good     — tier 3
    case cyan    // Q4: Abundant — tier 4

    var color: Color {
        switch self {
        case .rose:    return AppColors.pink
        case .magenta: return AppColors.magenta
        case .indigo:  return AppColors.electricViolet
        case .cyan:    return AppColors.cyan
        }
    }

    var label: String {
        switch self {
        case .rose:    return "Empty"
        case .magenta: return "Low"
        case .indigo:  return "Good"
        case .cyan:    return "Abundant"
        }
    }
}

// MARK: - PulseTier

enum PulseTier {
    case expansive   // 3.5+
    case sovereign   // 2.5–3.5
    case friction    // 1.5–2.5
    case protective  // < 1.5

    static func tier(for score: Double) -> PulseTier {
        switch score {
        case 3.5...: return .expansive
        case 2.5...: return .sovereign
        case 1.5...: return .friction
        default:     return .protective
        }
    }

    var label: String {
        switch self {
        case .expansive:  return "The Expansive Space"
        case .sovereign:  return "The Sovereign Space"
        case .friction:   return "The Friction Space"
        case .protective: return "The Protective Space"
        }
    }

    var sublabel: String {
        switch self {
        case .expansive:  return "Connected · Adventurous"
        case .sovereign:  return "Grounded · Secure"
        case .friction:   return "Anxious · Defensive"
        case .protective: return "Overwhelmed · Need Space"
        }
    }

    var color: Color {
        switch self {
        case .expansive:  return AppColors.cyan
        case .sovereign:  return AppColors.electricViolet
        case .friction:   return AppColors.magenta
        case .protective: return AppColors.pink
        }
    }

    // Light mode — same hue, reads on cream
    var lightColor: Color {
        switch self {
        case .expansive:  return AppColors.cyanDark
        case .sovereign:  return AppColors.purple
        case .friction:   return AppColors.magenta
        case .protective: return AppColors.magentaDark
        }
    }
}

// MARK: - PulseEntry

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
