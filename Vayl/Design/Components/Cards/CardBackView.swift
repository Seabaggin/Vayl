//
//  CardBackView.swift
//  Open Lightly
//
//  Two inits:
//  1. Full interactive init — used by onboarding ConversationCard (unchanged)
//  2. Deck mode init — decorative only, used by HomeCardCarousel
//

import SwiftUI

struct CardBackView: View {
    let cardSize: CGSize
    let cornerRadius: CGFloat
    let selectedPill: CardRevealPill?
    let selectedScale: CGFloat
    let selectedBorderWidth: CGFloat
    let unselectedVisible: Bool
    let revealed: Bool
    let isLight: Bool
    let onSelect: (CardRevealPill) -> Void
    let questionVisible: Bool
    let pillsVisible: Bool

    // ── Deck mode flag ───────────────────────────────────────────────────
    // Set to true by the deck-mode init. Suppresses all interactive
    // content and renders only the card shell + watermark.
    private let deckMode: Bool

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Init 1: Full interactive (onboarding ConversationCard)
    // Identical to the original — zero call-site changes required.
    // ─────────────────────────────────────────────────────────────────────
    init(
        cardSize: CGSize,
        cornerRadius: CGFloat,
        selectedPill: CardRevealPill?,
        selectedScale: CGFloat,
        selectedBorderWidth: CGFloat,
        unselectedVisible: Bool,
        revealed: Bool,
        isLight: Bool,
        onSelect: @escaping (CardRevealPill) -> Void,
        questionVisible: Bool,
        pillsVisible: Bool
    ) {
        self.cardSize            = cardSize
        self.cornerRadius        = cornerRadius
        self.selectedPill        = selectedPill
        self.selectedScale       = selectedScale
        self.selectedBorderWidth = selectedBorderWidth
        self.unselectedVisible   = unselectedVisible
        self.revealed            = revealed
        self.isLight             = isLight
        self.onSelect            = onSelect
        self.questionVisible     = questionVisible
        self.pillsVisible        = pillsVisible
        self.deckMode            = false
        // ── Deck positioning — neutral in interactive mode ──────────────
        self._deckOffsetX        = 0
        self._deckOffsetY        = 0
        self._deckRotation       = 0
        self._deckScale          = 1.0
        self._deckOpacity        = 1.0
    }

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Init 2: Deck mode (HomeCardCarousel decorative backing)
    //
    // Usage:
    //   CardBackView(offsetX: -60, offsetY: 8, rotation: -12,
    //                scale: 0.95, opacity: 0.45, isLight: isLight)
    //
    // Renders only: card shell fill + border + ∞ watermark.
    // All pill / reveal / heading content is suppressed.
    // ─────────────────────────────────────────────────────────────────────
    init(
        offsetX: CGFloat = 0,
        offsetY: CGFloat = 0,
        rotation: Double  = 0,
        scale: CGFloat = 1.0,
        opacity: Double  = 1.0,
        isLight: Bool    = false
    ) {
        // Fixed deck geometry
        self.cardSize            = CGSize(width: 300, height: 190)
        self.cornerRadius        = AppRadius.container
        // Suppress all interactive state
        self.selectedPill        = nil
        self.selectedScale       = 1.0
        self.selectedBorderWidth = 1.0
        self.unselectedVisible   = false
        self.revealed            = false
        self.isLight             = isLight
        self.onSelect            = { _ in }
        self.questionVisible     = false
        self.pillsVisible        = false
        self.deckMode            = true
        // Store positioning so the body can apply them
        self._deckOffsetX        = offsetX
        self._deckOffsetY        = offsetY
        self._deckRotation       = rotation
        self._deckScale          = scale
        self._deckOpacity        = opacity
    }

    // Deck positioning — only populated by the deck-mode init.
    // Prefixed with _ to signal they are internal layout values.
    private let _deckOffsetX: CGFloat
    private let _deckOffsetY: CGFloat
    private let _deckRotation: Double
    private let _deckScale: CGFloat
    private let _deckOpacity: Double

