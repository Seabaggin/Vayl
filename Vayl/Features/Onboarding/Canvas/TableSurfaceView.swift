//
//  TableSurfaceView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//

// Features/Onboarding/Canvas/TableSurfaceView.swift

import SwiftUI

// MARK: — TableSurfaceView
/// Layer 3 in OnboardingCanvasView.
/// Draws the full Vayl card table:
///   0. Upper void atmosphere — blobs in the card travel zone above the arc
///   1. Felt fill
///   2. Vignette — corner and top darkening
///   3. Topo contour lines
///   4. Compass star
///   5. Amber overhead pool
///   6. Spectrum rim arc + inner glow
///
/// Visibility is controlled entirely by fade — never by conditional rendering.
/// VaylDirector writes fade. SwiftUI animates it. This view never animates itself.
/// This view never responds to gestures and never holds state.
///
/// STRUCTURE — three stacked Canvases, split by what actually animates:
///   • TableBaseCanvas  (atmosphere + felt + vignette) — static; drawn once per size.
///   • TableTopoCanvas  (contour lines) — Animatable over warp/flowOut/forgeEnergy;
///     redraws per frame ONLY during the gender dissolution and the forge ceremony,
///     from precomputed TopoField samples (no per-frame noise evaluation).
///   • TableRimCanvas   (compass + amber pool + rim arc) — Animatable over rimBurst;
///     redraws per frame only while a rim burst decays.
///   `fade` is a plain `.opacity` on the stack — SwiftUI animates the composited
///   texture natively, so a table fade re-renders NOTHING.
/// The previous single-Canvas version made ALL of body's inputs animatable, which
/// re-evaluated the entire surface (62 noise-driven contour lines included) on
/// every frame of every fade and every card-landing rim burst — the main source
/// of dropped frames across the whole OB.
struct TableSurfaceView: View {

    // ── Parameters ────────────────────────────────────────────────────────────

    /// 0.0 = invisible, 1.0 = fully present.
    /// Never animated by this view — caller drives the value.
    /// VaylDirector is the only thing that writes this.
    var fade: Double
    /// 0.0 = resting spectrum rim. 1.0 = full impact flare.
    /// Caller drives — VaylDirector does not own this value.
    var rimBurst: Double = 0

    /// 0.0–0.52 — topo lines pulled inward toward card footprint (early dissolution).
    /// Driven by VaylDirector.dissolutionWarp. Zero when no card is crystallising.
    var dissolutionWarp: Double = 0

    /// 0.0–1.0 — topo lines deflect around card rounded-rect boundary (later dissolution).
    /// Driven by VaylDirector.dissolutionFlowOut. Zero when no card is crystallising.
    var dissolutionFlowOut: Double = 0

    /// 0.0–1.0 — the table "works": topo lines sway laterally with a per-line
    /// phase (forge ceremony). BuildDeckPhase oscillates this while the deck
    /// is being forged under the felt. Zero everywhere else.
    var forgeEnergy: Double = 0

    // ── Body ──────────────────────────────────────────────────────────────────

    var body: some View {
        ZStack {
            TableBaseCanvas()
            TableTopoCanvas(
                dissolutionWarp:    dissolutionWarp,
                dissolutionFlowOut: dissolutionFlowOut,
                forgeEnergy:        forgeEnergy
            )
            TableRimCanvas(rimBurst: rimBurst)
        }
        .opacity(fade)
        // No .animation(value: fade) here — the caller's withAnimation drives the
        // opacity natively. A view-level animation would retarget every caller
        // curve and low-pass all table fades to one duration regardless of intent.
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: — Preview
#Preview("Table Surface — Dark") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        TableSurfaceView(fade: 1.0)
    }
    .preferredColorScheme(.dark)
}

// MARK: — Shared geometry

