//
//  PairingService.swift
//  Vayl
//

import Foundation
import Supabase
import OSLog

private let logger = Logger(
    subsystem: "com.vayl.app",
    category: "PairingService"
)

// MARK: - Supabase Table/Function Name Constants

private enum SupabaseTable {
    static let pairingCodes = "pairing_codes"
}

private enum SupabaseFunction {
    static let createCouple = "create-couple"
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

    /// Inserts a new pairing code row for the current user.
    /// Returns the generated code string.
    /// Throws on any Supabase failure.
    func generateCode() async throws -> String {
        let code = makeCode()
        let userId = try await currentUserId()

        try await supabase
            .from(SupabaseTable.pairingCodes)
            .insert([
                "created_by": userId.uuidString,
                "code": code
            ])
            .execute()

        logger.info("Pairing code generated: \(code)")
        return code
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

    // MARK: - Poll For Claim

    /// Polls the pairing_codes table every 3 seconds until claimed_by is not null.
    /// Returns the coupleId when the partner joins.
    /// Throws if polling fails or task is cancelled.
    func pollForClaim(code: String) async throws -> UUID {
        let normalized = code.trimmingCharacters(in: .whitespaces).uppercased()

        while true {
            try Task.checkCancellation()

            let rows: [PairingCodeRow] = try await supabase
                .from(SupabaseTable.pairingCodes)
                .select("claimed_by")
                .eq("code", value: normalized)
                .execute()
                .value

            if let row = rows.first, let claimedBy = row.claimedBy {
                logger.info("Partner joined — claimedBy: \(claimedBy)")
                // Fetch couple_id for this code
                let coupleId = try await fetchCoupleId(code: normalized)
                return coupleId
            }

            try await Task.sleep(for: .seconds(3))
        }
    }

    // MARK: - Private Helpers

    /// Fetches the couple_id from the pairing_codes row after claim.
    /// The Edge Function writes couple_id before deleting the row —
    /// there is a brief window where it exists.
    private func fetchCoupleId(code: String) async throws -> UUID {
        struct CoupleIdRow: Decodable {
            let coupleId: UUID?
            enum CodingKeys: String, CodingKey {
                case coupleId = "couple_id"
            }
        }

        let rows: [CoupleIdRow] = try await supabase
            .from(SupabaseTable.pairingCodes)
            .select("couple_id")
            .eq("code", value: code)
            .execute()
            .value

        guard let coupleId = rows.first?.coupleId else {
            throw PairingError.coupleIdNotFound
        }

        return coupleId
    }

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