    // MARK: - Body

    var body: some View {
        ZStack {
            // ── Base fill ─────────────────────────────────────────────────
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(cardFill)

            // ── Ambient wash ──────────────────────────────────────────────
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    RadialGradient(
                        colors: isLight
                            ? [AppColors.accentTertiary.opacity(0.06), Color.clear]
                            : [AppColors.accentSecondary.opacity(0.15), Color.clear],
                        center: UnitPoint(x: 0.7, y: 0.8),
                        startRadius: 0,
                        endRadius: 180
                    )
                )

            // ── Border ────────────────────────────────────────────────────
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(AppColors.spectrumBorder, lineWidth: selectedBorderWidth)

            // ── ∞ Watermark (always visible) ──────────────────────────────
            // Shown in both deck mode and interactive mode.
            watermark

            // ── Interactive content — suppressed in deck mode ─────────────
            if !deckMode {
                interactiveContent
            } // end !deckMode
        }
        .frame(width: cardSize.width, height: cardSize.height)
        // ── Deck-mode positioning ─────────────────────────────────────────
        // In interactive mode these are all neutral (0 / 1.0 / 1.0)
        // so they have zero visual effect on existing call sites.
        .offset(x: _deckOffsetX, y: _deckOffsetY)
        .rotationEffect(.degrees(_deckRotation))
        .scaleEffect(_deckScale)
        .opacity(deckMode ? _deckOpacity : 1.0)
        // Shadows — only on interactive mode; deck mode uses caller-side shadow
        .if(!deckMode) { $0.cardShadows(isLight: isLight) }
    }

    // MARK: - Body subviews
    // Extracted from `body` so each is type-checked in isolation — the inline
    // ZStack with its nested isLight/selectedPill ternaries was 537ms.

    private var watermark: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("∞")
                    .font(AppFonts.body(28, weight: .regular, relativeTo: .title))
                    .foregroundStyle(
                        isLight
                            ? AppColors.accentSecondary.opacity(0.08)
                            : AppColors.accentSecondary.opacity(0.10)
                    )
                    .padding(AppSpacing.md)
                    .allowsHitTesting(false)
            }
        }
    }

    private var interactiveContent: some View {
        VStack(spacing: 0) {
            heading
                .padding(.top, AppSpacing.lg)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 6)
                .animation(AppAnimation.standard, value: revealed)

            Spacer()

            VStack(spacing: AppSpacing.sm) {
                ForEach(Array(CardRevealPill.allCases.enumerated()), id: \.element) { index, pill in
                    pillButton(index: index, pill: pill)
                }
            }
            .padding(.horizontal, AppSpacing.md)

            Spacer()

            Text("✦")
                .font(AppFonts.overline)
                .foregroundStyle(AppColors.textTertiary.opacity(0.5))
                .opacity(revealed ? 0.6 : 0)
                .animation(AppAnimation.enter.delay(0.5), value: revealed)
                .padding(.bottom, AppSpacing.lg)
        }
    }

    private var heading: some View {
        let titleColor: Color = isLight ? AppColors.textBody : AppColors.textPrimary
        let subtitleColor: Color = isLight ? AppColors.textBody.opacity(0.50) : AppColors.textSecondary

        return VStack(spacing: AppSpacing.xs) {
            Text("Something came up.")
                .font(AppFonts.body(20, weight: .semibold, relativeTo: .title3))
                .foregroundStyle(titleColor)
                .multilineTextAlignment(.center)

            Text("What's it closest to?")
                .font(AppFonts.caption)
                .foregroundStyle(subtitleColor)
        }
    }

    private func pillButton(index: Int, pill: CardRevealPill) -> some View {
        let isSelected: Bool = selectedPill == pill
        let dimmed: Bool     = selectedPill != nil && selectedPill != pill

        let textColor: Color = isSelected
            ? (isLight ? AppColors.textBody : AppColors.textPrimary)
            : (isLight ? AppColors.textSecondary : Color.white.opacity(0.75))

        let fillStyle: AnyShapeStyle = isSelected
            ? (isLight ? AnyShapeStyle(AppColors.glassFrostPillSelected) : AnyShapeStyle(Color.white.opacity(0.10)))
            : (isLight ? AnyShapeStyle(AppColors.glassFrostPill) : AnyShapeStyle(AppColors.cardBackground))

        let borderWidth: CGFloat = isSelected ? 2.0 : 1.5
        let borderStyle: AnyShapeStyle = isSelected
            ? AnyShapeStyle(AppColors.spectrumBorder)
            : AnyShapeStyle(AppColors.borderSubtle)

        let pillOpacity: Double = dimmed ? (unselectedVisible ? 1 : 0) : (revealed ? 1 : 0)

        return Button {
            guard selectedPill == nil else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            onSelect(pill)
        } label: {
            Text(pill.rawValue)
                .font(AppFonts.bodyMedium)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Capsule().fill(fillStyle))
                .overlay(
                    Capsule().strokeBorder(borderStyle, lineWidth: borderWidth)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? selectedScale : 1.0)
        .animation(AppAnimation.spring, value: selectedScale)
        .opacity(pillOpacity)
        .offset(y: revealed ? 0 : 10)
        .animation(AppAnimation.standard.delay(Double(index) * 0.07 + 0.12), value: revealed)
        .animation(AppAnimation.standard, value: unselectedVisible)
        .disabled(dimmed)
        .background(
            Capsule().fill(isLight ? AppColors.glassFrostPill : AppColors.cardBackground)
        )
    }

    // MARK: - Card fill

    private var cardFill: some ShapeStyle {
        isLight
            ? AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.99, blue: 1.00),
                    Color(red: 0.98, green: 0.97, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing))
            : AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 0.051, green: 0.043, blue: 0.122),
                    Color(red: 0.031, green: 0.024, blue: 0.094)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing))
    }
}