/// The primary table geometry every layer derives from. All constants come from
/// AppLayout tokens — nothing hardcoded inside any sub-layer function.
private struct TableGeometry {
    let W:      CGFloat
    let H:      CGFloat
    let TY:     CGFloat   // arc peak Y on screen
    let tableR: CGFloat   // large radius — top cap only
    let cx:     CGFloat   // horizontal center
    let cy:     CGFloat   // circle center below screen
    let dpX:    CGFloat   // deal point x — arc centerline
    let dpY:    CGFloat   // deal point y — sits on arc

    init(size: CGSize) {
        W      = size.width
        H      = size.height
        TY     = H * AppLayout.tableArcPeakYFrac
        tableR = H * AppLayout.tableArcRadiusFrac
        cx     = W * 0.50
        cy     = TY + tableR
        dpX    = cx
        dpY    = TY + 1
    }
}

// MARK: — Base canvas (static: atmosphere + felt + vignette)

private struct TableBaseCanvas: View {

    var body: some View {
        Canvas { context, size in
            let g = TableGeometry(size: size)
            drawUpperAtmosphere(context: context, size: size, W: g.W, H: g.H, TY: g.TY)
            drawFeltFill(context: context, size: size, cx: g.cx, cy: g.cy, tableR: g.tableR)
            drawVignette(context: context, size: size, W: g.W, H: g.H)
        }
    }

    private func drawUpperAtmosphere(
        context: GraphicsContext,
        size:    CGSize,
        W:       CGFloat,
        H:       CGFloat,
        TY:      CGFloat
    ) {
        let rect = CGRect(origin: .zero, size: size)

        struct Blob {
            let cx:     CGFloat
            let cy:     CGFloat
            let radius: CGFloat
            let color:  Color
        }

        let blobs: [Blob] = [
            // Large purple blob — upper left. Primary atmospheric anchor.
            // 0.058 — highest blob opacity, sets the atmospheric ceiling.
            Blob(cx: W * 0.18, cy: H * 0.10, radius: W * 0.60,
                 color: AppColors.spectrumPurple.opacity(0.058)),

            // Smaller purple blob — upper right. Secondary anchor.
            // 0.032 — half of primary, standard atmospheric falloff.
            Blob(cx: W * 0.82, cy: H * 0.08, radius: W * 0.46,
                 color: AppColors.spectrumPurple.opacity(0.032)),

            // Center purple bloom — sits at the deal point horizon.
            // 0.024 — tertiary, fills the center void without competing.
            Blob(cx: W * 0.50, cy: H * 0.22, radius: W * 0.52,
                 color: AppColors.spectrumPurple.opacity(0.024)),

            // Left cyan accent — adds spectral width to the atmosphere.
            // 0.016 — minimal, chromatic accent only.
            Blob(cx: W * 0.10, cy: H * 0.38, radius: W * 0.36,
                 color: AppColors.spectrumCyan.opacity(0.016)),

            // Right magenta accent — mirrors cyan for chromatic balance.
            // 0.014 — slightly lower than cyan so cyan leads.
            Blob(cx: W * 0.90, cy: H * 0.35, radius: W * 0.34,
                 color: AppColors.spectrumMagenta.opacity(0.014)),
        ]

        for blob in blobs {
            context.fill(
                Path(rect),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: blob.color,            location: 0),
                        .init(color: blob.color.opacity(0), location: 1),
                    ]),
                    center:      CGPoint(x: blob.cx, y: blob.cy),
                    startRadius: 0,
                    endRadius:   blob.radius
                )
            )
        }
    }

    private func drawFeltFill(
        context: GraphicsContext,
        size:    CGSize,
        cx:      CGFloat,
        cy:      CGFloat,
        tableR:  CGFloat
    ) {
        let gradient = Gradient(stops: [
            .init(color: AppColors.tableFeltCore,  location: 0.00),
            .init(color: AppColors.tableFeltMid,   location: 0.25),
            .init(color: AppColors.tableFeltOuter, location: 0.60),
            .init(color: AppColors.tableFeltEdge,  location: 1.00),
        ])

        var path = Path()
        path.addEllipse(in: CGRect(
            x: cx - tableR, y: cy - tableR,
            width: tableR * 2, height: tableR * 2
        ))

        context.fill(
            path,
            with: .radialGradient(
                gradient,
                center:      CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius:   tableR
            )
        )
    }

    private func drawVignette(
        context: GraphicsContext,
        size:    CGSize,
        W:       CGFloat,
        H:       CGFloat
    ) {
        let rect = CGRect(origin: .zero, size: size)

        // Four corner radial gradients — darken edges so the felt reads
        // as lit from the center overhead source. Edges fall into shadow.
        // AppColors.void is the darkest OB canvas surface — correct for vignette.
        // 0.82 — corner opacity. Strong enough to feel like physical shadow,
        // not so strong that it clips the topo lines near the card boundary.
        let cornerRadius  = W * 0.76
        let cornerOpacity = 0.82

        let corners: [CGPoint] = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: W, y: 0),
            CGPoint(x: W, y: H),
            CGPoint(x: 0, y: H),
        ]

        for corner in corners {
            context.fill(
                Path(rect),
                with: .radialGradient(
                    Gradient(stops: [
                        .init(color: AppColors.void.opacity(cornerOpacity), location: 0),
                        .init(color: AppColors.void.opacity(0),             location: 1),
                    ]),
                    center:      corner,
                    startRadius: 0,
                    endRadius:   cornerRadius
                )
            )
        }

        // Top linear gradient — darkens the top 20% of the screen.
        // Directs the eye toward the arc and deal point.
        // 0.45 — present enough to read as void depth, low enough
        // not to crush the atmosphere blobs beneath it.
        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: AppColors.void.opacity(0.45), location: 0.00),
                    .init(color: AppColors.void.opacity(0),    location: 1.00),
                ]),
                startPoint: CGPoint(x: W / 2, y: 0),
                endPoint:   CGPoint(x: W / 2, y: H * 0.20)
            )
        )
    }
}

