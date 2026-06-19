//
//  TableSurfaceView.swift
//  Vayl
//
//  Created by Bryan Jorden on 5/1/26.
//

// Features/Onboarding/Canvas/TableSurfaceView.swift

import SwiftUI

// MARK: — Pure Math Helpers
// Module-level private functions — no CoreGraphics, no UIKit, pure arithmetic.
// Called exclusively from the Canvas closure in TableSurfaceView.

/// Linear interpolation between two CGFloat values.
private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
    a + (b - a) * t
}

/// Clamp a CGFloat to a closed range.
private func clamp(_ value: CGFloat, _ minimum: CGFloat, _ maximum: CGFloat) -> CGFloat {
    Swift.max(minimum, Swift.min(maximum, value))
}

/// Fractal Brownian Motion — 4 octaves.
/// Combines layered sin/cos noise at increasing frequencies and decreasing
/// amplitudes to produce organic, terrain-like variation along a 2D field.
/// x, y are normalised noise-space coordinates, not screen pixels.
private func fbm(_ x: CGFloat, _ y: CGFloat, _ octaves: Int) -> CGFloat {
    var v: CGFloat         = 0
    var amplitude: CGFloat = 1.0
    var frequency: CGFloat = 1.0
    var sum: CGFloat       = 0

    for octave in 0 ..< octaves {
        let o     = CGFloat(octave)
        let sx    = x * frequency
        let sy    = y * frequency
        let layer =
            sin(sx * 1.10 + sy * 0.65 + o * 2.3) +
            cos(sx * 0.72 - sy * 1.28 + o * 1.8)
        v   += amplitude * layer
        sum += amplitude * 2
        amplitude *= 0.52
        frequency *= 1.95
    }

    return v / sum
}

/// Domain-warped FBM.
/// Displaces the input coordinates using two fbm samples before the final
/// evaluation. Produces the characteristic curved, flowing distortion visible
/// in the topo lines — straight vertical lines would read as digital.
private func domainWarp(_ x: CGFloat, _ y: CGFloat, _ warpStrength: CGFloat) -> CGFloat {
    let wx = fbm(x,       y,       4)
    let wy = fbm(x + 3.8, y + 1.6, 4)
    return fbm(x + warpStrength * wx, y + warpStrength * wy, 4)
}

// MARK: — TableSurfaceView

/// Layer 3 in OnboardingCanvasView.
/// Draws the full Vayl card table in a single Canvas pass:
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
struct TableSurfaceView: View, Animatable {

    // ── Parameter ─────────────────────────────────────────────────────────────

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

    // Without Animatable conformance a Canvas view receives only the FINAL
    // value of a withAnimation change — fades pop and oscillations freeze.
    // Conforming makes fade / rimBurst / forgeEnergy genuinely interpolate.
    var animatableData: AnimatablePair<Double, AnimatablePair<Double, Double>> {
        get { AnimatablePair(fade, AnimatablePair(rimBurst, forgeEnergy)) }
        set {
            fade        = newValue.first
            rimBurst    = newValue.second.first
            forgeEnergy = newValue.second.second
        }
    }

    // ── Body ──────────────────────────────────────────────────────────────────

