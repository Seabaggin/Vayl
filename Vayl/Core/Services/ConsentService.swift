//
//  ConsentService.swift
//  Vayl
//
//  The consent exchange's Supabase access. Reads couple-readable requests (only ever
//  pending/opened) and the caller's OWN declines (RLS-scoped to decided_by, so the asker
//  can never read a decline). Ask + respond go through the consent-ask / consent-respond
//  Edge Functions (service role) — the client never writes consent state directly.
//

import Foundation
import Supabase

struct ConsentRequestRow: Decodable, Identifiable, Sendable {
    let id: UUID
    let itemId: String
    let askerId: UUID
    let status: String
    let discussionCardId: String?
    enum CodingKeys: String, CodingKey {
        case id, status
        case itemId = "item_id"
        case askerId = "asker_id"
        case discussionCardId = "discussion_card_id"
    }
}

struct ConsentDeclineRow: Decodable, Sendable {
    let itemId: String
    enum CodingKeys: String, CodingKey { case itemId = "item_id" }
}

@MainActor
final class ConsentService {

    private var supabase: SupabaseClient { SupabaseManager.shared.client }

    func fetchRequests(coupleId: UUID) async throws -> [ConsentRequestRow] {
        try await supabase.from("consent_requests")
            .select("id, item_id, asker_id, status, discussion_card_id")
            .eq("couple_id", value: coupleId.uuidString)
            .execute()
            .value
    }

    /// RLS returns ONLY the caller's own declines (decided_by-scoped).
    func fetchMyDeclines(coupleId: UUID) async throws -> [ConsentDeclineRow] {
        try await supabase.from("consent_declines")
            .select("item_id")
            .eq("couple_id", value: coupleId.uuidString)
            .execute()
            .value
    }

    func ask(itemId: String) async throws {
        try await supabase.functions.invoke(
            "consent-ask",
            options: FunctionInvokeOptions(body: ["item_id": itemId])
        )
    }

    func respond(itemId: String, open: Bool) async throws {
        try await supabase.functions.invoke(
            "consent-respond",
            options: FunctionInvokeOptions(body: ["item_id": itemId, "decision": open ? "open" : "decline"])
        )
    }
}
