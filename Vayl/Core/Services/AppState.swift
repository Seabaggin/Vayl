//
//  AppState.swift
//  Vayl
//

import Foundation
import OSLog
import SwiftData

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

    /// The single in-memory read surface for onboarding completion. Read-only from
    /// outside — mutated only by the onboarding writers below, so it can never desync
    /// from the durable truth (UserProfile). Its didSet is the ONLY UserDefaults
    /// cache-write site.
    private(set) var isOnboardingComplete: Bool {
        didSet {
            UserDefaults.standard.set(isOnboardingComplete, forKey: UserDefaultsKey.hasCompletedOnboarding)
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
    /// Transient flag: set true to signal MapView to auto-open the Vault.
    /// MapView resets it to false immediately after presenting.
    var vaultOpenPending: Bool = false
    var loadState: AppLoadState = .idle

    // MARK: - Init

    init() {
        // isOnboardingComplete
        self.isOnboardingComplete = UserDefaults.standard.bool(
            forKey: UserDefaultsKey.hasCompletedOnboarding
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

    // MARK: - Onboarding Writers
    //
    // The ONLY writers of onboarding completion. UserProfile is the durable truth;
    // isOnboardingComplete is the in-memory surface; the UserDefaults cache is written
    // by the surface's didSet. Setting all three here — and only here — is what makes
    // completion impossible to desync.

    /// Marks onboarding complete across truth (UserProfile) + surface + cache.
    /// The single completion writer. Callers pass the profile + the context it was
    /// fetched on so truth and surface commit together.
    func markOnboardingComplete(_ profile: UserProfile, context: ModelContext) {
        profile.hasCompletedOnboarding = true
        profile.onboardingCompletedAt  = Date()
        try? context.save()
        isOnboardingComplete = true   // didSet writes the UserDefaults cache
    }

    /// Clears onboarding completion across truth + surface + cache. The single reset.
    /// Pass nil profile/context to clear only the surface + cache (e.g. when no
    /// profile exists yet) — though a launch reconcile would re-derive from truth.
    func resetOnboarding(_ profile: UserProfile?, context: ModelContext?) {
        profile?.hasCompletedOnboarding = false
        profile?.onboardingCompletedAt  = nil
        if let context { try? context.save() }
        isOnboardingComplete = false
    }

    /// Reconciles the in-memory surface (and thus the cache) against the durable
    /// truth at launch — UserProfile wins. `init` reads the UserDefaults cache for
    /// instant synchronous routing; this corrects any drift (e.g. from remote sync).
    /// Call once at startup.
    func hydrateOnboardingState(from container: ModelContainer) {
        let context = ModelContext(container)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        if isOnboardingComplete != profile.hasCompletedOnboarding {
            isOnboardingComplete = profile.hasCompletedOnboarding
        }
    }

    // MARK: - Unlink (Seg 9 scaffold — UNVERIFIED)
    //
    // Local breakup/dissolve: drops the partner link so routing returns to an
    // unlinked state. ARCHIVAL, not deletion — we do NOT delete the Couple or its
    // history (Couple's deleteRule is .nullify). The remote side (marking the
    // couples row dissolved, tearing down any open curated_session, revoking the
    // partner's device tokens) is NOT wired — it needs the backend work + a
    // two-device test. Per CLAUDE.md humility, a breakup needs no in-app fanfare;
    // this is quiet data hygiene.

    /// Clears the local partner link. Leaves history and the remote Couple row intact.
    func unlink() {
        coupleId = nil
        linkState = .unlinked
        logger.info("Local unlink — partner link cleared (history retained)")
    }

    // MARK: - Private Helpers

    private func persist(_ value: String, forKey key: PersistenceKey) {
        UserDefaults.standard.set(value, forKey: key.rawValue)
    }

    // MARK: - Persistence Keys

    // Note: the onboarding-completion flag is keyed by the shared
    // `UserDefaultsKey.hasCompletedOnboarding` (see isOnboardingComplete), not this enum.
    private enum PersistenceKey: String {
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
