import SwiftUI

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

    /// Slot index → intensity (ordered L→R).
    let intensities = CandleIntensity.ordered

    private var dealTask: Task<Void, Never>?

    /// Flip each card face-up in succession (L→R), assigning the face at the half-flip.
    func reveal() async {
        state = .revealing
        for i in 0..<3 {
            withAnimation(AppAnimation.cardFlip) { flipScaleX[i] = 0.0 }
            try? await Task.sleep(for: .milliseconds(160))
            showFace[i] = true              // identity becomes visible at the half-flip
            withAnimation(AppAnimation.cardFlip) { flipScaleX[i] = 1.0 }
            try? await Task.sleep(for: .milliseconds(140))
        }
        state = .faceUp
    }

    /// Place the three cards in the clean row, FACE DOWN (no reveal yet).
    func placeRowFaceDown(screenSize: CGSize) {
        let centers = AppLayout.monteRowCenters(in: screenSize.width)
        let restY   = AppLayout.obTableCardCenterY(in: screenSize.height) - screenSize.height / 2
        for i in 0..<3 {
            offsets[i] = CGSize(width: centers[i] - screenSize.width / 2, height: restY)
            showFace[i] = false
            flipScaleX[i] = 1.0
        }
        state = .idle
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
        dealTask = Task { @MainActor in
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

    func cancel() { dealTask?.cancel() }
}
