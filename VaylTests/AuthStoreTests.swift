//
//  AuthStoreTests.swift
//  VaylTests
//
//  AuthStore (Vayl/Features/Auth/Store/AuthStore.swift) is a thin read-through
//  Store over AuthService — no branching logic of its own beyond forwarding.
//  AuthService itself (Vayl/Core/Services/AuthService.swift) has NO injection
//  seam: `checkSession()`/`signOut()` call `SupabaseManager.shared.client`
//  directly (a computed singleton, not a stored/injectable dependency), and
//  `signInWithApple()` drives a real `ASAuthorizationController`. It is also
//  `final class ... : NSObject`, so it can't be subclassed for a test double
//  either. Per the scope guard, that's a real restructuring (extracting a
//  transport seam for Supabase auth + Apple ID calls), not a minimal additive
//  seam — flagged rather than done here.
//
//  What IS testable without touching production code: AuthService's state
//  properties (`isAuthenticated`, `userId`, `isLoading`, `error`) are plain
//  `var`s (not private(set)), so a real AuthService instance can be driven
//  directly and AuthStore's pass-through wiring verified against it — no
//  network, no Apple ID sheet, no seam needed.
//

import XCTest
@testable import Vayl

@MainActor
final class AuthStoreTests: XCTestCase {

    // Isolated-deinit workaround (same gotcha as the DM/Airlock suites): retain
    // every @Observable @MainActor store/service for the process lifetime.
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    private func makeStore(service: AuthService? = nil) -> AuthStore {
        let store = AuthStore(service: service)
        Self.retain(store, store.service)
        return store
    }

    func test_init_defaultsToAFreshUnauthenticatedService() {
        let store = makeStore()
        XCTAssertFalse(store.isAuthenticated, "must never default to authenticated")
        XCTAssertNil(store.userId)
        XCTAssertFalse(store.isLoading)
        XCTAssertNil(store.error)
    }

    func test_isAuthenticated_readsThroughFromInjectedService() {
        let service = AuthService()
        let store = makeStore(service: service)

        XCTAssertFalse(store.isAuthenticated)
        service.isAuthenticated = true
        XCTAssertTrue(store.isAuthenticated, "AuthStore must read live, not snapshot, service state")
    }

    func test_userId_readsThroughFromInjectedService() {
        let service = AuthService()
        let store = makeStore(service: service)
        let id = UUID()

        XCTAssertNil(store.userId)
        service.userId = id
        XCTAssertEqual(store.userId, id)
    }

    func test_isLoading_readsThroughFromInjectedService() {
        let service = AuthService()
        let store = makeStore(service: service)

        service.isLoading = true
        XCTAssertTrue(store.isLoading)
        service.isLoading = false
        XCTAssertFalse(store.isLoading)
    }

    func test_error_readsThroughFromInjectedService() {
        let service = AuthService()
        let store = makeStore(service: service)

        XCTAssertNil(store.error)
        service.error = "That purchase couldn't be verified." // any surfaced message
        XCTAssertEqual(store.error, "That purchase couldn't be verified.")
    }

    func test_service_isTheSameInstance_forCompositionRootInjection() {
        // SettingsStore legitimately reaches AuthStore.service to build its own
        // composition (per the file header). Confirm identity, not a copy.
        let service = AuthService()
        let store = makeStore(service: service)
        XCTAssertTrue(store.service === service)
    }
}
