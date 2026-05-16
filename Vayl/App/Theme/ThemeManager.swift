//
//  ThemeManager.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/8/26.
//

import SwiftUI

@Observable
class ThemeManager {

    var mode: ThemeMode {
        didSet {
            UserDefaults.standard.set(mode.rawValue, forKey: "appThemeMode")
        }
    }

    init() {
        var saved = UserDefaults.standard.string(forKey: "appThemeMode") ?? "dark"

        // Migrate legacy "amoled" value → "dark"
        if saved == "amoled" {
            saved = "dark"
            UserDefaults.standard.set("dark", forKey: "appThemeMode")
        }

        // Migrate stale "light" value when onboarding is not yet complete.
        // Light mode is unavailable in Act 1 — if "light" is stored and the
        // user has not finished onboarding, it leaked from a dev/test session.
        // Reset to "dark" so cold launch always starts with the Midnight palette.
        if saved == "light" && !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            saved = "dark"
            UserDefaults.standard.set("dark", forKey: "appThemeMode")
        }

        self.mode = ThemeMode(rawValue: saved) ?? .dark
    }

    func palette(for systemScheme: ColorScheme) -> AppPalette {
        switch mode {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return systemScheme == .dark ? .dark : .light
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - Environment Key

private struct PaletteKey: EnvironmentKey {
    // .dark — any view outside .themedRoot() gets Midnight, not Dawn.
    // Previously .light caused unthemed routes (SignIn, OB) to render
    // the warm palette even on dark-mode devices.
    static let defaultValue: AppPalette = .dark
}

extension EnvironmentValues {
    var theme: AppPalette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
