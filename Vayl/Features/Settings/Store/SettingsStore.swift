//
//  SettingsStore.swift
//  Vayl
//
//  Brain of the Settings vertical. Owns profile-edit persistence + remote push,
//  the share-capacity preference push, sign-out, and account deletion.
//  The views render and forward taps; the Store decides and does I/O.
//
//  Deps injected via init — never from @Environment.
//  ModelContext created fresh at write time — never stored on self.
//  Modeled on HomeStore / PairingStore.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "SettingsStore")

@Observable
@MainActor
final class SettingsStore {

    // MARK: - Account-action state (drives the view's confirmations + progress)

    enum AccountPhase: Equatable {
        case idle
        case signingOut
        case deleting
        case unlinking
        case error(String)
    }

    private(set) var accountPhase: AccountPhase = .idle

    /// Set true after a successful sign-out or delete so the view can route the user
    /// back out of the app shell. AppRootView re-routes reactively off AppState /
    /// AuthService; this is a belt-and-suspenders signal SettingsView uses to dismiss
    /// a pushed Settings immediately.
    private(set) var didLeaveAccount = false

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState
    private let authService: AuthService
    private let entitlements: EntitlementStore
    private let accountService: AccountService
    private let pairingService: PairingService
    private let syncManager: SyncManager
    private let pushService: PushService

    // MARK: - Init

    /// `accountService` / `pairingService` / `syncManager` / `pushService` nil resolve
    /// to instances inside the MainActor-isolated body — a default argument would
    /// evaluate in a nonisolated context and not compile.
    init(
        modelContainer: ModelContainer,
        appState: AppState,
        authService: AuthService,
        entitlements: EntitlementStore,
        accountService: AccountService? = nil,
        pairingService: PairingService? = nil,
        syncManager: SyncManager? = nil,
        pushService: PushService? = nil
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.authService = authService
        self.entitlements = entitlements
        self.accountService = accountService ?? AccountService()
        self.pairingService = pairingService ?? PairingService()
        self.syncManager = syncManager ?? .shared
        self.pushService = pushService ?? .shared
    }

    // MARK: - Identity edit (name / pronouns / experience)

    enum IdentityField { case name, pronouns, experience }

    /// Persists an identity edit to local SwiftData, mirrors the name into AppState so the
    /// header + routing update instantly, then pushes the partner-visible fields to remote
    /// `user_profiles`. Name/pronouns push through SyncManager.pushDisplayIdentity,
    /// experience through pushNMStage.
    func saveIdentity(field: IdentityField, rawText: String, stage: NMStage) {
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else {
            logger.error("saveIdentity — no UserProfile found")
            return
        }

        switch field {
        case .name:
            let trimmed = rawText.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            profile.displayName = trimmed
            appState.displayName = trimmed        // instant header + routing update
        case .pronouns:
            let trimmed = rawText.trimmingCharacters(in: .whitespaces)
            profile.pronouns = trimmed.isEmpty ? [] : trimmed
                .components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
        case .experience:
            profile.nmStage = stage
        }

        do {
            try context.saveWithLogging()
        } catch {
            logger.error("saveIdentity — local save failed: \(error.localizedDescription)")
            return
        }

        // Remote push (partner-visible fields). Best-effort — SyncManager logs failures.
        // The fetch context must outlive the push: `profile` is bound to it, and a
        // deallocated context would leave the model unreadable mid-push.
        Task { [syncManager] in
            switch field {
            case .name, .pronouns:
                await syncManager.pushDisplayIdentity(localProfile: profile)
            case .experience:
                await syncManager.pushNMStage(stage.rawValue)
            }
            withExtendedLifetime(context) {}
        }
    }

    // MARK: - Privacy preference (share capacity with partner)

    /// Pushes the "share capacity with partner" preference to remote `user_profiles`.
    /// Was called directly from SettingsPrivacyView (H-2 violation) — now routed here.
    func setShareCapacity(_ value: Bool) {
        Task { [syncManager] in await syncManager.pushSharePulse(value) }
    }

    // MARK: - Notifications (Settings > Notifications reminder toggles)

    /// Checks/requests local notification permission for a reminder toggle. Returns
    /// `true` when permission was denied (the caller should revert its toggle and
    /// surface the "notifications are off" alert), `false` when authorized.
    func requestNotificationPermission() async -> Bool {
        let result = await pushService.requestNotificationPermission()
        return result == .denied
    }

    // MARK: - Connection composition (spec §9 Settings row)

    /// The couple's current composition, for the row value + picker checkmark.
    /// Hydrated from the local Couple mirror instantly, then the remote row.
    private(set) var composition: GenderDynamic = .flexible

    func loadComposition() async {
        guard let coupleId = appState.coupleId else { return }
        // Instant local mirror (may not exist — nothing creates Couple rows locally).
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        if let couple = try? context.fetch(descriptor).first {
            composition = couple.connectionComposition
        }
        // Remote truth.
        if let remote = try? await pairingService.fetchComposition(coupleId: coupleId) {
            composition = remote
        }
    }

