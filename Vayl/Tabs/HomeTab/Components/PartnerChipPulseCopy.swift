// PartnerChipPulseCopy.swift
// Vayl
//
// Terse copy for the partner chip's Pulse quick-view tile. Deliberately
// short (one line, fits a ~90pt tile) — full detail (30-day grid, Us
// comparison) lives in the Map tab.

import Foundation

/// Maps a partner's current `PulsePosition` to the one-line copy shown on
/// the partner chip's Pulse tile. A nil position with `fetchFailed` false is
/// confirmed-empty (sharing off or never logged; the server can't tell those
/// apart, so the copy claims neither). `fetchFailed` true means the last
/// fetch didn't complete, which is a different, honest message.
enum PartnerChipPulseCopy {
    static func tileText(for position: PulsePosition?, fetchFailed: Bool = false) -> String {
        guard let position else {
            return fetchFailed ? "Couldn't check" : "No Pulse to show"
        }
        return position.quadrant.spaceName
    }
}
