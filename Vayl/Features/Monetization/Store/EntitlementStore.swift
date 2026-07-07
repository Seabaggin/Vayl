//
//  EntitlementStore.swift
//  Vayl
//
//  Central read surface for the couple's access tier — Monetization M1 + M2.
//  The single `isCore`/`tier` that every gate reads (M3+). Couple-level: one purchase unlocks
//  BOTH partners. `isCore` resolves from TWO sources OR'd (guide Part D):
//    • the couple's SERVER tier (couples.access_tier) — covers the partner (no local txn), and
//    • local StoreKit ownership — covers the buyer fast/offline, before the server grant propagates.
//
//  4-Layer arch: View → Store → Service. Views never call StoreKit — they read `isCore`/`tier`
//  and call `purchase()`/`restore()`. The Store decides; StoreKitService + EntitlementService do I/O.
//

import Foundation
import SwiftData
import StoreKit

@Observable
@MainActor
final class EntitlementStore {

    // MARK: - Published state

    /// The couple's resolved SERVER tier. `.free` until a paired couple resolves `core`.
    private(set) var tier: AccessTier = .free

    /// Founding-member perk flag (first-year-free Pro when Act 2 lands). Not sensitive.
    private(set) var isFoundingMember: Bool = false

    /// This device's Apple ID owns Core locally (StoreKit). The buyer's fast/offline fallback;
    /// the partner has no local transaction and unlocks from the server `tier` instead.
    private(set) var localOwnsCore: Bool = false

    /// Core product metadata for the paywall price label (nil until loaded / if ASC not set up yet).
    private(set) var coreProduct: Product?

    /// In-flight purchase/restore flag for the paywall UI.
    private(set) var isPurchasing: Bool = false

    /// Set when a server refresh failed; the last known tier still stands (offline-safe).
    private(set) var loadError: String?

    /// The single gate every paywalled surface reads (M3+). Server tier OR local StoreKit ownership.
    var isCore: Bool { tier != .free || localOwnsCore }

    /// Display price for the paywall CTA (e.g. "$24.99"), if the product loaded.
    var corePriceText: String? { coreProduct?.displayPrice }

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let appState: AppState
    private let service: EntitlementService
    private let storeKit: StoreKitService
    private var updatesTask: Task<Void, Never>?

    init(
        modelContainer: ModelContainer,
        appState: AppState,
        service: EntitlementService? = nil,
        storeKit: StoreKitService? = nil
    ) {
        self.modelContainer = modelContainer
        self.appState = appState
        // Construct in the @MainActor init body (not as a default arg, which is nonisolated).
        self.service = service ?? EntitlementService()
        self.storeKit = storeKit ?? StoreKitService()
        // Instant offline read from the local mirror; bootstrap()/refresh() corrects from server + StoreKit.
        hydrateFromLocal()
    }

    // MARK: - Bootstrap (app launch)

    /// Load the product, resolve tier from all sources, and start the StoreKit updates listener.
    /// Call once after the session is ready (VaylApp). Supersedes a bare refresh().
    func bootstrap() async {
        coreProduct = try? await storeKit.loadCoreProduct()
        await refresh()
        if updatesTask == nil {
            updatesTask = storeKit.observeTransactionUpdates { [weak self] transaction, jws, revoked in
                guard let self else { return }
                await self.handleTransactionUpdate(transaction: transaction, jws: jws, revoked: revoked)
            }
        }
    }

    // MARK: - Resolve tier (server OR local)

    /// Re-resolve `isCore` from the local StoreKit entitlement + the couple's server tier.
    /// Best-effort: on server failure the last known tier stands (offline / transient is non-fatal).
    func refresh() async {
        localOwnsCore = await storeKit.ownsCore()
        guard let coupleId = appState.coupleId else {
            apply(tier: .free, founding: false, coupleId: nil)
            return
        }
        do {
            guard let row = try await service.fetchTier(coupleId: coupleId) else { return }
            apply(tier: row.tier, founding: row.isFoundingMember, coupleId: coupleId)
            loadError = nil
        } catch {
            loadError = error.localizedDescription
            // Keep the last tier — do not downgrade a paid couple on a network blip.
        }
    }

