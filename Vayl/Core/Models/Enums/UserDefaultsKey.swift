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
    /// Set true when a couple completes their first card session — collapses the
    /// airlock's six house-rule bullets to the one-line "settle in" on repeats.
    static let hasCompletedCoupleSession = "vayl.hasCompletedCoupleSession"
    /// The pending-session banner the user dismissed. Shared across the Home
    /// and Play surfaces so one dismissal silences both.
    static let dismissedPendingSessionId = "vayl.dismissedPendingSessionId"
}
