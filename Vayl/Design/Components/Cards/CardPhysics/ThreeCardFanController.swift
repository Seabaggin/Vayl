import SwiftUI
import SpriteKit
import UIKit

enum ThreeMonteState: Equatable {
    case idle, dealing, shuffling, revealing, faceUp
    case lifted(CandleIntensity), confirming(CandleIntensity), done(CandleIntensity)
}

@Observable
@MainActor
final class ThreeCardFanController {
    var state: ThreeMonteState = .idle

    var offsets:    [CGSize] = [.zero, .zero, .zero]
    var angles:     [Double] = [0, 0, 0]
    var scales:     [Double] = [1, 1, 1]
    var alphas:     [Double] = [1, 1, 1]
    var flipScaleX: [Double] = [1, 1, 1]
    var showFace:   [Bool]   = [false, false, false]
    var elevations: [Double] = [0, 0, 0]
    var zIndices:   [Double] = [0, 2, 1]   // fan order: left under, right mid, center top
    var confirmHapticTrigger = false
    var shuffleHapticTrigger = false

    /// Group-sweep angle (degrees) for the fan flourish. The View applies this as a single
    /// rotationEffect on the ZStack holding all three cards, so the whole hand pivots
    /// rigidly about the fan center — relative card positions & z stay constant (clip-free).
    var sweep: Double = 0

    /// SpriteKit scene that handles card-back flight animation during deal-in.
    let flightScene = CardFlightScene()

    /// Slot index → intensity (ordered L→R).
    let intensities = CandleIntensity.ordered

    private var pocketTask:   Task<Void, Never>?
    private var sequenceTask: Task<Void, Never>?

    // MARK: - Place Fan Face Down

    /// Place the three cards in their fan slots, FACE DOWN and invisible (alpha 0).
    /// Sprites carry the visual during the deal; SwiftUI backs are revealed at hand-off.
    func placeFanFaceDown(screenSize: CGSize) {
        let fan     = AppLayout.monteFanLayout(in: screenSize.width)
        let centerY = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        for i in 0..<3 {
            offsets[i]    = CGSize(width: fan[i].offset.width,
                                   height: fan[i].offset.height + centerY)
            angles[i]     = fan[i].angle
            showFace[i]   = false
            flipScaleX[i] = 1.0
            alphas[i]     = 0
        }
        zIndices = [0, 2, 1]
        state = .idle
    }

    // MARK: - Deal-in

