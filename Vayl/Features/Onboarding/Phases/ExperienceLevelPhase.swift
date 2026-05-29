//
//  ExperienceLevelPhase.swift
//  Vayl
//

import SwiftUI

/// OB Phase — Experience Level
/// Three candle cards in a static row. Tap to lift, swipe up to confirm.
/// On confirm writes nmStage via director.commitExperienceLevel and advances to .context.
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
                        .onTapGesture {
                            withAnimation(AppAnimation.standard) {
                                monte.lift(monte.intensities[i], screenSize: screenSize)
                            }
                        }
                        .gesture(
                            DragGesture().onEnded { v in
                                if case .lifted(let held) = monte.state,
                                   held == monte.intensities[i],
                                   v.translation.height < -55,
                                   abs(v.translation.width) < 80 {
                                    monte.confirm(held, screenSize: screenSize) {
                                        director.commitExperienceLevel($0)
                                    }
                                }
                            }
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.selection, trigger: monte.state)
        .sensoryFeedback(.impact(weight: .medium), trigger: monte.confirmHapticTrigger)
        .onAppear  { monte.placeStaticRow(screenSize: screenSize) }
        .onDisappear { monte.cancel() }
        .accessibilityLabel("Experience level phase")
    }
}
