//
//  ExperienceLevelPhase.swift
//  Vayl
//

import SwiftUI
import SpriteKit

/// OB Phase — Experience Level
/// Three candle cards dealt face-down from the dealer point, then flipped L→R.
/// Tap to lift, swipe up to confirm.
/// On confirm writes nmStage via director.commitExperienceLevel and advances to .context.
struct ExperienceLevelPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    @State private var monte = CardThreeMonteController()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var cardW: CGFloat { AppLayout.obTableCardWidth(in: screenSize.width) }
    private var cardH: CGFloat { cardW * 1.5 }

    /// True only while SpriteKit sprites are in flight — hides the SwiftUI card layer.
    private var spriteActive: Bool {
        monte.state == .dealing || monte.state == .organizing
    }

    var body: some View {
        ZStack {
            AppColors.void.ignoresSafeArea()

            // ── Layer: SpriteKit card flight ──────────────────────────────────
            // Visible during .dealing/.organizing only (sprites carry the cards).
            // Hidden once .revealing starts — SwiftUI backs take over at same positions.
            // Matches the hosting convention used by OnboardingCanvasView Layer 4b.
            SpriteView(
                scene:   monte.flightScene,
                options: [.allowsTransparency]
            )
            .frame(width: screenSize.width, height: screenSize.height)
            .allowsHitTesting(false)
            .ignoresSafeArea()
            .opacity(spriteActive ? 1 : 0)
            .onAppear {
                monte.flightScene.size = screenSize
            }

            // ── Layer: SwiftUI cards ──────────────────────────────────────────
            // alphas[i] = 0 during flight (set by placeRowFaceDown).
            // alphas[i] = 1 after deal completes (set by showSwiftUIBacks),
            // so SwiftUI backs appear at the exact row positions where sprites stopped.
            TimelineView(.animation) { tl in
                let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
                ForEach(0..<3, id: \.self) { i in
                    Group {
                        if monte.showFace[i] {
                            VaylCardFace(content: .candle(intensity: monte.intensities[i], time: t))
                                .frame(width: cardW, height: cardH)
                        } else {
                            VaylCardBack()
                                .frame(width: cardW, height: cardH)
                        }
                    }
                    .scaleEffect(x: monte.flipScaleX[i], y: 1, anchor: .center)
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
        .onAppear {
            // Pre-set row positions (alphas stay 0 until deal completes).
            monte.placeRowFaceDown(screenSize: screenSize)

            // Reduce Motion: skip the deal-in entirely, show backs directly.
            guard !reduceMotion else {
                monte.showSwiftUIBacks()
                Task { await monte.reveal() }
                return
            }

            Task {
                // Snapshot the card back for SpriteKit textures.
                // Uses UIWindowScene.screen (iOS 26 compliant — no UIScreen.main).
                let scale = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first?.screen.scale ?? 2.0
                let renderer = ImageRenderer(
                    content: VaylCardBack().frame(width: cardW, height: cardH)
                )
                renderer.scale = scale

                guard let backImage = renderer.uiImage else {
                    // Snapshot failed — fall back to instant row reveal.
                    monte.showSwiftUIBacks()
                    await monte.reveal()
                    return
                }

                // Fly cards in via SpriteKit (alphas = 0 throughout; sprites carry visual).
                await monte.deal(screenSize: screenSize, backImage: backImage)

                // Hand-off: sprites cleared, SwiftUI backs appear at exact row positions.
                // No animation on the alpha change — instant swap for zero flicker.
                monte.showSwiftUIBacks()

                // Flip reveal runs with SwiftUI backs now visible.
                await monte.reveal()
            }
        }
        .onDisappear {
            monte.cancel()
            monte.flightScene.clearAllCards()
        }
        .accessibilityLabel("Experience level phase")
    }
}
