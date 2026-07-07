//
//  FeaturedDeckRule.swift
//  Vayl
//
//  ONE derivation for "the couple's deck right now", shared by the two surfaces
//  that show it (PlayStore.resolveFeatured, HomeStore.resolveRecentDeck). The
//  2026-07-07 review found the two stores using divergent rules (different
//  recency fields, different completed/lock filters), which guaranteed Home and
//  Play heroing different decks from day one. Pure function — no I/O, no state.
//

import Foundation

enum FeaturedDeckRule {

    /// The engaged deck, in priority order:
    /// 1. most-recently-played in-progress deck the couple can play,
    /// 2. the user's forged opener deck until it's completed (the OB promise),
    /// 3. most-recently-played completed deck ("Play again"),
    /// 4. nil — the caller decides its own empty fallback (never a locked deck).
    static func engagedDeckId(
        progress: [DeckProgress],
        availableIDs: Set<String>,
        openerID: String?
    ) -> String? {
        let available = progress.filter { availableIDs.contains($0.deckId) }
        let byRecency: (DeckProgress, DeckProgress) -> Bool = {
            ($0.lastPlayedAt ?? $0.firstOpenedAt ?? .distantPast)
                < ($1.lastPlayedAt ?? $1.firstOpenedAt ?? .distantPast)
        }
        if let inProgress = available
            .filter({ $0.completedAt == nil && $0.currentCardIndex > 0 })
            .max(by: byRecency) {
            return inProgress.deckId
        }
        if let openerID, availableIDs.contains(openerID),
           !progress.contains(where: { $0.deckId == openerID && $0.completedAt != nil }) {
            return openerID
        }
        if let completed = available
            .filter({ $0.completedAt != nil })
            .max(by: byRecency) {
            return completed.deckId
        }
        return nil
    }
}