// MARK: - Previews

#Preview("Interactive mode — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        CardBackView(
            cardSize: CGSize(width: 340, height: 420),
            cornerRadius: 20,
            selectedPill: nil,
            selectedScale: 1.0,
            selectedBorderWidth: 1.5,
            unselectedVisible: true,
            revealed: true,
            isLight: false,
            onSelect: { _ in },
            questionVisible: true,
            pillsVisible: true
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Deck mode — spread fan — dark") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ZStack {
            CardBackView(offsetX: -60, offsetY: 8,
                         rotation: -12, scale: 0.95, opacity: 0.70)
            CardBackView(offsetX: -30, offsetY: 4,
                         rotation: -6, scale: 0.97, opacity: 0.80)
            CardBackView(offsetX: 0, offsetY: 0,
                         rotation: 0, scale: 0.98, opacity: 1.00)
            CardBackView(offsetX: 30, offsetY: 4,
                         rotation: 6, scale: 0.97, opacity: 0.80)
            CardBackView(offsetX: 60, offsetY: 8,
                         rotation: 12, scale: 0.95, opacity: 0.70)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Deck mode — gathered stack — light") {
    ZStack {
        AppColors.pageBackground.ignoresSafeArea()
        ZStack {
            CardBackView(offsetY: 12, scale: 0.930,
                         opacity: 0.42, isLight: true)
            CardBackView(offsetY: 8, scale: 0.960,
                         opacity: 0.56, isLight: true)
            CardBackView(offsetY: 5, scale: 0.975,
                         opacity: 0.68, isLight: true)
            CardBackView(offsetY: 2, scale: 0.985,
                         opacity: 0.80, isLight: true)
        }
    }
    .preferredColorScheme(.light)
}
