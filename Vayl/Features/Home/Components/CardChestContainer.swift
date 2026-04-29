// Features/Home/Components/CardChestContainer.swift
// Open Lightly

import SwiftUI

struct CardChestContainer: View {

    var cards: [Prompt]
    var cardsCompleted: Int = 0
    var onCardAction: ((Prompt, CardAction) -> Void)? = nil
    var onNavigateToPlay: (() -> Void)? = nil
    var onPhaseChange: ((CarouselPhase) -> Void)? = nil

    @State private var breathPhase: CGFloat = 0
    @State private var deckPhase: CarouselPhase = .floating

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

                // Section label — collapses height when floating
                sectionLabel
                    .padding(.bottom, isFloating ? 0 : 10)
                    .opacity(isFloating ? 0 : 1)
                    .frame(height: isFloating ? 0 : nil, alignment: .top)
                    .clipped()
                    .animation(.easeOut(duration: 0.25), value: isFloating)

                // Glass chest
                chestSurface
                    .overlay(alignment: .bottom) {
                        underglow
                            .opacity(isFloating ? 0 : 1)
                            .animation(.easeOut(duration: 0.25), value: isFloating)
                            .allowsHitTesting(false)
                    }
            }


        }
        // ZStack must not clip — the card overflows upward during carousel
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
                        AppColors.purple.opacity(underlowOpacity),
                        Color.clear
                    ],
                    center:      .center,
                    startRadius: 0,
                    endRadius:   120
                )
            )
            .frame(height: 60)
            .padding(.horizontal, 60)
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
                .transition(.opacity.animation(.easeOut(duration: 0.25)))
            }

            VStack(spacing: 0) {

                if !isFloating {
                    chestHeader
                        .transition(
                            .opacity
                                .combined(with: .offset(y: -10))
                                .animation(.easeOut(duration: 0.25))
                        )
                }

                CardCarousel(
                    cards: cards,
                    onCardAction: onCardAction,
                    onNavigateToPlay: onNavigateToPlay,
                    onPhaseChange: {
                        deckPhase = $0
                        onPhaseChange?($0)
                    }
                )
            }
            .padding(.top, isFloating ? 0 : 6)
            .animation(.easeOut(duration: 0.25), value: isFloating)
        }
        // Clip shape only when the glass surface is visible.
        // When floating, NO clip at all — the card must be free to
        // overflow the container's bounds in lifted/carousel phases.
        // The clip is applied to the background surface only, not the
        // card content itself.
        .if(!isFloating) { view in
            view.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        // Overflow is handled by the ZStack parent — this view must
        // not re-introduce a clip boundary
        .overlay {
            if !isFloating {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        isLight
                            ? AnyShapeStyle(
                                AppColors.warmAuroraBorder.opacity(0.30)
                              )
                            : AnyShapeStyle(LinearGradient(
                                colors: [
                                    AppColors.cyan.opacity(0.08),
                                    AppColors.purple.opacity(0.08),
                                    AppColors.magenta.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint:   .bottomTrailing
                              )),
                        lineWidth: 1.5
                    )
                    .transition(.opacity.animation(.easeOut(duration: 0.25)))
            }
        }
        .overlay(alignment: .top) {
            if !isFloating {
                rimLight
                    .transition(.opacity.animation(.easeOut(duration: 0.25)))
            }
        }
        .shadow(
            color: AppColors.purple.opacity(isFloating ? 0 : 0.35),
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
                        AppColors.cyan.opacity(rimOpacity),
                        AppColors.purple.opacity(rimOpacity),
                        AppColors.magenta.opacity(rimOpacity * 0.65),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint:   .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 28)
            .shadow(
                color:  AppColors.purple.opacity(rimOpacity * 0.65),
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
                            AppColors.purple.opacity(0.28 + breath * 0.12),
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
                            AppColors.magenta.opacity(0.18 + breath * 0.10),
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
        VStack(spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("The Opening Sequence")
                        .font(AppFonts.sectionHeading)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple],
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
                                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                startPoint: .leading,
                                endPoint:   .trailing
                            )
                        )
                        .frame(width: geo.size.width * progressPct)
                        .shadow(
                            color:  AppColors.purple.opacity(0.55),
                            radius: 6, y: 0
                        )
                        .animation(
                            .spring(response: 0.9, dampingFraction: 0.8),
                            value: progressPct
                        )
                }
            }
            .frame(height: 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Breath Cycle

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
        AppColors.pageBg.ignoresSafeArea()
        ScrollView {
            CardChestContainer(cards: Prompt.samples)
                .padding(20)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Card Chest — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ScrollView {
            CardChestContainer(cards: Prompt.samples)
                .padding(20)
        }
    }
    .preferredColorScheme(.light)
}
