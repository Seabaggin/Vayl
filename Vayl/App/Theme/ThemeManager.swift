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
        if saved == "light" && !UserDefaults.standard.bool(forKey: UserDefaultsKey.hasCompletedOnboarding) {
            saved = "dark"
            UserDefaults.standard.set("dark", forKey: "appThemeMode")
        }

        self.mode = ThemeMode(rawValue: saved) ?? .dark
    }

    var preferredColorScheme: ColorScheme? {
        // Dark-only (Act 1) — force Midnight regardless of device setting or any
        // stored appThemeMode value. Reversible: restore the switch on `mode` to
        // re-enable light/system later (light returns via AppColors.dynamic, not AppPalette).
        .dark
    }
}
