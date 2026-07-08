//
//  AuthService.swift
//  Vayl
//

import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import Supabase

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

    // MARK: - Private

    private var currentNonce: String?

    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }

    // MARK: - Session Check

    /// Call once on app launch from VaylApp or AppShell.
    /// Resolves the real auth state from Supabase — no simulator shortcuts.
    func checkSession() async {
        do {
            let session = try await supabase.auth.session

            // Add this check
            if session.isExpired {
                try? await supabase.auth.signOut()
                self.isAuthenticated = false
                self.userId = nil
                return
            }

            self.userId = session.user.id
            self.isAuthenticated = true
            await ensureRemoteProfile()
        } catch {
            self.isAuthenticated = false
            self.userId = nil
        }
    }

    // MARK: - Sign In With Apple

    func signInWithApple() {
        isLoading = true
        error = nil

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
        do {
            try await supabase.auth.signOut()
        } catch {
            // Record the failure but never stay signed-in locally — a failed network
            // sign-out (or an already-dead session, e.g. right after account deletion)
            // must still clear local auth state or the app is stuck inside the shell.
            self.error = error.localizedDescription
        }
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
                await ensureRemoteProfile()
            } catch {
                self.error = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            self.error = error.localizedDescription
            self.isLoading = false
        }
    }
}
