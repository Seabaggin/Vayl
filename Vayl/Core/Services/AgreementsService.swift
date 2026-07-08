//
//  AgreementsService.swift
//  Vayl
//
//  Supabase access for the Vault's Agreements (dual-lock). Reads the couple's active
//  agreements + pending proposals; writes a proposal (INSERT) and a decision (UPDATE).
//  RLS enforces that only the non-proposer can decide; the DB trigger applies an
//  approved proposal to `agreements`. Mirrors DesireSyncService's client + DTO style.
//

import Foundation
import Supabase

// MARK: - Read DTOs

struct AgreementRow: Decodable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let isActive: Bool
    enum CodingKeys: String, CodingKey {
        case id, text
        case isActive = "is_active"
    }
}

struct AgreementProposalRow: Decodable, Identifiable, Sendable {
    let id: UUID
    let targetAgreementId: UUID?
    let action: String          // create | edit | retire
    let proposedText: String?
    let proposedBy: UUID
    enum CodingKeys: String, CodingKey {
        case id, action
        case targetAgreementId = "target_agreement_id"
        case proposedText = "proposed_text"
        case proposedBy = "proposed_by"
    }
}

// MARK: - Write DTOs

private struct AgreementProposalInsert: Encodable {
    let coupleId: String
    let proposedBy: String
    let action: String
    let targetAgreementId: String?
    let proposedText: String?

    enum CodingKeys: String, CodingKey {
        case coupleId = "couple_id"
        case proposedBy = "proposed_by"
        case action
        case targetAgreementId = "target_agreement_id"
        case proposedText = "proposed_text"
    }
}

private struct ProposalDecision: Encodable {
    let status: String
}

// MARK: - Service

@MainActor
final class AgreementsService {

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    func fetchAgreements(coupleId: UUID) async throws -> [AgreementRow] {
        try await supabase
            .from("agreements")
            .select("id, text, is_active")
            .eq("couple_id", value: coupleId.uuidString)
            .execute()
            .value
    }

    func fetchPendingProposals(coupleId: UUID) async throws -> [AgreementProposalRow] {
        try await supabase
            .from("agreement_proposals")
            .select("id, target_agreement_id, action, proposed_text, proposed_by")
            .eq("couple_id", value: coupleId.uuidString)
            .eq("status", value: "pending")
            .execute()
            .value
    }

    func propose(coupleId: UUID, proposerId: UUID, action: String,
                 targetAgreementId: UUID?, text: String?) async throws {
        let row = AgreementProposalInsert(
            coupleId: coupleId.uuidString,
            proposedBy: proposerId.uuidString,
            action: action,
            targetAgreementId: targetAgreementId?.uuidString,
            proposedText: text
        )
        try await supabase.from("agreement_proposals").insert(row).execute()
    }

    func decide(proposalId: UUID, approve: Bool) async throws {
        try await supabase
            .from("agreement_proposals")
            .update(ProposalDecision(status: approve ? "approved" : "declined"))
            .eq("id", value: proposalId.uuidString)
            .execute()
    }
}