    /// Writes the chosen composition through the RPC and mirrors it into the
    /// local Couple if one exists (mirror-if-present — never creates rows).
    /// Optimistic UI; reverts on failure.
    func setComposition(_ value: GenderDynamic) async {
        guard let coupleId = appState.coupleId else { return }
        let previous = composition
        composition = value
        do {
            try await pairingService.setComposition(coupleId: coupleId, value)
            let context = ModelContext(modelContainer)
            let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
            if let couple = try? context.fetch(descriptor).first {
                couple.connectionComposition = value
                try? context.saveWithLogging()
            }
        } catch {
            composition = previous
            logger.error("setComposition failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Unlink partner

    /// The unlink confirm message, honest about what actually happens for THIS user.
    /// Unlinking dissolves the couple, so the couple's Core tier goes with it; the buyer
    /// keeps access via local StoreKit ownership (isCore = tier OR localOwnsCore) and
    /// re-grants the couple on re-pairing. The non-payer's access ends with the pairing.
    var unlinkWarning: String {
        let base = "You each keep your own answers, but shared things like your Desire Map matches are removed."
        guard entitlements.isCore else {
            return base + " You can pair again anytime."
        }
        if entitlements.localOwnsCore {
            return base + " Your partner's full access ends, but your Lifetime purchase stays with you and unlocks again when you pair."
        }
        return base + " Full access came with this pairing, so your membership returns to free until you pair with the purchaser again."
    }

    /// Dissolves the couple. Remote first (both members reverted to unpaired, the couple
    /// row + shared artifacts deleted server-side); only on success is the local mirror
    /// cleared — the caller's profile goes unlinked, the couple-scoped shared rows
    /// (Couple, DesireMatch, DesireMapStatus) are removed to match the server, and
    /// session history stays (archival, per the AppState.unlink stance). The signed-in
    /// account itself is untouched. Quiet data hygiene — no fanfare.
    func unlink() async {
        accountPhase = .unlinking
        do {
            try await accountService.unlinkPartner()
        } catch {
            accountPhase = .error(error.localizedDescription)
            logger.error("Unlink failed: \(error.localizedDescription)")
            return
        }

        let context = ModelContext(modelContainer)
        if let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first {
            let coupleId = profile.coupleId ?? appState.coupleId
            profile.isLinked = false
            profile.coupleId = nil
            profile.partnerGenderIdentity = nil
            profile.partnerPronouns = nil
            profile.firstInviteSentAt = nil
            if let coupleId {
                try? context.delete(model: Couple.self,
                                    where: #Predicate { $0.id == coupleId })
                try? context.delete(model: DesireMatch.self,
                                    where: #Predicate { $0.coupleId == coupleId })
                try? context.delete(model: DesireMapStatus.self,
                                    where: #Predicate { $0.coupleId == coupleId })
            }
            try? context.saveWithLogging()
        }

        // Re-linking must earn the Us reveal ceremony again (Map spec §2.3).
        MapStore.resetUsRevealGlobally()

        appState.unlink()   // clears coupleId + linkState → routing re-renders unlinked
        accountPhase = .idle
        logger.info("Unlink complete — partner link dissolved")
    }

    // MARK: - Sign out

    /// Signs out of Supabase and wipes the local store; AppRootView then routes back to
    /// onboarding / sign-in reactively. Release-safe (no #if DEBUG gate).
    func signOut() async {
        accountPhase = .signingOut
        await accountService.signOut()
        accountService.wipeLocalStore(container: modelContainer)
        resetAppStateAfterLeaving()
        await authService.signOut()   // clears isAuthenticated → reactive routing
        accountPhase = .idle
        didLeaveAccount = true
        logger.info("Sign-out complete")
    }

    // MARK: - Delete account (A1 — hard App Store blocker)

    /// Irreversibly deletes the account. The server hard-deletes the caller's profile row
    /// (and cascades their own artifacts), reverts any partner to unpaired/free, and deletes
    /// the couple when it empties. Only on success do we sign out + wipe local + route out.
    func deleteAccount() async {
        accountPhase = .deleting
        do {
            try await accountService.deleteRemoteAccount()
        } catch {
            accountPhase = .error(error.localizedDescription)
            logger.error("Delete account failed: \(error.localizedDescription)")
            return
        }
        accountService.wipeLocalStore(container: modelContainer)
        resetAppStateAfterLeaving()
        await accountService.signOut()
        await authService.signOut()
        accountPhase = .idle
        didLeaveAccount = true
        logger.info("Account deleted + local cleared")
    }

    /// Dismisses a surfaced account-action error.
    func clearError() {
        if case .error = accountPhase { accountPhase = .idle }
    }

    // MARK: - Private

    /// Clears in-memory routing so the root re-renders to onboarding / sign-in cleanly.
    private func resetAppStateAfterLeaving() {
        appState.coupleId = nil
        appState.linkState = .unlinked
        appState.displayName = ""
        appState.resetOnboarding(nil, context: nil)   // clears the surface + cache (no profile left)
    }
}
