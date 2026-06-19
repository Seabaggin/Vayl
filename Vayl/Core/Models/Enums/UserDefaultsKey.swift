//
//  UserDefaultsKey.swift
//  Vayl
//

import Foundation

/// Canonical, app-wide UserDefaults key strings.
///
/// Single source of truth for raw `UserDefaults` keys so the same string is never
/// duplicated across layers (which previously caused onboarding-routing desyncs).
/// Read/write sites that touch `UserDefaults` directly (Stores, Services, the app
/// composition root) reference these constants — never a string literal.
///
/// `hasCompletedOnboarding` is the fast launch-routing mirror of
/// `UserProfile.hasCompletedOnboarding` (the SwiftData source of truth). The
/// in-memory owner that Views read is `AppState.isOnboardingComplete`.
enum UserDefaultsKey {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
}
