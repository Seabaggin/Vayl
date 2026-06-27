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
    var showFace:   [Bool]   = [false, false, false]   // false = back, true = face — drives the 3D turn in the view
    var elevations: [Double] = [0, 0, 0]
    var zIndices:   [Double] = [0, 1, 2]   // monotonic rightward fan — each card laps the one to its left; rightmost on top
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
            alphas[i]     = 0
        }
        zIndices = [0, 1, 2]
        state = .idle
    }

    // MARK: - Deal-in

    /// Flies three face-down card backs from the dealer point to the fan slots via SpriteKit,
    /// one at a time, dealt across L→C→R so each card laps the previous (rightmost on top).
    ///
    /// Deal order: slot 0 (left), slot 1 (center), slot 2 (right) — monotonic rightward fan.
    func deal(screenSize: CGSize, backImage: UIImage) async {
        state = .dealing
        if flightScene.size != screenSize { flightScene.size = screenSize }

        let fan     = AppLayout.monteFanLayout(in: screenSize.width)
        let centerY = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        let restYAbs = AppLayout.obTableCardCenterY(in: screenSize.height)

        let dealerSwiftUI = CGPoint(x: screenSize.width / 2,
                                    y: screenSize.height * AppLayout.dealPointYFrac)
        let dealerSK = CGPoint(x: dealerSwiftUI.x, y: screenSize.height - dealerSwiftUI.y)

        let order = [0, 1, 2]   // deal across L→C→R; each card laps the previous (rightmost on top)
        for slot in order {
            if Task.isCancelled {
                for i in 0..<3 { flightScene.clearCard(id: "monte-\(i)") }
                return
            }

            let destX:    CGFloat = screenSize.width / 2 + fan[slot].offset.width
            let destYAbs: CGFloat = restYAbs + fan[slot].offset.height
            let destSK            = CGPoint(x: destX, y: screenSize.height - destYAbs)

            // SpriteKit is y-up (positive zRotation = CCW); SwiftUI's
            // .rotationEffect is y-down (positive = CW). The position math
            // already flips y (screenSize.height - destYAbs), so the angle
            // must be negated too — otherwise the resting sprite tilts the
            // opposite way from the SwiftUI VaylCardBack and the card visibly
            // snaps ~2× the fan angle at the sprite→SwiftUI handoff.
            let finalAngle: CGFloat = CGFloat(-fan[slot].angle * .pi / 180)
            let zPos:       CGFloat = CGFloat(zIndices[slot])

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
                    finalAngle:   finalAngle,
                    zPosition:    zPos,
                    duration:     0.45
                )
            }

            if Task.isCancelled {
                for i in 0..<3 { flightScene.clearCard(id: "monte-\(i)") }
                return
            }

            // Landing tick — every other deal in the OB lands with one; the
            // monte was the only silent deal.
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

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

    // MARK: - Spread-turnover reveal (ribbon-spread turnover)

    /// The reveal, redesigned as a real card move: open the fan into a spread, sweep-turn
    /// each card face-up in a left→right wave (a genuine 3D edge-turn driven by `showFace`
    /// in the view — not a flat scaleX squish), then re-collect to the resting fan for the
    /// pick. Replaces the old open→sway→close flourish + in-place flip: the "open" and
    /// "re-collect" beats now bracket a turnover that actually means something.
    ///
    /// Runs only on the non-Reduce-Motion entrance (the RM path uses `reveal()` — instant).
    /// Durations/stagger are felt constants — tune on device (FEEL-GATE).
    func spreadTurnoverReveal(screenSize: CGSize) async {
        let fan     = AppLayout.monteFanLayout(in: screenSize.width)
        let centerY = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2

        // ── 1. Open into a ribbon — flatten the fan, widen and level it so each card has
        //       room to roll over. The flourish's "open" finally has a job.
        state = .shuffling
        shuffleHapticTrigger.toggle()
        withAnimation(.easeOut(duration: 0.42)) {
            for i in 0..<3 {
                angles[i]  = fan[i].angle * 0.30                                        // flatten toward a row
                offsets[i] = CGSize(width: fan[i].offset.width * 1.5, height: centerY)  // widen + level
                scales[i]  = 1.0
            }
        }
        try? await Task.sleep(for: .milliseconds(440))
        if Task.isCancelled { resetFan(screenSize: screenSize); return }

        // ── 2. Sweep-turn — a left→right wave; each card rolls face-up over its edge.
        //       Flipping showFace drives the 3D crossfade in the view; the stagger here IS
        //       the wave (each turn starts before the previous finishes). A light tick rides
        //       each turn so the sweep is felt, not just seen.
        state = .revealing
        for i in 0..<3 {
            showFace[i] = true
            shuffleHapticTrigger.toggle()
            try? await Task.sleep(for: .milliseconds(150))   // wave stagger — FEEL-GATE
            if Task.isCancelled { return }
        }
        // Let the last card finish its turn before re-collecting.
        try? await Task.sleep(for: .milliseconds(380))
        if Task.isCancelled { return }

        // ── 3. Re-collect to the resting fan for the pick (the flourish's "close").
        withAnimation(.easeInOut(duration: 0.42)) {
            for i in 0..<3 {
                angles[i]  = fan[i].angle
                offsets[i] = CGSize(width: fan[i].offset.width,
                                    height: fan[i].offset.height + centerY)
                scales[i]  = 1.0
            }
        }
        try? await Task.sleep(for: .milliseconds(440))
        state = .faceUp
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

    // MARK: - Reveal (instant — Reduce Motion + snapshot fallback)

    /// Instant face-up. Used by the Reduce-Motion path and the snapshot-fail fallback.
    /// The animated ribbon turnover lives in `spreadTurnoverReveal` (non-RM entrance).
    func reveal() async {
        for i in 0..<3 { showFace[i] = true }
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
                zIndices[i] = [0, 1, 2][i]
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
                    } else {
                        alphas[idx] = 0
                    }
                }
                // Alpha rides its own late curve so the card stays visible for
                // ~90% of the flight and dissolves INTO the deck — fading with
                // the whole travel made it vanish at launch.
                if !reduceMotion {
                    withAnimation(AppAnimation.pocketAlphaFade) { alphas[idx] = 0 }
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
            try? await Task.sleep(for: .milliseconds(250))
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
            // Ribbon-spread turnover on the SwiftUI cards: spread → sweep-turn → re-collect.
            await spreadTurnoverReveal(screenSize: screenSize)
        }
    }

    // MARK: - Cancel

    func cancel() {
        pocketTask?.cancel()
        sequenceTask?.cancel()
    }
}
