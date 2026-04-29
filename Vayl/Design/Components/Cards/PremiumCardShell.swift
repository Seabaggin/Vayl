//
//  PremiumCardShell.swift
//  Open Lightly

import SwiftUI

struct PremiumCardShell<Content: View>: View {
    let isLight: Bool
    var cornerRadius: CGFloat = 24.0
    var fuseProgress: Double = 0.0
    let content: Content

    init(
        isLight: Bool,
        cornerRadius: CGFloat = 24.0,
        fuseProgress: Double = 0.0,
        @ViewBuilder content: () -> Content
    ) {
        self.isLight = isLight
        self.cornerRadius = cornerRadius
        self.fuseProgress = fuseProgress
        self.content = content()
    }

    var body: some View {
        ZStack {
            // ── 1. Base fill ───────────────────────────────────────────
            // Dark: flat near-black — unified with Pulse/Prism/Beacon
            // Light: frosted white — lets aurora atmosphere bleed through
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(cardFill)

            // ── 2. Specular — top-left diagonal catch ─────────────────
            // Simulates light source from outside screen, top-left.
            // Dark: barely there (glass is dark tinted, absorbs light)
            // Light: dominant (cream surface reflects strongly)
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: isLight ? [
                            .init(color: .white.opacity(0.90), location: 0.00),
                            .init(color: .white.opacity(0.55), location: 0.15),
                            .init(color: .white.opacity(0.10), location: 0.35),
                            .init(color: .clear,               location: 0.55),
                        ] : [
                            .init(color: .white.opacity(0.08), location: 0.00),
                            .init(color: .white.opacity(0.03), location: 0.22),
                            .init(color: .clear,               location: 0.50),
                        ],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    )
                )

