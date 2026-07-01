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
    private let accountService: AccountService

    // MARK: - Init

    /// `accountService` nil resolves to a fresh AccountService inside the MainActor-isolated
    /// body — a default argument would evaluate in a nonisolated context and not compile.
    init(
        modelContainer: ModelContainer,
        appState: AppState,
        authService: AuthService,
        accountService: AccountService? = nil
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        self.authService = authService
        self.accountService = accountService ?? AccountService()
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
        Task {
            switch field {
            case .name, .pronouns:
                await SyncManager.shared.pushDisplayIdentity(localProfile: profile)
            case .experience:
                await SyncManager.shared.pushNMStage(stage.rawValue)
            }
            withExtendedLifetime(context) {}
        }
    }

    // MARK: - Privacy preference (share capacity with partner)

    /// Pushes the "share capacity with partner" preference to remote `user_profiles`.
    /// Was called directly from SettingsPrivacyView (H-2 violation) — now routed here.
    func setShareCapacity(_ value: Bool) {
        Task { await SyncManager.shared.pushSharePulse(value) }
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
