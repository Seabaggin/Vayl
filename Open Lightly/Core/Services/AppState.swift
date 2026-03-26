//
//  AppState.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/20/26.
//


// Core/AppState.swift

import Foundation
import OSLog

private let logger = Logger(
    subsystem: "com.openlightly.app",
    category: "AppState"
)

/// Central app-level state. Injected as @Environment at the root.
/// Owns experience routing and onboarding gate.
/// Does not own feature-level state — that lives in feature ViewModels.
@MainActor
@Observable
final class AppState {

    // MARK: - Published State

    var experienceType: ExperienceType {
        didSet {
            persist(experienceType.rawValue, forKey: .experienceType)
            logger.info("Experience changed to: \(self.experienceType.rawValue)")
        }
    }

    var isOnboardingComplete: Bool {
        didSet {
            persist(isOnboardingComplete, forKey: .onboardingComplete)
            logger.info("Onboarding complete: \(self.isOnboardingComplete)")
        }
    }

    var loadState: AppLoadState = .idle

    // MARK: - Init

    init() {
        // Safe read — defaults to .soloSingle if key missing or unrecognised.
        // Unrecognised raw value means a future migration introduced a new case
        // before this version knew about it — .soloSingle is the safest fallback.
        let savedRaw = UserDefaults.standard.string(forKey: PersistenceKey.experienceType.rawValue)

        if let raw = savedRaw, let resolved = ExperienceType(rawValue: raw) {
            self.experienceType = resolved
        } else {
            self.experienceType = .soloSingle
            if savedRaw != nil {
                // A value existed but wasn't recognised — log for diagnostics.
                // Do NOT log the raw value itself (could contain user-entered data in future).
                logger.warning("Unrecognised experienceType in UserDefaults — defaulting to soloSingle")
            }
        }

        self.isOnboardingComplete = UserDefaults.standard.bool(
            forKey: PersistenceKey.onboardingComplete.rawValue
        )
    }

    // MARK: - Private Helpers

    private func persist(_ value: String, forKey key: PersistenceKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    private func persist(_ value: Bool, forKey key: PersistenceKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    // MARK: - Persistence Keys

    private enum PersistenceKey: String {
        case experienceType    = "experienceType"
        case onboardingComplete = "isOnboardingComplete"
    }
}

// MARK: - App Load State

enum AppLoadState {
    case idle
    case loading
    case ready
    case error(String)
}