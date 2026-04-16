//
//  CardChestContainer.swift
//  Open Lightly
//
//  Created by Bryan Jorden on 4/13/26.
//


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

    private var completedCount: Int { cardsCompleted }

    private var progressPct: CGFloat {
        guard !cards.isEmpty else { return 0 }
        return CGFloat(cardsCompleted) / CGFloat(cards.count)
    }

    // Rim light breathes on 8s cycle — shared with Pulse
    private var rimOpacity: CGFloat {
        let base = 0.55 + progressPct * 0.30
        let breath = sin(breathPhase * .pi * 2) * 0.5 + 0.5
        return base * (0.80 + breath * 0.20)
    }

    private var underlowOpacity: CGFloat {
        let breath = sin(breathPhase * .pi * 2) * 0.5 + 0.5
        return 0.18 + breath * 0.14
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionLabel
                .padding(.bottom, 10)
                .opacity(deckPhase == .floating ? 0 : 1)
                .animation(.easeOut(duration: 0.25), value: deckPhase)

            ZStack(alignment: .bottom) {
                // Underglow — fades with decoration
                underglow
                    .opacity(deckPhase == .floating ? 0 : 1)
                    .animation(.easeOut(duration: 0.25), value: deckPhase)

                // Glass chest
                chestSurface
            }
        }
        .padding(.top, 10)
        .offset(y: -10)
        .onAppear { startBreathCycle() }
    }

    // MARK: - Section Label

    private var sectionLabel: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("THE DECK")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.8)
                .foregroundStyle(AppColors.textPrimary.opacity(0.45))

            Text("·")
                .foregroundStyle(AppColors.textPrimary.opacity(0.15))

            Text("Last session 2 days ago")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(AppColors.textPrimary.opacity(0.22))

            Spacer()

            Text("\(completedCount) / \(cards.count)")
                .font(.system(size: 11, weight: .medium))
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
                    center: .center,
                    startRadius: 0,
                    endRadius: 120
                )
            )
            .frame(height: 60)
            .padding(.horizontal, 60)
            .blur(radius: 22)
            .offset(y: 32)
            .allowsHitTesting(false)
    }

    // MARK: - Glass Surface

    private var chestSurface: some View {
        ZStack(alignment: .top) {
            // Decorative background — fades in floating state
            ZStack {
                // Layer 1: Void base
                Color(red: 0.05, green: 0.04, blue: 0.12)
                    .opacity(0.0)

                // Layer 2: Ambient orbs
                ambientOrbs

                // Layer 3: Frost
                Color.white.opacity(0.04)

                // Layer 4: Grain
                NoiseTexture(opacity: 0.028)
            }
            .opacity(isFloating ? 0 : 1)
            .animation(.easeOut(duration: 0.25), value: deckPhase)

            // Content — always visible
            VStack(spacing: 0) {
                // Header removed from layout when floating
                if !isFloating {
                    chestHeader
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Carousel stays visible at all times
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
            .animation(.easeOut(duration: 0.25), value: isFloating)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    isLight
                        ? AnyShapeStyle(AppColors.warmAuroraBorder.opacity(0.30))
                        : AnyShapeStyle(LinearGradient(
                            colors: [
                                AppColors.cyan.opacity(0.08),
                                AppColors.purple.opacity(0.08),
                                AppColors.magenta.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )),
                    lineWidth: 1.5
                )
                .opacity(isFloating ? 0 : 1)
                .animation(.easeOut(duration: 0.25), value: deckPhase)
        }
        // Rim light — top edge only
        .overlay(alignment: .top) {
            rimLight
                .opacity(isFloating ? 0 : 1)
                .animation(.easeOut(duration: 0.25), value: deckPhase)
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
                    endPoint: .trailing
                )
            )
            .frame(height: 1)
            .padding(.horizontal, 28)
            .shadow(
                color: AppColors.purple.opacity(rimOpacity * 0.65),
                radius: 14, y: 0
            )
            .allowsHitTesting(false)
    }

    // MARK: - Ambient Orbs

    private var ambientOrbs: some View {
        GeometryReader { geo in
            let breath = sin(breathPhase * .pi * 2) * 0.5 + 0.5
            ZStack {
                // Purple — top left
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.purple.opacity(0.28 + breath * 0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    ))
                    .frame(width: 220, height: 180)
                    .position(x: geo.size.width * 0.18, y: geo.size.height * 0.30)
                    .blur(radius: 28)

                // Magenta — bottom right
                Ellipse()
                    .fill(RadialGradient(
                        colors: [
                            AppColors.magenta.opacity(0.18 + breath * 0.10),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 90
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
                    // Deck name — gradient text, matches Pulse tier name
                    Text("The Opening Sequence")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("\(cards.count - completedCount) cards left · 4m avg")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(AppColors.textPrimary.opacity(0.28))
                }

                Spacer()
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppColors.cyan, AppColors.purple, AppColors.magenta],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progressPct)
                        .shadow(
                            color: AppColors.purple.opacity(0.55),
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
                let x = CGFloat.random(in: 0..<size.width)
                let y = CGFloat.random(in: 0..<size.height)
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
