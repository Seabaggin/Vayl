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
}
