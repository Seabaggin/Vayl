//
//  SessionPlan.swift
//  Vayl
//
//  A curated session plan — the ordered set of cards (1...N) a couple plays
//  in one sitting, with optional per-card timers and global settings.
//
//  orderedCardIds DEFAULTS to a deck's authored order (deck.orderedCards),
//  but the user may reorder or trim it — recommended, never forced.
//
//  This is local persistable truth for: build-your-own, save & reuse,
//  same-as-last-time, and presets. The LIVE two-device session state lives
//  in the Supabase `curated_sessions` row (server-authoritative) — not here.
//

import Foundation
import SwiftData

// MARK: - SessionPlan

@Model
final class SessionPlan {

    var id: UUID
    var coupleId: UUID?                      // nil for built-in presets until instantiated for a couple
    var deckId: String                       // String reference to JSON content ID — not a UUID FK
    var deckVariant: String?                 // gendered variant (mf/mm/ff/flexible), resolved from connection composition
    var title: String                        // user label, e.g. "Date night short"
    var orderedCardIds: [String]             // play order; defaults to deck.orderedCards, user may reorder/trim
    var perCardTimerSeconds: [String: Int]   // cardId -> seconds; absent = no timer for that card
    var globalTimerSeconds: Int?             // optional default per-card limit
    var isPreset: Bool                       // true = built-in preset template (read-only)
    var isLDR: Bool                          // together vs apart — drives remote affordances
    var createdAt: Date
    var lastUsedAt: Date?                    // drives "same as last time"

    init(
        coupleId: UUID?,
        deckId: String,
        title: String,
        orderedCardIds: [String],
        deckVariant: String? = nil,
        perCardTimerSeconds: [String: Int] = [:],
        globalTimerSeconds: Int? = nil,
        isPreset: Bool = false,
        isLDR: Bool = false
    ) {
        self.id = UUID()
        self.coupleId = coupleId
        self.deckId = deckId
        self.deckVariant = deckVariant
        self.title = title
        self.orderedCardIds = orderedCardIds
        self.perCardTimerSeconds = perCardTimerSeconds
        self.globalTimerSeconds = globalTimerSeconds
        self.isPreset = isPreset
        self.isLDR = isLDR
        self.createdAt = Date()
        self.lastUsedAt = nil
    }
}

// MARK: - Stub (Phase A verification + Phase B real-time spike)
// A hardcoded short plan so the two-device handshake (Phase B) and the Player
// (Phase D) can be exercised before the Builder (Phase E) exists.
// TODO(Phase B/D): reconcile these card ids with the real ids in
// Resources/Decks/the-opener.json before using the stub for actual playback.
// Remove this stub once the Builder ships.
extension SessionPlan {
    static func stub(coupleId: UUID?) -> SessionPlan {
        SessionPlan(
            coupleId: coupleId,
            deckId: "the-opener",
            title: "Stub session",
            orderedCardIds: ["opener-01", "opener-02", "opener-03"]
        )
    }
}
