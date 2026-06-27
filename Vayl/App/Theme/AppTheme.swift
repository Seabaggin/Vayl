//
//  AppTheme.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

// MARK: - Theme Mode

enum ThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }
}

// AppPalette (the legacy parallel light/dark color system, with desaturated dark
// values) was removed in the dark-only consolidation — all color now flows through
// AppColors. ThemeMode is retained for persistence/migration; the app is hard-locked
// to .dark in ThemeManager.preferredColorScheme.
