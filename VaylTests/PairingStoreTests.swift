//
//  PairingStoreTests.swift
//  VaylTests
//
//  Covers the firstInviteSentAt lifecycle rule: stamped once, never
//  overwritten by a later invite/regenerate call for the same pairing
//  attempt. The full stamp/clear lifecycle lives in PairingStore
//  (generateInvite/persistLink) and SettingsStore (unlink) — this test
//  calls PairingStore.recordFirstInviteSentIfNeeded() directly (internal,
//  not private, specifically so @testable import Vayl can reach it) against
//  an in-memory ModelContainer, so a regression in the real guard fails
//  this test.
//

import XCTest
import SwiftData
@testable import Vayl

@MainActor
final class PairingStoreFirstInviteSentAtTests: XCTestCase {

    // Workaround for a Swift @MainActor isolated-deinit runtime double-free
    // (swift_task_deinitOnExecutorImpl → POINTER_BEING_FREED_WAS_NOT_ALLOCATED) that aborts
    // the app-hosted test host whenever an @Observable @MainActor AppState/store deallocates
    // mid-suite. Keeping them alive for the process means the buggy isolated deinit never runs
    // during the test run. Test-only; not a production concern (the app never deinits AppState).
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    private func makeStore(container: ModelContainer) -> PairingStore {
        let appState = AppState()
        let store = PairingStore(modelContainer: container, appState: appState)
        Self.retain(store, appState)
        return store
    }

    func testFirstInviteSentAtIsNotOverwrittenOnSecondCall() async throws {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let profile = UserProfile()
        let firstStamp = Date().addingTimeInterval(-1000)
        profile.firstInviteSentAt = firstStamp
        context.insert(profile)
        try context.save()

        let store = makeStore(container: container)
        await store.recordFirstInviteSentIfNeeded()

        let refetched = try context.fetch(FetchDescriptor<UserProfile>()).first
        XCTAssertEqual(refetched?.firstInviteSentAt, firstStamp, "existing timestamp must not be overwritten")
    }

    func testFirstInviteSentAtIsSetOnFirstCall() async throws {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let profile = UserProfile()
        profile.firstInviteSentAt = nil
        context.insert(profile)
        try context.save()

        let store = makeStore(container: container)
        await store.recordFirstInviteSentIfNeeded()

        let refetched = try context.fetch(FetchDescriptor<UserProfile>()).first
        let stamped = try XCTUnwrap(refetched?.firstInviteSentAt)
        XCTAssertEqual(stamped.timeIntervalSinceNow, 0, accuracy: 5, "should stamp to approximately now")
    }
}
