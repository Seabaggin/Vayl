//
//  EntitlementRecord.swift
//  Vayl
//

import Foundation
import SwiftData

// MARK: - EntitlementRecord
// Records a purchase that unlocks Core tier for a couple.
// Lives on Couple — one purchase covers both partners.
// No hierarchy displayed to either partner.
//
// Receipt validation happens server-side via Edge Function.
// Never client-only validation.
//
// isFoundingMember enables first-year-free Pro when Act 2 launches.
// Lifetime purchases (expiresAt nil) are never revoked except
// for confirmed refunds.
// purchasedBy is recorded for support resolution only —
// never shown to either partner under any circumstances.

@Model
final class EntitlementRecord {

    // MARK: - Identity

    var id: UUID
    var coupleId: UUID
    var productId: String           // StoreKit product identifier
    var transactionId: String       // StoreKit transaction ID

    // MARK: - Purchase Metadata

    var purchasedBy: UUID           // support use only — never shown to partner
    var purchasedAt: Date
    var isActive: Bool
    var expiresAt: Date?            // nil for lifetime purchases

    // MARK: - Founding Member

    var isFoundingMember: Bool      // true if purchased before Pro launches
                                    // enables first-year-free Pro in Act 2

    // MARK: - Init

    init(
        coupleId: UUID,
        productId: String,
        purchasedBy: UUID,
        transactionId: String
    ) {
        self.id = UUID()
        self.coupleId = coupleId
        self.productId = productId
        self.purchasedBy = purchasedBy
        self.purchasedAt = Date()
        self.transactionId = transactionId
        self.isActive = true
        self.expiresAt = nil
        self.isFoundingMember = false
    }

    // MARK: - Computed

    var isLifetime: Bool {
        expiresAt == nil
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    // MARK: - Preview Helpers

    static let example = EntitlementRecord(
        coupleId: UUID(),
        productId: "com.vayl.core.lifetime",
        purchasedBy: UUID(),
        transactionId: "txn-preview-001"
    )

    static let foundingMemberExample: EntitlementRecord = {
        let e = EntitlementRecord(
            coupleId: UUID(),
            productId: "com.vayl.core.lifetime",
            purchasedBy: UUID(),
            transactionId: "txn-preview-002"
        )
        e.isFoundingMember = true
        return e
    }()
}

// MARK: - ConnectionEntitlement
// Records a $7.99 additional connection purchase.
// Permanent — no expiry, survives relationship dissolution.
//
// The $7.99 Permanent Bill of Rights — regardless of future
// pricing changes, this purchase always includes forever:
//   Infinite card sessions with that specific connection
//   Multi-person decks for that configuration
//   Shared Lock In with that connection
//   Desire Map input with that connection

@Model
final class ConnectionEntitlement {

    // MARK: - Identity

    var id: UUID
    var purchasedBy: UUID
    var connectionCoupleId: UUID    // which additional connection this unlocks
    var purchasedAt: Date
    var transactionId: String       // StoreKit transaction ID

    // No expiresAt — $7.99 is permanent, no expiry ever

    // MARK: - Init

    init(
        purchasedBy: UUID,
        connectionCoupleId: UUID,
        transactionId: String
    ) {
        self.id = UUID()
        self.purchasedBy = purchasedBy
        self.connectionCoupleId = connectionCoupleId
        self.purchasedAt = Date()
        self.transactionId = transactionId
    }

    // MARK: - Preview Helpers

    static let example = ConnectionEntitlement(
        purchasedBy: UUID(),
        connectionCoupleId: UUID(),
        transactionId: "txn-connection-preview-001"
    )
}