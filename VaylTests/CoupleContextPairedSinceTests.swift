//
//  CoupleContextPairedSinceTests.swift
//  VaylTests
//
//  Regression coverage for the pairedSince staleness bug found in Task 10
//  code review: unlink() never called CoupleContext.clearPartner(), and
//  loadPairedSinceIfNeeded() guarded only on `fetchedPairedSince == nil`
//  (no coupleId key), so re-pairing with a NEW partner in the same app
//  session (no relaunch) kept showing the FIRST partner's paired-since date.
//
//  Fix: loadPairedSinceIfNeeded() now guards on a `fetchedPairedSinceForCoupleId`
//  tracker, the same coupleId-keyed pattern partnerName's loader already used,
//  so refreshIfNeeded() naturally refetches when appState.coupleId changes.
//

import XCTest
import SwiftData
@testable import Vayl

@MainActor
final class CoupleContextPairedSinceTests: XCTestCase {

    // See HomeStorePartnerChipStateTests for why this retain workaround exists:
    // an @MainActor isolated-deinit runtime bug aborts the test host when an
    // @Observable @MainActor AppState/store deallocates mid-suite.
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    func testPairedSinceRefetchesAfterRepairingWithNewCoupleInSameSession() async throws {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)

        let firstPairedDate = Date().addingTimeInterval(-30 * 24 * 60 * 60)
        let profile = UserProfile()
        profile.linkedAt = firstPairedDate
        context.insert(profile)
        try context.save()

        let appState = AppState()
        appState.linkState = .linked
        let firstCoupleId = UUID()
        appState.coupleId = firstCoupleId

        let entitlements = EntitlementStore(modelContainer: container, appState: appState)
        let couple = CoupleContext(appState: appState, entitlements: entitlements, modelContainer: container)
        Self.retain(couple, appState, entitlements)

        await couple.refreshIfNeeded()
        let firstFetched = try XCTUnwrap(couple.pairedSince, "pairedSince should be loaded once linked")
        XCTAssertEqual(
            firstFetched.timeIntervalSince1970,
            firstPairedDate.timeIntervalSince1970,
            accuracy: 1,
            "First fetch should load the first partner's paired-since date"
        )

        // Simulate unlink + re-pair with a NEW partner in the same app session
        // (no relaunch): the local profile's linkedAt is overwritten with a new
        // date, and AppState.coupleId changes to the new couple's id.
        let secondPairedDate = Date()
        profile.linkedAt = secondPairedDate
        try context.save()
        appState.coupleId = UUID()
        XCTAssertNotEqual(appState.coupleId, firstCoupleId)

        await couple.refreshIfNeeded()

        let secondFetched = try XCTUnwrap(couple.pairedSince, "pairedSince should be loaded after re-pairing")
        XCTAssertEqual(
            secondFetched.timeIntervalSince1970,
            secondPairedDate.timeIntervalSince1970,
            accuracy: 1,
            "After re-pairing with a new couple in the same session, pairedSince must refetch instead of serving the stale first-partner date"
        )
    }
}
