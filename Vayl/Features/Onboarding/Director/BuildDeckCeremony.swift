//
//  BuildDeckCeremony.swift
//  Vayl
//
//  Owns the Living Case tap ceremony state for BuildDeckPhase (Beat 5).
//
//  The case is not a passive container — it is actively holding the deck in.
//  The three taps are a negotiation: the case RECOGNIZES the strike (tap 1,
//  a card tears through and the lattice reseals), RESISTS harder (tap 2, two
//  cards, slower reseal), then RELEASES (tap 3, the seams stay open, the held
//  breath, the flower peel). No authored strike positions — the sequence is
//  fixed; where the finger lands does not matter.
//

import SwiftUI

@Observable
@MainActor
final class BuildDeckCeremony {

    /// Strikes landed this ceremony (0…3). Escalates the eruption, the seam
    /// stress, and the wake rings; the third arms the held breath + peel.
    private(set) var tapCount: Int = 0

    /// When the current eruption began — MetallicCaseView derives the card's
    /// rise / hold / reseal from this moment on its own frame clock.
    private(set) var eruptStart: Date = .distantFuture

    /// True between the third strike landing and the peel firing: everything
    /// freezes, the case brightens, nothing moves. The phase releases it.
    private(set) var holdBreath: Bool = false

    /// Seam-stress target per strike — how far the lattice bows outward from
    /// centre. Taps 1–2 reseal back to rest on the module's timeline; tap 3
    /// holds at 1.0 (the case cannot close anymore).
    var stressLevel: Double { Self.stressLevels[min(tapCount, 3)] }
    private static let stressLevels: [Double] = [0, 0.40, 0.72, 1.0]

    func runEntry() {
        tapCount = 0
        eruptStart = .distantFuture
        holdBreath = false
    }

    /// Land a strike. Returns the tap index that just landed (0, 1, 2) so the
    /// phase can run the matching shake + choreography, or nil if the ceremony
    /// is complete / breath-held and the tap is ignored.
    func registerTap() -> Int? {
        guard tapCount < 3, !holdBreath else { return nil }
        tapCount += 1
        eruptStart = .now
        if tapCount >= 3 { holdBreath = true }
        return tapCount - 1
    }

    /// The held breath ends — the phase calls this right before firing the peel.
    func releaseBreath() {
        holdBreath = false
    }
}
