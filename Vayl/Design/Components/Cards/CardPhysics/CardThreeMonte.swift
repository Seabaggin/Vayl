// NOTE: Despite the class name, CardThreeMonteController now drives a FANNED HAND,
// not a three-card-monte row. The name is preserved to avoid Xcode project / test churn.

import SwiftUI
import SpriteKit

enum ThreeMonteState: Equatable {
    case idle, dealing, revealing, faceUp
    case lifted(CandleIntensity), confirming(CandleIntensity), done(CandleIntensity)
}

@Observable
@MainActor
final class CardThreeMonteController {
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
                    finalAngle:   CGFloat(fan[slot].angle * .pi / 180),
                    zPosition:    CGFloat(zIndices[slot]),
                    duration:     0.45
                )
            }

            if Task.isCancelled {
                for i in 0..<3 { flightScene.clearCard(id: "monte-\(i)") }
                return
            }

            offsets[slot] = CGSize(width: fan[slot].offset.width, height: fan[slot].offset.height + centerY)
            angles[slot]  = fan[slot].angle
            alphas[slot]  = 1
            flightScene.clearCard(id: "monte-\(slot)")
            withAnimation(AppAnimation.cardCenter) {
                scales[slot] = 1.0
            }
            try? await Task.sleep(for: .milliseconds(180))   // stagger between deals
        }
    }

    // MARK: - Reveal

    /// Flip each card face-up in succession (L→R), assigning the face at the half-flip.
    /// Each half uses `cardFlipHalf` (0.29s), so the two halves compose the full 0.58s flip.
    func reveal() async {
        state = .revealing
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
                alphas[i]   = 0.3
                zIndices[i] = [0, 2, 1][i]
            }
        }
    }

    // MARK: - Confirm

    /// Pocket the chosen card to the corner deck and call `onConfirm` to write data + advance.
    func confirm(_ intensity: CandleIntensity, screenSize: CGSize,
                 onConfirm: @escaping (CandleIntensity) -> Void) {
        guard case .lifted(let held) = state, held == intensity else { return }
        state = .confirming(intensity)
        confirmHapticTrigger.toggle()
        pocketTask = Task { @MainActor in
            let cornerX = screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2
            let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
            let cardWidth = AppLayout.obFanCardWidth(in: screenSize.width)
            if let idx = intensities.firstIndex(of: intensity) {
                withAnimation(AppAnimation.cardPocket) {
                    offsets[idx] = CGSize(width: cornerX - screenSize.width  / 2,
                                          height: cornerY - screenSize.height / 2)
                    scales[idx]  = AppLayout.cornerDeckWidth / cardWidth
                    alphas[idx]  = 0
                }
            }
            try? await Task.sleep(for: .milliseconds(520))
            guard !Task.isCancelled else { return }
            state = .done(intensity)
            onConfirm(intensity)
        }
    }

    // MARK: - Entrance Sequence

    /// Runs the full entrance: deal → showSwiftUIBacks → reveal.
    /// The task is stored so `cancel()` can interrupt it at any await point.
    func runEntrance(screenSize: CGSize, backImage: UIImage) {
        sequenceTask?.cancel()
        sequenceTask = Task { @MainActor in
            await deal(screenSize: screenSize, backImage: backImage)
            guard !Task.isCancelled else { return }
            showSwiftUIBacks()
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
