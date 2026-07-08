import XCTest
@testable import Vayl

@MainActor
final class PathStoreTests: XCTestCase {
    private func makeStore(coupleId: UUID = UUID(), profileId: UUID = UUID()) -> (PathStore, MockPathTransport) {
        let transport = MockPathTransport()
        let store = PathStore(coupleId: coupleId, profileId: profileId, pathStyle: "swinging", transport: transport)
        return (store, transport)
    }

    func test_load_populatesLandmarksFromContent() async throws {
        let (store, _) = makeStore()
        try await store.load()
        XCTAssertEqual(store.landmarks.count, 13)
        XCTAssertEqual(store.landmarks.first?.id, "fantasy-talk")
    }

    func test_state_forLandmarkWithNoProgressRow_isUntouched() async throws {
        let (store, _) = makeStore()
        try await store.load()
        XCTAssertEqual(store.state(for: "solo-night"), .untouched)
    }

    func test_settingDidIt_onALaterLandmark_doesNotCascadeToAnEarlierUntouchedLandmark() async throws {
        // Spec §2: "Superseding doesn't cascade." Marking landmark 7 (lifestyle-club) Did it
        // must never change the state of landmark 5 (flirt-bar) or landmark 6 (nm-mixer).
        let (store, _) = makeStore()
        try await store.load()
        try await store.setDidIt("lifestyle-club", date: Date())
        XCTAssertEqual(store.state(for: "lifestyle-club"), .didIt)
        XCTAssertEqual(store.state(for: "flirt-bar"), .untouched)
        XCTAssertEqual(store.state(for: "nm-mixer"), .untouched)
    }

    func test_markCuriousPrivately_doesNotAppearInSharedProgress() async throws {
        // Spec §4: private until explicitly shared.
        let (store, transport) = makeStore()
        try await store.load()
        try await store.markCuriousPrivately("soft-swap")
        XCTAssertTrue(store.isPrivatelyMarkedCurious("soft-swap"))
        XCTAssertEqual(store.state(for: "soft-swap"), .untouched)
        XCTAssertTrue(transport.progress.isEmpty)
    }

    func test_shareCurious_movesFromPrivateToSharedState_andLogsActivity() async throws {
        let (store, transport) = makeStore()
        try await store.load()
        try await store.markCuriousPrivately("soft-swap")
        try await store.shareCurious("soft-swap")
        XCTAssertEqual(store.state(for: "soft-swap"), .curious)
        XCTAssertEqual(transport.loggedKinds, [.curiousShared])
    }

    func test_privateCuriousMark_neverAppearsInActivityLog() async throws {
        let (store, transport) = makeStore()
        try await store.load()
        try await store.markCuriousPrivately("soft-swap")
        XCTAssertTrue(transport.loggedKinds.isEmpty)
    }

    func test_setDiscussedViaSession_recordsSource_andLogsCorrectKind() async throws {
        let (store, transport) = makeStore()
        try await store.load()
        try await store.setDiscussed("seen-as-couple", via: .session)
        XCTAssertEqual(store.state(for: "seen-as-couple"), .discussed)
        XCTAssertEqual(store.discussedVia(for: "seen-as-couple"), .session)
        XCTAssertEqual(transport.loggedKinds, [.discussedSession])
    }

    func test_setDiscussedManually_logsManualKind() async throws {
        let (store, transport) = makeStore()
        try await store.load()
        try await store.setDiscussed("dinner-couple", via: .manual)
        XCTAssertEqual(transport.loggedKinds, [.discussedManual])
    }

    func test_setPlanning_isAFlagWithNoContent() async throws {
        let (store, transport) = makeStore()
        try await store.load()
        try await store.setPlanning("strip-club")
        XCTAssertEqual(store.state(for: "strip-club"), .planning)
        XCTAssertEqual(transport.loggedKinds, [.planningSet])
    }

    func test_editDidItDate_changesDateWithoutChangingState() async throws {
        let (store, transport) = makeStore()
        try await store.load()
        let original = Date(timeIntervalSince1970: 1_700_000_000)
        try await store.setDidIt("virtual-hellos", date: original)
        let edited = Date(timeIntervalSince1970: 1_600_000_000)
        try await store.editDidItDate("virtual-hellos", date: edited)
        XCTAssertEqual(store.state(for: "virtual-hellos"), .didIt)
        XCTAssertEqual(store.didItDate(for: "virtual-hellos"), edited)
        XCTAssertEqual(transport.loggedKinds, [.didItSet, .didItDateChanged])
    }

    func test_skip_removesFromDefaultTrail_andRestoreBringsItBackAsUntouched() async throws {
        let (store, transport) = makeStore()
        try await store.load()
        try await store.skip("nm-mixer")
        XCTAssertEqual(store.state(for: "nm-mixer"), .skipped)
        XCTAssertFalse(store.visibleLandmarks.contains { $0.id == "nm-mixer" })

        try await store.restore("nm-mixer")
        XCTAssertEqual(store.state(for: "nm-mixer"), .untouched)
        XCTAssertTrue(store.visibleLandmarks.contains { $0.id == "nm-mixer" })
        XCTAssertEqual(transport.loggedKinds, [.skipped, .restored])

        // Restoring must clear the *remote* row too, not just the in-memory
        // cache — `.untouched` is never persisted (PathLandmarkProgress.swift),
        // so a stale `.skipped` row left behind would silently resurface on the
        // next load() (relaunch, pull-to-refresh, partner's realtime update).
        XCTAssertFalse(transport.progress.contains { $0.landmarkId == "nm-mixer" })
        try await store.load()
        XCTAssertEqual(store.state(for: "nm-mixer"), .untouched)
    }
}
