//
//  EntitlementService.swift
//  Vayl
//
//  Service layer (network I/O) for couple-level entitlements — Monetization M1.
//  Injected into EntitlementStore; no Store/View references, no state ownership.
//
//  Read path:  couples.access_tier (the denormalized resolved tier; RLS scopes it to the
//              couple's members). The raw `entitlements` ledger is SERVICE-ROLE-ONLY and is
//              never read by the client — who-paid is support-only.
//  Write path: the `grant-entitlement` edge function. The server validates the purchase
//              (StoreKit 2 JWS, wired in M2) and writes the couple entitlement via the service
//              role, returning the resolved tier. Invoked from the StoreKit flow in M2.
//

import Foundation
import Supabase

final class EntitlementService {

    private let supabase: SupabaseClient

    init(supabase: SupabaseClient = SupabaseManager.shared.client) {
        self.supabase = supabase
    }

    // MARK: - Read tier

    /// Reads the couple's resolved tier + unlock state. RLS scopes the row to couple members,
    /// so a non-member (or unpaired caller) reads nothing → returns nil.
    func fetchTier(coupleId: UUID) async throws -> CoupleTierRow? {
        let rows: [CoupleTierRow] = try await supabase
            .from("couples")
            .select("access_tier, core_unlocked_at, is_founding_member")
            .eq("id", value: coupleId.uuidString)
            .execute()
            .value
        return rows.first
    }

    // MARK: - Grant (server-authoritative)

    /// Invokes `grant-entitlement`. The server validates the StoreKit 2 signed transaction
    /// (M2) and writes the couple entitlement via the service role — one purchase unlocks BOTH
    /// partners. Returns the resolved tier. Wired into purchase + restore in M2.
    @discardableResult
    func grantCore(
        productId: String = "com.vayl.core.lifetime",
        signedTransaction: String
    ) async throws -> GrantResponse {
        try await supabase.functions.invoke(
            "grant-entitlement",
            options: FunctionInvokeOptions(
                body: ["productId": productId, "signedTransaction": signedTransaction]
            )
        )
    }
}

// MARK: - DTOs

/// The couple's client-safe resolved tier. Mirrors the non-sensitive columns on
/// `public.couples` — deliberately NEVER includes who paid (support-only, service-role-only).
struct CoupleTierRow: Decodable, Sendable {
    let accessTier: String
    let coreUnlockedAt: String?
    let isFoundingMember: Bool

    enum CodingKeys: String, CodingKey {
        case accessTier = "access_tier"
        case coreUnlockedAt = "core_unlocked_at"
        case isFoundingMember = "is_founding_member"
    }

    var tier: AccessTier { AccessTier(rawValue: accessTier) ?? .free }
}

/// Result of `grant-entitlement` — tier only, never the receipt/buyer details.
struct GrantResponse: Decodable, Sendable {
    let tier: String
    let coupleId: UUID

    var resolvedTier: AccessTier { AccessTier(rawValue: tier) ?? .free }
}
