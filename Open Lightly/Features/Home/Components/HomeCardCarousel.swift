// Features/Home/Components/HomeCardCarousel.swift
// Open Lightly

import SwiftUI

// MARK: - Supporting Types

enum CarouselPhase: Equatable {
    case spread
    case gathering
    case lifted
    case carousel
}

enum CarouselDirection {
    case next
    case prev
}

enum CardAction {
    case discussed
    case notReady
    case bookmark
}

// MARK: - Layout Constants

private let spreadOffsets:   [CGFloat] = [-60, -30,  0,  30,  60]
private let spreadRotations: [Double]  = [-12,  -6,  0,   6,  12]
private let spreadYOffsets:  [CGFloat] = [  8,   4,  0,   4,   8]
private let spreadOpacities: [Double]  = [0.70, 0.80, 1.00, 0.80, 0.70]
private let spreadScales:    [CGFloat] = [0.95, 0.97, 0.98, 0.97, 0.95]

private let gatheredYOffsets:  [CGFloat] = [12,   8,    5,    2   ]
private let gatheredOpacities: [Double]  = [0.42, 0.56, 0.68, 0.80]
private let gatheredScales:    [CGFloat] = [0.93, 0.96, 0.975, 0.985]

// MARK: - HomeCardCarousel

struct HomeCardCarousel: View {

    // ── Inputs ───────────────────────────────────────────────────────────
    var cards: [Prompt]
    var onCardAction: ((Prompt, CardAction) -> Void)? = nil

    // ── Phase ────────────────────────────────────────────────────────────
    @State private var phase: CarouselPhase = .spread

    // ── Carousel navigation ──────────────────────────────────────────────
    @State private var activeIndex:   Int     = 0
    @State private var dragOffset:    CGFloat = 0
    @State private var isDragging:    Bool    = false
    @State private var isExiting:     Bool    = false
    @State private var exitDirection: Int     = 0

    // ── Specular glint ───────────────────────────────────────────────────
    @State private var specularPhase:  CGFloat = 0
    @State private var specularActive: Bool    = false

    // ── Carousel 3D ──────────────────────────────────────────────────────
    @State private var lastShimmeredIndex:  Int     = -1
    @State private var dragVelocity:        CGFloat = 0
    @State private var previousDragOffset:  CGFloat = 0

    // ── Environment ──────────────────────────────────────────────────────
    @Environment(\.colorScheme)               private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isLight: Bool { colorScheme == .light }