// MARK: — Topo canvas (animatable: dissolution warp/flow + forge sway)

private struct TableTopoCanvas: View, Animatable {

    var dissolutionWarp:    Double
    var dissolutionFlowOut: Double
    var forgeEnergy:        Double

    // Without Animatable conformance a Canvas view receives only the FINAL
    // value of a withAnimation change — the dissolution and forge oscillation
    // would freeze. Conforming makes these genuinely interpolate per frame.
    var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get {
            AnimatablePair(forgeEnergy, AnimatablePair(dissolutionWarp, dissolutionFlowOut))
        }
        set {
            forgeEnergy        = newValue.first
            dissolutionWarp    = newValue.second.first
            dissolutionFlowOut = newValue.second.second
        }
    }

    var body: some View {
        Canvas { context, size in
            drawTopoLines(context: context, size: size)
        }
    }

    private func drawTopoLines(context: GraphicsContext, size: CGSize) {
        let field = TopoField.shared.field(for: size)

        let activeWarp  = dissolutionWarp > 0.001 || dissolutionFlowOut > 0.001
        let activeForge = forgeEnergy > 0.001

        // ── Resting fast path ──────────────────────────────────────────────────
        // No displacement active (the whole OB outside the gender dissolution and
        // the forge ceremony): stroke the precomputed paths and return.
        guard activeWarp || activeForge else {
            for line in field.restingPaths {
                context.stroke(
                    line.path,
                    with: .color(AppColors.tableTopoLine.opacity(line.alpha)),
                    lineWidth: line.width
                )
            }
            return
        }

        // ── Animated path — displace cached base samples per frame ────────────
        let g = TableGeometry(size: size)
        let tableRSqInner = (g.tableR - 2) * (g.tableR - 2)

        // ── Card geometry for dissolution warp + flow-around ──────────────────
        // Derived entirely from AppLayout tokens — no raw geometry values.
        let cardW:      CGFloat = AppLayout.obTableCardWidth(in: g.W) * AppLayout.obTableCardCinematicScale
        let cardH:      CGFloat = cardW * 1.5   // 3:2 portrait ratio — matches obTableCardHeight derivation
        let cardCX:     CGFloat = g.W * 0.50
        let cardCY:     CGFloat = g.H * AppLayout.obGenderCardRestYFrac
        let cardRadius: CGFloat = AppRadius.obCard

        // Tuning constants — calibrated against the HTML prototype.
        let warpPullStrength:    CGFloat = 0.55  // inward pull magnitude at influence edge
        let flowInsidePush:      CGFloat = 0.92  // push-to-boundary strength inside card
        let flowOutsideBend:     CGFloat = 0.70  // tangential bend strength outside card
        let flowInfluenceRadius: CGFloat = 0.38  // influence zone as fraction of cardW

        let netWarp = CGFloat(dissolutionWarp) * (1 - CGFloat(dissolutionFlowOut))
        let netFlow = CGFloat(dissolutionFlowOut) * 0.68
        let fe      = CGFloat(forgeEnergy)

        for line in field.lines {
            var path      = Path()
            var wasInside = false

            for sample in line.samples {
                var px = sample.x
                let py = sample.y

                // ── Forge sway — the table works (BuildDeck ceremony) ─────────
                // Each line breathes laterally with its own phase; amplitude
                // scales with forgeEnergy so the felt is dead-still at 0.
                // 4.5 — max sway amplitude (pt). Rendering constant.
                if activeForge {
                    px += sin(sample.depthT * 5.2 + line.seed * 4.7 + fe * .pi * 2) * 4.5 * fe
                }

                // ── Dissolution warp + flow-around ────────────────────────────
                // Only runs when the gender card is crystallising.
                if activeWarp {
                    // — Phase 1: WARP — topo lines pulled inward toward card centre.
                    // Decays as flowOut rises — warp gives way to flow-around.
                    if netWarp > 0.001 {
                        let wdx = px - cardCX
                        let wdy = py - cardCY
                        let wd  = sqrt(wdx*wdx + wdy*wdy)
                        // 0.85 — warp influence radius as fraction of cardW.
                        let wr = cardW * 0.85
                        if wd < wr && wd > 0.001 {
                            let wf = pow(1 - wd/wr, 2.2)
                            px -= wdx * netWarp * wf * warpPullStrength
                        }
                    }

                    // — Phase 2: FLOW-AROUND — deflect lines at card rounded-rect boundary.
                    // SDF gives the signed distance to the card outline:
                    //   < 0 = inside card   → push point to nearest boundary
                    //   > 0 = outside, near → bend tangentially along boundary
                    if netFlow > 0.001 {
                        let sdf        = rrSDF(px: px, py: py,
                                               cx: cardCX, cy: cardCY,
                                               w: cardW,   h: cardH, r: cardRadius)
                        let influenceR = cardW * flowInfluenceRadius

                        if sdf < influenceR {
                            let rawProx  = 1 - max(0, min(1, sdf / influenceR))
                            // Smoothstep — prevents hard edge at influence boundary.
                            let smoothP  = rawProx * rawProx * (3 - 2 * rawProx)
                            let bx = nearestOnRRx(px: px, py: py,
                                                  cx: cardCX, cy: cardCY,
                                                  w: cardW,   h: cardH, r: cardRadius)
                            if sdf < 0 {
                                // Inside card: push all the way to the boundary.
                                px += (bx - px) * netFlow * smoothP * flowInsidePush
                            } else {
                                // Outside but close: gentle tangential bend.
                                px += (bx - px) * netFlow * smoothP * flowOutsideBend
                            }
                        }
                    }
                }

                let dx     = px - g.cx
                let dyCir  = py - g.cy
                let distSq = dx * dx + dyCir * dyCir
                let inside = distSq < tableRSqInner && py >= g.TY - 2

                if inside {
                    if !wasInside { path.move(to: CGPoint(x: px, y: py)) }
                    else          { path.addLine(to: CGPoint(x: px, y: py)) }
                }
                wasInside = inside
            }

            if !path.isEmpty {
                context.stroke(
                    path,
                    with: .color(AppColors.tableTopoLine.opacity(line.alpha)),
                    lineWidth: line.width
                )
            }
        }
    }

    // MARK: - Dissolution SDF Helpers

    /// Signed distance field for a rounded rectangle.
    /// Returns < 0 if `(px, py)` is inside, > 0 if outside.
    /// Used by drawTopoLines to determine which flow-around force to apply.
    private func rrSDF(px: CGFloat, py: CGFloat,
                       cx: CGFloat, cy: CGFloat,
                       w:  CGFloat, h:  CGFloat,
                       r:  CGFloat) -> CGFloat {
        let qx = abs(px - cx) - w / 2 + r
        let qy = abs(py - cy) - h / 2 + r
        return sqrt(max(qx, 0) * max(qx, 0) + max(qy, 0) * max(qy, 0))
             + min(max(qx, qy), 0) - r
    }

    /// X coordinate of the nearest point on the rounded-rect boundary to `(px, py)`.
    /// For inside points: returns the x of the nearest face centre.
    /// For outside points: returns the x of the nearest corner arc tangent point.
    private func nearestOnRRx(px: CGFloat, py: CGFloat,
                              cx: CGFloat, cy: CGFloat,
                              w:  CGFloat, h:  CGFloat,
                              r:  CGFloat) -> CGFloat {
        let hw = w / 2
        let hh = h / 2
        let dx = px - cx
        let dy = py - cy
        let qx = abs(dx) - hw + r
        let qy = abs(dy) - hh + r

        if qx <= 0 && qy <= 0 {
            // Inside: push to nearest vertical face (left/right wall).
            // If the horizontal distance to the face is smaller, push there;
            // otherwise leave x unchanged (point will push to top/bottom face via y).
            let toFace = hw - abs(dx)
            let toTop  = hh - abs(dy)
            if toFace < toTop {
                return cx + (dx >= 0 ? hw : -hw)
            } else {
                return px
            }
        } else {
            // Outside: project from the nearest corner circle centre.
            let cornerCX = cx + (dx >= 0 ? (hw - r) : -(hw - r))
            let cornerCY = cy + (dy >= 0 ? (hh - r) : -(hh - r))
            let dcx = px - cornerCX
            let dcy = py - cornerCY
            let dl  = sqrt(dcx * dcx + dcy * dcy)
            guard dl > 0.001 else { return cornerCX + r }
            return cornerCX + dcx / dl * r
        }
    }
}

