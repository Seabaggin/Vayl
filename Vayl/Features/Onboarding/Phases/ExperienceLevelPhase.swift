//
//  ExperienceLevelPhase.swift
//  Vayl

import SwiftUI
import SpriteKit

/// OB Phase — Experience Level
/// Three candle cards deal in one-at-a-time and settle into a fan, flip to reveal.
/// Tap to lift (shows level name + descriptor), swipe up to confirm.
/// On confirm writes nmStage via director.commitExperienceLevel and advances to .context.
struct ExperienceLevelPhase: View {

    let director:   VaylDirector
    let screenSize: CGSize

    @State private var monte        = CardThreeMonteController()
    @State private var liftedText:  String?          = nil
    @State private var liftedLevel: CandleIntensity? = nil
    @State private var liftTextTask: Task<Void, Never>? = nil
    @State private var pressedSlot: Int?             = nil
    @State private var promptTask:  Task<Void, Never>? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // ── Card dimensions (fan tokens) ─────────────────────────────
    private var cardW: CGFloat { AppLayout.obFanCardWidth(in: screenSize.width) }
    private var cardH: CGFloat { AppLayout.obFanCardHeight(in: screenSize.width) }

    /// SpriteKit layer visible ONLY during `.dealing` — sprites carry the cards.
    private var spriteActive: Bool {
        monte.state == .dealing
    }

    var body: some View {
        // NOTE: AppColors.void, AtmosphereView, and TableSurfaceView are provided by
        // OnboardingCanvasView — phases render as transparent overlays on top.
        ZStack {
            // ── Layer: SpriteKit card flight ──────────────────────────────────
            // Visible only during .dealing (sprites carry the cards in flight).
            // Hidden once deal completes — SwiftUI backs take over at fan positions.
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
            TimelineView(.animation) { tl in
                let t = reduceMotion ? 0 : tl.date.timeIntervalSinceReferenceDate
                ZStack {
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
                        .scaleEffect(pressedSlot == i ? 0.97 : monte.scales[i])
                        .rotationEffect(.degrees(monte.angles[i]))
                        .offset(monte.offsets[i])
                        .opacity(monte.alphas[i])
                        .zIndex(monte.zIndices[i])
                        .shadow(color: s.color, radius: s.radius, y: s.y)
                        .sensoryFeedback(.impact(weight: .light), trigger: pressedSlot == i)
                        .onTapGesture {
                            promptTask?.cancel()
                            director.hideDealerLine()
                            withAnimation(AppAnimation.standard) {
                                monte.lift(monte.intensities[i], screenSize: screenSize)
                            }
                            liftTextTask?.cancel()
                            withAnimation(AppAnimation.fast) {
                                liftedText  = nil
                                liftedLevel = nil
                            }
                            scheduleLiftText(for: monte.intensities[i])
                        }
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in pressedSlot = i }
                                .onEnded   { _ in pressedSlot = nil }
                        )
                        .gesture(
                            DragGesture().onEnded { v in
                                if case .lifted(let held) = monte.state,
                                   held == monte.intensities[i],
                                   v.translation.height < -55,
                                   abs(v.translation.width) < 80 {
                                    liftTextTask?.cancel()
                                    withAnimation(AppAnimation.fast) {
                                        liftedText  = nil
                                        liftedLevel = nil
                                    }
                                    director.hideDealerLine()
                                    monte.confirm(held, screenSize: screenSize) {
                                        director.commitExperienceLevel($0)
                                    }
                                }
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // ── Layer: Projected dealer prompt ────────────────────────────────
            if director.projectedTextVisible, let copy = director.projectedText {
                ProjectedTextView(text: copy, screenSize: screenSize)
                    .transition(.opacity.combined(with: .offset(y: -6)))
                    .zIndex(18)
            }

            // ── Layer: Lift label ─────────────────────────────────────────────
            if let text = liftedText, let level = liftedLevel {
                liftCopyLayer(title: level.displayName, subtitle: text)
                    .transition(.opacity)
                    .zIndex(20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sensoryFeedback(.selection, trigger: monte.state)
        .sensoryFeedback(.impact(weight: .medium), trigger: monte.confirmHapticTrigger)
        .onAppear {
            // Pre-set fan positions (alphas stay 0 until deal completes).
            monte.placeFanFaceDown(screenSize: screenSize)

            // Dealer prompt — appears after the deal lands.
            promptTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(1600))
                guard !Task.isCancelled else { return }
                director.showDealerLineManual("How much have you explored?")
                try? await Task.sleep(for: .milliseconds(3000))
                guard !Task.isCancelled else { return }
                director.hideDealerLine()
            }

            // Reduce Motion: skip deal-in theatre; show backs + reveal.
            if reduceMotion {
                monte.showSwiftUIBacks()
                Task { await monte.reveal() }
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
                // Snapshot failed — fall back to instant reveal.
                monte.showSwiftUIBacks()
                Task { await monte.reveal() }
                return
            }

            // Full entrance: deal → showSwiftUIBacks → reveal.
            monte.runEntrance(screenSize: screenSize, backImage: backImage)
        }
        .onDisappear {
            promptTask?.cancel()
            liftTextTask?.cancel()
            // cancel() stops both sequenceTask and pocketTask.
            monte.cancel()
        }
        .accessibilityLabel("Experience level phase")
    }

    // MARK: — Lift copy overlay

    private func liftCopyLayer(title: String, subtitle: String) -> some View {
        ZStack {
            VStack(spacing: AppSpacing.sm) {
                // Level name — LivingText
                LivingText(
                    text: title,
                    font: AppFonts.heroTitle
                )

                // Descriptor — GradientText
                GradientText(
                    text: subtitle,
                    font: AppFonts.sectionHeading
                )
                .multilineTextAlignment(.center)

                // Spectrum hairline
                Rectangle()
                    .frame(height: 0.75)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .clear,
                                AppColors.spectrumCyan,
                                AppColors.spectrumPurple,
                                AppColors.spectrumMagenta,
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(0.55)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.xs)
            }
            .liftCopyGlow()
        }
        .position(x: screenSize.width / 2, y: screenSize.height * 0.16)
        .allowsHitTesting(false)
    }

    // MARK: — Lift text scheduler

    private func scheduleLiftText(for intensity: CandleIntensity) {
        liftTextTask?.cancel()
        liftTextTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            let descriptor: String = {
                switch intensity {
                case .curious:     return "Just opening the door."
                case .exploring:   return "Finding our rhythm."
                case .experienced: return "We know what we like."
                }
            }()
            withAnimation(AppAnimation.standard) {
                liftedText  = descriptor
                liftedLevel = intensity
            }
        }
    }
}
