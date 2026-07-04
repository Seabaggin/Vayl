//
//  EventLogEnums.swift
//  Vayl
//
//  The Event Log's small, curated vocabulary. `EventMood` is deliberately NOT the
//  Pulse quadrant set, so an event's feeling never blurs with your capacity graph. `EventTag`
//  is a fixed NM-purposeful set, not freeform. Bryan can rework the copy later.
//

import Foundation

enum EventMood: String, CaseIterable, Codable, Identifiable {
    case light, good, mixed, tender, hard
    var id: String { rawValue }
    var label: String {
        switch self {
        case .light:  return "Light"
        case .good:   return "Good"
        case .mixed:  return "Mixed"
        case .tender: return "Tender"
        case .hard:   return "Hard"
        }
    }
}

enum EventTag: String, CaseIterable, Codable, Identifiable {
    case date, play, metamour, milestone, hardConvo, reconnection
    var id: String { rawValue }
    var label: String {
        switch self {
        case .date:         return "Date"
        case .play:         return "Play"
        case .metamour:     return "Metamour"
        case .milestone:    return "Milestone"
        case .hardConvo:    return "Hard convo"
        case .reconnection: return "Reconnection"
        }
    }
}

enum EventVisibility: String, Codable, CaseIterable, Identifiable {
    case onlyMe = "private"
    case shared = "shared"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .onlyMe: return "Private"
        case .shared: return "Shared"
        }
    }
}