// MARK: — Rim canvas (compass + amber pool + rim arc; animatable: rimBurst)

private struct TableRimCanvas: View, Animatable {

    var rimBurst: Double

    var animatableData: Double {
        get { rimBurst }
        set { rimBurst = newValue }
    }

    var body: some View {
        Canvas { context, size in
            let g = TableGeometry(size: size)
            drawCompassStar(context: context, dpX: g.dpX, dpY: g.dpY, starSize: 20)
            drawAmberPool(context: context, size: size, dpX: g.dpX, dpY: g.dpY, W: g.W)
            drawSpectrumRim(
                context: context, size: size,
                cx: g.cx, cy: g.cy, tableR: g.tableR,
                TY: g.TY, W: g.W, dpX: g.dpX, dpY: g.dpY,
                rimBurst: rimBurst
            )
        }
    }

    private func drawCompassStar(
        context:  GraphicsContext,
        dpX:      CGFloat,
        dpY:      CGFloat,
        starSize: CGFloat
    ) {
        let center = CGPoint(x: dpX, y: dpY)

        // ── Soft glow behind star ──────────────────────────────────────────────
        // Drawn first so all star geometry renders on top.
        // AppGlows.compassStarGlow.color is tuned to 0.07 opacity — whisper presence.
        let glowRadius   = starSize * AppGlows.compassStarGlow.radiusMultiplier
        let glowGradient = Gradient(stops: [
            .init(color: AppGlows.compassStarGlow.color,            location: 0),
            .init(color: AppGlows.compassStarGlow.color.opacity(0), location: 1),
        ])

        var glowPath = Path()
        glowPath.addEllipse(in: CGRect(
            x: dpX - glowRadius, y: dpY - glowRadius,
            width: glowRadius * 2, height: glowRadius * 2
        ))
        context.fill(
            glowPath,
            with: .radialGradient(
                glowGradient,
                center:      center,
                startRadius: 0,
                endRadius:   glowRadius
            )
        )

        // ── Outer halo ring ────────────────────────────────────────────────────
        // 1.18 — halo radius multiplier. Rendering constant — outer decorative ring
        // proportional to star size.
        let haloRadius = starSize * 1.18
        var haloPath   = Path()
        haloPath.addEllipse(in: CGRect(
            x: dpX - haloRadius, y: dpY - haloRadius,
            width: haloRadius * 2, height: haloRadius * 2
        ))
        context.stroke(
            haloPath,
            with: .color(AppColors.tableCompassStar.opacity(0.06)),
            lineWidth: 0.30
        )

        // ── Inner ring ─────────────────────────────────────────────────────────
        // 0.22 — inner ring radius multiplier. Rendering constant.
        let innerRingRadius = starSize * 0.22
        var innerRingPath   = Path()
        innerRingPath.addEllipse(in: CGRect(
            x: dpX - innerRingRadius, y: dpY - innerRingRadius,
            width: innerRingRadius * 2, height: innerRingRadius * 2
        ))
        context.stroke(
            innerRingPath,
            with: .color(AppColors.tableCompassStar.opacity(0.18)),
            lineWidth: 0.35
        )

        // ── 8 spikes ───────────────────────────────────────────────────────────
        // 4 cardinal (even index) + 4 intercardinal (odd index).
        // Each spike: light face + shadow face + thin outline.
        for i in 0 ..< 8 {
            let angle      = (CGFloat(i) / 8.0) * 2 * .pi - (.pi / 2)
            let isCardinal = (i % 2 == 0)

            // 0.46 — intercardinal length ratio. Rendering constant.
            // 0.072 / 0.048 — cardinal and intercardinal base widths. Rendering constants.
            let length:   CGFloat = isCardinal ? starSize         : starSize * 0.46
            let halfBase: CGFloat = isCardinal ? starSize * 0.072 : starSize * 0.048

            let perpAngle = angle + (.pi / 2)

            let tip = CGPoint(
                x: center.x + cos(angle) * length,
                y: center.y + sin(angle) * length
            )
            let baseLeft = CGPoint(
                x: center.x + cos(perpAngle) * halfBase,
                y: center.y + sin(perpAngle) * halfBase
            )
            let baseRight = CGPoint(
                x: center.x - cos(perpAngle) * halfBase,
                y: center.y - sin(perpAngle) * halfBase
            )

            // 0.62 / 0.40 — light face opacities. Rendering constants —
            // simulate overhead light catching the spike face.
            // 0.36 / 0.22 — shadow face opacities. Rendering constants —
            // simulate self-shadow on the opposite spike face.
            let lightOpacity:  Double = isCardinal ? 0.62 : 0.40
            let shadowOpacity: Double = isCardinal ? 0.36 : 0.22

            var lightFace = Path()
            lightFace.move(to: tip)
            lightFace.addLine(to: baseLeft)
            lightFace.addLine(to: center)
            lightFace.closeSubpath()
            context.fill(lightFace,
                         with: .color(AppColors.tableCompassStar.opacity(lightOpacity)))

            var shadowFace = Path()
            shadowFace.move(to: tip)
            shadowFace.addLine(to: baseRight)
            shadowFace.addLine(to: center)
            shadowFace.closeSubpath()
            context.fill(shadowFace,
                         with: .color(AppColors.tableCompassStar.opacity(shadowOpacity)))

            var outline = Path()
            outline.move(to: tip)
            outline.addLine(to: baseLeft)
            outline.addLine(to: center)
            outline.addLine(to: baseRight)
            outline.addLine(to: tip)
            context.stroke(
                outline,
                with: .color(AppColors.tableCompassStar.opacity(0.25)),
                lineWidth: 0.30
            )
        }

        // ── Center octagon ─────────────────────────────────────────────────────
        // 0.075 — octagon radius multiplier. Rendering constant.
        let octRadius = starSize * 0.075
        var octPath   = Path()
        for i in 0 ..< 8 {
            let a     = (CGFloat(i) / 8.0) * 2 * .pi
            let point = CGPoint(
                x: center.x + cos(a) * octRadius,
                y: center.y + sin(a) * octRadius
            )
            if i == 0 { octPath.move(to: point) }
            else       { octPath.addLine(to: point) }
        }
        octPath.closeSubpath()
        context.fill(octPath,
                     with: .color(AppColors.tableCompassStar.opacity(0.72)))
    }