    // MARK: - Purchase / restore (M2)

    /// Run the Core purchase. On a verified transaction → push the signed JWS to the server
    /// (grant-entitlement writes the COUPLE entitlement so the partner unlocks too) → re-resolve.
    /// Returns true once the couple is Core. Safe from the paywall / D4 unlock CTA.
    @discardableResult
    func purchase() async -> Bool {
        guard !isPurchasing else { return isCore }
        if coreProduct == nil { coreProduct = try? await storeKit.loadCoreProduct() }
        guard let product = coreProduct else {
            loadError = "Core isn't available right now."
            return false
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await storeKit.purchase(product) {
            case .success(let transaction, let jws):
                localOwnsCore = true                       // buyer unlocks immediately
                // Grant BEFORE finish: an unfinished transaction replays via
                // Transaction.updates, so a failed grant retries on next launch
                // instead of silently leaving the partner locked forever.
                await grantThenFinish(transaction: transaction, jws: jws)
                await refresh()
                return isCore
            case .pending, .userCancelled:
                return false
            case .unverified:
                loadError = "That purchase couldn't be verified."
                return false
            }
        } catch {
            loadError = error.localizedDescription
            return false
        }
    }

    /// Push the couple grant; finish the transaction only once it lands.
    private func grantThenFinish(transaction: Transaction, jws: String) async {
        do {
            _ = try await service.grantCore(signedTransaction: jws)   // server → partner unlocks too
            await storeKit.finish(transaction)
        } catch {
            // Leave unfinished — StoreKit replays it into the updates listener,
            // which re-attempts the grant. The buyer stays unlocked locally.
            loadError = "You're unlocked. Syncing to your partner will retry."
        }
    }

    /// Explicit "Restore Purchases" (Apple requires a restore path for non-consumables). Re-syncs
    /// from the App Store; if Core is owned, re-grants the couple server-side and re-resolves.
    @discardableResult
    func restore() async -> Bool {
        guard !isPurchasing else { return isCore }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            if let (_, jws) = try await storeKit.restore() {
                localOwnsCore = true
                do {
                    _ = try await service.grantCore(signedTransaction: jws)
                } catch {
                    loadError = "You're unlocked. Syncing to your partner will retry."
                }
            }
            await refresh()
        } catch {
            loadError = error.localizedDescription
        }
        return isCore
    }

    // MARK: - Background updates

    /// Handle a transaction arriving outside an explicit purchase (Ask-to-Buy, another device,
    /// refund/revocation) — or a replay of one left unfinished by a failed grant. Refund →
    /// drop the local fallback + re-resolve (couple-level downgrade is server-driven via the
    /// refund webhook — a documented fast-follow).
    private func handleTransactionUpdate(transaction: Transaction, jws: String, revoked: Bool) async {
        if revoked {
            localOwnsCore = false
            await storeKit.finish(transaction)
            await refresh()
        } else {
            localOwnsCore = true
            await grantThenFinish(transaction: transaction, jws: jws)
            await refresh()
        }
    }

    // MARK: - Local mirror

    /// Seed the in-memory tier from the local Couple at init (before the network resolves).
    private func hydrateFromLocal() {
        guard let coupleId = appState.coupleId,
              let couple = localCouple(coupleId) else { return }
        tier = couple.entitlementTier
        isFoundingMember = couple.isFoundingMember
    }

    /// Update the in-memory surface and mirror into the local Couple (if one exists) so offline
    /// reads and `Couple.canRevealDesireMap` stay correct. Never creates/owns Couple rows.
    private func apply(tier newTier: AccessTier, founding: Bool, coupleId: UUID?) {
        tier = newTier
        isFoundingMember = founding
        guard let coupleId, let couple = localCouple(coupleId) else { return }
        couple.entitlementTier = newTier
        couple.isFoundingMember = founding
        if newTier != .free && couple.coreUnlockedAt == nil {
            couple.coreUnlockedAt = Date()
        }
        try? couple.modelContext?.save()
    }

    private func localCouple(_ coupleId: UUID) -> Couple? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        return try? context.fetch(descriptor).first
    }
}
