//
//  RevealEnvelope.swift
//  Vayl
//
//  The Broadcast payload for reveal mechanics (whisper, unspoken, mirror,
//  snapshot, whatIf). EPHEMERAL BY DESIGN: sent only after the local seal,
//  buffered in the store until the reveal fires, NEVER persisted anywhere.
//  Durable truth is only the seal/reveal FLAGS in curated_sessions.reveal_state.
//
//  Codable synthesis on the Body enum produces case-keyed nesting
//  ({"text": {"_0": "..."}}) — both devices use the same coder, so the wire
//  shape is symmetric and private to the app.
//

import Foundation

struct RevealEnvelope: Codable, Sendable {
    let cardId: String
    let role: SessionRole          // sender
    let body: Body

    enum Body: Codable, Sendable {
        case text(String)          // whisper, whatIf, mirror answers
        case position(Double)      // unspoken slider 0.0-1.0
        case word(String)          // snapshot single word
    }
}
