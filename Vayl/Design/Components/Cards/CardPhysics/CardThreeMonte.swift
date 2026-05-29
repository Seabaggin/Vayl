import SwiftUI
import SpriteKit

enum ThreeMonteState: Equatable {
    case idle, dealing, organizing, shuffling, revealing, faceUp
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
    var zIndices:   [Double] = [0, 1, 2]
    var confirmHapticTrigger = false

    /// SpriteKit scene that handles card-back flight animation during deal-in.
    let flightScene = CardFlightScene()

    /// Slot index → intensity (ordered L→R).
    let intensities = CandleIntensity.ordered

    private var pocketTask:   Task<Void, Never>?
    private var sequenceTask: Task<Void, Never>?

    // MARK: - Deal-in

    /// Flies three face-down card backs from the dealer point to the row via SpriteKit.
    ///
    /// Alphas start at 0 (SwiftUI cards hidden) and stay 0 until `deal()` completes.
    /// Call `placeRowFaceDown(screenSize:)` before `deal()` so the SwiftUI row offsets
    /// are pre-set for the hand-off. After `deal()` returns, set alphas to 1 and call
    /// `reveal()` — the SwiftUI backs are positioned exactly where the sprites landed.
    ///
    /// - Parameters:
    ///   - screenSize: Full screen CGSize (SwiftUI coords, origin top-left).
    ///   - backImage:  Rendered UIImage of `VaylCardBack` at `obTableCardWidth × height`.
    func deal(screenSize: CGSize, backImage: UIImage) async {
        state = .dealing

        // Ensure scene is sized for this screen.
        if flightScene.size == .zero || flightScene.size != screenSize {
            flightScene.size = screenSize
        }

        let centers  = AppLayout.monteRowCenters(in: screenSize.width)
        let restYAbs = AppLayout.obTableCardCenterY(in: screenSize.height)

        // Dealer origin in SwiftUI coords (top-left origin).
        // dealPointYFrac (.32) is the exact horizon where the deal point lives,
        // matching every other OB deal that launches from center-top of the felt.
        let dealerSwiftUI = CGPoint(
            x: screenSize.width / 2,
            y: screenSize.height * AppLayout.dealPointYFrac
        )

        // SpriteKit uses bottom-left origin — flip Y.
        let dealerSK = CGPoint(
            x: dealerSwiftUI.x,
            y: screenSize.height - dealerSwiftUI.y
        )

        // Per-card rest points in SpriteKit coords.
        let destsSK: [CGPoint] = centers.map { cx in
            CGPoint(x: cx, y: screenSize.height - restYAbs)
        }

        // Counter for how many cards have rested — tracked as an instance property
        // to stay @MainActor-isolated without capture issues.
        restedCount = 0

        // `resumed` ensures the continuation fires exactly once even if Task is
        // cancelled mid-flight and clearAllCards() removes the onCardRested handlers
        // before all three cards have rested (which would otherwise strand the continuation).
        var resumed = false
        func resumeOnce(_ cont: CheckedContinuation<Void, Never>) {
            guard !resumed else { return }
            resumed = true
            cont.resume()
        }

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            // Safety: if the task is already cancelled before we even start,
            // resume immediately so we don't strand the continuation.
            guard !Task.isCancelled else { resumeOnce(cont); return }

            for i in 0..<3 {
                let id = "monte-\(i)"
                // Guard against duplicate fires (onCardRested removes itself, but be safe).
                var fired = false
                flightScene.onCardRested[id] = { [weak self] _, _, _ in
                    guard let self else { return }
                    guard !fired else { return }
                    fired = true
                    self.restedCount += 1
                    if self.restedCount == 3 { resumeOnce(cont) }
                }
                flightScene.dealCard(
                    id:           id,
                    image:        backImage,
                    from:         dealerSK,
                    to:           destsSK[i],
                    initialAngle: -0.24,
                    finalAngle:   0.0,
                    zPosition:    CGFloat(i),   // deal-order stacking: card 0 lowest
                    duration:     0.55
                )
            }
        }

