//
//  CoupleContext.swift
//  Vayl
//
//  The single owner of couple-level shared facts (2026-07-04 audit, Blueprint A).
//
//  Before this existed, partner identity had FOUR independent owners (HomeStore /
//  MapStore / PairingStore / SessionEntryStore) — and HomeStore's copy had no
//  production writer at all, so a linked couple's release build rendered
//  "your partner" everywhere while a #if DEBUG "Alex" seed hid the gap in dev.
//  The desire-reveal unlock rule was likewise implemented four times, one copy
//  still reading the lagging `Couple.canRevealDesireMap` mirror the other copies
//  explicitly distrust.
//
//  Rules:
//  · Partner identity is fetched HERE, once per link, and read everywhere else.
//  · The reveal gate is `canRevealAll` — the OR'd entitlement (server tier OR
//    local StoreKit ownership) via EntitlementStore.isCore. Never read the
//    local `Couple.canRevealDesireMap` mirror for gating; it lags a
//    just-purchased buyer.
//  · This is couple-fact state only. Feature flow state stays in feature stores.
//

import Foundation
import OSLog
import SwiftData

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "CoupleContext"
)

@MainActor
@Observable
final class CoupleContext {

    // MARK: - Partner identity (single source of truth)

    /// Backing cache — written only by `refreshIfNeeded()` / `setPartner(name:)`.
    /// Keyed to the couple it was fetched for, so an unlink + re-pair with a
    /// different partner refetches instead of serving the stale name.
    private var fetchedPartnerName: String?
    private var fetchedForCoupleId: UUID?

    /// The linked partner's display name, or nil when unlinked / not yet fetched /
    /// the partner has no name. Gated on linkState so an unlink clears the read
    /// surface without a manual reset.
    var partnerName: String? {
        #if DEBUG
        // Dev convenience (matches the old MapStore fallback): show a partner
        // without a live paired backend so headers/toggles are exercisable.
        // This is the ONLY debug partner seed in the app — release reads below.
        return fetchedPartnerName ?? "Alex"
        #else
        guard appState.linkState == .linked else { return nil }
        return fetchedPartnerName
        #endif
    }

    /// Backing cache for the local `UserProfile.linkedAt` couple-fact — when
    /// pairing completed. Local-only (SwiftData), not something PairingService
    /// fetches from the server.
    private var fetchedPairedSince: Date?
    private var fetchedPairedSinceForCoupleId: UUID?

    /// When this device's pairing completed, or nil when unlinked / not yet
    /// fetched. Mirrors `partnerName`'s shape exactly: gated on linkState, and
    /// its loader is keyed on `fetchedPairedSinceForCoupleId` so an unlink +
    /// re-pair with a different partner in the same app session refetches
    /// instead of serving the first partner's stale paired-since date (same
    /// DEBUG passthrough omitted — pairedSince has no dev-seed need since it's
    /// a local field that's always readable once linked).
    var pairedSince: Date? {
        guard appState.linkState == .linked else { return nil }
        return fetchedPairedSince
    }

    // MARK: - Reveal gate (single truth rule)

    /// Whether every desire match may be shown (vs. free-reveal rows only).
    /// THE gate rule — all reveal surfaces (Home ladder, Map align list, Vault,
    /// the reveal itself) must read this and nothing else.
    var canRevealAll: Bool { entitlements.isCore }

    // MARK: - Dependencies

    private let appState: AppState
    private let entitlements: EntitlementStore
    private let pairingService: PairingService
    private let modelContainer: ModelContainer

    init(appState: AppState,
         entitlements: EntitlementStore,
         modelContainer: ModelContainer,
         pairingService: PairingService? = nil) {
        self.appState = appState
        self.entitlements = entitlements
        self.modelContainer = modelContainer
        self.pairingService = pairingService ?? PairingService()
    }

    // MARK: - Hydration

    /// The couple the entitlement tier was last server-resolved for. Keyed like
    /// the partner-name cache so an unlink + re-pair triggers exactly one
    /// re-resolve for the NEW couple (which runs EntitlementStore's
    /// payer-portability self-heal — the buyer's receipt re-grants the fresh
    /// couple without a manual Restore).
    private var entitlementsResolvedForCoupleId: UUID?

    /// Fetches the partner's identity once per link. Safe to call on every
    /// appear — it no-ops when already loaded or unlinked (same load-once
    /// semantics the old MapStore fetch had, so the header toggle fades in
    /// exactly once and never flickers).
    func refreshIfNeeded() async {
        guard appState.linkState == .linked else { return }
        loadPairedSinceIfNeeded()
        if let coupleId = appState.coupleId, entitlementsResolvedForCoupleId != coupleId {
            entitlementsResolvedForCoupleId = coupleId
            await entitlements.refresh()
        }
        guard fetchedPartnerName == nil || fetchedForCoupleId != appState.coupleId else { return }
        do {
            if let identity = try await pairingService.fetchPartner(),
               let name = identity.name, !name.isEmpty {
                fetchedPartnerName = name
                fetchedForCoupleId = appState.coupleId
                logger.info("CoupleContext: partner identity loaded")
            }
        } catch {
            logger.error("CoupleContext: partner fetch failed — \(error.localizedDescription)")
        }
    }

    /// Local SwiftData read for `UserProfile.linkedAt` — no-ops once already
    /// loaded for the current couple, same coupleId-keyed load-once semantics
    /// as the partner-name fetch above (guards against serving a prior
    /// partner's paired-since date after an unlink + re-pair in one session).
    private func loadPairedSinceIfNeeded() {
        guard fetchedPairedSince == nil || fetchedPairedSinceForCoupleId != appState.coupleId else { return }
        let context = ModelContext(modelContainer)
        guard let profile = try? context.fetch(FetchDescriptor<UserProfile>()).first else { return }
        fetchedPairedSince = profile.linkedAt
        fetchedPairedSinceForCoupleId = appState.coupleId
    }

    /// Write-through for flows that already know the name (e.g. the pairing
    /// flow's link success) so consumers update without a second fetch.
    func setPartner(name: String?) {
        fetchedPartnerName = (name?.isEmpty == false) ? name : nil
        fetchedForCoupleId = appState.coupleId
    }

    /// Clears the cached identity (unlink / account reset). Not strictly required
    /// for correctness — the read surface gates on linkState and the cache is
    /// keyed to coupleId — but keeps stale identity out of memory.
    func clearPartner() {
        fetchedPartnerName = nil
        fetchedForCoupleId = nil
        fetchedPairedSince = nil
        fetchedPairedSinceForCoupleId = nil
        entitlementsResolvedForCoupleId = nil
    }
}
