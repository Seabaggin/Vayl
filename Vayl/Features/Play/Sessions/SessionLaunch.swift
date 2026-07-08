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
