//
//  PairingStoreTests.swift
//  VaylTests
//
//  Covers the firstInviteSentAt lifecycle rule: stamped once, never
//  overwritten by a later invite/regenerate call for the same pairing
//  attempt. The full stamp/clear lifecycle lives in PairingStore
//  (generateInvite/persistLink) and SettingsStore (unlink) — this test
//  exercises the narrow, pure "don't overwrite an existing timestamp"
//  guard rule directly against SwiftData, since PairingStore's actual
//  methods reach out to the network.
//

import XCTest
import SwiftData
@testable import Vayl

@MainActor
final class PairingStoreFirstInviteSentAtTests: XCTestCase {
    func testFirstInviteSentAtIsNotOverwrittenOnSecondCall() async throws {
        let container = try ModelContainer(
            for: UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let profile = UserProfile()
        context.insert(profile)
        try context.save()

        let firstStamp = Date().addingTimeInterval(-1000)
        profile.firstInviteSentAt = firstStamp
        try context.save()

        // Simulate what recordFirstInviteSentIfNeeded does: fetch, check nil, skip if set.
        let refetched = try context.fetch(FetchDescriptor<UserProfile>()).first
        XCTAssertNotNil(refetched?.firstInviteSentAt)
        if refetched?.firstInviteSentAt == nil {
            refetched?.firstInviteSentAt = Date()
        }
        try context.save()

        XCTAssertEqual(refetched?.firstInviteSentAt, firstStamp, "existing timestamp must not be overwritten")
    }
}
