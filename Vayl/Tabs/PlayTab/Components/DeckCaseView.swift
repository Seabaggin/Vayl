//
//  DeckCaseView.swift
//  Vayl — Play
//
//  A deck's case for the WALL — a bespoke, fully STATIC holo-hex render (no .metal
//  shader, no TimelineView, no per-frame Canvas work), so a whole LazyVGrid of them
//  stays cheap to scroll. Distilled from the mockup's `.dcase` recipe and the 3D
//  `MetallicCaseView` foil look: a hue-tinted anodized base + a debossed honeycomb
//  lattice (lit from the top) + a top catch-light + the 2-pass spectrum frame +
//  the deck title poured INSIDE the case in editorial serif. No category glyph
//  anywhere (deck-circle-lock ruling: the deck identifies itself by title +
//  colorway, not an icon). Each deck's colorway (category spectrum slice + per-deck
//  hue nudge) tints the metal + frame + title, so no two cases look identical.
//
//  Three static states (spec 2026-07-11 §6, richness increases locked → sealed →
//  opened), driven by `DeckDisplayState`:
//    • opened — hex lattice + full spectrum frame + full-opacity title, plus ONE
//               slow catch-light sweep drifting across the case (auraBreathe, the
//               living-surface tempo, gated OFF under Reduce Motion + Low Power).
//    • sealed — richer anodized metallic tone, NO hex (foil not yet knitted), full
//               frame + title, a slightly BRIGHTER static-feel sweep — the only
//               "new" cue (no dot/badge/count). A resting frame of the live
//               `MetallicCaseView`, so the ceremony's hand-off stays seamless.
//    • locked — dimmed dormant metal, NO hex, engraved-spectrum LOCKED, title +
//               frame at reduced opacity, NO sweep (dormant).
//
//  Only the sweep animates, and it lives ABOVE the `.drawingGroup()` so the lattice
//  never re-rasterizes. Everything else composites once. Tap routing / title-under
//  metadata live on the wall cell + PlayStore — this view is the grid render only.
//

import SwiftUI

struct DeckCaseView: View {
    let summary: DeckSummary
    let style: DeckStyle
    /// Which of the three static treatments to render. Store-derived
    /// (`PlayStore.deckState`) — the ONLY signal this view branches on.
    let state: DeckDisplayState

