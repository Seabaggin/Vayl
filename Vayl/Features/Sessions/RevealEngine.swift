//
//  RevealEngine.swift
//  Vayl
//
//  PLAN16-SECTION3 replaces this stub with the real five-mechanic reveal state
//  machine (whisper, whatIf, unspoken, mirror, snapshot). Section 2 only
//  forwards row/broadcast deltas into these hooks; nothing else about reveals
//  lives in Section 2.
//

import Foundation

@MainActor
final class RevealEngine {

    /// PLAN16-SECTION3 replaces this stub — seal/reveal flags from the row.
    func applyRow(_ revealState: [String: RevealCardState]) {}

    /// PLAN16-SECTION3 replaces this stub — partner payloads (broadcast).
    func applyBroadcast(_ envelope: RevealEnvelope) {}

    /// PLAN16-SECTION3 replaces this stub — card changed.
    func reset(forCardId: String) {}
}
