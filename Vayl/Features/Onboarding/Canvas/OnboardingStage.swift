//
//  OnboardingStage.swift
//  Vayl
//

import Foundation
import CoreGraphics

/// The narrow surface a phase sequencer needs back from the coordinator (VaylDirector).
///
/// Extracted sequencers depend only on the capabilities they actually use — not the whole
/// 900-line director — which keeps them decoupled and unit-testable with a mock stage.
///
/// This grows as more sequencers are extracted (e.g. `advance(to:)`, `receiveCredential(_:)`,
/// `setTableFade(...)`).
@MainActor
protocol OnboardingStage: AnyObject {
    var onboardingData: OnboardingData { get set }

    /// Dealer-line projection surface. Sequencers speak through the stage so every
    /// phase shares the one typed dealer voice (canvas ProjectedTextView) — no
    /// phase-local dealer text in a different font or cadence.
    func showDealerLineManual(_ text: String, anchorYFrac: CGFloat)
    func hideDealerLine()
}