    var body: some View {
        Canvas { context, size in
            // ── Primary geometry ──────────────────────────────────────────────
            // All geometry constants derive from AppLayout tokens.
            // Nothing is hardcoded inside any sub-layer function.
            let W      = size.width
            let H      = size.height
            let TY     = H * AppLayout.tableArcPeakYFrac    // arc peak Y on screen
            let tableR = H * AppLayout.tableArcRadiusFrac   // large radius — top cap only
            let cx     = W * 0.50                           // horizontal center
            let cy     = TY + tableR                        // circle center below screen
            let dpX    = cx                                 // deal point x — arc centerline
            let dpY    = TY + 1                             // deal point y — sits on arc

            drawUpperAtmosphere(
                context: context, size: size,
                W: W, H: H, TY: TY
            )
            drawFeltFill(
                context: context, size: size,
                cx: cx, cy: cy, tableR: tableR
            )
            drawVignette(
                context: context, size: size,
                W: W, H: H
            )
            drawTopoLines(
                context: context, size: size,
                cx: cx, cy: cy, tableR: tableR,
                TY: TY, W: W, H: H,
                dissolutionWarp:    dissolutionWarp,
                dissolutionFlowOut: dissolutionFlowOut,
                forgeEnergy:        forgeEnergy
            )
            drawCompassStar(
                context: context,
                dpX: dpX, dpY: dpY, starSize: 20
            )
            drawAmberPool(
                context: context, size: size,
                dpX: dpX, dpY: dpY, W: W
            )
            drawSpectrumRim(
                context: context, size: size,
                cx: cx, cy: cy, tableR: tableR,
                TY: TY, W: W, dpX: dpX, dpY: dpY,
                rimBurst: rimBurst
            )
        }
        .opacity(fade)
        // No .animation(value: fade) here — the Animatable conformance already
        // interpolates fade per-frame under the CALLER's withAnimation curve.
        // A view-level animation would retarget every interpolated frame and
        // low-pass all table fades to ~cinematicFade regardless of caller intent.
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: — Layer 0: Upper Void Atmosphere

private extension TableSurfaceView {

    func drawUpperAtmosphere(
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
}

// MARK: — Layer 1: Felt Fill

private extension TableSurfaceView {

    func drawFeltFill(
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
}

// MARK: — Layer 2: Vignette

private extension TableSurfaceView {

    func drawVignette(
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

// MARK: — Layer 3: Topo Lines

private extension TableSurfaceView {

    func drawTopoLines(
        context:            GraphicsContext,
        size:               CGSize,
        cx:                 CGFloat,
        cy:                 CGFloat,
        tableR:             CGFloat,
        TY:                 CGFloat,
        W:                  CGFloat,
        H:                  CGFloat,
        dissolutionWarp:    Double = 0,
        dissolutionFlowOut: Double = 0,
        forgeEnergy:        Double = 0
    ) {
        // 62 — topo line count. Rendering constant — produces the correct
        // visual density of contour lines across the felt surface.
        let lineCount     = 62
        let tableRSqInner = (tableR - 2) * (tableR - 2)

        // ── Card geometry for dissolution warp + flow-around ──────────────────
        // Computed once per drawTopoLines call — not inside the inner loop.
        // Derived entirely from AppLayout tokens — no raw geometry values.
        let cardW:      CGFloat = AppLayout.obTableCardWidth(in: W) * AppLayout.obTableCardCinematicScale
        let cardH:      CGFloat = cardW * 1.5   // 3:2 portrait ratio — matches obTableCardHeight derivation
        let cardCX:     CGFloat = W * 0.50
        let cardCY:     CGFloat = H * AppLayout.obGenderCardRestYFrac
        let cardRadius: CGFloat = AppRadius.obCard

        // Tuning constants — named locals matching existing TableSurfaceView comment style.
        // Rendering constants — calibrated against the HTML prototype.
        let warpPullStrength:    CGFloat = 0.55  // inward pull magnitude at influence edge
        let flowInsidePush:      CGFloat = 0.92  // push-to-boundary strength inside card
        let flowOutsideBend:     CGFloat = 0.70  // tangential bend strength outside card
        let flowInfluenceRadius: CGFloat = 0.38  // influence zone as fraction of cardW

        let activeWarp = dissolutionWarp > 0.001 || dissolutionFlowOut > 0.001

        for li in 0 ..< lineCount {
            let t      = CGFloat(li) / CGFloat(lineCount - 1)
            let startX = lerp(cx - tableR * 0.96, cx + tableR * 0.96, t)

            let isIndex   = (li % 7 == 6)
            // 0.165 / 0.100 — index and standard line opacities.
            // Rendering constants — index lines are bolder for readability.
            let alpha     = isIndex ? 0.165 : 0.100
            // 0.75 / 0.45 — index and standard line widths. Rendering constants.
            let lineWidth = isIndex ? CGFloat(0.75) : CGFloat(0.45)
            // 0.713 / 1.05 — seed values for per-line noise phase offset.
            // Rendering constants — ensure lines look hand-drawn, not stamped.
            let seed      = CGFloat(li) * 0.713 + 1.05

            var path             = Path()
            var wasInside        = false
            var currentPathStart = false

            let yStart = Int(TY) - 6
            let yEnd   = Int(H)

            for pyInt in yStart ... yEnd {
                let py      = CGFloat(pyInt)
                let depthT  = clamp((py - TY) / (H - TY), 0, 1.05)
                // 0.40 — fan sweep scale. Rendering constant — controls how much
                // lines converge toward the bottom of the circle.
                let sweep   = depthT * depthT * W * 0.40
                // 0.09 — lateral fan bias scale. Rendering constant — adds subtle
                // asymmetric perspective to the line convergence.
                let fanBias = (1.0 - t) * depthT * W * 0.09

                let nx = (startX / W) * 2.2 + seed * 0.28
                let ny = depthT * 2.8 + seed * 0.14
                let ws = 0.30 + 0.22 * sin(depthT * .pi)

                let n1 = domainWarp(nx, ny, ws)
                let n2 = fbm(nx * 1.7 + 0.5, ny * 1.3 + seed * 0.4, 4) * 0.50
                let n3 = fbm(nx * 3.8 + 1.1, ny * 2.6 + seed * 0.8, 3) * 0.22

                // 10 / 26 — noise amplitude range. Rendering constants —
                // lines are tighter at the horizon, more organic at depth.
                let noiseAmp: CGFloat = 10 + depthT * 26
                let noiseX            = (n1 + n2 * 0.45 + n3 * 0.20) * noiseAmp
                var px                = startX - sweep - fanBias + noiseX

                // ── Forge sway — the table works (BuildDeck ceremony) ─────────
                // Each line breathes laterally with its own phase; amplitude
                // scales with forgeEnergy so the felt is dead-still at 0.
                // 4.5 — max sway amplitude (pt). Rendering constant.
                if forgeEnergy > 0.001 {
                    let fe = CGFloat(forgeEnergy)
                    px += sin(depthT * 5.2 + seed * 4.7 + fe * .pi * 2) * 4.5 * fe
                }

                // ── Dissolution warp + flow-around ────────────────────────────
                // Only runs when the gender card is crystallising.
                // Skipped entirely when dissolutionWarp and dissolutionFlowOut are both 0.
                if activeWarp {
                    // — Phase 1: WARP — topo lines pulled inward toward card centre.
                    // Decays as flowOut rises — warp gives way to flow-around.
                    let netWarp = CGFloat(dissolutionWarp) * (1 - CGFloat(dissolutionFlowOut))
                    if netWarp > 0.001 {
                        let wdx = px - cardCX
                        let wdy = py - cardCY
                        let wd  = sqrt(wdx*wdx + wdy*wdy)
                        // 0.85 — warp influence radius as fraction of cardW.
                        // Rendering constant — lines beyond this distance are unaffected.
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
                    let netFlow = CGFloat(dissolutionFlowOut) * 0.68
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

                let dx     = px - cx
                let dyCir  = py - cy
                let distSq = dx * dx + dyCir * dyCir
                let inside = distSq < tableRSqInner && py >= TY - 2

                if inside {
                    if !wasInside {
                        path.move(to: CGPoint(x: px, y: py))
                        currentPathStart = true
                    } else {
                        path.addLine(to: CGPoint(x: px, y: py))
                    }
                } else {
                    if wasInside && currentPathStart {
                        context.stroke(
                            path,
                            with: .color(AppColors.tableTopoLine.opacity(alpha)),
                            lineWidth: lineWidth
                        )
                        path             = Path()
                        currentPathStart = false
                    }
                }
                wasInside = inside
            }

            if wasInside && currentPathStart {
                context.stroke(
                    path,
                    with: .color(AppColors.tableTopoLine.opacity(alpha)),
                    lineWidth: lineWidth
                )
            }
        }
    }
}

// MARK: — Dissolution SDF Helpers

private extension TableSurfaceView {

    /// Signed distance field for a rounded rectangle.
    /// Returns < 0 if `(px, py)` is inside, > 0 if outside.
    /// Used by drawTopoLines to determine which flow-around force to apply.
    func rrSDF(px: CGFloat, py: CGFloat,
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
    func nearestOnRRx(px: CGFloat, py: CGFloat,
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

// MARK: — Layer 4: Compass Star

private extension TableSurfaceView {

    func drawCompassStar(
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
}

// MARK: — Layer 5: Amber Overhead Pool

private extension TableSurfaceView {

    func drawAmberPool(
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
}

// MARK: — Layer 6: Spectrum Rim

private extension TableSurfaceView {

    func drawSpectrumRim(
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

// MARK: — Preview

#Preview("Table Surface — Dark") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        TableSurfaceView(fade: 1.0)
    }
    .preferredColorScheme(.dark)
}
