//
//  CoupleCapacityStoreTests.swift
//  VaylTests
//
//  Covers CoupleCapacityStore.load() over the two shapes the read path can
//  produce: a present partner row (→ banded tier, not-checked-in false) and an
//  absent row (nil → tier nil, not-checked-in true). Uses a MockCoupleCapacity-
//  Service so nothing touches Supabase.
//

import XCTest
@testable import Vayl

@MainActor
final class CoupleCapacityStoreTests: XCTestCase {

    /// In-memory stand-in for the real service — returns a fixed result.
    private struct MockCoupleCapacityService: CoupleCapacityService {
        let result: PartnerCapacity?
        func fetchPartnerCapacity() async throws -> PartnerCapacity? { result }
    }

    func testPresentCapacitySetsTierAndClearsNotCheckedIn() async {
        // score 0.72 → falls in the ..<0.75 band → .indigo
        let service = MockCoupleCapacityService(
            result: PartnerCapacity(capacityScore: 0.72, updatedAt: Date())
        )
        let store = CoupleCapacityStore(service: service)

        await store.load()

        XCTAssertNotNil(store.partnerTier, "a present row must yield a tier")
        XCTAssertEqual(store.partnerTier, .indigo, "0.72 bands to .indigo")
        XCTAssertFalse(store.partnerNotCheckedIn, "present row is not 'not checked in'")
    }

    func testAbsentCapacityClearsTierAndFlagsNotCheckedIn() async {
        let service = MockCoupleCapacityService(result: nil)
        let store = CoupleCapacityStore(service: service)

        await store.load()

        XCTAssertNil(store.partnerTier, "no shared row → no tier")
        XCTAssertTrue(store.partnerNotCheckedIn, "no shared row → not checked in")
    }
}
