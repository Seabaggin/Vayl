//
//  EntitlementStoreTests.swift
//  VaylTests
//
//  EntitlementStore against fake EntitlementServicing / CoreStoreKitServicing seams
//  (added alongside this suite — see EntitlementStore.swift's "Service seams" section).
//  Covers the money-path logic: free→core resolution, the couple-level OR gate
//  (server tier OR local StoreKit ownership), offline-safe refresh failure, the
//  self-heal guard conditions, and the local-mirror hydrate-on-init path.
//
//  NOT covered here (flagged, not faked): a self-heal that actually FIRES
//  grant-entitlement, and the purchase()/restore() success paths — both require a
//  real verified StoreKit `Transaction`, which has no public initializer and can
//  only be produced via the StoreKitTest framework (SKTestSession + .storekit
//  config). That's integration-test territory, not a unit-test fake.
//

import XCTest
import SwiftData
import StoreKit
@testable import Vayl

// MARK: - Fakes

@MainActor
private final class FakeEntitlementService: EntitlementServicing {
    var tierRow: CoupleTierRow?
    var fetchError: Error?
    private(set) var fetchCallCount = 0

    var grantError: Error?
    var grantResponse: GrantResponse?
    private(set) var grantedJWS: [String] = []

    func fetchTier(coupleId: UUID) async throws -> CoupleTierRow? {
        fetchCallCount += 1
        if let fetchError { throw fetchError }
        return tierRow
    }

    func grantCore(productId: String, signedTransaction: String) async throws -> GrantResponse {
        if let grantError { throw grantError }
        grantedJWS.append(signedTransaction)
        return grantResponse ?? GrantResponse(tier: "core", coupleId: UUID())
    }
}

private struct FakeError: Error {}

@MainActor
private final class FakeStoreKit: CoreStoreKitServicing {
    var ownsCoreValue = false
    var product: Product?
    /// Left nil by default — a fake can't fabricate a real `Transaction`
    /// (no public initializer), so self-heal's "fires" path can't be exercised here.
    var entitlementPair: (transaction: Transaction, jws: String)?

    func loadCoreProduct() async throws -> Product? { product }
    func purchase(_ product: Product) async throws -> StoreKitService.PurchaseOutcome { .userCancelled }
    func finish(_ transaction: Transaction) async {}
    func coreEntitlement() async -> (transaction: Transaction, jws: String)? { entitlementPair }
    func ownsCore() async -> Bool { ownsCoreValue }
    func restore() async throws -> (transaction: Transaction, jws: String)? { nil }
    // Synchronous protocol requirement — must be nonisolated so this @MainActor
    // fake can witness it (async requirements get the hop for free; sync ones don't).
    nonisolated func observeTransactionUpdates(
        onChange: @escaping @Sendable (_ transaction: Transaction, _ jws: String, _ revoked: Bool) async -> Void
    ) -> Task<Void, Never> {
        Task {}
    }
}

// MARK: - Tests

@MainActor
final class EntitlementStoreTests: XCTestCase {

    // Isolated-deinit workaround (same gotcha as the DM/Airlock suites): retain
    // every @Observable @MainActor store + its fakes for the process lifetime.
    private static var retained: [AnyObject] = []
    private static func retain(_ objects: AnyObject...) { retained.append(contentsOf: objects) }

    private func makeCouple(in context: ModelContext, tier: AccessTier = .free) -> Couple {
        let couple = Couple(partnerAId: UUID(), partnerBId: UUID())
        couple.entitlementTier = tier
        context.insert(couple)
        try? context.save()
        return couple
    }

    private func makeStore(
        container: ModelContainer,
        appState: AppState,
        service: FakeEntitlementService,
        storeKit: FakeStoreKit
    ) -> EntitlementStore {
        let store = EntitlementStore(
            modelContainer: container,
            appState: appState,
            service: service,
            storeKit: storeKit
        )
        Self.retain(store, service, storeKit, appState)
        return store
    }

    // MARK: hydrateFromLocal (init)

