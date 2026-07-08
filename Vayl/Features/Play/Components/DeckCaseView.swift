//
//  DeckCaseView.swift
//  Vayl — Play
//
//  A deck's sealed case for the WALL — a bespoke, fully STATIC holo-hex render
//  (no .metal shader, no TimelineView, no per-frame work), so a whole grid of
//  them stays cheap to scroll. Distilled from the mockup's `.dcase` recipe and
//  the 3D `MetallicCaseView` foil look: a hue-tinted anodized base + a debossed
//  honeycomb lattice (lit from the top) + a top catch-light + the 2-pass
//  spectrum frame. No category glyph anywhere (deck-circle-lock mockup ruling:
//  the deck identifies itself by title and colorway, not an icon). Each deck's
//  colorway (category spectrum slice + per-deck hue nudge) tints the metal +
//  frame, so no two cases look identical.
//
//  Tiering (free vs Core, no coming-soon): locked cases drop the hex lattice
//  (plain dormant metal) and carry one engraved word — LOCKED — debossed into
//  the metal with the spectrum poured into the letterform. No badge, no icon,
//  no dimming. Title/meta sit underneath in `DeckCellView`. Tap → the real
//  animated 3D `MetallicCaseView` (detail / ceremony) — this static view is
//  the grid render only.
//

import SwiftUI

struct DeckCaseView: View {
    let summary: DeckSummary
    let style: DeckStyle
    /// Live lock state threaded in from the wall/detail (PlayStore.isLocked —
    /// catalog flag AND not Core). nil falls back to the frozen catalog flag
    /// (previews / storeless call sites only).
    var lockedOverride: Bool?

    private var locked: Bool { lockedOverride ?? summary.isLocked }

