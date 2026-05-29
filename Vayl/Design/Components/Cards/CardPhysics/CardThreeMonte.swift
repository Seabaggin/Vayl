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
    var showFace:   [Bool]   = [true, true, true]
    var elevations: [Double] = [0, 0, 0]
    var zIndices:   [Double] = [0, 1, 2]
    var confirmHapticTrigger = false

    /// Slot index → intensity (ordered L→R).
    let intensities = CandleIntensity.ordered

    private var dealTask: Task<Void, Never>?

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

    func cancel() { dealTask?.cancel() }
}
