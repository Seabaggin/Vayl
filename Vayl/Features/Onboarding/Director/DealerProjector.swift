//
//  DealerProjector.swift
//  Vayl
//
//  Handles the projection of the dealer's speech onto the canvas.
//

import SwiftUI

@Observable
@MainActor
final class DealerProjector {

    var projectedText: String?
    var projectedTextVisible: Bool = false
    var projectedTextAnchorYFrac: CGFloat = AppLayout.tableHorizonYFrac

    @ObservationIgnored private var dealerLineAttempt: Int = 0

    func showDealerLine(_ text: String, hideAfter seconds: Double = 4.0, anchorYFrac: CGFloat? = nil) {
        dealerLineAttempt += 1
        let current = dealerLineAttempt
        projectedText = text
        projectedTextAnchorYFrac = anchorYFrac ?? AppLayout.tableHorizonYFrac

        withAnimation(AppAnimation.textProject.reduceMotionSafe) {
            projectedTextVisible = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(seconds))
            guard current == self.dealerLineAttempt else { return }
            withAnimation(AppAnimation.textProject.reduceMotionSafe) {
                self.projectedTextVisible = false
            }
        }
    }

    func showDealerLineManual(_ text: String, anchorYFrac: CGFloat? = nil) {
        dealerLineAttempt += 1
        projectedText = text
        projectedTextAnchorYFrac = anchorYFrac ?? AppLayout.tableHorizonYFrac
        withAnimation(AppAnimation.textProject.reduceMotionSafe) {
            projectedTextVisible = true
        }
    }

    func hideDealerLine() {
        dealerLineAttempt += 1
        withAnimation(AppAnimation.textProject.reduceMotionSafe) {
            projectedTextVisible = false
        }
    }
}