        // If cancelled during flight, clear sprites and bail before hand-off logic.
        if Task.isCancelled {
            for i in 0..<3 { flightScene.clearCard(id: "monte-\(i)") }
            return
        }

        // Clear sprites — SwiftUI backs take over at the same positions.
        for i in 0..<3 { flightScene.clearCard(id: "monte-\(i)") }
        state = .organizing
    }

    /// Internal rested-card counter. Kept on the controller (not captured in closures)
    /// so it is always @MainActor-isolated.
    private var restedCount: Int = 0

    // MARK: - Organize

    /// Animate all three from their post-deal landing positions to the exact clean row.
    /// Cards remain face-down. ~0.42 s with AppAnimation.standard.
    func organize(screenSize: CGSize) async {
        let centers = AppLayout.monteRowCenters(in: screenSize.width)
        let restY   = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        withAnimation(AppAnimation.standard) {
            for i in 0..<3 {
                offsets[i]    = CGSize(width: centers[i] - screenSize.width / 2, height: restY)
                angles[i]     = 0
                scales[i]     = 1
                elevations[i] = 0
            }
        }
        try? await Task.sleep(for: .milliseconds(420))
    }

    // MARK: - Shuffle

    /// Lift-and-toss theatre: several position swaps between the three row slots (~3–4 s).
    /// Each swap ramps elevation 0→1 (drives shadow + scale bump), cards arc to each
    /// other's slot, then drop. zIndices are NOT changed — deal-order over/under is permanent.
    func shuffle(screenSize: CGSize) async {
        state = .shuffling
        let centers = AppLayout.monteRowCenters(in: screenSize.width)
        let restY   = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        let liftY   = restY - 18   // tune on-device: arc height above rest row

        // slotOf[cardIndex] = which row slot (0,1,2) that card currently occupies.
        var slotOf = [0, 1, 2]
        let swaps: [(Int, Int)] = [(0, 1), (1, 2), (0, 2), (1, 2), (0, 1)]   // tune count on-device

        for (a, b) in swaps {
            guard let ia = slotOf.firstIndex(of: a),
                  let ib = slotOf.firstIndex(of: b) else { continue }

            // Lift phase: raise elevation + scale, arc upward to mid-travel height.
            withAnimation(.easeInOut(duration: 0.34)) {
                elevations[ia] = 1; elevations[ib] = 1
                scales[ia] = 1.06; scales[ib] = 1.06
                // Arc: lift Y before crossing so travel reads as a toss, not a flat slide.
                offsets[ia] = CGSize(width: centers[b] - screenSize.width / 2, height: liftY)
                offsets[ib] = CGSize(width: centers[a] - screenSize.width / 2, height: liftY)
            }
            try? await Task.sleep(for: .milliseconds(340))

            // Drop phase: settle to rest row, restore scale/elevation.
            withAnimation(.easeOut(duration: 0.14)) {
                elevations[ia] = 0; elevations[ib] = 0
                scales[ia] = 1; scales[ib] = 1
                offsets[ia] = CGSize(width: centers[b] - screenSize.width / 2, height: restY)
                offsets[ib] = CGSize(width: centers[a] - screenSize.width / 2, height: restY)
            }
            slotOf.swapAt(ia, ib)
            try? await Task.sleep(for: .milliseconds(120))
        }

        // Restore cards to canonical slot order before reveal (identity assigned at reveal).
        withAnimation(AppAnimation.standard) {
            for i in 0..<3 {
                offsets[i] = CGSize(width: centers[i] - screenSize.width / 2, height: restY)
            }
        }
        try? await Task.sleep(for: .milliseconds(300))
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

    /// Place the three cards in the clean row, FACE DOWN (no reveal yet).
    ///
    /// Sets offsets to the exact row positions so the SwiftUI backs match where
    /// `deal()` sprites will land. Alphas are set to 0 — cards are invisible until
    /// `showSwiftUIBacks()` is called after deal completes. This prevents double-card
    /// flicker during the SpriteKit→SwiftUI hand-off.
    func placeRowFaceDown(screenSize: CGSize) {
        let centers = AppLayout.monteRowCenters(in: screenSize.width)
        let restY   = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        for i in 0..<3 {
            offsets[i]    = CGSize(width: centers[i] - screenSize.width / 2, height: restY)
            showFace[i]   = false
            flipScaleX[i] = 1.0
            alphas[i]     = 0   // hidden until deal completes; sprites carry the visual
        }
        state = .idle
    }

    /// Makes the SwiftUI card backs visible — call this immediately before `reveal()`
    /// to hand off from SpriteKit sprites to SwiftUI views at the same row positions.
    func showSwiftUIBacks() {
        for i in 0..<3 { alphas[i] = 1 }
    }

    /// Lay the three cards directly in the clean row, face-up. (Pre-deal placeholder;
    /// later tasks replace this with deal→organize→shuffle→reveal.)
    func placeStaticRow(screenSize: CGSize) {
        let centers = AppLayout.monteRowCenters(in: screenSize.width)
        let restY   = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        for i in 0..<3 {
            offsets[i] = CGSize(width: centers[i] - screenSize.width / 2, height: restY)
            showFace[i] = true
        }
        state = .faceUp
    }

    /// Lift the tapped card to a cinematic position; dim the other two.
    func lift(_ intensity: CandleIntensity, screenSize: CGSize) {
        switch state {
        case .faceUp, .lifted: break
        default: return
        }
        state = .lifted(intensity)
        let liftY   = screenSize.height * 0.42 - screenSize.height / 2
        let centers = AppLayout.monteRowCenters(in: screenSize.width)
        let restY   = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        for i in 0..<3 {
            if intensities[i] == intensity {
                offsets[i]   = CGSize(width: 0, height: liftY)
                scales[i]    = AppLayout.obTableCardCinematicScale
                angles[i]    = 0
                alphas[i]    = 1
                zIndices[i]  = 99
            } else {
                offsets[i]   = CGSize(width: centers[i] - screenSize.width / 2, height: restY)
                scales[i]    = 0.92
                alphas[i]    = 0.30
                zIndices[i]  = Double(i)
            }
        }
    }

    /// Pocket the chosen card to the corner deck and call `onConfirm` to write data + advance.
    func confirm(_ intensity: CandleIntensity, screenSize: CGSize,
                 onConfirm: @escaping (CandleIntensity) -> Void) {
        guard case .lifted(let held) = state, held == intensity else { return }
        state = .confirming(intensity)
        confirmHapticTrigger.toggle()
        pocketTask = Task { @MainActor in
            let cornerX = screenSize.width  - AppLayout.cornerDeckRight - AppLayout.cornerDeckWidth  / 2
            let cornerY = AppLayout.cornerDeckTop + AppLayout.cornerDeckHeight / 2
            let cardWidth = AppLayout.obTableCardWidth(in: screenSize.width)
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

    /// Runs the full entrance: deal → showSwiftUIBacks → organize → (shuffle unless reduceMotion) → reveal.
    /// The task is stored so `cancel()` can interrupt it at any await point.
    func runEntrance(screenSize: CGSize, backImage: UIImage, reduceMotion: Bool) {
        sequenceTask?.cancel()
        sequenceTask = Task { @MainActor in
            await deal(screenSize: screenSize, backImage: backImage)
            guard !Task.isCancelled else { return }

            // Hand-off: sprites cleared, SwiftUI backs appear at exact row positions.
            // Instant alpha swap (no animation) for zero flicker.
            showSwiftUIBacks()

            guard !Task.isCancelled else { return }
            await organize(screenSize: screenSize)
            guard !Task.isCancelled else { return }

            if !reduceMotion {
                await shuffle(screenSize: screenSize)
                guard !Task.isCancelled else { return }
            }

            await reveal()
        }
    }

    // MARK: - Cancel

    func cancel() {
        pocketTask?.cancel()
        sequenceTask?.cancel()
    }
}
