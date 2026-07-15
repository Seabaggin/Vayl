//
//  AuthService.swift
//  Vayl
//

import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import Supabase

// MARK: - Session Failure Outcome

/// How a failed session check should be handled. A returning signed-in user who
/// cold-launches offline must NOT be bounced to SignIn: `supabase.auth.session`
/// refreshes an expired access token over the network, and that refresh throws a raw
/// `URLError` on a transport failure (a revoked/invalid grant comes back as an
/// `AuthError` instead). So a network failure with a stored session is recoverable;
/// everything else means sign out. Top-level and `nonisolated` (the module defaults
/// to `@MainActor` isolation) so the pure classifier and its `Equatable` conformance
/// stay usable from a nonisolated test context.
nonisolated enum SessionFailureOutcome: Equatable {
    /// Keep the user in, flag offline, retry the refresh later.
    case retryOffline
    /// Clear local auth and route to SignIn (revoked/invalid grant, or nothing cached).
    case signOut
}

// MARK: - AuthService

@Observable
@MainActor
final class AuthService: NSObject {

    // MARK: - State

    /// Starts false. Set to true only after a real session is confirmed.
    /// Never defaults to true. Never bypassed on simulator.
    var isAuthenticated = false
    var userId: UUID?
    var isLoading = false
    var error: String?

    /// True when we're authenticated from a cached session but couldn't reach the
    /// network to refresh it (returning user, cold-launched offline). Drives the
    /// non-blocking Home offline banner. Cleared the moment a refresh succeeds.
    var isOffline = false

    // MARK: - Private

