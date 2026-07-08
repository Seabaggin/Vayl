// PartnerChipPulseCopy.swift
// Vayl
//
// Terse copy for the partner chip's Pulse quick-view tile. Deliberately
// short (one line, fits a ~90pt tile) — full detail (30-day grid, Us
// comparison) lives in the Map tab.

import Foundation

/// Maps a partner's current `PulsePosition` to the one-line copy shown on
/// the partner chip's Pulse tile.
enum PartnerChipPulseCopy {
    static func tileText(for position: PulsePosition?) -> String {
        guard let position else { return "Not sharing" }
        return position.quadrant.spaceName
    }
}