    private func drawAmberPool(
        context: GraphicsContext,
        size:    CGSize,
        dpX:     CGFloat,
        dpY:     CGFloat,
        W:       CGFloat
    ) {
        // 35 — pool center vertical offset below deal point. Rendering constant —
        // pool sits on the near felt surface, not at the arc itself.
        // 0.42 — pool radius as fraction of screen width. Rendering constant.
        let poolCenter = CGPoint(x: dpX, y: dpY + 35)
        let poolRadius = W * 0.42

        let gradient = Gradient(stops: [
            .init(color: AppColors.tableAmberPool,            location: 0),
            .init(color: AppColors.tableAmberPool.opacity(0), location: 1),
        ])

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                gradient,
                center:      poolCenter,
                startRadius: 0,
                endRadius:   poolRadius
            )
        )
    }

    private func drawSpectrumRim(
        context:  GraphicsContext,
        size:     CGSize,
        cx:       CGFloat,
        cy:       CGFloat,
        tableR:   CGFloat,
        TY:       CGFloat,
        W:        CGFloat,
        dpX:      CGFloat,
        dpY:      CGFloat,
        rimBurst: Double
    ) {
        // ── Rim inner glow ─────────────────────────────────────────────────────
        // AppGlows.tableRimInnerGlow.color is tuned to 0.05 opacity — accent only.
        let innerR = tableR - AppGlows.tableRimInnerGlow.innerInset
        let outerR = tableR + AppGlows.tableRimInnerGlow.outerInset
        let peak   = AppGlows.tableRimInnerGlow.peakPosition

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: AppGlows.tableRimInnerGlow.color.opacity(0), location: 0),
                    .init(color: AppGlows.tableRimInnerGlow.color,            location: peak),
                    .init(color: AppGlows.tableRimInnerGlow.color.opacity(0), location: 1),
                ]),
                center:      CGPoint(x: cx, y: cy),
                startRadius: innerR,
                endRadius:   outerR
            )
        )

        // ── Star emission glow along arc ───────────────────────────────────────
        // The compass star sits at arc center (3π/2). A radial gradient from the
        // star position outward makes the arc read as powered by the star.
        // 0.18 — star emit radius multiplier. Rendering constant — tight halo
        // immediately around the star position only.
        // 0.03 — star emit opacity. Rendering constant — atmosphere, not glow.
        let starEmitRadius = tableR * 0.18
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: AppColors.tableCompassStar.opacity(0.03), location: 0),
                    .init(color: AppColors.tableCompassStar.opacity(0),    location: 1),
                ]),
                center:      CGPoint(x: dpX, y: dpY),
                startRadius: 0,
                endRadius:   starEmitRadius
            )
        )

        // ── Tapered spectrum rim arc ───────────────────────────────────────────
        // Arc runs from π (left) to 2π (right) — top arc only.
        // The compass star sits at 3π/2 (top center — the arc midpoint).
        //
        // Taper uses a squared distance curve — holds thick longer at the ends
        // and drops off faster near center so the star feels deliberately spotlit.
        //
        // Crisp stroke:  0.9pt center → 2.7pt edges
        // Base stroke:   crisp × 2.5 (bloom hugs the crisp line exactly)
        // Base pass composited at 0.12 opacity via drawLayer — reads as a glow
        // embedded in the felt surface rather than a fat duplicate stroke.

        // 120 — segment count. Rendering constant — smooth taper at any screen size.
        let segmentCount = 120
        let arcStart:    CGFloat = .pi
        let arcEnd:      CGFloat = 2 * .pi
        let arcMid:      CGFloat = 3 * .pi / 2
        let arcSpan:     CGFloat = arcEnd - arcStart

        // Rendering constants — crisp stroke range.
        let crispThin:   CGFloat = 0.9
        let crispThick:  CGFloat = 2.7
        // 2.5 — base bloom multiplier. Rendering constant — bloom hugs crisp line exactly.
        let baseMultiplier: CGFloat = 2.5
        // rimBurst spikes to 1.0 on card impact, decays to 0.0.
        // Multiplies base pass opacity and rim gradient stops for the flare.
        let burstMult   = 1.0 + rimBurst * 4.0
        let baseOpacity = 0.12 * burstMult

        let bo = min(rimBurst * 2.5, 1.0)  // burst opacity additive, capped
        let rimGradient = Gradient(stops: [
            .init(color: AppColors.spectrumCyan.opacity(0.28 + bo * 0.50),    location: 0.00),
            .init(color: AppColors.spectrumCyan.opacity(0.55 + bo * 0.40),    location: 0.06),
            .init(color: AppColors.spectrumCyan.opacity(0.70 + bo * 0.30),    location: 0.26),
            .init(color: AppColors.spectrumPurple.opacity(0.88 + bo * 0.12),  location: 0.44),
            .init(color: AppColors.spectrumPurple.opacity(0.94 + bo * 0.06),  location: 0.50),
            .init(color: AppColors.spectrumPurple.opacity(0.88 + bo * 0.12),  location: 0.56),
            .init(color: AppColors.spectrumMagenta.opacity(0.70 + bo * 0.30), location: 0.74),
            .init(color: AppColors.spectrumMagenta.opacity(0.55 + bo * 0.40), location: 0.94),
            .init(color: AppColors.spectrumMagenta.opacity(0.28 + bo * 0.50), location: 1.00),
        ])

        let gradStart = CGPoint(x: 0, y: TY)
        let gradEnd   = CGPoint(x: W, y: TY)

        for i in 0 ..< segmentCount {
            let t0 = CGFloat(i)     / CGFloat(segmentCount)
            let t1 = CGFloat(i + 1) / CGFloat(segmentCount)

            let angle0   = arcStart + t0 * arcSpan
            let angle1   = arcStart + t1 * arcSpan
            let angleMid = (angle0 + angle1) / 2

            // Normalised angular distance from arc center (0=star, 1=edge).
            let distFromCenter = abs(angleMid - arcMid) / (arcSpan / 2)

            // Squared taper — holds thick at edges, drops fast near center.
            let taper = distFromCenter * distFromCenter

            let crispWidth = crispThin + (crispThick - crispThin) * taper
            let baseWidth  = crispWidth * baseMultiplier

            var segPath = Path()
            segPath.addArc(
                center:     CGPoint(x: cx, y: cy),
                radius:     tableR,
                startAngle: .radians(angle0),
                endAngle:   .radians(angle1),
                clockwise:  false
            )

            // Base pass — composited at reduced opacity so it reads as a
            // glow embedded in the felt surface, not a fat duplicate stroke.
            context.drawLayer { layerContext in
                layerContext.opacity = baseOpacity
                layerContext.stroke(
                    segPath,
                    with: .linearGradient(rimGradient,
                                          startPoint: gradStart,
                                          endPoint:   gradEnd),
                    lineWidth: baseWidth
                )
            }

            // Crisp top pass — the visible spectrum line.
            context.stroke(
                segPath,
                with: .linearGradient(rimGradient,
                                      startPoint: gradStart,
                                      endPoint:   gradEnd),
                lineWidth: crispWidth
            )
        }
    }
}
