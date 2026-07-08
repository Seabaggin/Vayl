// Models/Enums/AppTab.swift
// Open Lightly

import Foundation

// Settings is NOT a tab — it opens as a full-screen cover from the masthead
// gear on every tab (AppState.settingsPresented, presented in AppShell).
enum AppTab: String, CaseIterable, Hashable {
    case home
    case play
    case map
    case learn

    var icon: String {
        switch self {
        case .home:  return "house"
        case .play:  return "play"
        case .map:   return "map"
        case .learn: return "books.vertical"
        }
    }

    var label: String {
        switch self {
        case .home:  return "Home"
        case .play:  return "Play"
        case .map:   return "Map"
        case .learn: return "Learn"
        }
    }

    var filledIcon: String {
        switch self {
        case .home:  return "house.fill"
        case .play:  return "play.fill"
        case .map:   return "map.fill"
        case .learn: return "books.vertical.fill"
        }
    }
}
