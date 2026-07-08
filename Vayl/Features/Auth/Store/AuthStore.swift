//
//  AuthStore.swift
//  Vayl
//
//  The Auth feature's Store layer (4-layer: View -> Store -> Service -> Model).
//  Views read auth state and forward taps here; AuthService owns the actual
//  Apple/Supabase work. Before this store existed, SignInView / AppRootView /
//  SettingsView talked to AuthService directly — the one 2-layer feature left
//  in the app (2026-07-08 architecture pass).
//
//  `service` stays reachable for composition roots only (SettingsView builds a
//  SettingsStore that legitimately injects the service). Views must never call
//  it directly.
//

import Foundation
import Observation

@Observable
@MainActor
final class AuthStore {

    // MARK: - Dependencies

    /// The underlying service — exposed for Store composition (e.g. SettingsStore's
    /// initializer), never for direct View calls.
    let service: AuthService

    /// `service` nil-resolves inside the MainActor-isolated body (a default
    /// argument would evaluate nonisolated — same pattern as SettingsStore).
    init(service: AuthService? = nil) {
        self.service = service ?? AuthService()
    }

    // MARK: - State (read-through; AuthService is @Observable, so tracking works)

    var isAuthenticated: Bool { service.isAuthenticated }
    var isLoading: Bool { service.isLoading }
    var error: String? { service.error }
    var userId: UUID? { service.userId }

    // MARK: - Actions

    func checkSession() async { await service.checkSession() }
    func signInWithApple() { service.signInWithApple() }
    func signOut() async { await service.signOut() }
}
