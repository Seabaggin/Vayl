//
//  AccountService.swift
//  Vayl
//
//  I/O for irreversible account actions: delete-account (service-role edge function)
//  and sign-out. No state, no UI knowledge — injected into SettingsStore.
//  deleteRemoteAccount mirrors PairingService: async/await, errors rethrown, never
//  swallowed. signOut is deliberately best-effort so local session teardown can
//  always proceed even when the network call fails.
//

import Foundation
import SwiftData
import Supabase
import OSLog

private let logger = Logger(subsystem: "com.vayl.app", category: "AccountService")

/// Deployed edge-function slugs (same convention as PairingService.SupabaseFunction).
private enum AccountFunction {
    static let deleteAccount = "delete-account"
}

@MainActor
final class AccountService {

    private let supabase: SupabaseClient

    /// Nil resolves to the shared client inside the MainActor-isolated body —
    /// a default argument would evaluate in a nonisolated context and not compile.
    init(supabase: SupabaseClient? = nil) {
        self.supabase = supabase ?? SupabaseManager.shared.client
    }

    /// Invokes the `delete-account` edge function. The server hard-deletes the caller's
    /// `user_profiles` row (Postgres cascades their own per-user artifacts), reverts any
    /// partner to unpaired/free, and deletes the couple when it empties. Throws on failure —
    /// the caller must NOT sign out or wipe local data unless this succeeds.
    func deleteRemoteAccount() async throws {
        struct DeleteResponse: Decodable { let deleted: Bool }
        let response: DeleteResponse = try await supabase.functions.invoke(
            AccountFunction.deleteAccount,
            options: FunctionInvokeOptions()
        )
        guard response.deleted else {
            throw AccountError.deletionRejected
        }
        logger.info("Remote account deleted")
    }

    /// Ends the Supabase session. Best-effort — local session teardown must still proceed
    /// even if the network call fails (the app must not be stuck signed-in).
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            logger.info("Signed out of Supabase")
        } catch {
            logger.warning("Supabase signOut failed (non-fatal): \(error.localizedDescription)")
        }
    }

    /// Wipes every local SwiftData row so no stale profile / session survives a sign-out or
    /// account deletion. Takes the shared app container so it clears the same store the app
    /// reads. Also clears the cached remote profile id + pending-sync flags in UserDefaults.
    func wipeLocalStore(container: ModelContainer) {
        let context = ModelContext(container)
        for model in SchemaV1.models {
            try? context.delete(model: model)
        }
        try? context.saveWithLogging()
        for key in ["supabaseProfileId", "pendingProfileSync", "pendingOnboardingSync", "pendingDesireSync"] {
            UserDefaults.standard.removeObject(forKey: key)
        }
        logger.info("Local store wiped")
    }

    enum AccountError: LocalizedError {
        case deletionRejected
        var errorDescription: String? {
            switch self {
            case .deletionRejected: return "Your account could not be deleted. Please try again."
            }
        }
    }
}
