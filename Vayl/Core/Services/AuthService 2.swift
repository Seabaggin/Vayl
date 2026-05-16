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
            self.isAuthenticated = false
            self.userId = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Helpers

    var currentAuthId: UUID? { userId }

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
