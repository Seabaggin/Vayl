//
//  HomeStorePartnerChipStateTests.swift
//  VaylTests
//
//  Covers the nudge-threshold math HomeStore.partnerChipState relies on to
//  shift an unclaimed invite from quiet "invite pending" to the warmer
//  "nudge" tone after 3 days (docs/superpowers/specs/2026-07-05-partner-chip-and-pairing-design.md).
//
//  The boundary-math test below only proves the threshold arithmetic itself;
//  the tests further down exercise the real HomeStore/partnerChipState code
//  path end to end (UserProfile.firstInviteSentAt -> loadProfile() ->
//  partnerChipState), so a regression in the actual wiring (not just the
//  threshold constant) fails these.
//

import XCTest
import SwiftData
@testable import Vayl

@MainActor
final class HomeStorePartnerChipStateTests: XCTestCase {

    // Workaround for a Swift @MainActor isolated-deinit runtime double-free
    // (swift_task_deinitOnExecutorImpl -> POINTER_BEING_FREED_WAS_NOT_ALLOCATED) that aborts
    // the app-hosted test host whenever an @Observable @MainActor AppState/store deallocates
    // mid-suite. Keeping them alive for the process means the buggy isolated deinit never runs
    // during the test run. Test-only; not a production concern (the app never deinits AppState).
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    func testInvitePendingBecomesNudgeAfterThreeDays() {
        let sentFourDaysAgo = Date().addingTimeInterval(-4 * 24 * 60 * 60)
        let sentOneDayAgo = Date().addingTimeInterval(-1 * 24 * 60 * 60)

        XCTAssertTrue(
            Date().timeIntervalSince(sentFourDaysAgo) >= (3 * 24 * 60 * 60),
            "4 days ago must be past the 3-day threshold"
        )
        XCTAssertFalse(
            Date().timeIntervalSince(sentOneDayAgo) >= (3 * 24 * 60 * 60),
            "1 day ago must be under the 3-day threshold"
        )
    }

    /// Builds a HomeStore wired to an unlinked-but-paired (`.together`/`.unlinked`)
    /// AppState, matching the state partnerChipState's `.unlinked` branch actually
    /// reads (isPaired == appMode == .together; guard requires it before nudge/
    /// invitePending are reachable at all).
    private func makeStore(container: ModelContainer) -> HomeStore {
        let appState = AppState()
        appState.appMode = .together
        appState.linkState = .unlinked

        let entitlements = EntitlementStore(modelContainer: container, appState: appState)
        let couple = CoupleContext(appState: appState, entitlements: entitlements)
        let store = HomeStore(modelContainer: container, appState: appState, couple: couple)

        Self.retain(store, appState, couple, entitlements)
        return store
    }

    func testPartnerChipStateIsNudgeWhenInviteSentFourDaysAgo() async throws {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let profile = UserProfile()
        profile.firstInviteSentAt = Date().addingTimeInterval(-4 * 24 * 60 * 60)
        context.insert(profile)
        try context.save()

        let store = makeStore(container: container)
        await store.loadProfile()

        XCTAssertEqual(store.partnerChipState, .nudge)
    }

    func testPartnerChipStateIsInvitePendingWhenInviteSentOneDayAgo() async throws {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let profile = UserProfile()
        profile.firstInviteSentAt = Date().addingTimeInterval(-1 * 24 * 60 * 60)
        context.insert(profile)
        try context.save()

        let store = makeStore(container: container)
        await store.loadProfile()

        XCTAssertEqual(store.partnerChipState, .invitePending)
    }
}
