//
//  SessionLaunch.swift
//  Vayl
//
//  Everything the session cover needs to boot: the hand, who I am, and (for
//  two-device sessions) the open row. `session == nil` = pure-local DEBUG path.
//  Built by PlayStore (initiator), SessionEntryStore (joiner), and Home's
//  DEBUG couch mode; consumed by CardSessionContainerView.
//

import Foundation

struct SessionLaunch: Identifiable, Equatable {
    enum Entry: Equatable { case initiator, joiner, localDebug }
    let id = UUID()
    let hand: [Card]
    let entry: Entry
    let role: SessionRole
    let session: CuratedSessionDTO?
    static func == (l: SessionLaunch, r: SessionLaunch) -> Bool { l.id == r.id }
}

extension SessionLaunch {
    /// Strict hand build (spec 2026-07-09 §1.8): every id in `cardIds` must
    /// resolve to a real card in the locally loaded deck, or the whole launch
    /// fails. An app-version mismatch between the two phones (a card id
    /// missing from one side's bundled deck) must never silently SHORTEN the
    /// hand — that would desync "card N" between the two devices, which is
    /// worse than refusing to launch. Shared by SessionEntryStore.accept(),
    /// .resume(), and PlayStore.openSession()/.resumeConflict() so the rule
    /// lives in exactly one place.
    static func buildHand(cardIds: [String], deck: Deck) -> [Card]? {
        guard !cardIds.isEmpty else { return nil }
        var hand: [Card] = []
        hand.reserveCapacity(cardIds.count)
        for id in cardIds {
            guard let card = deck.orderedCards.first(where: { $0.id == id }) else { return nil }
            hand.append(card)
        }
        return hand
    }
}
