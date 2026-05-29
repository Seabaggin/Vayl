//
//  ExperienceLevelPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Experience Level
/// Renders three candle cards in a static row using CardThreeMonteController.
/// No pick/confirm yet — static layout only (Task 7).
/// Advances to .context via director (wired in Task 8).
struct ExperienceLevelPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    @State private var monte = CardThreeMonteController()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cardW: CGFloat { AppLayout.obTableCardWidth(in: screenSize.width) }
    private var cardH: CGFloat { cardW * 1.5 }

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()

            TimelineView(.animation) { tl in
                let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
                ForEach(0..<3, id: \.self) { i in
                    VaylCardFace(content: .candle(intensity: monte.intensities[i], time: t))
                        .frame(width: cardW, height: cardH)
                        .scaleEffect(monte.scales[i])
                        .rotationEffect(.degrees(monte.angles[i]))
                        .offset(monte.offsets[i])
                        .opacity(monte.alphas[i])
                        .zIndex(monte.zIndices[i])
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear  { monte.placeStaticRow(screenSize: screenSize) }
        .onDisappear { monte.cancel() }
        .accessibilityLabel("Experience level phase")
    }
}
