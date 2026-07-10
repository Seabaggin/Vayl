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

// MARK: - Service seams (test injection)
//
// Minimal additive seam: EntitlementStore already took injected concrete
// service/storeKit instances (Monetization M1/M2), but the concrete types
// made them un-fakeable in tests. These protocols mirror the concrete APIs
// exactly (same signatures, same defaults) so production call sites and
// behavior are unchanged; only the stored property types move from
// concrete → protocol. Follows the AirlockTransport seam pattern.

protocol EntitlementServicing: AnyObject {
    func fetchTier(coupleId: UUID) async throws -> CoupleTierRow?
    func grantCore(productId: String, signedTransaction: String) async throws -> GrantResponse
}

extension EntitlementServicing {
    @discardableResult
    func grantCore(signedTransaction: String) async throws -> GrantResponse {
        try await grantCore(productId: "com.vayl.core.lifetime", signedTransaction: signedTransaction)
    }
}

extension EntitlementService: EntitlementServicing {}

protocol CoreStoreKitServicing: AnyObject {
    func loadCoreProduct() async throws -> Product?
    func purchase(_ product: Product) async throws -> StoreKitService.PurchaseOutcome
    func finish(_ transaction: Transaction) async
    func coreEntitlement() async -> (transaction: Transaction, jws: String)?
    func ownsCore() async -> Bool
    func restore() async throws -> (transaction: Transaction, jws: String)?
    func observeTransactionUpdates(
        onChange: @escaping @Sendable (_ transaction: Transaction, _ jws: String, _ revoked: Bool) async -> Void
    ) -> Task<Void, Never>
}

extension StoreKitService: CoreStoreKitServicing {}

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
    private let service: EntitlementServicing
    private let storeKit: CoreStoreKitServicing
    private var updatesTask: Task<Void, Never>?

    init(
        modelContainer: ModelContainer,
        appState: AppState,
        service: EntitlementServicing? = nil,
        storeKit: CoreStoreKitServicing? = nil
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
            await selfHealGrantIfNeeded(coupleId: coupleId)
        } catch {
            loadError = error.localizedDescription
            // Keep the last tier — do not downgrade a paid couple on a network blip.
        }
    }

    /// Payer-portability self-heal (2026-07-07). Unlink DELETES the couple row,
    /// which cascades the couple-scoped entitlements ledger rows — so when the
    /// buyer re-pairs, the new couple resolves `free` even though this Apple ID
    /// owns Core, and the partner stays locked until a manual Restore. Detect
    /// exactly that state (local ownership, server says free, a couple exists)
    /// and re-push the receipt once: grant-entitlement writes a fresh ledger
    /// row for the NEW couple and recomputes its tier server-side.
    private var isSelfHealing = false

    private func selfHealGrantIfNeeded(coupleId: UUID) async {
        guard localOwnsCore, tier == .free, !isSelfHealing else { return }
        isSelfHealing = true
        defer { isSelfHealing = false }
        guard let (_, jws) = await storeKit.coreEntitlement() else { return }
        do {
            _ = try await service.grantCore(signedTransaction: jws)
            if let row = try? await service.fetchTier(coupleId: coupleId) {
                apply(tier: row.tier, founding: row.isFoundingMember, coupleId: coupleId)
            }
        } catch {
            // Non-fatal: the next refresh retries; the buyer stays unlocked locally.
            FunnelEventService.shared.log(.grantRetried, coupleId: coupleId, detail: error.localizedDescription)
            loadError = "You're unlocked. Syncing to your partner will retry."
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
        // Observability layer 1 (review 2026-07-09 §1.6): funnel joints only.
        // Payload rule: detail carries error strings, NEVER desire item ids or match names.
        FunnelEventService.shared.log(.purchaseStarted, coupleId: appState.coupleId)
        // Clear any stale status so post-purchase loadError reflects THIS attempt only
        // (the paywall reads it back as its purchase status line).
        loadError = nil
        do {
            switch try await storeKit.purchase(product) {
            case .success(let transaction, let jws):
                FunnelEventService.shared.log(.purchaseSucceeded, coupleId: appState.coupleId)
                localOwnsCore = true                       // buyer unlocks immediately
                // Grant BEFORE finish: an unfinished transaction replays via
                // Transaction.updates, so a failed grant retries on next launch
                // instead of silently leaving the partner locked forever.
                await grantThenFinish(transaction: transaction, jws: jws)
                await refresh()
                return isCore
            case .userCancelled:
                // A cancel is not a failure — no funnel event (review 2026-07-09 §1.6).
                return false
            case .pending:
                // Ask-to-Buy / SCA (review addendum 2026-07-09): the approved transaction
                // arrives later via Transaction.updates and unlocks on its own — tell the
                // user what is happening instead of failing silently.
                FunnelEventService.shared.log(.purchasePending, coupleId: appState.coupleId)
                loadError = "Purchase pending approval. It will unlock automatically once it's approved."
                return false
            case .unverified:
                FunnelEventService.shared.log(.purchaseFailed, coupleId: appState.coupleId, detail: "unverified")
                loadError = "That purchase couldn't be verified."
                return false
            }
        } catch {
            FunnelEventService.shared.log(.purchaseFailed, coupleId: appState.coupleId, detail: error.localizedDescription)
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
            FunnelEventService.shared.log(.grantRetried, coupleId: appState.coupleId, detail: error.localizedDescription)
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
                // Observability layer 1 (review 2026-07-09 §1.6): a restore that yields
                // ownership counts as a purchase success on the funnel.
                FunnelEventService.shared.log(.purchaseSucceeded, coupleId: appState.coupleId, detail: "restore")
                do {
                    _ = try await service.grantCore(signedTransaction: jws)
                } catch {
                    FunnelEventService.shared.log(.grantRetried, coupleId: appState.coupleId, detail: error.localizedDescription)
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
        do {
            try couple.modelContext?.save()
        } catch {
            // Non-fatal: the in-memory tier is already correct; only the offline
            // mirror is stale. The next apply() retries the save.
            loadError = error.localizedDescription
        }
    }

    private func localCouple(_ coupleId: UUID) -> Couple? {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Couple>(predicate: #Predicate { $0.id == coupleId })
        return try? context.fetch(descriptor).first
    }
}
