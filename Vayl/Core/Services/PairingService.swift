//
//  PairingService.swift
//  Vayl
//

import Foundation
import Supabase
import OSLog

nonisolated private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "PairingService"
)

// MARK: - Supabase Table/Function Name Constants

private enum SupabaseTable {
    static let pairingCodes = "pairing_codes"
}

private enum SupabaseFunction {
    static let createCouple = "rapid-task"   // function display-name is "create-couple"; deployed slug is "rapid-task"
    static let getPartner   = "get-partner"  // returns the linked partner's name + pronouns only
}

// MARK: - Response Models

struct CreateCoupleResponse: Decodable {
    let coupleId: UUID

    enum CodingKeys: String, CodingKey {
        case coupleId = "couple_id"
    }
}

struct PairingCodeRow: Decodable {
    let claimedBy: UUID?

    enum CodingKeys: String, CodingKey {
        case claimedBy = "claimed_by"
    }
}

/// The linked partner's display identity, as returned by `get-partner`.
/// Either field may be nil if the partner hasn't set it yet.
struct PartnerIdentity: Decodable {
    let name: String?
    let pronouns: String?
}

// MARK: - PairingService

/// Pure data access layer for partner linking.
/// No UI knowledge. No state ownership.
/// All methods use async/await only — no Combine, no callbacks.
/// All errors are rethrown — never swallowed.

final class PairingService {

    // MARK: - Dependencies

    private let supabase: SupabaseClient

    // MARK: - Init

    init(supabase: SupabaseClient = SupabaseManager.shared.client) {
        self.supabase = supabase
    }

    // MARK: - Generate Code

    /// Inserts a new pairing code row for the current user and reads back the
    /// DB-assigned `expires_at` (the column defaults to `now() + 24h`).
    /// Returns the code plus its expiry so the waiting UI can count down and the
    /// poll can bound itself. Throws on any Supabase failure.
    func generateCode() async throws -> (code: String, expiresAt: Date) {
        struct GeneratedCodeRow: Decodable {
            let code: String
            let expiresAt: Date
            enum CodingKeys: String, CodingKey {
                case code
                case expiresAt = "expires_at"
            }
        }

        let code = makeCode()
        let userId = try await currentUserId()

        let row: GeneratedCodeRow = try await supabase
            .from(SupabaseTable.pairingCodes)
            .insert([
                "created_by": userId.uuidString,
                "code": code
            ])
            .select("code, expires_at")
            .single()
            .execute()
            .value

        logger.info("Pairing code generated: \(row.code)")
        return (row.code, row.expiresAt)
    }

    // MARK: - Claim Code

    /// Claims a pairing code and triggers the create-couple Edge Function.
    /// Returns the coupleId on success.
    /// Throws on expired code, not found, or Edge Function failure.
    func claimCode(_ code: String) async throws -> UUID {
        let normalized = code.trimmingCharacters(in: .whitespaces).uppercased()

        let response: CreateCoupleResponse = try await supabase.functions.invoke(
            SupabaseFunction.createCouple,
            options: FunctionInvokeOptions(body: ["code": normalized])
        )

        logger.info("Code claimed — coupleId: \(response.coupleId)")
        return response.coupleId
    }

    // MARK: - Fetch Partner

    /// Invokes `get-partner` and returns the linked partner's name + pronouns.
    /// Returns nil when the caller isn't linked or the partner has no name yet.
    /// Throws only on transport/decode failure.
    func fetchPartner() async throws -> PartnerIdentity? {
        struct PartnerResponse: Decodable { let partner: PartnerIdentity? }
        let response: PartnerResponse = try await supabase.functions.invoke(
            SupabaseFunction.getPartner,
            options: FunctionInvokeOptions()
        )
        return response.partner
    }

    // MARK: - Poll For Claim

    /// Polls every 3 seconds until the partner joins, the `deadline` passes, or
    /// the code expires in the DB — whichever comes first.
    /// Returns the coupleId when the partner joins.
    /// Throws `PairingError.expiredCode` if the code times out before a partner
    /// joins, or rethrows on cancellation / network failure.
    func pollForClaim(code: String, deadline: Date) async throws -> UUID {
        struct ProfileCoupleRow: Decodable, Sendable {
            let coupleId: UUID?
            enum CodingKeys: String, CodingKey { case coupleId = "couple_id" }
        }

        let myAuthId = try await currentUserId()

        let channel = supabase.channel("pairing:\(myAuthId.uuidString)")
        let changes = channel.postgresChange(
            AnyAction.self,
            schema: "public",
            table: "user_profiles",
            filter: .eq("auth_id", value: myAuthId.uuidString)
        )
        
        try await channel.subscribeWithError()
        defer { Task { await self.supabase.removeChannel(channel) } }
        
        // 1) Partner joined? (initial check before stream starts)
        let initialRows: [ProfileCoupleRow] = try await supabase
            .from("user_profiles")
            .select("couple_id")
            .eq("auth_id", value: myAuthId.uuidString)
            .execute()
            .value
            
        if let coupleId = initialRows.first?.coupleId {
            logger.info("Linked (initial) — coupleId: \(coupleId)")
            return coupleId
        }

        // 2) Listen for realtime changes or timeout
        return try await withThrowingTaskGroup(of: UUID.self) { group in
            group.addTask {
                for await _ in changes {
                    let rows: [ProfileCoupleRow] = try await self.supabase
                        .from("user_profiles")
                        .select("couple_id")
                        .eq("auth_id", value: myAuthId.uuidString)
                        .execute()
                        .value
                    if let coupleId = rows.first?.coupleId {
                        logger.info("Linked (realtime) — coupleId: \(coupleId)")
                        return coupleId
                    }
                }
                throw CancellationError()
            }
            
            group.addTask {
                let timeToWait = deadline.timeIntervalSinceNow
                if timeToWait > 0 {
                    try await Task.sleep(for: .seconds(timeToWait))
                }
                logger.info("Pairing code expired (deadline reached)")
                throw PairingError.expiredCode
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    // MARK: - Private Helpers

    /// Returns the current authenticated user's UUID.
    /// Throws if no session exists.
    private func currentUserId() async throws -> UUID {
        let session = try await supabase.auth.session
        return session.user.id
    }

    /// Generates a 6-character alphanumeric code.
    /// Excludes ambiguous characters: 0, O, 1, I, L.
    private func makeCode() -> String {
        let chars: [Character] = Array("ABCDEFGHJKMNPQRSTUVWXYZ2345679")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

// MARK: - PairingError

enum PairingError: Error, LocalizedError {
    case coupleIdNotFound
    case expiredCode
    case invalidCode
    case selfLink
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .coupleIdNotFound:
            return "Could not retrieve couple ID after linking."
        case .expiredCode:
            return "This code has expired. Ask your partner to generate a new one."
        case .invalidCode:
            return "Code not found. Check the code and try again."
        case .selfLink:
            return "You cannot link with yourself."
        case .unknown(let message):
            return message
        }
    }
}
