//
//  DesireMapStoreTests.swift
//  VaylTests
//
//  The rater store's persistence contract: load resolves the track + items, rate upserts one
//  DesireMapEntry per (userId, itemId), re-rating updates in place, notForMe IS persisted
//  locally (sync-all posture), and completing every item marks the profile complete.
//
//  App-hosted test target (TEST_HOST set), so ContentLoader reads the real bundled
//  desire_items.json. Uses the profile-seeded in-memory container for isolation.
//

import XCTest
import SwiftData
@testable import Vayl

@MainActor
final class DesireMapStoreTests: XCTestCase {

    // A box so the no-op sync seam can capture what WOULD have been pushed, without any
    // background network/SwiftData work (which would race test teardown and corrupt the heap).
    private final class SyncCapture {
        var lastPayload: [PendingDesireRating]?
        var lastStage: String?
    }

    private func makeLoadedStore() -> (DesireMapStore, ModelContainer, SyncCapture) {
        let container = ModelContainer.previewContainerWithProfile   // seeds UserProfile "Jordan", nmStage .curious
        let capture = SyncCapture()
        let store = DesireMapStore(modelContainer: container, appState: AppState()) { payload, stage in
            capture.lastPayload = payload
            capture.lastStage = stage
        }
        store.load()
        return (store, container, capture)
    }

    private func entries(in container: ModelContainer) -> [DesireMapEntry] {
        let context = ModelContext(container)
        return (try? context.fetch(FetchDescriptor<DesireMapEntry>())) ?? []
    }

    private func profile(in container: ModelContainer) -> UserProfile? {
        let context = ModelContext(container)
        return try? context.fetch(FetchDescriptor<UserProfile>()).first
    }

    // MARK: - Load

    func test_load_resolvesCuriousTrackAndItems() {
        let (store, _, _) = makeLoadedStore()
        XCTAssertNil(store.loadError)
        XCTAssertEqual(store.track, "curious")
        XCTAssertGreaterThan(store.items.count, 0, "curious track should ship items in the bundle")
        XCTAssertEqual(store.ratedCount, 0)
        XCTAssertFalse(store.isComplete)
    }

    // MARK: - Rate (upsert)

    func test_rate_persistsAndReflectsInState() throws {
        let (store, container, _) = makeLoadedStore()
        let item = try XCTUnwrap(store.items.first)

        store.rate(itemId: item.id, rating: .openToIt)

        XCTAssertEqual(store.existingRating(for: item.id), .openToIt)
        XCTAssertEqual(store.ratedCount, 1)
        let saved = entries(in: container).filter { $0.itemId == item.id }
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.rating, .openToIt)
    }

    func test_reRate_updatesInPlaceWithoutDuplicating() throws {
        let (store, container, _) = makeLoadedStore()
        let item = try XCTUnwrap(store.items.first)

        store.rate(itemId: item.id, rating: .openToIt)
        store.rate(itemId: item.id, rating: .excitedAboutIt)

        XCTAssertEqual(store.existingRating(for: item.id), .excitedAboutIt)
        XCTAssertEqual(store.ratedCount, 1, "re-rating the same item must not add a second answer")
        let saved = entries(in: container).filter { $0.itemId == item.id }
        XCTAssertEqual(saved.count, 1, "one DesireMapEntry per (userId, itemId)")
        XCTAssertEqual(saved.first?.rating, .excitedAboutIt)
    }

    func test_notForMe_isPersistedLocally() throws {
        // Sync-all posture: notForMe is a real stored weight (privacy is enforced server-side
        // by RLS + the match edge fn), NOT withheld at the device.
        let (store, container, _) = makeLoadedStore()
        let item = try XCTUnwrap(store.items.first)

        store.rate(itemId: item.id, rating: .notForMe)

        XCTAssertEqual(store.existingRating(for: item.id), .notForMe)
        let saved = entries(in: container).filter { $0.itemId == item.id }
        XCTAssertEqual(saved.first?.rating, .notForMe)
    }

    // MARK: - Completion

    func test_completingEveryItem_marksProfileComplete_andEnqueuesFullSync() {
        let (store, container, capture) = makeLoadedStore()
        XCTAssertFalse(store.isComplete)

        // Include a notForMe to prove the sync-all posture: every weight is pushed.
        for (i, item) in store.items.enumerated() {
            store.rate(itemId: item.id, rating: i == 0 ? .notForMe : .openToIt)
        }

        XCTAssertTrue(store.isComplete)
        XCTAssertEqual(store.ratedCount, store.totalCount)
        XCTAssertEqual(profile(in: container)?.hasCompletedDesireMap, true)

        // Completion enqueues a sync of ALL ratings, notForMe included (obscured server-side, not withheld).
        let payload = capture.lastPayload ?? []
        XCTAssertEqual(payload.count, store.totalCount)
        XCTAssertTrue(payload.contains { $0.rating == .notForMe }, "notForMe is synced, not withheld")
    }

    // MARK: - View helpers

    func test_answers_returnFourOptionsForTrack() throws {
        let (store, _, _) = makeLoadedStore()
        let item = try XCTUnwrap(store.items.first)
        // Every rateable item ships four answers (one per DesireRatingValue) on its track.
        XCTAssertEqual(store.answers(for: item).count, DesireRatingValue.allCases.count)
    }
}
