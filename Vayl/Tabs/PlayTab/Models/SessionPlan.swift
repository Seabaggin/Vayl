//
//  SessionPlan.swift
//  Vayl
//
//  Tonight's session shape — the Builder's output and openSession's input.
//  Maps 1:1 onto the curated_sessions plan columns (card_ids / per_card_timer /
//  global_timer_seconds / deck_variant). A plain value type: the LIVE session
//  state is the server row; "same as last time" persistence is UserDefaults
//  (Codable), keyed by deckId. Never registered in SchemaV1.
//
//  Replaces the dead @Model of the same name (deleted 2026-07-01; it had zero
//  call sites and predated the server-authoritative row design).
//

import Foundation

struct SessionPlan: Codable, Sendable {
    let deckId: String
    let cardIds: [String]                     // tonight's order, subset allowed
    let perCardTimerSeconds: [String: Int]?   // nil = untimed card
    let globalTimerSeconds: Int?              // nil = no session budget
    let deckVariant: String?                  // nil = authored order
}

extension SessionPlan {

    /// The value snapshot openSession writes to the row. Draft's timer dict is
    /// non-optional; a nil plan timer means "no per-card timers" = empty dict.
    var draft: CuratedSessionDraft {
        CuratedSessionDraft(
            deckId: deckId,
            deckVariant: deckVariant,
            cardIds: cardIds,
            perCardTimer: perCardTimerSeconds ?? [:],
            globalTimerSeconds: globalTimerSeconds
        )
    }
}
