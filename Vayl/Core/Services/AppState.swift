//
//  AppState.swift
//  Vayl
//

import Foundation
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "AppState"
)

/// Central app-level state. Injected as @Environment at the root.
/// Owns onboarding gate, link state, and tab routing.
/// Does not own feature-level state — that lives in feature Stores.
@MainActor
@Observable
final class AppState {

    // MARK: - Onboarding

    var isOnboardingComplete: Bool {
        didSet {
            persist(isOnboardingComplete, forKey: .onboardingComplete)
            logger.info("Onboarding complete: \(self.isOnboardingComplete)")
        }
    }

    // MARK: - Identity

    var displayName: String {
        didSet {
            persist(displayName, forKey: .displayName)
        }
    }

    // MARK: - Routing

    /// Whether this user has linked a partner.
    /// Drives content visibility and home state rendering.
    var linkState: LinkState {
        didSet {
            persist(linkState.rawValue, forKey: .linkState)
            logger.info("LinkState changed to: \(self.linkState.rawValue)")
        }
    }

    /// The mode the user selected in onboarding — together, solo, or browsing.
    /// Mutable — user can switch in Settings (browsing users cannot switch without re-onboarding).
    var appMode: AppMode {
        didSet {
            persist(appMode.rawValue, forKey: .appMode)
            logger.info("AppMode changed to: \(self.appMode.rawValue)")
        }
    }

    /// The couple ID assigned after partner linking.
    /// Mirrors UserProfile.coupleId — UserProfile is the source of truth.
    /// Persisted to UserDefaults for fast in-memory routing on relaunch.
    var coupleId: UUID? {
        didSet {
            if let id = coupleId {
                persist(id.uuidString, forKey: .coupleId)
                logger.info("CoupleId set: \(id)")
            } else {
                UserDefaults.standard.removeObject(forKey: PersistenceKey.coupleId.rawValue)
                logger.info("CoupleId cleared")
            }
        }
    }

    // MARK: - Navigation

    var selectedTab: AppTab = .home
    var loadState: AppLoadState = .idle

    // MARK: - Init

    init() {
        // isOnboardingComplete
        self.isOnboardingComplete = UserDefaults.standard.bool(
            forKey: PersistenceKey.onboardingComplete.rawValue
        )

        // displayName
        let savedName = UserDefaults.standard.string(
            forKey: PersistenceKey.displayName.rawValue
        )
        #if DEBUG
        if savedName == nil || savedName!.isEmpty {
            UserDefaults.standard.set("Jordan", forKey: PersistenceKey.displayName.rawValue)
        }
        #endif
        self.displayName = UserDefaults.standard.string(
            forKey: PersistenceKey.displayName.rawValue
        ) ?? ""

        // linkState
        let savedLinkRaw = UserDefaults.standard.string(
            forKey: PersistenceKey.linkState.rawValue
        )
        if let raw = savedLinkRaw, let resolved = LinkState(rawValue: raw) {
            self.linkState = resolved
        } else {
            self.linkState = .unlinked
        }

        // appMode
        let savedAppModeRaw = UserDefaults.standard.string(
            forKey: PersistenceKey.appMode.rawValue
        )
        if let raw = savedAppModeRaw, let resolved = AppMode(rawValue: raw) {
            self.appMode = resolved
        } else {
            self.appMode = .together
            if savedAppModeRaw != nil {
                logger.warning("Unrecognised appMode in UserDefaults — defaulting to together")
            }
        }

        // coupleId
        if let savedCoupleId = UserDefaults.standard.string(
            forKey: PersistenceKey.coupleId.rawValue
        ), let uuid = UUID(uuidString: savedCoupleId) {
            self.coupleId = uuid
        } else {
            self.coupleId = nil
        }
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
        // Canonical app-wide onboarding-completion flag — the SAME key read/written by
        // AppRootView, VaylApp, ThemeManager, SettingsView, SyncManager, and OnboardingStore.
        // (AppState previously used a divergent "isOnboardingComplete", which desynced on
        // partial-update paths like the DEBUG reset and SyncManager.)
        case onboardingComplete  = "hasCompletedOnboarding"
        case displayName         = "displayName"
        case linkState           = "linkState"
        case appMode             = "appMode"
        case coupleId            = "coupleId"
    }
}

// MARK: - App Load State

enum AppLoadState {
    case idle
    case loading
    case ready
    case error(String)
}
