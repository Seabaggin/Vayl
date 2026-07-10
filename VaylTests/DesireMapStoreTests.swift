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

    // Workaround for a Swift @MainActor isolated-deinit runtime double-free
    // (swift_task_deinitOnExecutorImpl → POINTER_BEING_FREED_WAS_NOT_ALLOCATED) that aborts
    // the app-hosted test host whenever an @Observable @MainActor AppState/store deallocates
    // mid-suite. Keeping them alive for the process means the buggy isolated deinit never runs
    // during the test run. Test-only; not a production concern (the app never deinits AppState).
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    // A box so the no-op sync seam can capture what WOULD have been pushed, without any
    // background network/SwiftData work (which would race test teardown and corrupt the heap).
    private final class SyncCapture {
        var lastPayload: [PendingDesireRating]?
        var lastStage: String?
    }

    private func makeLoadedStore() -> (DesireMapStore, ModelContainer, SyncCapture) {
        let container = ModelContainer.previewContainerWithProfile   // seeds UserProfile "Jordan", nmStage .curious
        let capture = SyncCapture()
        let appState = AppState()
        let store = DesireMapStore(modelContainer: container, appState: appState) { payload, stage in
            capture.lastPayload = payload
            capture.lastStage = stage
        }
        store.load()
        Self.retain(store, appState, capture)
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

    func test_load_trackIsCuriousRegardlessOfNMStage() {
        // V1 one-curious-superset decision (2026-06-25, re-ratified 2026-07-09 review):
        // the track never derives from nmStage — an experienced user still rates the
        // curious superset, matching the server edge fn's constant track.
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        context.insert(UserProfile(displayName: "Sam", nmStage: .experienced))
        try? context.save()

        let appState = AppState()
        let store = DesireMapStore(modelContainer: container, appState: appState) { _, _ in }
        store.load()
        Self.retain(store, appState)

        XCTAssertEqual(store.track, "curious")
        XCTAssertGreaterThan(store.items.count, 0)
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

    // MARK: - Hydration merge rule (SyncManager pure helpers — review 2026-07-09 §1.3)
    // The network side of hydrateDesireRatings has no injectable seam (singleton service),
    // so the decision logic is extracted pure on SyncManager and contract-tested here.

    func test_hydrationMerge_insertsWhenNoLocalEntry() {
        XCTAssertEqual(
            SyncManager.ratingMergeDecision(localCompletedAt: nil, serverCreatedAt: Date()),
            .insert
        )
    }

    func test_hydrationMerge_serverNewerWins() {
        let local = Date(timeIntervalSince1970: 1_000)
        let server = Date(timeIntervalSince1970: 2_000)
        XCTAssertEqual(
            SyncManager.ratingMergeDecision(localCompletedAt: local, serverCreatedAt: server),
            .overwrite
        )
    }

    func test_hydrationMerge_localSameOrNewerKept_neverDeleted() {
        let newer = Date(timeIntervalSince1970: 2_000)
        let older = Date(timeIntervalSince1970: 1_000)
        // Local ahead of a failed sync → keep local. Equal timestamps → keep local too
        // (overwrite is strictly-newer only). There is deliberately NO delete outcome —
        // hydration may only add or update.
        XCTAssertEqual(
            SyncManager.ratingMergeDecision(localCompletedAt: newer, serverCreatedAt: older),
            .keepLocal
        )
        XCTAssertEqual(
            SyncManager.ratingMergeDecision(localCompletedAt: newer, serverCreatedAt: newer),
            .keepLocal
        )
    }

    func test_hydrationTimestamp_parsesFractionalAndPlainISO8601() {
        // Postgres emits fractional seconds; device-uploaded rows may be plain.
        XCTAssertNotNil(SyncManager.parseRatingTimestamp("2026-07-09T12:34:56.789Z"))
        XCTAssertNotNil(SyncManager.parseRatingTimestamp("2026-07-09T12:34:56Z"))
        XCTAssertNil(SyncManager.parseRatingTimestamp("not-a-date"))
        // Ordering survives the parse (latest-wins depends on it).
        let earlier = SyncManager.parseRatingTimestamp("2026-07-09T12:00:00Z")!
        let later = SyncManager.parseRatingTimestamp("2026-07-09T12:00:00.500Z")!
        XCTAssertLessThan(earlier, later)
    }

    func test_hydrationCompletion_derivedOnlyFromFullTrackCoverage() throws {
        let items = try ContentLoader.loadDesireItems().filter { $0.appears(in: "curious") }
        XCTAssertFalse(items.isEmpty)

        let allIds = Set(items.map(\.id))
        XCTAssertTrue(SyncManager.coversTrack(ratedItemIds: allIds, trackItems: items))

        // One missing item → not complete.
        var partial = allIds
        partial.remove(items[0].id)
        XCTAssertFalse(SyncManager.coversTrack(ratedItemIds: partial, trackItems: items))

        // Unknown/extra ids never substitute for coverage; empty track never completes.
        XCTAssertFalse(SyncManager.coversTrack(ratedItemIds: ["ghost-item"], trackItems: items))
        XCTAssertFalse(SyncManager.coversTrack(ratedItemIds: allIds, trackItems: []))
    }

    // MARK: - CompanionCard content loader

    func test_loadCompanionCards_returnsThreeTiers() throws {
        let pools = try ContentLoader.loadCompanionCards()
        XCTAssertEqual(pools.count, 3)
        let tiers = Set(pools.map(\.tier))
        XCTAssertTrue(tiers.contains(.mutual))
        XCTAssertTrue(tiers.contains(.adjacent))
        XCTAssertTrue(tiers.contains(.consentOpened))
    }

    func test_loadCompanionCards_eachTierHasPrompts() throws {
        let pools = try ContentLoader.loadCompanionCards()
        for pool in pools {
            XCTAssertFalse(pool.prompts.isEmpty, "Tier \(pool.tier.rawValue) has no prompts")
        }
    }

    // MARK: - CompanionCardStore tier lookup

    func test_companionCardStore_mutualMatchReturnsMutualPrompt() async throws {
        let store = await CompanionCardStore()
        let card = await store.card(forItemId: "desire-001", tier: .mutual)
        XCTAssertNotNil(card)
        XCTAssertFalse(card!.prompt.isEmpty)
    }

    func test_companionCardStore_sameItemAlwaysReturnsSamePrompt() async throws {
        let store = await CompanionCardStore()
        let card1 = await store.card(forItemId: "desire-003", tier: .adjacent)
        let card2 = await store.card(forItemId: "desire-003", tier: .adjacent)
        XCTAssertEqual(card1?.prompt, card2?.prompt)
    }

    func test_companionCardStore_consentOpenedTierUsesCorrectPool() async throws {
        let store = await CompanionCardStore()
        let pools = try ContentLoader.loadCompanionCards()
        let consentPool = pools.first { $0.tier == .consentOpened }!
        let card = await store.card(forItemId: "desire-005", tier: .consentOpened)
        XCTAssertNotNil(card)
        XCTAssertTrue(consentPool.prompts.map(\.text).contains(card!.prompt))
    }
}
