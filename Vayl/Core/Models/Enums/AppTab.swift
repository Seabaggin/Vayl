// Models/Enums/AppTab.swift
// Open Lightly

import Foundation

enum AppTab: String, CaseIterable, Hashable {
    case home
    case play
    case map
    case learn
    case settings

    var icon: String {
        switch self {
        case .home:     return "house"
        case .play:     return "play"
        case .map:      return "map"
        case .learn:    return "books.vertical"
        case .settings: return "gearshape"
        }
    }

    var label: String {
        switch self {
        case .home:     return "Home"
        case .play:     return "Play"
        case .map:      return "Map"
        case .learn:    return "Learn"
        case .settings: return "Settings"
        }
    }
}