    private var currentNonce: String?
    private var isObservingAuthState = false

    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }

    // MARK: - Session Check

    /// Classifies a thrown session-check error. Pure — no I/O, no actor state — so it
    /// is unit-tested directly. Only a transport failure (`URLError`) with a stored
    /// session to fall back on is recoverable offline; auth failures (`AuthError`,
    /// surfaced as any non-`URLError`) and "no stored session" both sign out.
    nonisolated static func classifyFailure(
        _ error: Error,
        hasStoredSession: Bool
    ) -> SessionFailureOutcome {
        guard hasStoredSession else { return .signOut }
        return (error is URLError) ? .retryOffline : .signOut
    }

    /// Call once on app launch from VaylApp or AppShell.
    /// Resolves the real auth state from Supabase — no simulator shortcuts.
    ///
    /// `supabase.auth.session` refreshes an expired access token over the network, so a
    /// returning user who cold-launches offline lands in the catch block. We must NOT
    /// sign that user out: `classifyFailure` keeps them in (offline) when the failure is
    /// a transport error and a cached session exists, and only signs out on a genuine
    /// auth failure (revoked/invalid grant) or when nothing is cached.
    func checkSession() async {
        do {
            let session = try await supabase.auth.session

            // `.session` already refreshed an expired token above, so this is defensive.
            if session.isExpired {
                try? await supabase.auth.signOut()
                self.isAuthenticated = false
                self.userId = nil
                self.isOffline = false
                return
            }

            self.userId = session.user.id
            self.isAuthenticated = true
            self.isOffline = false
            PostHogService.shared.identify(authId: session.user.id, email: session.user.email)
            await ensureRemoteProfile()
        } catch {
            // A stored (possibly expired) session survives a failed refresh — read it
            // WITHOUT the network via `currentSession`.
            let cached = supabase.auth.currentSession
            switch AuthService.classifyFailure(error, hasStoredSession: cached != nil) {
            case .retryOffline:
                // Network failure with a cached session: stay in, show offline, and let
                // `retrySessionIfOffline` / the auth-state observer recover us later.
                self.userId = cached?.user.id
                self.isAuthenticated = true
                self.isOffline = true
            case .signOut:
                self.isAuthenticated = false
                self.userId = nil
                self.isOffline = false
            }
        }
    }

    /// Re-attempts the session refresh, but only if we're currently authenticated-offline.
    /// Called on return to foreground (VaylApp scene phase). A success clears `isOffline`.
    func retrySessionIfOffline() async {
        guard isOffline else { return }
        await checkSession()
    }

    /// Observes Supabase auth-state changes for the app's lifetime so that when
    /// connectivity returns WHILE the app is foregrounded, the SDK's background
    /// auto-refresh (which fires `.tokenRefreshed`) clears the offline state without a
    /// scene-phase change. Idempotent — safe to call more than once. Start once at launch.
    func startObservingAuthState() {
        guard !isObservingAuthState else { return }
        isObservingAuthState = true
        Task { [weak self] in
            for await (event, session) in SupabaseManager.shared.client.auth.authStateChanges {
                guard let self else { return }
                switch event {
                case .signedIn, .tokenRefreshed:
                    guard let session else { continue }
                    self.userId = session.user.id
                    self.isAuthenticated = true
                    self.isOffline = false
                case .signedOut:
                    self.isAuthenticated = false
                    self.userId = nil
                    self.isOffline = false
                default:
                    break
                }
            }
        }
    }

    /// Maps a sign-in error to user-facing copy. A transport failure (`URLError`) during
    /// the token exchange gets calm, actionable copy (the Sign In button IS the retry);
    /// anything else falls back to the underlying description. Pure — unit-tested.
    nonisolated static func signInErrorMessage(_ error: Error) -> String {
        (error is URLError)
            ? "Couldn't connect. Check your connection and try again."
            : error.localizedDescription
    }

    // MARK: - Sign In With Apple

    func signInWithApple() {
        isLoading = true
        error = nil
        PostHogService.shared.capture("auth_sign_in_started", properties: [
            "provider": "apple"
        ])

        let nonce = randomNonceString()
        currentNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }

    // MARK: - Sign Out

    func signOut() async {
        let previousUserId = userId
        do {
            try await supabase.auth.signOut()
        } catch {
            // Record the failure but never stay signed-in locally — a failed network
            // sign-out (or an already-dead session, e.g. right after account deletion)
            // must still clear local auth state or the app is stuck inside the shell.
            self.error = error.localizedDescription
        }
        PostHogService.shared.capture("auth_signed_out", properties: [
            "had_user_id": previousUserId != nil
        ])
        PostHogService.shared.reset()
        self.isAuthenticated = false
        self.userId = nil
    }

    // MARK: - Helpers

    var currentAuthId: UUID? { userId }

    // MARK: - Remote Profile Guarantee

    /// Guarantees a remote `user_profiles` row exists for the signed-in user.
    ///
    /// Pairing's edge function 409s if either partner has no profile row, but
    /// nothing else creates one for a brand-new user (onboarding persists only
    /// to local SwiftData; the SyncManager retry loop never primes itself). This
    /// closes that gap by creating the row the moment auth is confirmed —
    /// fresh sign-in and session restore both route through here.
    ///
    /// Idempotent: short-circuits once the profile id is cached, so it's at most
    /// one round-trip per install. `SyncManager.syncProfileToSupabase` wraps the
    /// select-before-insert `fetchOrCreateProfile` (no duplicate row even without
    /// an `auth_id` unique index) and flags a retry on failure. Errors are
    /// swallowed here — a transient failure leaves the cache nil, so the next
    /// launch retries, and we must never block the user from getting past auth.
    private func ensureRemoteProfile() async {
        guard UserDefaults.standard.string(forKey: "supabaseProfileId") == nil,
              let authId = userId else { return }
        _ = try? await SyncManager.shared.syncProfileToSupabase(authId: authId)
    }

    // MARK: - Nonce

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        guard errorCode == errSecSuccess else {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { byte in charset[Int(byte) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AuthService: ASAuthorizationControllerDelegate {

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8)
        else {
            Task { @MainActor in
                self.error = "Failed to get Apple ID token"
                self.isLoading = false
            }
            return
        }

        Task { @MainActor in
            do {
                let session = try await supabase.auth.signInWithIdToken(
                    credentials: .init(
                        provider: .apple,
                        idToken: identityToken,
                        nonce: currentNonce
                    )
                )
                self.userId = session.user.id
                self.isAuthenticated = true
                self.isLoading = false
                PostHogService.shared.identify(authId: session.user.id, email: session.user.email)
                PostHogService.shared.capture("auth_sign_in_succeeded", properties: [
                    "provider": "apple",
                    "has_email": session.user.email != nil
                ])
                await ensureRemoteProfile()
            } catch {
                self.error = AuthService.signInErrorMessage(error)
                self.isLoading = false
                PostHogService.shared.capture("auth_sign_in_failed", properties: [
                    "provider": "apple",
                    "error_type": String(describing: type(of: error)),
                    "is_network_error": error is URLError
                ])
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            self.error = AuthService.signInErrorMessage(error)
            self.isLoading = false
            PostHogService.shared.capture("auth_sign_in_failed", properties: [
                "provider": "apple",
                "error_type": String(describing: type(of: error)),
                "is_network_error": error is URLError
            ])
        }
    }
}
