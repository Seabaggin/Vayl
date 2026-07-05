// PartnerChipDesireMapCopy.swift
// Vayl
//
// Terse copy for the partner chip's Desire Map quick-view tile. Deliberately
// short (one line, fits a ~90pt tile) — full detail lives in the Map tab.

import Foundation

/// Maps `DesireMapState` to the one-line copy shown on the partner chip's
/// Desire Map tile.
///
/// `partnerName` is taken as a separate parameter rather than trusting the
/// name embedded in `.youDone(partnerName:)` (or any other case). The
/// embedded value is captured once, at the moment `HomeStore` resolves
/// `desireMapState`; the caller's live `partnerName` (sourced from
/// `CoupleContext` via `HomeStore.partnerName`) can change afterward — e.g.
/// when the partner's name arrives asynchronously after pairing. Reading the
/// parameter instead of the case's own payload keeps the tile from ever
/// showing a stale name. Accordingly the switch below matches cases without
/// binding their associated values.
enum PartnerChipDesireMapCopy {
    static func tileText(for state: DesireMapState, partnerName: String) -> String {
        switch state {
        case .hidden:
            return "Not linked yet"
        case .gated:
            return "You haven't started"
        case .yourTurn:
            return "Your turn"
        case .youDone:
            return "Waiting on \(partnerName)"
        case .waiting:
            return "Waiting"
        case .bothReady:
            return "Both complete"
        case .freeRevealSeen:
            return "Reveal viewed"
        case .matchReady:
            return "Ready to view"
        case .redoInProgress:
            return "Redo in progress"
        case .revealed:
            return "Revealed"
        case .fullyUnlocked:
            return "Fully unlocked"
        }
    }
}
