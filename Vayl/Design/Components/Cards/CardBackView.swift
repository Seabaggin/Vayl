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
    let cardSize:            CGSize
    let cornerRadius:        CGFloat
    let selectedPill:        CardRevealPill?
    let selectedScale:       CGFloat
    let selectedBorderWidth: CGFloat
    let unselectedVisible:   Bool
    let revealed:            Bool
    let isLight:             Bool
    let onSelect:            (CardRevealPill) -> Void
    let questionVisible:     Bool
    let pillsVisible:        Bool

    // ── Deck mode flag ───────────────────────────────────────────────────
    // Set to true by the deck-mode init. Suppresses all interactive
    // content and renders only the card shell + watermark.
    private let deckMode: Bool

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Init 1: Full interactive (onboarding ConversationCard)
    // Identical to the original — zero call-site changes required.
    // ─────────────────────────────────────────────────────────────────────
    init(
        cardSize:            CGSize,
        cornerRadius:        CGFloat,
        selectedPill:        CardRevealPill?,
        selectedScale:       CGFloat,
        selectedBorderWidth: CGFloat,
        unselectedVisible:   Bool,
        revealed:            Bool,
        isLight:             Bool,
        onSelect:            @escaping (CardRevealPill) -> Void,
        questionVisible:     Bool,
        pillsVisible:        Bool
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
        offsetX:  CGFloat = 0,
        offsetY:  CGFloat = 0,
        rotation: Double  = 0,
        scale:    CGFloat = 1.0,
        opacity:  Double  = 1.0,
        isLight:  Bool    = false
    ) {
        // Fixed deck geometry
        self.cardSize            = CGSize(width: 300, height: 190)
        self.cornerRadius        = 20
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
    private let _deckOffsetX:  CGFloat
    private let _deckOffsetY:  CGFloat
    private let _deckRotation: Double
    private let _deckScale:    CGFloat
    private let _deckOpacity:  Double

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
                            ? [AppColors.magenta.opacity(0.06), Color.clear]
                            : [AppColors.purple.opacity(0.15),  Color.clear],
                        center:      UnitPoint(x: 0.7, y: 0.8),
                        startRadius: 0,
                        endRadius:   180
                    )
                )

            // ── Border ────────────────────────────────────────────────────
            if isLight {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        AppColors.warmAuroraBorder,
                        lineWidth: selectedBorderWidth
                    )
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                        AppColors.spectrumBorder,
                        lineWidth: selectedBorderWidth
                    )
            }

            // ── ∞ Watermark (always visible) ──────────────────────────────
            // Shown in both deck mode and interactive mode.
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("∞")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(
                            isLight
                                ? AppColors.purple.opacity(0.08)
                                : AppColors.purple.opacity(0.10)
                        )
                        .padding(14)
                        .allowsHitTesting(false)
                }
            }

            // ── Interactive content — suppressed in deck mode ─────────────
            if !deckMode {
                VStack(spacing: 0) {

                    // Heading
                    VStack(spacing: 6) {
                        Text("Something came up.")
                            .font(AppFonts.body(20, weight: .semibold))
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightCardTitle
                                    : AppColors.textPrimary
                            )
                            .multilineTextAlignment(.center)

                        Text("What's it closest to?")
                            .font(AppFonts.caption)
                            .foregroundStyle(
                                isLight
                                    ? AppColors.lightCardTitle.opacity(0.50)
                                    : AppColors.textSecondary
                            )
                    }
                    .padding(.top, 24)
                    .opacity(revealed ? 1 : 0)
                    .offset(y: revealed ? 0 : 6)
                    .animation(.easeOut(duration: 0.3), value: revealed)

                    Spacer()

                    // Pills
                    VStack(spacing: 8) {
                        ForEach(
                            Array(CardRevealPill.allCases.enumerated()),
                            id: \.element
                        ) { index, pill in
                            Button {
                                guard selectedPill == nil else { return }
                                UIImpactFeedbackGenerator(style: .light)
                                    .impactOccurred()
                                onSelect(pill)
                            } label: {
                                Text(pill.rawValue)
                                    .font(AppFonts.bodyMedium)
                                    .foregroundStyle(
                                        selectedPill == pill
                                            ? (isLight
                                                ? AppColors.lightCardTitle
                                                : AppColors.textPrimary)
                                            : (isLight
                                                ? AppColors.lightBodyWineDark
                                                : Color.white.opacity(0.75))
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(
                                        Capsule()
                                            .fill(
                                                selectedPill == pill
                                                    ? (isLight
                                                        ? AnyShapeStyle(AppColors.lightFrostPillSel)
                                                        : AnyShapeStyle(Color.white.opacity(0.10)))
                                                    : (isLight
                                                        ? AnyShapeStyle(AppColors.lightFrostPill)
                                                        : AnyShapeStyle(AppColors.cardBg))
                                            )
                                    )
                                    .overlay(
                                        Group {
                                            if selectedPill == pill {
                                                if isLight {
                                                    Capsule()
                                                        .strokeBorder(
                                                            AppColors.warmAuroraBorder,
                                                            lineWidth: 2.0
                                                        )
                                                } else {
                                                    Capsule()
                                                        .strokeBorder(
                                                            AppColors.spectrumBorder,
                                                            lineWidth: 2.0
                                                        )
                                                }
                                            } else {
                                                Capsule()
                                                    .strokeBorder(
                                                        isLight
                                                            ? AppColors.lightBorder
                                                            : AppColors.border,
                                                        lineWidth: 1.5
                                                    )
                                            }
                                        }
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(
                                selectedPill == pill ? selectedScale : 1.0
                            )
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.7),
                                value: selectedScale
                            )
                            .opacity({
                                if selectedPill != nil && selectedPill != pill {
                                    return unselectedVisible ? 1 : 0
                                }
                                return revealed ? 1 : 0
                            }())
                            .offset(y: revealed ? 0 : 10)
                            .animation(
                                .easeOut(duration: 0.3)
                                    .delay(Double(index) * 0.07 + 0.12),
                                value: revealed
                            )
                            .animation(
                                .easeIn(duration: 0.35),
                                value: unselectedVisible
                            )
                            .disabled(
                                selectedPill != nil && selectedPill != pill
                            )
                            .background(
                                Capsule()
                                    .fill(
                                        isLight
                                            ? AppColors.lightFrostPill
                                            : AppColors.cardBg
                                    )
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer()

                    Text("✦")
                        .font(AppFonts.overline)
                        .foregroundStyle(
                            isLight
                                ? AppColors.lightTextTertiary.opacity(0.5)
                                : AppColors.textTertiary.opacity(0.5)
                        )
                        .opacity(revealed ? 0.6 : 0)
                        .animation(
                            .easeOut(duration: 0.4).delay(0.5),
                            value: revealed
                        )
                        .padding(.bottom, 24)
                }
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

    // MARK: - Card fill

    private var cardFill: some ShapeStyle {
        isLight
            ? AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 1.00, green: 0.99, blue: 1.00),
                    Color(red: 0.98, green: 0.97, blue: 0.99),
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing))
            : AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 0.051, green: 0.043, blue: 0.122),
                    Color(red: 0.031, green: 0.024, blue: 0.094),
                ],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing))
    }
}