    /// Pointy-top unit hexagon vertices (center → vertex), scaled by the cell radius.
    private static let hexUnit: [CGPoint] = [
        CGPoint(x: 0.0000000, y: -1.0),
        CGPoint(x: 0.8660254, y: -0.5),
        CGPoint(x: 0.8660254, y: 0.5),
        CGPoint(x: 0.0000000, y: 1.0),
        CGPoint(x: -0.8660254, y: 0.5),
        CGPoint(x: -0.8660254, y: -0.5)
    ]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let inset = min(w, h) * 0.05
            ZStack {
                metalBase(h)

                // Locked cases sleep: plain dormant metal, no lattice. The
                // engraving below is the whole locked signal.
                if !locked {
                    HexFoil(unit: Self.hexUnit, columns: 6, tint: style.colorway.c0)
                        .opacity(0.6)
                        .mask(LinearGradient(stops: [
                            .init(color: .white, location: 0.0),
                            .init(color: .white.opacity(0.42), location: 0.58),
                            .init(color: .white.opacity(0.12), location: 1.0)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                }

                sheen
                catchLight(w, h)
                bevelVignette(w, h, inset)
                spectrumFrame(inset: inset)

                if locked {
                    lockedEngraving(h)
                }
            }
            .compositingGroup()
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
            .drawingGroup()        // rasterize the static case to one texture → cheap to scroll
            .cardElevation()       // shadow stays OUTSIDE the group
        }
        .aspectRatio(1.0 / 1.2, contentMode: .fit)
    }

    // MARK: - Layers

    /// Anodized metal: a faint hue at the top edge falling to deep void, plus a
    /// soft top-center bloom in the deck's warm colorway end.
    private func metalBase(_ h: CGFloat) -> some View {
        ZStack {
            LinearGradient(stops: [
                .init(color: style.colorway.c1.opacity(0.20), location: 0.0),
                .init(color: AppColors.cardBackgroundRaised, location: 0.35),
                .init(color: AppColors.cardBg, location: 0.72),
                .init(color: AppColors.void, location: 1.0)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)

            RadialGradient(colors: [style.colorway.c2.opacity(0.26), .clear],
                           center: .top, startRadius: 0, endRadius: h * 0.66)
        }
    }

    /// Cool overhead key catching the top rim — the strongest "solid object" cue.
    private func catchLight(_ w: CGFloat, _ h: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            .fill(LinearGradient(colors: [AppColors.spectrumCyan.opacity(0.16), .clear],
                                 startPoint: .top, endPoint: .bottom))
            .frame(height: h * 0.36)
            .padding(.horizontal, w * 0.06)
            .padding(.top, h * 0.04)
            .frame(maxHeight: .infinity, alignment: .top)
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
    }

    /// A faint diagonal specular sweep — the foil catching light. Static.
    private var sheen: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0.30),
                .init(color: .white.opacity(0.05), location: 0.46),
                .init(color: .white.opacity(0.10), location: 0.50),
                .init(color: .white.opacity(0.05), location: 0.54),
                .init(color: .clear, location: 0.70)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    /// Depth: a corner vignette + an inner bevel (top-lit, bottom-shadowed) just inside
    /// the spectrum frame, so the case reads as a solid lit object rather than a flat box.
    private func bevelVignette(_ w: CGFloat, _ h: CGFloat, _ inset: CGFloat) -> some View {
        let r = max(2, AppRadius.obCard - inset)
        return ZStack {
            RadialGradient(
                colors: [.clear, AppColors.void.opacity(0.45)],
                center: .center,
                startRadius: min(w, h) * 0.30,
                endRadius: max(w, h) * 0.72
            )
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .stroke(
                    LinearGradient(colors: [.white.opacity(0.14), .clear, .black.opacity(0.22)],
                                   startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
                .padding(inset)
        }
        .allowsHitTesting(false)
    }

    /// Two-pass spectrum frame (blurred glow + crisp hairline), inset, colorway-tinted.
    private func spectrumFrame(inset: CGFloat) -> some View {
        let r = max(2, AppRadius.obCard - inset)
        let grad = LinearGradient(colors: [style.colorway.c0, style.colorway.c1, style.colorway.c2],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        return ZStack {
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .stroke(grad, lineWidth: 1.4)
                .blur(radius: 3)
                .opacity(0.5)
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .stroke(grad, lineWidth: 1.0)
                .opacity(0.9)
        }
        .padding(inset)
        .allowsHitTesting(false)
    }

    // MARK: - Locked engraving

    /// The word LOCKED, debossed into the metal with the app's spectrum poured
    /// into the cut letterform (deck-circle-lock mockup, `engraved-spectrum`):
    /// a dark shadow on the top edge (light blocked), a thin light catch on the
    /// bottom edge (bounced light) — recessed foil, not a raised badge.
    private func lockedEngraving(_ h: CGFloat) -> some View {
        Text("LOCKED")
            .font(AppFonts.overline)
            .tracking(3)
            .foregroundStyle(
                LinearGradient(
                    colors: [AppColors.spectrumCyan, AppColors.spectrumPurple, AppColors.spectrumMagenta],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .opacity(0.8)
            .shadow(color: AppColors.void.opacity(0.55), radius: 0, y: -1)
            .shadow(color: .white.opacity(0.10), radius: 0, y: 1)
            .padding(.top, h * 0.08)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .allowsHitTesting(false)
    }
}

/// Static debossed honeycomb — drawn ONCE in a Canvas (only on size change), no
/// per-frame work. Two faint offset strokes (white groove + colorway tint) read
/// as foil; the caller masks it brighter at the top so it reads as lit-from-above.
private struct HexFoil: View {
    let unit: [CGPoint]
    var columns: Double = 6
    var tint: Color

    var body: some View {
        Canvas { ctx, size in
            let cols = max(3, columns)
            let hw = size.width / cols              // horizontal center spacing = flat-to-flat width
            let radius = hw / 1.7320508             // pointy-top circumradius (hw = √3 · R)
            let rowH = radius * 1.5

            func hex(_ cx: Double, _ cy: Double) -> Path {
                var p = Path()
                for (i, u) in unit.enumerated() {
                    let pt = CGPoint(x: cx + Double(u.x) * radius, y: cy + Double(u.y) * radius)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
                return p
            }

            var grid = Path()
            var row = 0
            var y = -radius
            while y < Double(size.height) + radius {
                let xOffset = (row % 2 == 0) ? 0.0 : hw / 2
                var x = -hw + xOffset
                while x < Double(size.width) + hw {
                    grid.addPath(hex(x, y))
                    x += hw
                }
                y += rowH
                row += 1
            }

            ctx.stroke(grid, with: .color(AppColors.borderDefault), lineWidth: 0.6)
            ctx.translateBy(x: 0.5, y: 0.5)
            ctx.stroke(grid, with: .color(tint.opacity(0.06)), lineWidth: 0.6)
        }
    }
}

#if DEBUG
#Preview("Cases") {
    let samples = (try? DeckCatalogService().loadSummaries()) ?? []
    return ZStack {
        AppColors.void.ignoresSafeArea()
        ScrollView {
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: AppSpacing.lg) {
                ForEach(samples) { s in
                    DeckCaseView(summary: s, style: DeckStyle.make(for: s))
                }
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
#endif
