//
//  StoreKitService.swift
//  Vayl
//
//  StoreKit 2 wrapper — Monetization M2. Service layer: I/O only, no app state, no decisions.
//  Injected into EntitlementStore. Swift 6 / StoreKit 2 (Product / Transaction / VerificationResult).
//
//  Vayl's unlock is COUPLE-level (one purchase → both partners). StoreKit only knows THIS Apple
//  ID on THIS device, so a verified purchase here is pushed to the server (grant-entitlement),
//  which writes the couple entitlement so the PARTNER (who has no local transaction) unlocks too.
//  This service just surfaces the verified transaction + its signed JWS; EntitlementStore decides.
//

import Foundation
import StoreKit

final class StoreKitService {

    /// Must match the App Store Connect product id + the `.storekit` config + the edge fn.
    nonisolated static let coreProductID = "com.vayl.core.lifetime"

    /// Outcome of a purchase attempt. `.success` carries the verified transaction + its signed
    /// JWS representation (what the server re-verifies in grant-entitlement).
    enum PurchaseOutcome {
        case success(transaction: Transaction, jws: String)
        case userCancelled
        case pending            // Ask-to-Buy / parental approval — resolves later via updates
        case unverified         // signature check failed — NEVER grant
    }

    // MARK: - Load

    /// Load the Core product metadata (price, display name) for the paywall.
    func loadCoreProduct() async throws -> Product? {
        let products = try await Product.products(for: [Self.coreProductID])
        return products.first
    }

    // MARK: - Purchase

    /// Run Apple's purchase sheet. Returns a *verified* transaction + JWS on success.
    /// Finishes the transaction (required, or StoreKit replays it forever).
    func purchase(_ product: Product) async throws -> PurchaseOutcome {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let jws = verification.jwsRepresentation
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                return .success(transaction: transaction, jws: jws)
            case .unverified:
                return .unverified
            }
        case .userCancelled:
            return .userCancelled
        case .pending:
            return .pending
        @unknown default:
            return .userCancelled
        }
    }

    // MARK: - Ownership / restore

    /// The device's signed-in Apple ID's CURRENT Core entitlement (verified, non-revoked) + its
    /// JWS — or nil. Drives the local unlock fallback for the buyer + restore.
    func coreEntitlement() async -> (transaction: Transaction, jws: String)? {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.coreProductID,
               transaction.revocationDate == nil {
                return (transaction, result.jwsRepresentation)
            }
        }
        return nil
    }

    /// Does this Apple ID currently own Core? (silent launch check — no password prompt)
    func ownsCore() async -> Bool {
        await coreEntitlement() != nil
    }

    /// Explicit "Restore Purchases" → re-sync from the App Store (may prompt for Apple ID).
    /// Returns the restored Core entitlement (+ JWS) so the caller can re-grant the couple.
    func restore() async throws -> (transaction: Transaction, jws: String)? {
        try await AppStore.sync()
        return await coreEntitlement()
    }

    // MARK: - Background updates

    /// Long-running listener for transactions arriving outside an explicit purchase — Ask-to-Buy
    /// approvals, purchases on another device, and refunds/revocations. Start once at launch.
    /// `onChange` receives the verified Core transaction + JWS (or nil when it was revoked).
    func observeTransactionUpdates(
        onChange: @escaping @Sendable (_ transaction: Transaction, _ jws: String, _ revoked: Bool) async -> Void
    ) -> Task<Void, Never> {
        Task.detached {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update,
                   transaction.productID == Self.coreProductID {
                    await transaction.finish()
                    await onChange(transaction, update.jwsRepresentation, transaction.revocationDate != nil)
                }
            }
        }
    }
}