    private var activeCard: Prompt? {
        guard cards.indices.contains(activeIndex) else { return nil }
        return cards[activeIndex]
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {

            // Instruction label — spread phase only
            if phase == .spread {
                Text("Tap to begin")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .transition(.opacity)
                    .padding(.bottom, 12)
            } else {
                Color.clear.frame(height: 1)
            }

            // ── Card stack ───────────────────────────────────────────────
            ZStack {

                // ── Aurora / bloom glows ──────────────────────────────────
                if let card = activeCard {
                    // Primary bloom — active card color
                    Ellipse()
                        .fill(RadialGradient(
                            colors: [
                                card.difficulty.glowColor
                                    .opacity(phase == .spread ? 0.14 : 0.32),
                                card.difficulty.glowColor
                                    .opacity(0.10),
                                Color.clear
                            ],
                            center:      .center,
                            startRadius: 0,
                            endRadius:   200
                        ))
                        .frame(width: 440, height: 280)
                        .blur(radius: 65)
                        .allowsHitTesting(false)
                        .animation(.easeOut(duration: 0.55), value: activeIndex)

                    // Secondary bloom — incoming card color bleeds during drag
                    if phase == .carousel && !reduceMotion {
                        let incomingIndex = dragOffset < 0
                            ? min(activeIndex + 1, cards.count - 1)
                            : max(activeIndex - 1, 0)
                        let bleedAmount = min(abs(dragOffset) / 320, 1.0)

                        Ellipse()
                            .fill(RadialGradient(
                                colors: [
                                    cards[incomingIndex].difficulty
                                        .glowColor.opacity(bleedAmount * 0.25),
                                    Color.clear
                                ],
                                center:      .center,
                                startRadius: 0,
                                endRadius:   180
                            ))
                            .frame(width: 440, height: 280)
                            .offset(x: dragOffset < 0 ? 60 : -60)
                            .blur(radius: 70)
                            .allowsHitTesting(false)
                            .animation(
                                isDragging ? .none : .easeOut(duration: 0.4),
                                value: dragOffset
                            )
                    }
                }

                // ── Backing cards (indices 0–3) ───────────────────────────
                ForEach(0..<4, id: \.self) { i in
                    let isSpread = phase == .spread

                    CardBackView(
                        offsetX:  isSpread ? spreadOffsets[i]   : 0,
                        offsetY:  isSpread ? spreadYOffsets[i]  : gatheredYOffsets[i],
                        rotation: isSpread ? spreadRotations[i] : 0,
                        scale:    isSpread ? spreadScales[i]    : gatheredScales[i],
                        opacity:  isSpread ? spreadOpacities[i] : gatheredOpacities[i],
                        isLight:  isLight
                    )
                    .zIndex(Double(i))
                    .animation(
                        reduceMotion
                            ? .easeOut(duration: 0.2)
                            : .timingCurve(0.4, 0, 0.2, 1, duration: 0.45),
                        value: phase
                    )
                    .offset(y: (phase == .lifted || phase == .carousel)
                        ? -8 : 0)
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.72),
                        value: phase)
                }

                // ── Fifth backing card (spread only) ─────────────────────
                CardBackView(
                    offsetX:  spreadOffsets[4],
                    offsetY:  spreadYOffsets[4],
                    rotation: spreadRotations[4],
                    scale:    spreadScales[4],
                    opacity:  phase == .spread ? spreadOpacities[4] : 0,
                    isLight:  isLight
                )
                .zIndex(4)
                .animation(
                    reduceMotion
                        ? .easeOut(duration: 0.2)
                        : .timingCurve(0.4, 0, 0.2, 1, duration: 0.35),
                    value: phase
                )

                // ── Peek cards (carousel phase) ───────────────────────────
                peekCards

                // ── Front card ────────────────────────────────────────────
                if let card = activeCard,
                   phase != .spread {
                    frontCard(card: card)
                        .zIndex(10)
                }
            }
            .frame(height: 280)
            .onTapGesture {
                if phase == .spread { handleSpreadTap() }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                phase == .carousel
                    ? "Card \(activeIndex + 1) of \(cards.count). \(activeCard?.text ?? "")"
                    : "Card deck. Tap to begin."
            )
            .accessibilityHint(
                phase == .carousel
                    ? "Swipe up or down to navigate cards"
                    : "Double tap to open"
            )
            .accessibilityAdjustableAction { direction in
                guard phase == .carousel else { return }
                switch direction {
                case .increment: navigateCarousel(direction: .next)
                case .decrement: navigateCarousel(direction: .prev)
                @unknown default: break
                }
            }