            // ── 3. Internal reflection — radial from top-left ─────────
            // Light entering from outside the screen bounces inside
            // the glass. Separate from specular — specular is the
            // surface, this is the interior volume.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: isLight
                            ? [.white.opacity(0.35), .clear]
                            : [.white.opacity(0.04), .clear],
                        center:      UnitPoint(x: 0.10, y: 0.08),
                        startRadius: 0,
                        endRadius:   120
                    )
                )

            // ── 4. Ambient orbs — card identity ───────────────────────
            // Two orbs define the card's color identity.
            // Top-right: primary accent, bleeds in from outside
            // Bottom-left: secondary accent, pools at base
            // Opacity halved in light mode — cream absorbs, aurora
            // atmosphere already provides color energy behind the card.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: isLight
                            ? [AppColors.magenta.opacity(0.07), .clear]
                            : [AppColors.purple.opacity(0.18),  .clear],
                        center:      UnitPoint(x: 0.80, y: 0.10),
                        startRadius: 0,
                        endRadius:   160
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: isLight
                            ? [AppColors.purple.opacity(0.05), .clear]
                            : [AppColors.cyan.opacity(0.10),   .clear],
                        center:      UnitPoint(x: 0.15, y: 0.88),
                        startRadius: 0,
                        endRadius:   120
                    )
                )

            // ── 5. Base shadow — physical thickness ───────────────────
            // Glass has depth. The bottom edge falls into shadow,
            // making the card feel like a slab, not a sticker.
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isLight
                            ? [.clear, .black.opacity(0.04)]
                            : [.clear, .black.opacity(0.28)],
                        startPoint: .init(x: 0.5, y: 0.65),
                        endPoint:   .bottom
                    )
                )

            // ── 6. Premium border — unchanged ─────────────────────────
            // Dark: cyan → purple → magenta (spectrumBorder)
            // Light: purple → magenta → gold (warmAuroraBorder)
            // Both include glow blur duplicate via PillBorder.swift
            if isLight {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.warmAuroraBorder, lineWidth: 2.5)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppColors.spectrumBorder, lineWidth: 2.5)
            }

            // ── 7. Fuse animation — unchanged ─────────────────────────
            if fuseProgress > 0 {
                burnCoverAndSpark
            }

            // ── 8. Content ────────────────────────────────────────────
            content
        }
        // Inset shadow — defines top edge catch and bottom base.
        // Applied on the ZStack so it sits outside the clip boundary
        // and renders against the page background correctly.
        .shadow(
            color: isLight
                ? AppColors.lightShadowMagenta.opacity(0.10)
                : .black.opacity(0.35),
            radius: isLight ? 16 : 32,
            y:      isLight ? 4  : 12
        )
        .shadow(
            color: isLight
                ? AppColors.lightShadowPurple.opacity(0.07)
                : AppColors.purple.opacity(0.08),
            radius: isLight ? 28 : 48,
            y:      isLight ? 8  : 18
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Card Fill

    private var cardFill: some ShapeStyle {
        isLight
            // Frosted white — aurora atmosphere bleeds through at the edges
            ? AnyShapeStyle(Color.white.opacity(0.55))
            // Flat near-black — unified with Pulse / Prism / Beacon glass spec
            : AnyShapeStyle(AppColors.cardBg)
    }

    // MARK: - Fuse Animation — untouched

    @ViewBuilder
    private var burnCoverAndSpark: some View {
        ZStack {
            Canvas { ctx, canvasSize in
                let rect = CGRect(x: 1.25, y: 1.25, width: canvasSize.width - 2.5, height: canvasSize.height - 2.5)
                let path = RoundedRectangle(cornerRadius: cornerRadius - 1.25).path(in: rect)

                let startOffset: Double = 0.75
                let end = startOffset + fuseProgress
                let strokeColor = isLight
                    ? Color.white.opacity(0.65)
                    : Color(red: 0.031, green: 0.027, blue: 0.055)

                if end <= 1.0 {
                    let consumed = path.trimmedPath(from: startOffset, to: end)
                    ctx.stroke(consumed, with: .color(strokeColor), style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
                } else {
                    let seg1 = path.trimmedPath(from: startOffset, to: 1.0)
                    let seg2 = path.trimmedPath(from: 0, to: end - 1.0)
                    ctx.stroke(seg1, with: .color(strokeColor), style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
                    ctx.stroke(seg2, with: .color(strokeColor), style: StrokeStyle(lineWidth: 4.0, lineCap: .round))
                }
            }

            if fuseProgress < 1.0 {
                Canvas { ctx, canvasSize in
                    let rect = CGRect(x: 1.25, y: 1.25, width: canvasSize.width - 2.5, height: canvasSize.height - 2.5)
                    let path = RoundedRectangle(cornerRadius: cornerRadius - 1.25).path(in: rect)

                    let startOffset: Double = 0.75
                    let sparkPos = (startOffset + fuseProgress).truncatingRemainder(dividingBy: 1.0)
                    let head = path.trimmedPath(from: max(0, sparkPos - 0.001), to: sparkPos)
                    guard let pt = head.currentPoint else { return }

                    let r = CGFloat(3.5)
                    let sparkRect = CGRect(x: pt.x - r, y: pt.y - r, width: r * 2, height: r * 2)

                    let sparkColor: Color = isLight ? AppColors.magenta : AppColors.cyan

                    var outerCtx = ctx
                    outerCtx.addFilter(.blur(radius: 6))
                    outerCtx.fill(Circle().path(in: sparkRect.insetBy(dx: -4, dy: -4)), with: .color(sparkColor.opacity(0.5)))

                    var midCtx = ctx
                    midCtx.addFilter(.blur(radius: 3))
                    midCtx.fill(Circle().path(in: sparkRect.insetBy(dx: -1, dy: -1)), with: .color(sparkColor.opacity(0.7)))

                    ctx.fill(Circle().path(in: sparkRect), with: .color(sparkColor))
                    ctx.fill(Circle().path(in: sparkRect.insetBy(dx: r * 0.45, dy: r * 0.45)), with: .color(.white.opacity(0.95)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
