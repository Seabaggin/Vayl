//
//  AppPulseEnums.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/22/26.
//

import SwiftUI

// ─────────────────────────────────────────────────────────────
// MARK: - Pulse
// ─────────────────────────────────────────────────────────────

/// What created a pulse entry.
/// All three sources write to the same PulseEntry store.
enum PulseSource: String, CaseIterable, Codable {
    case manual
    case lockIn
    case postSession

    var displayName: String {
        switch self {
        case .manual:      return "Manual"
        case .lockIn:      return "Lock In"
        case .postSession: return "Post Session"
        }
    }
}

/// The type of insight generated from pulse data.
/// Insights are observational — never evaluative.
/// "Your bandwidth has been lower this week" not "You seem stressed."
enum InsightType: String, CaseIterable, Codable {
    case weeklyPattern
    case trending
    case anomaly
}

/// Color tier for a pulse entry — maps to AppColors in AppColors.swift extension.
/// Names and tiers are not final — revisit when PulseEntry shape is confirmed.
enum PulseCapacityColor: String, Codable, CaseIterable {
    case rose       // tier 1 — lowest
    case magenta    // tier 2
    case indigo     // tier 3
    case cyan       // tier 4 — highest

    var label: String {
        switch self {
        case .rose:    return "Empty"
        case .magenta: return "Low"
        case .indigo:  return "Good"
        case .cyan:    return "Abundant"
        }
    }
}

/// The four corner quadrants of the capacity circumplex (energy x openness).
/// These are the geometric anchors of the space system; the richer six-space
/// classification (incl. Neutral / Uncharted / border states) lives in `PulseSpace`.
/// Axis rule: midline (0.5) ties resolve toward charged/open.
/// Note: `reactive`/`receptive` were formerly named `friction`/`sovereign` — the case
/// identifiers are never persisted (quadrant is derived from PulsePosition), so the
/// rename is display-and-vocabulary only.
nonisolated enum PulseQuadrant: String, CaseIterable, Codable {
    case expansive   // high energy + open    (top-right)
    case reactive    // high energy + guarded (top-left)
    case receptive   // low energy  + open    (bottom-right)
    case protective  // low energy  + guarded (bottom-left)

    var spaceName: String {
        switch self {
        case .expansive:  return "The Expansive Space"
        case .reactive:   return "The Reactive Space"
        case .receptive:  return "The Receptive Space"
        case .protective: return "The Protective Space"
        }
    }

    var sublabel: String {
        switch self {
        case .expansive:  return "Connected · Vibrant"
        case .reactive:   return "Buzzing · Tense"
        case .receptive:  return "Gentle · Available"
        case .protective: return "Still · Withdrawn"
        }
    }

    /// Capacity-tier colour token for the aura body.
    var capacityColor: PulseCapacityColor {
        switch self {
        case .expansive:  return .cyan
        case .receptive:  return .indigo
        case .reactive:   return .magenta
        case .protective: return .rose
        }
    }
}

/// Time window for pulse graph display.
/// widgetDefault drives the home screen widget.
/// Full window selector appears in PulseFullView only.
enum PulseWindow: String, CaseIterable, Identifiable {
    case oneWeek      = "1W"
    case twoWeeks     = "2W"
    case oneMonth     = "1M"
    case threeMonths  = "3M"
    case sixMonths    = "6M"
    case oneYear      = "1Y"
    case twoYears     = "2Y"
    case lifetime     = "All"

    var id: String { rawValue }

    var startDate: Date? {
        guard self != .lifetime else { return nil }
        return Calendar.current.date(
            byAdding: .day,
            value: -days,
            to: Date()
        )
    }

    func includes(_ date: Date) -> Bool {
        guard let start = startDate else { return true }
        return date >= start
    }

    func filter(_ entries: [PulseEntry]) -> [PulseEntry] {
        guard let start = startDate else { return entries }
        return entries.filter { $0.date >= start }
    }

    var days: Int {
        switch self {
        case .oneWeek:     return 7
        case .twoWeeks:    return 14
        case .oneMonth:    return 30
        case .threeMonths: return 90
        case .sixMonths:   return 180
        case .oneYear:     return 365
        case .twoYears:    return 730
        case .lifetime:    return Int.max
        }
    }

    var graphWidth: CGFloat {
        switch self {
        case .oneWeek:     return 320
        case .twoWeeks:    return 320
        case .oneMonth:    return 480
        case .threeMonths: return 640
        case .sixMonths:   return 960
        case .oneYear:     return 1400
        case .twoYears:    return 2400
        case .lifetime:    return 2400
        }
    }

    var label: String { rawValue }

    var accessibilityLabel: String {
        switch self {
        case .oneWeek:     return "One week"
        case .twoWeeks:    return "Two weeks"
        case .oneMonth:    return "One month"
        case .threeMonths: return "Three months"
        case .sixMonths:   return "Six months"
        case .oneYear:     return "One year"
        case .twoYears:    return "Two years"
        case .lifetime:    return "All time"
        }
    }

    static let widgetDefault: PulseWindow = .twoWeeks
}
