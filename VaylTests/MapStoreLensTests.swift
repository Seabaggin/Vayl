// VaylTests/MapStoreLensTests.swift
//
// TDD for MapStore lens gating + the one-shot Us reveal flag (Map dashboard
// spec §2.3–2.4). Us exists only after linking; unlink snaps the lens back to
// Me and resets the reveal so re-linking earns the ceremony again.

import XCTest
@testable import Vayl

@MainActor
final class MapStoreLensTests: XCTestCase {

    private func freshDefaults() -> UserDefaults {
        let suite = "MapStoreLensTests"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    // MARK: - Lens gating (§2.3)

    func testHasUsFalseWithoutPartner() {
        let store = MapStore()
        XCTAssertFalse(store.hasUs)
    }

    func testEnforceLensGateSnapsToMe() {
        let store = MapStore()
        store.layer = .us
        store.enforceLensGate()
        XCTAssertEqual(store.layer, .me)
    }

    // MARK: - Us reveal ceremony flag (§2.4)

    func testRevealFlagRoundTrips() {
        let store = MapStore(defaults: freshDefaults())
        XCTAssertFalse(store.usRevealSeen)
        store.markUsRevealSeen()
        XCTAssertTrue(store.usRevealSeen)
        store.resetUsReveal()
        XCTAssertFalse(store.usRevealSeen)
    }

    func testRevealResetIsSharedAcrossInstances() {
        let defaults = freshDefaults()
        let first = MapStore(defaults: defaults)
        let second = MapStore(defaults: defaults)
        first.markUsRevealSeen()
        XCTAssertTrue(second.usRevealSeen)
    }
}