    func test_init_hydratesTierFromLocalCouple() {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let couple = makeCouple(in: context, tier: .core)
        let appState = AppState()
        appState.coupleId = couple.id

        let store = makeStore(
            container: container, appState: appState,
            service: FakeEntitlementService(), storeKit: FakeStoreKit()
        )

        XCTAssertEqual(store.tier, .core)
        XCTAssertTrue(store.isCore, "hydrateFromLocal seeds isCore before any network call")
    }

    func test_init_withNoCoupleId_defaultsToFree() {
        let container = ModelContainer.previewContainer
        let appState = AppState()
        appState.coupleId = nil

        let store = makeStore(
            container: container, appState: appState,
            service: FakeEntitlementService(), storeKit: FakeStoreKit()
        )

        XCTAssertEqual(store.tier, .free)
        XCTAssertFalse(store.isCore)
    }

    // MARK: isCore OR-logic

    func test_isCore_trueWhenLocalOwnsCore_evenWithNoCoupleOrServerTier() async {
        let container = ModelContainer.previewContainer
        let appState = AppState()
        appState.coupleId = nil
        let storeKit = FakeStoreKit()
        storeKit.ownsCoreValue = true

        let store = makeStore(
            container: container, appState: appState,
            service: FakeEntitlementService(), storeKit: storeKit
        )
        await store.refresh()

        XCTAssertEqual(store.tier, .free, "no couple means server tier stays free")
        XCTAssertTrue(store.isCore, "local StoreKit ownership alone satisfies the OR gate")
    }

    func test_isCore_trueWhenServerTierCore_evenWithoutLocalOwnership() async {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let couple = makeCouple(in: context, tier: .free)
        let appState = AppState()
        appState.coupleId = couple.id

        let service = FakeEntitlementService()
        service.tierRow = CoupleTierRow(accessTier: "core", coreUnlockedAt: nil, isFoundingMember: false)
        let storeKit = FakeStoreKit()
        storeKit.ownsCoreValue = false

        let store = makeStore(container: container, appState: appState, service: service, storeKit: storeKit)
        await store.refresh()

        XCTAssertFalse(store.localOwnsCore)
        XCTAssertEqual(store.tier, .core)
        XCTAssertTrue(store.isCore, "server-resolved couple tier alone satisfies the OR gate")
    }

    func test_isCore_falseWhenNeitherSourceGrantsCore() async {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let couple = makeCouple(in: context, tier: .free)
        let appState = AppState()
        appState.coupleId = couple.id

        let service = FakeEntitlementService()
        service.tierRow = CoupleTierRow(accessTier: "free", coreUnlockedAt: nil, isFoundingMember: false)
        let storeKit = FakeStoreKit()
        storeKit.ownsCoreValue = false

        let store = makeStore(container: container, appState: appState, service: service, storeKit: storeKit)
        await store.refresh()

        XCTAssertFalse(store.isCore)
    }

    // MARK: refresh() offline-safety

    func test_refresh_onServerFailure_setsLoadErrorAndKeepsLastKnownTier() async {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let couple = makeCouple(in: context, tier: .core)
        let appState = AppState()
        appState.coupleId = couple.id

        let service = FakeEntitlementService()
        service.fetchError = FakeError()
        let store = makeStore(container: container, appState: appState, service: service, storeKit: FakeStoreKit())

        XCTAssertEqual(store.tier, .core, "hydrated from the local mirror at init")
        await store.refresh()

        XCTAssertNotNil(store.loadError, "a fetch failure must surface loadError")
        XCTAssertEqual(store.tier, .core, "a paid couple must never be downgraded on a network blip")
    }

    func test_refresh_onSuccess_clearsAPreviousLoadError() async {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let couple = makeCouple(in: context, tier: .free)
        let appState = AppState()
        appState.coupleId = couple.id

        let service = FakeEntitlementService()
        service.fetchError = FakeError()
        let store = makeStore(container: container, appState: appState, service: service, storeKit: FakeStoreKit())
        await store.refresh()
        XCTAssertNotNil(store.loadError)

        service.fetchError = nil
        service.tierRow = CoupleTierRow(accessTier: "free", coreUnlockedAt: nil, isFoundingMember: false)
        await store.refresh()
        XCTAssertNil(store.loadError)
    }

