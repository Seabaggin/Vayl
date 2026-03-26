//
//  AuthService.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 3/9/26.
//

import AuthenticationServices
import Supabase
import CryptoKit
import Foundation
import Combine

@MainActor
final class AuthService: NSObject, ObservableObject {
    
    // MARK: - Published State

    @Published var isAuthenticated = true
    @Published var userId: UUID?
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Private
    
    private var currentNonce: String?
    
    private var supabase: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    // MARK: - Check Existing Session
    
    func checkSession() async {
        #if targetEnvironment(simulator)
        isAuthenticated = true
        userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        #else
        do {
            let session = try await supabase.auth.session
            self.userId = session.user.id
            self.isAuthenticated = true
            #if DEBUG
            print("✅ Existing session found: \(session.user.id)")
            #endif
        } catch {
            // No active session — user needs to sign in
            #if DEBUG
            print("ℹ️ No existing session")
            #endif
            // ✅ TestFlight ready — properly clears auth state on failure
            self.isAuthenticated = false
            self.userId = nil
        }
        #endif
    }
    
    // MARK: - Sign in with Apple
    
    func signInWithApple() {
        #if targetEnvironment(simulator)
        isAuthenticated = true
        userId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        #else
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
        #endif
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.isAuthenticated = false
            self.userId = nil
            #if DEBUG
            print("✅ Signed out")
            #endif
        } catch {
            self.error = error.localizedDescription
            #if DEBUG
            print("❌ Sign out failed")
            #endif
        }
    }
    
    // MARK: - Current User ID Helper
    
    var currentAuthId: UUID? {
        return userId
    }
    
    // MARK: - Nonce Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
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
                #if DEBUG
                print("✅ Apple sign-in successful: \(session.user.id)")
                #endif
            } catch {
                self.error = error.localizedDescription
                self.isLoading = false
                #if DEBUG
                print("❌ Apple sign-in failed: \(error.localizedDescription)")
                #endif
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
            #if DEBUG
            print("❌ Apple auth error: \(error.localizedDescription)")
            #endif
        }
    }
}
