//
//  UsOrbState.swift
//  Vayl
//
//  The Us orb's per-half state machine (Map dashboard spec §3.3). Pure logic —
//  no SwiftUI. One rule: cycling = unwritten, solid = current, ember = quiet.
//

import Foundation

enum UsOrbState: Equatable {

    /// Neither partner has EVER checked in → one whole cycling orb.
    /// The first entry by either partner earns the split.
    case wholeUnwritten
    case split(mine: HalfState, partner: HalfState)

    enum HalfState: Equatable {
        case unwritten   // never checked in → cycling ramp
        case current     // entry within the quiet window → solid space colour
        case quiet       // has history, none within window → ember (0.6 α, desaturated)
    }

    /// The second, deeper staleness threshold (isPositionStale = not-today only
    /// softens copy). Start value 4 — FEEL: tune on device.
    static let quietAfterDays = 4

    static func halfState(entries: [PulseEntry], now: Date = Date()) -> HalfState {
        guard let last = entries.last?.date else { return .unwritten }
        // Normalize BOTH ends to startOfDay so this counts calendar days, the same
        // way PulseStore.relativeDay does. Raw timestamps counted elapsed 24h blocks
        // instead, so the orb and the staleness copy could disagree near the 4-day
        // boundary (an evening entry viewed 4 calendar days later in the morning
        // read as only 3 elapsed blocks: copy said "4 days ago", orb stayed solid).
        let cal = Calendar.current
        let days = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: last),
            to: cal.startOfDay(for: now)
        ).day ?? .max
        return days < quietAfterDays ? .current : .quiet
    }

    static func resolve(mine: [PulseEntry], partner: [PulseEntry], now: Date = Date()) -> UsOrbState {
        if mine.isEmpty && partner.isEmpty { return .wholeUnwritten }
        return .split(mine: halfState(entries: mine, now: now),
                      partner: halfState(entries: partner, now: now))
    }

    /// Headline guard: the relational read may only compute distance when BOTH
    /// halves are current.
    var allowsLiveComparison: Bool {
        if case .split(.current, .current) = self { return true }
        return false
    }
}