    // MARK: self-heal guard (grant-fires path needs StoreKitTest — flagged, not faked)

    func test_selfHeal_doesNotGrant_whenLocalDoesNotOwnCore() async {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let couple = makeCouple(in: context, tier: .free)
        let appState = AppState()
        appState.coupleId = couple.id

        let service = FakeEntitlementService()
        service.tierRow = CoupleTierRow(accessTier: "free", coreUnlockedAt: nil, isFoundingMember: false)
        let storeKit = FakeStoreKit()
        storeKit.ownsCoreValue = false

        let store = makeStore(container: container, appState: appState, service: service, storeKit: storeKit)
        await store.refresh()

        XCTAssertTrue(service.grantedJWS.isEmpty, "no local entitlement means nothing to self-heal")
    }

    func test_selfHeal_doesNotGrant_whenServerTierAlreadyCore() async {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let couple = makeCouple(in: context, tier: .free)
        let appState = AppState()
        appState.coupleId = couple.id

        let service = FakeEntitlementService()
        service.tierRow = CoupleTierRow(accessTier: "core", coreUnlockedAt: nil, isFoundingMember: false)
        let storeKit = FakeStoreKit()
        storeKit.ownsCoreValue = true

        let store = makeStore(container: container, appState: appState, service: service, storeKit: storeKit)
        await store.refresh()

        XCTAssertTrue(service.grantedJWS.isEmpty, "already-core couples never need the self-heal re-grant")
    }

    func test_selfHeal_doesNotGrant_whenNoLocalEntitlementPairAvailable() async {
        // localOwnsCore true + server free clears the guard, but coreEntitlement()
        // (the real receipt lookup) returning nil must short-circuit before granting.
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let couple = makeCouple(in: context, tier: .free)
        let appState = AppState()
        appState.coupleId = couple.id

        let service = FakeEntitlementService()
        service.tierRow = CoupleTierRow(accessTier: "free", coreUnlockedAt: nil, isFoundingMember: false)
        let storeKit = FakeStoreKit()
        storeKit.ownsCoreValue = true
        storeKit.entitlementPair = nil

        let store = makeStore(container: container, appState: appState, service: service, storeKit: storeKit)
        await store.refresh()

        XCTAssertTrue(service.grantedJWS.isEmpty)
        XCTAssertEqual(store.tier, .free)
        XCTAssertTrue(store.isCore, "local ownership still satisfies the OR gate even though self-heal didn't fire")
    }

    // MARK: apply() — coreUnlockedAt written once

    func test_apply_setsCoreUnlockedAtOnce_notOverwrittenOnSubsequentRefresh() async {
        let container = ModelContainer.previewContainer
        let context = ModelContext(container)
        let couple = makeCouple(in: context, tier: .free)
        let appState = AppState()
        appState.coupleId = couple.id

        let service = FakeEntitlementService()
        service.tierRow = CoupleTierRow(accessTier: "core", coreUnlockedAt: nil, isFoundingMember: false)
        let store = makeStore(container: container, appState: appState, service: service, storeKit: FakeStoreKit())

        // The store writes through its OWN fresh ModelContext; re-fetch through a
        // fresh context (same in-memory store) rather than trusting a possibly
        // stale snapshot on the original `couple` reference.
        let coupleId = couple.id
        func fetchUnlockDate() -> Date? {
            let ctx = ModelContext(container)
            let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
            return try? ctx.fetch(descriptor).first?.coreUnlockedAt
        }

        await store.refresh()
        let firstUnlock = fetchUnlockDate()
        XCTAssertNotNil(firstUnlock)

        try? await Task.sleep(for: .milliseconds(5))
        await store.refresh()
        XCTAssertEqual(fetchUnlockDate(), firstUnlock, "coreUnlockedAt is a write-once timestamp")
    }
}