    /// Flies three face-down card backs from the dealer point to the fan slots via SpriteKit,
    /// one at a time (left → right → center), each with a spring settle at landing.
    ///
    /// Deal order: slot 0 (left), slot 2 (right), slot 1 (center — on top).
    func deal(screenSize: CGSize, backImage: UIImage) async {
        state = .dealing
        if flightScene.size != screenSize { flightScene.size = screenSize }

        let fan     = AppLayout.monteFanLayout(in: screenSize.width)
        let centerY = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        let restYAbs = AppLayout.obTableCardCenterY(in: screenSize.height)

        let dealerSwiftUI = CGPoint(x: screenSize.width / 2,
                                    y: screenSize.height * AppLayout.dealPointYFrac)
        let dealerSK = CGPoint(x: dealerSwiftUI.x, y: screenSize.height - dealerSwiftUI.y)

        let order = [0, 2, 1]   // left, right, center-last (center on top)
        for slot in order {
            if Task.isCancelled {
                for i in 0..<3 { flightScene.clearCard(id: "monte-\(i)") }
                return
            }

            let destX   = screenSize.width / 2 + fan[slot].offset.width
            let destYAbs = restYAbs + fan[slot].offset.height
            let destSK  = CGPoint(x: destX, y: screenSize.height - destYAbs)

            await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                var fired = false
                flightScene.onCardRested["monte-\(slot)"] = { _, _, _ in
                    guard !fired else { return }; fired = true; cont.resume()
                }
                flightScene.dealCard(
                    id:           "monte-\(slot)",
                    image:        backImage,
                    from:         dealerSK,
                    to:           destSK,
                    initialAngle: -0.24,
                    // SpriteKit is y-up (positive zRotation = CCW); SwiftUI's
                    // .rotationEffect is y-down (positive = CW). The position math
                    // already flips y (screenSize.height - destYAbs), so the angle
                    // must be negated too — otherwise the resting sprite tilts the
                    // opposite way from the SwiftUI VaylCardBack and the card visibly
                    // snaps ~2× the fan angle at the sprite→SwiftUI handoff.
                    finalAngle:   CGFloat(-fan[slot].angle * .pi / 180),
                    zPosition:    CGFloat(zIndices[slot]),
                    duration:     0.45
                )
            }

            if Task.isCancelled {
                for i in 0..<3 { flightScene.clearCard(id: "monte-\(i)") }
                return
            }

            // Leave the card as a resting sprite on the flight layer. The SwiftUI
            // back is NOT revealed until every card has landed (see runEntrance) —
            // otherwise a later-dealt card flies beneath an already-handed-off
            // SwiftUI card and pops on top at handoff. Sprites carry correct
            // zPosition among themselves, so the center card lands on top.
            offsets[slot] = CGSize(width: fan[slot].offset.width, height: fan[slot].offset.height + centerY)
            angles[slot]  = fan[slot].angle
            try? await Task.sleep(for: .milliseconds(180))   // stagger between deals
        }
    }

    // MARK: - Flourish (SwiftUI rigid-group fan sweep)

    /// Dealer-style flourish on the SwiftUI cards (run AFTER the sprite→SwiftUI handoff,
    /// so the cards are face-down `VaylCardBack` views the whole time). Pure animation over
    /// the published `angles` / `offsets` / `scales` / `sweep` — no SpriteKit.
    ///
    /// Clip-free by construction:
    ///   1. **Open** — the fan widens so the cards SEPARATE (overlap only decreases).
    ///   2. **Sweep sway** — a rigid group rotation about the fan center (`sweep`); every
    ///      card shares the same transform, so relative position & z never change → no card
    ///      ever crosses another.
    ///   3. **Close** — restore the canonical fan, so `reveal()`/`lift()` and the
    ///      slot→intensity mapping are unaffected.
    ///
    /// Durations/magnitudes are felt constants — tune on device. Cadence lives in
    /// `Task.sleep`, matching the codebase's hint-loop pattern.
    func flourish(screenSize: CGSize) async {
        state = .shuffling

        let fan     = AppLayout.monteFanLayout(in: screenSize.width)
        let centerY = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2

        // ── 1. Open — widen angles & push the outer cards apart (overlap shrinks). ──
        shuffleHapticTrigger.toggle()
        withAnimation(.easeOut(duration: 0.35)) {
            for i in 0..<3 {
                angles[i]  = fan[i].angle * 1.9
                offsets[i] = CGSize(width: fan[i].offset.width * 1.5,
                                    height: fan[i].offset.height + centerY)
                scales[i]  = 1.04
            }
        }
        try? await Task.sleep(for: .milliseconds(380))
        if Task.isCancelled { resetFan(screenSize: screenSize); return }

        // ── 2. Sweep sway — rigid group rotation; no relative motion, cannot clip. ──
        shuffleHapticTrigger.toggle()
        withAnimation(.easeInOut(duration: 0.28)) { sweep = -10 }
        try? await Task.sleep(for: .milliseconds(300))
        if Task.isCancelled { resetFan(screenSize: screenSize); return }

        shuffleHapticTrigger.toggle()
        withAnimation(.easeInOut(duration: 0.36)) { sweep = 10 }
        try? await Task.sleep(for: .milliseconds(380))
        if Task.isCancelled { resetFan(screenSize: screenSize); return }

        withAnimation(.easeInOut(duration: 0.28)) { sweep = 0 }
        try? await Task.sleep(for: .milliseconds(280))
        if Task.isCancelled { resetFan(screenSize: screenSize); return }

        // ── 3. Close — back to the canonical fan. ──────────────────────────────────
        withAnimation(.easeOut(duration: 0.35)) {
            for i in 0..<3 {
                angles[i]  = fan[i].angle
                offsets[i] = CGSize(width: fan[i].offset.width,
                                    height: fan[i].offset.height + centerY)
                scales[i]  = 1.0
            }
        }
        try? await Task.sleep(for: .milliseconds(350))   // settle quietly before the reveal
    }

    /// Snap the cards back to the canonical fan — used if the flourish is cancelled mid-way.
    private func resetFan(screenSize: CGSize) {
        let fan     = AppLayout.monteFanLayout(in: screenSize.width)
        let centerY = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        sweep = 0
        for i in 0..<3 {
            angles[i]  = fan[i].angle
            offsets[i] = CGSize(width: fan[i].offset.width, height: fan[i].offset.height + centerY)
            scales[i]  = 1.0
        }
    }

    // MARK: - Reveal

    /// Flip each card face-up in succession (L→R), assigning the face at the half-flip.
    /// Each half uses `cardFlipHalf` (0.29s), so the two halves compose the full 0.58s flip.
    func reveal() async {
        state = .revealing
        // Reduce Motion: skip the flip rotation entirely — the face swaps in place
        // (per the cardFlip token's documented fallback), no scaleX animation, no sleeps.
        if UIAccessibility.isReduceMotionEnabled {
            for i in 0..<3 { showFace[i] = true }
            state = .faceUp
            return
        }
        for i in 0..<3 {
            withAnimation(AppAnimation.cardFlipHalf) { flipScaleX[i] = 0.0 }
            try? await Task.sleep(for: .milliseconds(290))  // wait for first half to complete
            showFace[i] = true              // identity becomes visible at the half-flip
            withAnimation(AppAnimation.cardFlipHalf) { flipScaleX[i] = 1.0 }
            try? await Task.sleep(for: .milliseconds(290))  // wait for second half to complete
        }
        state = .faceUp
    }

    /// Makes the SwiftUI card backs visible — call this immediately before `reveal()`
    /// to hand off from SpriteKit sprites to SwiftUI views at the same fan positions.
    func showSwiftUIBacks() {
        for i in 0..<3 { alphas[i] = 1 }
    }

    // MARK: - Lift

    /// Lift the tapped card to a cinematic position; receded cards return to their fan slot.
    func lift(_ intensity: CandleIntensity, screenSize: CGSize) {
        switch state { case .faceUp, .lifted: break; default: return }
        state = .lifted(intensity)
        let fan     = AppLayout.monteFanLayout(in: screenSize.width)
        let centerY = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        let liftY   = screenSize.height * 0.42 - screenSize.height / 2
        for i in 0..<3 {
            if intensities[i] == intensity {
                offsets[i]  = CGSize(width: 0, height: liftY)
                scales[i]   = 1.12
                angles[i]   = 0
                alphas[i]   = 1
                zIndices[i] = 99
            } else {
                offsets[i]  = CGSize(width: fan[i].offset.width, height: fan[i].offset.height + centerY)
                angles[i]   = fan[i].angle
                scales[i]   = 0.9
                alphas[i]   = 0.6   // bright enough to read as "still tappable" — easy switching
                zIndices[i] = [0, 2, 1][i]
            }
        }
    }

    // MARK: - Confirm

    /// Pocket the chosen card to the corner deck, then clear the two non-selected cards and
    /// settle before handing control back. Exit sequence (winner-first, discards fade in place):
    ///   1. Winner flies to the corner deck (`cardPocket`, 520ms).
    ///   2. `onConfirm` fires *at the landing* — the View wires this to the director's
    ///      "receive" (write data + append deck card + deck pulse), so the deck reacts the
    ///      instant the card arrives (no flicker from a delayed receive).
    ///   3. The two discards fade in place (α → 0) — no slide, no jump.
    ///   4. A short settle beat over the cleared felt.
    ///   5. `state = .done` — the View observes this to advance to the next phase, so the
    ///      crossfade happens over an already-empty table.
    /// Durations/timings are local feel constants — tune on device.
    func confirm(_ intensity: CandleIntensity, screenSize: CGSize,
                 onConfirm: @escaping (CandleIntensity) -> Void) {
        guard case .lifted(let held) = state, held == intensity else { return }
        state = .confirming(intensity)
        confirmHapticTrigger.toggle()
        pocketTask = Task { @MainActor in
            let cornerX = screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2
            let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
            let cardWidth = AppLayout.obFanCardWidth(in: screenSize.width)
            let chosenIdx = intensities.firstIndex(of: intensity)
            let reduceMotion = UIAccessibility.isReduceMotionEnabled

            // 1. Winner pockets to the corner deck.
            //    Reduce Motion: the card disappears in place (alpha only) — no fly-to-corner
            //    (per the cardPocket token's documented fallback).
            if let idx = chosenIdx {
                withAnimation(AppAnimation.cardPocket.reduceMotionSafe) {
                    if !reduceMotion {
                        offsets[idx] = CGSize(width: cornerX - screenSize.width  / 2,
                                              height: cornerY - screenSize.height / 2)
                        scales[idx]  = AppLayout.cornerDeckWidth / cardWidth
                    }
                    alphas[idx]  = 0
                }
            }
            try? await Task.sleep(for: .milliseconds(520))
            guard !Task.isCancelled else { return }

            // 2. Receive into the deck at the moment the winner lands.
            onConfirm(intensity)

            // 3. Clear the two non-selected cards — fade in place (no offset/scale change).
            withAnimation(AppAnimation.exit.reduceMotionSafe) {
                for i in 0..<3 where i != chosenIdx { alphas[i] = 0 }
            }
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }

            // 4. Settle beat over the cleared felt.
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }

            // 5. Terminal — the View advances the phase off this.
            state = .done(intensity)
        }
    }

    // MARK: - Entrance Sequence

    /// Runs the full entrance: deal → handoff → flourish → reveal.
    /// The task is stored so `cancel()` can interrupt it at any await point.
    func runEntrance(screenSize: CGSize, backImage: UIImage) {
        sequenceTask?.cancel()
        sequenceTask = Task { @MainActor in
            await deal(screenSize: screenSize, backImage: backImage)
            guard !Task.isCancelled else { return }
            // Hand off from the SpriteKit sprites to the SwiftUI backs at the same fan
            // positions: reveal the backs, hold one frame so they paint, then clear the
            // sprites. The flourish runs entirely on the SwiftUI cards after this.
            showSwiftUIBacks()
            try? await Task.sleep(for: .milliseconds(32))
            guard !Task.isCancelled else { return }
            for i in 0..<3 { flightScene.clearCard(id: "monte-\(i)") }
            // Rigid-group SwiftUI flourish (clip-free), then the flip-reveal.
            await flourish(screenSize: screenSize)
            guard !Task.isCancelled else { return }
            await reveal()
        }
    }

    // MARK: - Cancel

    func cancel() {
        pocketTask?.cancel()
        sequenceTask?.cancel()
    }
}