    /// The case's exact width; height is always `width × 1.5` (2:3). The view sizes
    /// itself from this — no internal `GeometryReader`. A greedy GeometryReader read
    /// the parent's proposed (unclamped) height, so `.drawingGroup()` rasterized the
    /// art taller than the layout frame and it spilled past the case onto the shelf.
    /// Callers pass a measured width (DeckWallView column / carousel thumbWidth).
    var width: CGFloat = 150

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        caseBody(tone: CaseTone.tone(for: state))
    }

    private func caseBody(tone: CaseTone) -> some View {
        let w = width, h = width * 1.5
        // ~6px at the wall case width → spectrum-frame radius = obCard(14) − 6 = 8,
        // matching the guidepost frameSVG (inset 6, rx 8). Concentric with the case.
        let inset = min(w, h) * 0.037
        return Group {
            ZStack {
                // Static, composited-once layer stack → one rasterized texture.
                ZStack {
                    metalBase(h, tone: tone)

                    // Opened cases wear the knitted foil lattice; sealed + locked
                    // do not (foil unknitted / dormant).
                    if tone.hexOn {
                        HexFoil(unit: Self.hexUnit, columns: 6, tint: style.colorway.c0)
                            .opacity(0.85)   // matches guidepost lattice alpha (was 0.6 → knit too faint)
                            .mask(LinearGradient(stops: [
                                .init(color: .white, location: 0.0),
                                .init(color: .white.opacity(0.42), location: 0.58),
                                .init(color: .white.opacity(0.12), location: 1.0)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }

                    // Sealed's extra anodized two-tone — the "metallic foil" richness
                    // over opened, held static (the live sheen is the ceremony's job).
                    if tone.anodized {
                        anodizedSheen
                    }

                    sheen
                    catchLight(w, h, cyan: tone.catchLight)
                    bevelVignette(w, h, inset)

                    // Locked's deliberate dimming (reverses the old "no dimming"
                    // note): a void scrim under the frame so LOCKED + title stay
                    // legible on top while the metal recedes.
                    if tone.dimScrim > 0 {
                        AppColors.void.opacity(tone.dimScrim)
                    }

                    spectrumFrame(inset: inset, glow: tone.frameGlow, crisp: tone.frameCrisp)
                }
                .compositingGroup()
                .drawingGroup()        // rasterize the static case to one texture → cheap to scroll

                // The one animated layer — per-cell hex glow (the guidepost's
                // `startShimmer`): random lattice cells ignite in the colorway and
                // fade. Sits ABOVE the drawingGroup so it animates without
                // re-rasterizing the static lattice, and only on hex (unlocked)
                // cases when ambient motion is allowed (Reduce Motion + Low Power
                // both remove it — the static hex reads complete).
                if tone.hexOn, !(reduceMotion || AppAnimation.lowPower) {
                    HexTwinkle(unit: Self.hexUnit, columns: 6,
                               c0: style.colorway.c0,
                               c1: style.colorway.c1,
                               c2: style.colorway.c2,
                               width: w)
                }
            }
            .frame(width: w, height: h)     // firm size — no GeometryReader to over-read
            // Title / LOCKED positioned via overlay alignment, NOT a greedy
            // `.frame(maxHeight:.infinity)`. That greedy fill inside the sized ZStack
            // collapsed the Text to zero area — the real reason the deck name never
            // rendered inside the case. An overlay places it deterministically.
            .overlay(alignment: .bottom) { inCaseTitle(h, opacity: tone.titleOpacity) }
            .overlay(alignment: .top) {
                if state == .locked { lockedEngraving(h) }
            }
            // Outer corner = the HTML `.case` radius (r-card 14). Concentric with
            // the spectrum frame (radius 8, inset 6) — the exact tuck-box geometry
            // the guidepost renders. Every state shares it, so all decks are one shape.
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.obCard, style: .continuous)
                    .strokeBorder(AppColors.borderSubtle, lineWidth: 1)
            )
            .cardElevation()       // shadow stays OUTSIDE the group
        }
    }

    // MARK: - Layers

    /// Anodized metal: a hue at the top edge falling to deep void, plus a soft
    /// top-center bloom in the deck's warm colorway end. `tone` scales the tint so
    /// sealed reads richer, locked reads dormant.
    private func metalBase(_ h: CGFloat, tone: CaseTone) -> some View {
        ZStack {
            LinearGradient(stops: [
                .init(color: style.colorway.c1.opacity(tone.topTint), location: 0.0),
                .init(color: AppColors.cardBackgroundRaised, location: 0.35),
                .init(color: AppColors.cardBg, location: 0.72),
                .init(color: AppColors.void, location: 1.0)
            ], startPoint: .topLeading, endPoint: .bottomTrailing)

            RadialGradient(colors: [style.colorway.c2.opacity(tone.bloom), .clear],
                           center: .top, startRadius: 0, endRadius: h * 0.66)
        }
    }

    /// Sealed-only anodized two-tone: a soft diagonal colorway wash (c0 → c2) that
    /// gives the foil a richer, more metallic cast than opened's bare metal. Static.
    private var anodizedSheen: some View {
        LinearGradient(
            stops: [
                .init(color: style.colorway.c0.opacity(0.18), location: 0.0),
                .init(color: .clear, location: 0.5),
                .init(color: style.colorway.c2.opacity(0.20), location: 1.0)
            ],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    /// Cool overhead key catching the top rim — the strongest "solid object" cue.
    /// `cyan` strength drops for locked (guidepost: 0.16 opened → 0.06 locked) so a
    /// dormant case doesn't get a full-strength top glow.
    private func catchLight(_ w: CGFloat, _ h: CGFloat, cyan: Double) -> some View {
        RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
            .fill(LinearGradient(colors: [AppColors.spectrumCyan.opacity(cyan), .clear],
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
    /// `glow` / `crisp` opacities drop for the locked (dormant) state.
    private func spectrumFrame(inset: CGFloat, glow: Double, crisp: Double) -> some View {
        let r = max(2, AppRadius.obCard - inset)
        let grad = LinearGradient(colors: [style.colorway.c0, style.colorway.c1, style.colorway.c2],
                                  startPoint: .topLeading, endPoint: .bottomTrailing)
        return ZStack {
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .stroke(grad, lineWidth: 1.4)
                .blur(radius: 3)
                .opacity(glow)
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .stroke(grad, lineWidth: 1.0)
                .opacity(crisp)
        }
        .padding(inset)
        .allowsHitTesting(false)
    }

    // MARK: - In-case title

    /// The deck title poured INTO the case face: editorial serif (`AppFonts.caseTitle`,
    /// Playfair Black), spectrum-gradient fill in the deck's colorway, bottom-anchored,
    /// centered, up to 3 lines. Full opacity for opened / sealed; ~0.4 for locked.
    private func inCaseTitle(_ h: CGFloat, opacity: Double) -> some View {
        Text(summary.title)
            .font(AppFonts.caseTitle)
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.7)
            .foregroundStyle(
                LinearGradient(colors: [style.colorway.c0, style.colorway.c1, style.colorway.c2],
                               startPoint: .leading, endPoint: .trailing)
            )
            .opacity(opacity)
            .padding(.horizontal, h * 0.06)
            .padding(.bottom, h * 0.09)   // guidepost .incase-title { bottom: 9% }
            .frame(maxWidth: .infinity)   // fill width for centering; overlay owns vertical placement
            .allowsHitTesting(false)
    }

    // MARK: - Locked engraving

    /// The word LOCKED, debossed into the metal with the app's spectrum poured into
    /// the cut letterform (deck-circle-lock mockup, `engraved-spectrum`): a dark
    /// shadow on the top edge (light blocked), a thin light catch on the bottom edge
    /// (bounced light) — recessed foil, not a raised badge.
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
            .opacity(0.85)
            // Debossed / cut-into-metal bevel: a crisp dark shadow on the TOP edge
            // (light blocked by the cut wall) + a light catch on the BOTTOM edge
            // (bounced light off the lower wall). Stronger offsets so it reads engraved
            // on the dormant metal, not printed on top.
            .shadow(color: AppColors.void.opacity(0.85), radius: 0, y: -1.2)
            .shadow(color: .white.opacity(0.22), radius: 0, y: 1.2)
            .shadow(color: AppColors.void.opacity(0.5), radius: 1.5, y: 0)
            .padding(.top, h * 0.08)
            .frame(maxWidth: .infinity)   // overlay(alignment: .top) owns vertical placement
            .allowsHitTesting(false)
    }
}

// MARK: - Per-state tone

/// Sweep intensity tier for the moving catch-light. `.none` = no animated layer.
private enum SweepMode { case none, subtle, bright }

/// The static differences between the three case treatments, in one place so the
/// body stays a straight read. Richness increases locked → sealed → opened.
private struct CaseTone {
    let topTint: Double        // colorway hue strength at the top edge of the metal
    let bloom: Double          // top-center colorway bloom strength
    let catchLight: Double     // top cyan catch-light strength (dormant → low)
    let dimScrim: Double       // void scrim over the metal (locked dormancy only)
    let frameGlow: Double      // spectrum frame's blurred-glow pass opacity
    let frameCrisp: Double     // spectrum frame's crisp-hairline pass opacity
    let hexOn: Bool            // knitted foil lattice (opened only)
    let anodized: Bool         // extra sealed two-tone metallic wash
    let titleOpacity: Double   // in-case title opacity
    let sweep: SweepMode       // moving catch-light tier

    static func tone(for state: DeckDisplayState) -> CaseTone {
        switch state {
        case .opened:
            // Guidepost non-locked values: tint 0.20, bloom 0.26, catch-light 0.16.
            return CaseTone(topTint: 0.20, bloom: 0.26, catchLight: 0.16, dimScrim: 0.0,
                            frameGlow: 0.5, frameCrisp: 0.9, hexOn: true,
                            anodized: false, titleOpacity: 1.0, sweep: .subtle)
        case .sealed:
            // The THIRD look — unlocked but not yet opened: a static approximation
            // of the ceremony's anodized MetallicCaseView. It KEEPS the hex (so
            // every unlocked deck reads with the knit — the consistency fix) but
            // wears a richer, darker anodized-metal cast (`anodized` two-tone + a
            // brighter metallic key + the bright glint sweep) so it reads as sealed
            // metal, distinct from the opened deck's lit-glass vibrancy. Same 2:3
            // footprint as every other case.
            return CaseTone(topTint: 0.30, bloom: 0.36, catchLight: 0.20, dimScrim: 0.0,
                            frameGlow: 0.45, frameCrisp: 0.80, hexOn: true,
                            anodized: true, titleOpacity: 1.0, sweep: .bright)
        case .locked:
            // Dormant. The vivid spectrum frame is what reads "active", so it drops
            // hard (glow 0.18 / crisp 0.32) — a faint outline, not a lit edge. Metal
            // stays dark (tint 0.06), catch-light low (0.06), in-case title recedes
            // (0.30). The engraved LOCKED is the one legible cue on dead metal.
            return CaseTone(topTint: 0.06, bloom: 0.10, catchLight: 0.06, dimScrim: 0.0,
                            frameGlow: 0.18, frameCrisp: 0.32, hexOn: false,
                            anodized: false, titleOpacity: 0.30, sweep: .none)
        }
    }
}

// MARK: - Static honeycomb

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

// MARK: - Live hex twinkle

/// Random lattice cells ignite in the deck colorway and fade, over the static HexFoil.
///
/// **Performance design:** all geometry, path objects, and color bridge calls are
/// pre-computed once at init from the known `width`. The per-frame Canvas loop only
/// iterates the ~6 active cells per card (sin + lerp + fill + stroke) — never the
/// full ~60-cell lattice. Six simultaneous instances on screen (LazyVGrid viewport
/// limit) cost roughly the same as the old single-pass version over the full lattice.
private struct HexTwinkle: View {
    let unit: [CGPoint]
    var columns: Double = 6
    let c0: Color, c1: Color, c2: Color
    /// Known at construction — the parent ZStack frames to `(w, w*1.5)` before mounting.
    let width: CGFloat

    @State private var birth = Date()

    // Pre-built once per view lifetime.
    private struct ActiveCell {
        let path: Path
        let phase: Double       // [0,1) stable per-cell offset into the cycle
        let colorFrac: Double   // drives lerp3 color selection
    }
    private let activeCells: [ActiveCell]
    private let colorStops: [(r: Double, g: Double, b: Double)]

    init(unit: [CGPoint], columns: Double = 6,
         c0: Color, c1: Color, c2: Color, width: CGFloat) {
        self.unit = unit; self.columns = columns
        self.c0 = c0; self.c1 = c1; self.c2 = c2; self.width = width
        // Bridge UIColor once here, never on the draw path.
        self.colorStops = [Self.comps(c0), Self.comps(c1), Self.comps(c2)]

        let w = Double(width), h = w * 1.5
        let cols = max(3, columns)
        let hw = w / cols
        let radius = hw / 1.7320508
        let rowH = radius * 1.5
        var built: [ActiveCell] = []
        var idx = 0, row = 0
        var y = -radius
        while y < h + radius {
            let xo = row % 2 == 0 ? 0.0 : hw / 2
            var x = -hw + xo
            while x < w + hw {
                let s = Double(idx)
                // ~1 in 12 cells breathes (≈4–5 per card). Seed 2.31 avoids
                // column-aligned clustering that 1.73 produced with the hex stride.
                if Self.fract(s * 2.31) < 0.08 {
                    var p = Path()
                    for (i, u) in unit.enumerated() {
                        let pt = CGPoint(x: x + Double(u.x) * radius,
                                         y: y + Double(u.y) * radius)
                        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                    }
                    p.closeSubpath()
                    built.append(ActiveCell(path: p,
                                            phase: Self.fract(s * 4.7),
                                            colorFrac: Self.fract(s * 5.9)))
                }
                x += hw; idx += 1
            }
            y += rowH; row += 1
        }
        self.activeCells = built
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            Canvas { ctx, _ in
                let elapsed = timeline.date.timeIntervalSince(birth)
                    .truncatingRemainder(dividingBy: 3600)
                for cell in activeCells {
                    // truncatingRemainder = real fractional part; Self.fract is the
                    // PRNG hash — wrong here, right for stable per-cell seeds above.
                    let localT = (elapsed / AppAnimation.auraBreathe + cell.phase)
                        .truncatingRemainder(dividingBy: 1.0)
                    let env = pow(sin(localT * .pi), 2)
                    guard env > 0.18 else { continue }
                    let br = (env - 0.18) / 0.82
                    let col = Self.lerp3(colorStops, cell.colorFrac)
                    ctx.opacity = br * 0.7
                    ctx.fill(cell.path, with: .color(col.opacity(0.10)))
                    ctx.stroke(cell.path, with: .color(col), lineWidth: 0.8)
                }
            }
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
        }
    }

    /// Deterministic fractional hash — the per-cell PRNG (stable every launch).
    /// Call only with fixed cell-index values, never with a changing time argument.
    private static func fract(_ x: Double) -> Double {
        let v = sin(x * 12.9898 + 78.233) * 43758.5453
        return v - v.rounded(.down)
    }
    private static func comps(_ c: Color) -> (r: Double, g: Double, b: Double) {
        let ui = UIColor(c)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
    private static func lerp3(_ s: [(r: Double, g: Double, b: Double)], _ p: Double) -> Color {
        let x = min(1, max(0, p))
        let (a, b, t) = x < 0.5 ? (s[0], s[1], x / 0.5) : (s[1], s[2], (x - 0.5) / 0.5)
        return Color(red: a.r + (b.r - a.r) * t,
                     green: a.g + (b.g - a.g) * t,
                     blue: a.b + (b.b - a.b) * t)
    }
}

#if DEBUG
#Preview("Cases — three states") {
    let samples = (try? DeckCatalogService().loadSummaries()) ?? []
    let states: [DeckDisplayState] = [.locked, .sealed, .opened]
    return ZStack {
        AppColors.void.ignoresSafeArea()
        ScrollView {
            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: AppSpacing.lg) {
                ForEach(Array(samples.enumerated()), id: \.element.id) { index, s in
                    DeckCaseView(summary: s,
                                 style: DeckStyle.make(for: s),
                                 state: states[index % states.count],
                                 width: 150)
                }
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}
#endif
