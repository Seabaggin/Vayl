// Features/Home/Components/CardChestContainer.swift
// Open Lightly

import SwiftUI

struct CardChestContainer: View {

    var cards:            [Card]
    var cardsCompleted:   Int                               = 0
    var onCardAction:     ((Card, CardAction) -> Void)?     = nil
    var onNavigateToPlay: (() -> Void)?                     = nil
    var onPhaseChange:    ((CarouselPhase) -> Void)?        = nil

    @State private var breathPhase: CGFloat        = 0
    @State private var deckPhase:   CarouselPhase  = .floating

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }

    private var isFloating: Bool { deckPhase == .floating }

    @Namespace private var deckNamespace

    private var completedCount: Int { cardsCompleted }

    private var progressPct: CGFloat {
        guard !cards.isEmpty else { return 0 }
        return CGFloat(cardsCompleted) / CGFloat(cards.count)
    }

    private var rimOpacity: CGFloat {
        let base   = 0.55 + progressPct * 0.30
        let breath = sin(breathPhase * .pi * 2) * 0.5 + 0.5
        return base * (0.80 + breath * 0.20)
    }

    private var underlowOpacity: CGFloat {
        let breath = sin(breathPhase * .pi * 2) * 0.5 + 0.5
        return 0.18 + breath * 0.14
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {

                sectionLabel
                    .padding(.bottom, isFloating ? 0 : AppSpacing.sm)
                    .opacity(isFloating ? 0 : 1)
                    .frame(height: isFloating ? 0 : nil, alignment: .top)
                    .clipped()
                    .animation(AppAnimation.fast, value: isFloating)

                chestSurface
                    .overlay(alignment: .bottom) {
                        underglow
                            .opacity(isFloating ? 0 : 1)
                            .animation(AppAnimation.fast, value: isFloating)
                            .allowsHitTesting(false)
                    }
            }
        }
        .onAppear { startBreathCycle() }
    }

    // MARK: - Section Label

    private var sectionLabel: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("THE DECK")
                .font(AppFonts.overline)
                .tracking(2.8)
                .foregroundStyle(AppColors.textPrimary.opacity(0.45))

            Text("·")
                .foregroundStyle(AppColors.textPrimary.opacity(0.15))

            Text("Last session 2 days ago")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textPrimary.opacity(0.22))

            Spacer()

            Text("\(completedCount) / \(cards.count)")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textPrimary.opacity(0.28))
        }
    }

    // MARK: - Underglow

    private var underglow: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        AppColors.accentSecondary.opacity(underlowOpacity),
                        Color.clear
                    ],
                    center:      .center,
                    startRadius: 0,
                    endRadius:   120
                )
            )
            .frame(height: 60)
            .padding(.horizontal, AppSpacing.xxl)
            .blur(radius: 22)
            .offset(y: 32)
    }

    // MARK: - Glass Surface

    private var chestSurface: some View {
        ZStack(alignment: .top) {

            if !isFloating {
                ZStack {
                    Color(red: 0.05, green: 0.04, blue: 0.12)
                    ambientOrbs
                    Color.white.opacity(0.04)
                    NoiseTexture(opacity: 0.028)
                }
                .transition(.opacity.animation(AppAnimation.fast))
            }

            VStack(spacing: 0) {

                if !isFloating {
                    chestHeader
                        .transition(
                            .opacity
                                .combined(with: .offset(y: -10))
                                .animation(AppAnimation.fast)
                        )
                }

                CardCarousel(
                    cards:            cards,
                    onCardAction:     onCardAction,
                    onNavigateToPlay: onNavigateToPlay,
                    onPhaseChange: {
                        deckPhase = $0
                        onPhaseChange?($0)
                    }
                )
            }
            .padding(.top, isFloating ? 0 : AppSpacing.sm)
            .animation(AppAnimation.fast, value: isFloating)
        }
        .if(!isFloating) { view in
            view.clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        }
        .overlay {
            if !isFloating {
                RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                    .strokeBorder(
                        isLight
                            ? AnyShapeStyle(AppColors.spectrumBorder.opacity(0.30))
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.accentPrimary.opacity(0.08),
                                    AppColors.accentSecondary.opacity(0.08),
                                    AppColors.accentTertiary.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint:   .bottomTrailing
                              )),
                        lineWidth: 1.5
                    )
                    .transition(.opacity.animation(AppAnimation.fast))
            }
        }
        .overlay(alignment: .top) {
            if !isFloating {
                rimLight
                    .transition(.opacity.animation(AppAnimation.fast))
            }
        }
        .shadow(
            color: AppColors.accentSecondary.opacity(isFloating ? 0 : 0.35),
            radius: 28, y: 10
        )
    }

    // MARK: - Rim Light

    private var rimLight: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.clear,
                        AppColors.accentPrimary.opacity(rimOpacity),
                        AppColors.accentSecondary.opacity(rimOpacity),
                        AppColors.accentTertiary.opacity(rimOpacity * 0.65),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
            )
            .animation(AppAnimation.fast, value: isFloating)
            .frame(height: 1)
            .padding(.horizontal, AppSpacing.xl)
            .shadow(
                color:  AppColors.accentSecondary.opacity(rimOpacity * 0.65),
                radius: 14, y: 0
            )
            .allowsHitTesting(false)
    }

    // MARK: - Ambient Orbs

    private var ambientOrbs: some View {
        GeometryReader { geo in
            let breath = sin(breathPhase * .pi * 2) * 0.5 + 0.5
            ZStack {
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.accentSecondary.opacity(0.28 + breath * 0.12),
                            Color.clear
                        ],
                        center:      .center,
                        startRadius: 0,
                        endRadius:   120
                    ))
                    .frame(width: 220, height: 180)
                    .position(x: geo.size.width * 0.18, y: geo.size.height * 0.30)
                    .blur(radius: 28)

                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.accentTertiary.opacity(0.18 + breath * 0.10),
                            Color.clear
                        ],
                        center:      .center,
                        startRadius: 0,
                        endRadius:   90
                    ))
                    .frame(width: 180, height: 140)
                    .position(x: geo.size.width * 0.85, y: geo.size.height * 0.82)
                    .blur(radius: 24)
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Chest Header

    private var chestHeader: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("The Opening Sequence")
                        .font(AppFonts.sectionHeading)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.accentPrimary, AppColors.accentSecondary],
                                startPoint: .leading,
                                endPoint:   .trailing
                            )
                        )
                        .matchedGeometryEffect(
                            id: "deckName",
                            in: deckNamespace,
                            anchor: .leading,
                            isSource: !isFloating
                        )

                    Text("\(completedCount) / \(cards.count)")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textPrimary.opacity(0.28))
                        .matchedGeometryEffect(
                            id: "deckFraction",
                            in: deckNamespace,
                            anchor: .leading,
                            isSource: !isFloating
                        )
                }
                Spacer()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.accentPrimary, AppColors.accentSecondary, AppColors.accentTertiary],
                                startPoint: .leading,
                                endPoint:   .trailing
                            )
                        )
                        .frame(width: geo.size.width * progressPct)
                        .shadow(
                            color:  AppColors.accentSecondary.opacity(0.55),
                            radius: 6, y: 0
                        )
                        // Intentional slow spring — progress bar fill should
                        // feel weighty, not snappy. response: 0.9 is deliberate.
                        .animation(
                            .spring(response: 0.9, dampingFraction: 0.8),
                            value: progressPct
                        )
                }
            }
            .frame(height: 2)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, AppSpacing.md)
    }

    // MARK: - Breath Cycle
    // 8.0s — intentional above ambientDrift. Matches HomeDashboardView
    // breathPhase system — all ambient breath on the home screen runs
    // at the same rate for visual coherence.

    private func startBreathCycle() {
        withAnimation(
            .linear(duration: 8.0).repeatForever(autoreverses: false)
        ) {
            breathPhase = 1.0
        }
    }
}

// MARK: - NoiseTexture

struct NoiseTexture: View {
    var opacity: CGFloat = 0.028

    var body: some View {
        Canvas { context, size in
            for _ in 0..<Int(size.width * size.height * 0.04) {
                let x          = CGFloat.random(in: 0..<size.width)
                let y          = CGFloat.random(in: 0..<size.height)
                let brightness = CGFloat.random(in: 0.4...1.0)
                context.fill(
                    Path(CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(Color.white.opacity(brightness * opacity))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Preview

#Preview("Card Chest — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            CardChestContainer(cards: Card.samples)
                .padding(AppSpacing.md)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Card Chest — light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ScrollView {
            CardChestContainer(cards: Card.samples)
                .padding(AppSpacing.md)
        }
    }
    .preferredColorScheme(.light)
}
