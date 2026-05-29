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

    /// SpriteKit layer visible ONLY during `.dealing` — sprites carry the cards.
    /// `.organizing` and `.shuffling` use the visible SwiftUI face-down cards.
    private var spriteActive: Bool {
        monte.state == .dealing
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
                    let s = AppElevation.cardShadow(elevation: monte.elevations[i])
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
                    .shadow(color: s.color, radius: s.radius, y: s.y)
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

            // Reduce Motion: skip deal-in and shuffle theatre; show backs + tidy row + reveal.
            if reduceMotion {
                monte.showSwiftUIBacks()
                Task {
                    await monte.organize(screenSize: screenSize)
                    await monte.reveal()
                }
                return
            }

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
                Task { await monte.reveal() }
                return
            }

            // Full entrance: deal → showSwiftUIBacks → organize → shuffle → reveal.
            // The sequence is owned by the controller so it can be cancelled on disappear.
            monte.runEntrance(screenSize: screenSize, backImage: backImage, reduceMotion: false)
        }
        .onDisappear {
            // cancel() stops both sequenceTask and pocketTask.
            // clearAllCards() is NOT called here — deal()'s cancellation path clears
            // sprites itself, and the normal completion path in deal() clears them too.
            monte.cancel()
        }
        .accessibilityLabel("Experience level phase")
    }
}
