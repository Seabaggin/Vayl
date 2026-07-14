//
//  CardBackView.swift
//  Open Lightly
//
//  Decorative deck-back shell used by CardCarousel's backing/fan cards.
//  Renders only: card shell fill + border + ∞ watermark.
//

import SwiftUI

struct CardBackView: View {
    let cardSize: CGSize
    let cornerRadius: CGFloat
    let isLight: Bool

    // ─────────────────────────────────────────────────────────────────────
    // MARK: - Init (CardCarousel decorative backing)
    //
    // Usage:
    //   CardBackView(offsetX: -60, offsetY: 8, rotation: -12,
    //                scale: 0.95, opacity: 0.45, isLight: isLight)
    // ─────────────────────────────────────────────────────────────────────
    init(
        offsetX: CGFloat = 0,
        offsetY: CGFloat = 0,
        rotation: Double  = 0,
        scale: CGFloat = 1.0,
        opacity: Double  = 1.0,
        isLight: Bool    = false
    ) {
        self.cardSize     = CGSize(width: 300, height: 190)
        self.cornerRadius = AppRadius.container
        self.isLight      = isLight
        self._deckOffsetX = offsetX
        self._deckOffsetY = offsetY
        self._deckRotation = rotation
        self._deckScale    = scale
        self._deckOpacity  = opacity
    }

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
                .strokeBorder(AppColors.spectrumBorder, lineWidth: 1.0)

            // ── ∞ Watermark ───────────────────────────────────────────────
            watermark
        }
        .frame(width: cardSize.width, height: cardSize.height)
        .offset(x: _deckOffsetX, y: _deckOffsetY)
        .rotationEffect(.degrees(_deckRotation))
        .scaleEffect(_deckScale)
        .opacity(_deckOpacity)
    }

    // MARK: - Body subviews

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