            // ── Card metadata crossfade (carousel only) ───────────────────
            if phase == .carousel, let card = activeCard {
                HStack(spacing: 8) {
                    Text(card.category.displayName.uppercased())
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(AppColors.textTertiary)

                    Text("·")
                        .foregroundStyle(AppColors.textTertiary)

                    Text(card.difficulty.displayName)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(card.difficulty.glowColor)
                }
                .id(activeIndex)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 6)),
                    removal:   .opacity.combined(with: .offset(y: -6))
                ))
                .animation(.easeOut(duration: 0.22), value: activeIndex)
                .padding(.top, 10)
            }

            // ── Action buttons ────────────────────────────────────────────
            if phase == .lifted || phase == .carousel {
                actionButtons
                    .transition(.opacity.animation(
                        .easeIn(duration: 0.3).delay(0.2)))
                    .padding(.top, 16)
            }

            // ── Progress dots ─────────────────────────────────────────────
            if phase == .carousel {
                progressDots
                    .transition(.opacity)
                    .padding(.top, 12)
            }
        }
        // ── Drag gesture (carousel phase only) ────────────────────────────
        .gesture(
            phase == .carousel
                ? DragGesture(minimumDistance: 8)
                    .onChanged { value in
                        // Haptic on first frame
                        if dragOffset == 0 {
                            UIImpactFeedbackGenerator(style: .light)
                                .impactOccurred()
                        }

                        // Velocity tracking for shimmer
                        dragVelocity = value.translation.width - previousDragOffset
                        previousDragOffset = value.translation.width

                        isDragging = true

                        // Rubber-band resistance at deck edges
                        let atStart = activeIndex == 0
                            && value.translation.width > 0
                        let atEnd = activeIndex == cards.count - 1
                            && value.translation.width < 0

                        if atStart || atEnd {
                            // Haptic on rubber-band hit
                            if abs(value.translation.width) > 20
                                && abs(dragOffset) < 5 {
                                UIImpactFeedbackGenerator(style: .rigid)
                                    .impactOccurred()
                            }
                            dragOffset = value.translation.width * 0.28
                        } else {
                            dragOffset = value.translation.width
                        }
                    }
                    .onEnded { value in
                        isDragging        = false
                        dragVelocity      = 0
                        previousDragOffset = 0

                        let velocity  = value.predictedEndTranslation.width
                        let threshold: CGFloat = 50

                        if dragOffset < -threshold || velocity < -200 {
                            navigateCarousel(direction: .next)
                        } else if dragOffset > threshold || velocity > 200 {
                            navigateCarousel(direction: .prev)
                        } else {
                            withAnimation(.spring(
                                response: 0.42,
                                dampingFraction: 0.78)
                            ) {
                                dragOffset = 0
                            }
                        }
                    }
                : nil
        )
    }

    // MARK: - 3D Carousel Helpers

    /// Normalized distance [0, 1] from center accounting for live drag.
    private func normalizedDistance(cardOffset: CGFloat) -> CGFloat {
        let fullWidth: CGFloat = 320
        return min(abs(cardOffset + dragOffset) / fullWidth, 1.0)
    }

    /// Sign of card position for rotation direction.
    private func positionSign(cardOffset: CGFloat) -> CGFloat {
        (cardOffset + dragOffset) >= 0 ? 1 : -1
    }

    /// Applies curved-glass 3D transforms as a function of off-center distance.
    @ViewBuilder
    private func carouselCardModifiers<V: View>(
        _ view: V,
        cardOffset: CGFloat
    ) -> some View {
        let n    = normalizedDistance(cardOffset: cardOffset)
        let sign = positionSign(cardOffset: cardOffset)

        view
            // Scale — recedes as it moves away
            .scaleEffect(1.0 - n * 0.13)
            // Opacity — atmospheric perspective dimming
            .opacity(1.0 - Double(n) * 0.45)
            // Vertical sink — gravity effect
            .offset(y: n * 14)
            // 3D Y-axis tilt — reveals card thickness, tilts toward center
            .rotation3DEffect(
                reduceMotion ? .zero : .degrees(Double(n) * 12.0 * Double(-sign)),
                axis: (x: 0, y: 1, z: 0),
                anchor: .center,
                anchorZ: 0,
                perspective: 0.35
            )
            // Depth-of-field blur
            .blur(radius: reduceMotion ? 0 : n * 2.0)
            // Spring when not dragging, instant while dragging
            .animation(
                isDragging
                    ? .none
                    : .spring(response: 0.38, dampingFraction: 0.78),
                value: dragOffset
            )
    }

    // MARK: - Front Card

    private func frontCard(card: Prompt) -> some View {
        ZStack {
            // Card face with content parallax
            PromptCard(prompt: card, showDifficultyDots: false)
                .frame(width: 300, height: 210)
                // Content floats inside glass at 8% of drag speed
                .offset(x: (phase == .carousel && !reduceMotion)
                    ? dragOffset * -0.08 : 0)
                .animation(
                    isDragging
                        ? .none
                        : .spring(response: 0.5, dampingFraction: 0.85),
                    value: dragOffset
                )

            // Holographic shimmer overlay
            if phase == .carousel {
                // Velocity-driven shimmer for carousel
                let shimmerIntensity = min(abs(dragVelocity) / 400, 1.0)
                let lightX = 0.5 - Double(dragOffset) / 600.0

                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear,
                                      location: 0),
                                .init(color: .white.opacity(
                                        0.04 + shimmerIntensity * 0.12),
                                      location: max(0, lightX - 0.15)),
                                .init(color: .white.opacity(
                                        0.08 + shimmerIntensity * 0.22),
                                      location: lightX),
                                .init(color: .white.opacity(
                                        0.04 + shimmerIntensity * 0.12),
                                      location: min(1, lightX + 0.15)),
                                .init(color: .clear,
                                      location: 1),
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        )
                    )
                    .blendMode(.screen)
                    .allowsHitTesting(false)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .animation(
                        isDragging ? .none : .easeOut(duration: 0.3),
                        value: dragOffset
                    )
            } else if specularActive {
                // Static specular glint for lifted phase
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0),
                                .init(color: .white.opacity(
                                        isLight ? 0.14 : 0.08),
                                      location: 0.35),
                                .init(color: .white.opacity(
                                        isLight ? 0.28 : 0.20),
                                      location: 0.50),
                                .init(color: .white.opacity(
                                        isLight ? 0.14 : 0.08),
                                      location: 0.65),
                                .init(color: .clear, location: 1),
                            ],
                            startPoint: .init(
                                x: specularPhase * 1.4 - 0.4, y: 0),
                            endPoint: .init(
                                x: specularPhase * 1.4 - 0.1, y: 1)
                        )
                    )
                    .blendMode(.screen)
                    .allowsHitTesting(false)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
        // Carousel offset + lift
        .offset(
            x: phase == .carousel
                ? (isExiting
                    ? CGFloat(exitDirection) * -360
                    : dragOffset * 0.88)
                : 0,
            y: phase == .lifted || phase == .carousel ? -24 : 0
        )
        .scaleEffect(
            phase == .lifted
                ? 1.04
                : phase == .carousel
                    ? max(1.0 - abs(dragOffset) * 0.0003, 0.94)
                    : 1.0
        )
        .opacity(isExiting ? 0 : 1)
        .shadow(
            color: (activeCard?.difficulty.glowColor ?? AppColors.purple)
                .opacity(
                    phase == .lifted || phase == .carousel ? 0.35 : 0
                ),
            radius: 40, y: 20
        )
        .shadow(
            color: .black.opacity(
                phase == .lifted || phase == .carousel ? 0.5 : 0
            ),
            radius: 16, y: 12
        )
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.2)
                : .spring(response: 0.55, dampingFraction: 0.72),
            value: phase
        )
        .animation(
            isDragging
                ? .none
                : .spring(response: 0.35, dampingFraction: 0.82),
            value: dragOffset
        )
        .onTapGesture {
            handleSpreadTap()
        }
        .transition(.opacity.animation(
            .easeIn(duration: 0.25)))
    }

    // MARK: - Peek Cards

    @ViewBuilder
    private var peekCards: some View {
        // Previous — left edge
        if phase == .carousel && activeIndex > 0 {
            let offsetX: CGFloat = -(300 + 16) + dragOffset * 0.25
            let peekView = CardBackView(
                offsetX:  0,
                offsetY:  0,
                rotation: 4,
                scale:    0.88,
                opacity:  0.55,
                isLight:  isLight
            )

            carouselCardModifiers(peekView, cardOffset: offsetX)
                .offset(x: offsetX)
                .animation(
                    isDragging
                        ? .none
                        : .spring(response: 0.35, dampingFraction: 0.82),
                    value: dragOffset
                )
                .onTapGesture { navigateCarousel(direction: .prev) }
                .accessibilityLabel(
                    "Previous card: \(cards[activeIndex - 1].text)"
                )
                .zIndex(5)
        }

        // Next — right edge
        if phase == .carousel && activeIndex < cards.count - 1 {
            let offsetX: CGFloat = (300 + 16) + dragOffset * 0.25
            let peekView = CardBackView(
                offsetX:  0,
                offsetY:  0,
                rotation: -4,
                scale:    0.88,
                opacity:  0.55,
                isLight:  isLight
            )

            carouselCardModifiers(peekView, cardOffset: offsetX)
                .offset(x: offsetX)
                .animation(
                    isDragging
                        ? .none
                        : .spring(response: 0.35, dampingFraction: 0.82),
                    value: dragOffset
                )
                .onTapGesture { navigateCarousel(direction: .next) }
                .accessibilityLabel(
                    "Next card: \(cards[activeIndex + 1].text)"
                )
                .zIndex(5)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if let card = activeCard {
                HStack(spacing: 10) {
                    actionButton(
                        label: "✓ Discussed",
                        color: AppColors.cyan
                    ) {
                        onCardAction?(card, .discussed)
                    }
                    .accessibilityLabel("Mark as Discussed")

                    actionButton(
                        label: "→ Not Ready",
                        color: AppColors.textTertiary
                    ) {
                        onCardAction?(card, .notReady)
                    }
                    .accessibilityLabel("Skip — not ready")

                    actionButton(
                        label: "🔖",
                        color: AppColors.gold
                    ) {
                        onCardAction?(card, .bookmark)
                    }
                    .accessibilityLabel("Bookmark")
                    .frame(width: 48)
                }
                .padding(.horizontal, 20)
            }

            Button {
                if phase == .carousel {
                    handleBackToDeck()
                } else {
                    handleBrowseDeck()
                }
            } label: {
                Text(phase == .carousel
                     ? "← Back to deck"
                     : "Browse Deck")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Action Button Helper

    private func actionButton(
        label: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(AppFonts.caption)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.20), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 5) {
            ForEach(cards.indices, id: \.self) { i in
                Capsule()
                    .fill(
                        i == activeIndex
                            ? AnyShapeStyle(LinearGradient(
                                colors: cards[i].difficulty.glowColor
                                    == AppColors.cyan
                                    ? [AppColors.cyan,    AppColors.purple]
                                    : cards[i].difficulty.glowColor
                                        == AppColors.purple
                                        ? [AppColors.purple,  AppColors.magenta]
                                        : [AppColors.magenta, AppColors.pink],
                                startPoint: .leading,
                                endPoint:   .trailing))
                            : AnyShapeStyle(
                                AppColors.textTertiary.opacity(0.35))
                    )
                    .frame(width: i == activeIndex ? 20 : 4, height: 3)
                    .animation(
                        .spring(response: 0.35, dampingFraction: 0.8),
                        value: activeIndex
                    )
                    .onTapGesture { activeIndex = i }
            }
        }
    }

    // MARK: - Specular Glint

    func triggerSpecularGlint() {
        guard !reduceMotion else { return }
        specularPhase  = 0
        specularActive = true
        withAnimation(.timingCurve(0.4, 0, 0.6, 1, duration: 0.75)) {
            specularPhase = 1.0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            specularActive = false
            specularPhase  = 0
        }
    }

    // MARK: - Phase Transitions

    func handleSpreadTap() {
        guard phase == .spread else { return }

        if reduceMotion {
            phase = .lifted
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            return
        }

        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.45)) {
            phase = .gathering
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                phase = .lifted
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            triggerSpecularGlint()
        }
    }

    func handleBrowseDeck() {
        let animation: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.4, dampingFraction: 0.85)
        withAnimation(animation) { phase = .carousel }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func handleBackToDeck() {
        let animation: Animation = reduceMotion
            ? .easeOut(duration: 0.2)
            : .spring(response: 0.4, dampingFraction: 0.85)
        withAnimation(animation) {
            phase       = .lifted
            activeIndex = 0
            dragOffset  = 0
        }
    }

    // MARK: - Carousel Navigation

    func navigateCarousel(direction: CarouselDirection) {
        let next = direction == .next
            ? min(activeIndex + 1, cards.count - 1)
            : max(activeIndex - 1, 0)

        guard next != activeIndex else {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                dragOffset = 0
            }
            return
        }

        if reduceMotion {
            activeIndex = next
            dragOffset  = 0
            UISelectionFeedbackGenerator().selectionChanged()
            return
        }

        // Fly current card out
        withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.22)) {
            dragOffset = direction == .next ? -320 : 320
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            activeIndex = next
            dragOffset  = 0
            UISelectionFeedbackGenerator().selectionChanged()
            triggerSpecularGlint()
        }
    }
}

// MARK: - Previews

#Preview("Spread — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        HomeCardCarousel(cards: Prompt.samples)
    }
    .preferredColorScheme(.dark)
}

#Preview("Spread — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        HomeCardCarousel(cards: Prompt.samples)
    }
    .preferredColorScheme(.light)
}