// MARK: - Previews

#Preview("Interactive mode — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        CardBackView(
            cardSize:            CGSize(width: 340, height: 420),
            cornerRadius:        20,
            selectedPill:        nil,
            selectedScale:       1.0,
            selectedBorderWidth: 1.5,
            unselectedVisible:   true,
            revealed:            true,
            isLight:             false,
            onSelect:            { _ in },
            questionVisible:     true,
            pillsVisible:        true
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("Deck mode — spread fan — dark") {
    ZStack {
        AppColors.pageBg.ignoresSafeArea()
        ZStack {
            CardBackView(offsetX: -60, offsetY: 8,
                         rotation: -12, scale: 0.95, opacity: 0.70)
            CardBackView(offsetX: -30, offsetY: 4,
                         rotation: -6,  scale: 0.97, opacity: 0.80)
            CardBackView(offsetX:   0, offsetY: 0,
                         rotation:  0,  scale: 0.98, opacity: 1.00)
            CardBackView(offsetX:  30, offsetY: 4,
                         rotation:  6,  scale: 0.97, opacity: 0.80)
            CardBackView(offsetX:  60, offsetY: 8,
                         rotation:  12, scale: 0.95, opacity: 0.70)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Deck mode — gathered stack — light") {
    ZStack {
        AppColors.lightPageBg.ignoresSafeArea()
        ZStack {
            CardBackView(offsetY: 12, scale: 0.930,
                         opacity: 0.42, isLight: true)
            CardBackView(offsetY:  8, scale: 0.960,
                         opacity: 0.56, isLight: true)
            CardBackView(offsetY:  5, scale: 0.975,
                         opacity: 0.68, isLight: true)
            CardBackView(offsetY:  2, scale: 0.985,
                         opacity: 0.80, isLight: true)
        }
    }
    .preferredColorScheme(.light)
}
