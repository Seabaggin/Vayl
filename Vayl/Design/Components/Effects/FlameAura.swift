// Design/Components/Effects/FlameAura.swift
// Open Lightly
//
// Wisp-based flame renderer.
// Each wisp is an independent tapered path that:
//   • rises at its own speed
//   • wobbles horizontally via stacked sine offsets (fake turbulence)
//   • shifts colour from hot-pink/magenta at the base → deep purple at tip
//   • fades in opacity as it rises
//
// Rendered entirely in Canvas so there are zero UIKit/CALayer allocations.

import SwiftUI

// ─────────────────────────────────────────────
// MARK: Public view
// ─────────────────────────────────────────────

struct FlameAura: View {

    let intensity: SelectablePill.Intensity

    // Appearance entrance
    @State private var appeared = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Wisps advance at 0.018 per 1/60s tick — 1.08 units/sec — matched here so the
    // gated TimelineView reproduces the original per-frame ticker's rate exactly.
    private static let tRate: Double = 1.08

    private var wispCount: Int {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 9
        case .alive: return 14
        }
    }

    private var maxWispHeight: CGFloat {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 0.72   // fraction of frame height
        case .alive: return 0.92
        }
    }

    private var masterOpacity: Double {
        switch intensity {
        case .dim:   return 0
        case .warm:  return 0.82
        case .alive: return 1.0
        }
    }

    var body: some View {
        Group {
            // Ambient gate — under Reduce Motion / Low Power Mode the flame holds
            // ONE static frame and the per-frame timer subscription is never
            // created, so a backgrounded pill stops burning CPU entirely.
            if reduceMotion || AppAnimation.lowPower {
                wispCanvas(t: 0)
            } else {
                TimelineView(.animation) { timeline in
                    wispCanvas(t: timeline.date.timeIntervalSinceReferenceDate * Self.tRate)
                }
            }
        }
        .opacity(appeared ? masterOpacity : 0)
        .onAppear {
            withAnimation(AppAnimation.enter) { appeared = true }
        }
        .onDisappear { appeared = false }
        .allowsHitTesting(false)
    }

    private func wispCanvas(t: Double) -> some View {
        Canvas { ctx, size in
            guard wispCount > 0 else { return }
            for i in 0..<wispCount {
                drawWisp(ctx: &ctx, size: size, index: i, t: t)
            }
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Wisp renderer
    // ─────────────────────────────────────────────

    private func drawWisp(
        ctx: inout GraphicsContext,
        size: CGSize,
        index: Int,
        t: Double
    ) {
        // Each wisp gets a stable seed so its personality is consistent
        let seed     = Double(index) * 1.618_033          // golden ratio spread
        let baseX    = size.width * lerp(0.08, 0.92, fract(seed * 0.37))

        // Rise phase — wraps 0→1 continuously, offset per wisp
        let risePhase = fract(t * lerp(0.18, 0.32, fract(seed * 0.71)) + fract(seed * 0.53))
        // Ease the rise so wisps accelerate as they climb
        let easedRise = easeInQuad(risePhase)

        let bottomY  = size.height * 0.95
        let topY     = size.height * (1.0 - maxWispHeight * easedRise)
        let wispH    = bottomY - topY
        guard wispH > 2 else { return }

        // Base width tapers to zero at tip
        let baseWidth = size.width * lerp(0.06, 0.14, fract(seed * 0.29))

        // Horizontal turbulence — two stacked sine waves per wisp
        // creates convincing flicker without Perlin noise
        let wobble1  = sin(t * lerp(1.8, 3.2, fract(seed * 0.43)) + seed) * size.width * 0.045
        let wobble2  = sin(t * lerp(3.0, 5.5, fract(seed * 0.67)) + seed * 2.1) * size.width * 0.022

        // Fade in at birth (risePhase 0→0.15), fade out near tip (0.75→1.0)
        let birthFade = smoothStep(0, 0.15, risePhase)
        let deathFade = 1.0 - smoothStep(0.72, 1.0, risePhase)
        let alpha     = birthFade * deathFade

        guard alpha > 0.01 else { return }

        // Build tapered wisp path — 4-point bezier ribbon
        let cx      = baseX + wobble1 + wobble2
        let path    = taperedWispPath(
            cx: cx,
            bottomY: bottomY,
            topY: topY,
            baseWidth: baseWidth,
            wispH: wispH
        )

        // Colour: base = magenta-pink, tip = deep purple
        // We draw the wisp twice:
        //   pass 1 — wide blur  (outer glow / heat haze)
        //   pass 2 — tight blur (bright core)

        let baseColor = lerpColor(
            Color(red: 1.0,  green: 0.15, blue: 0.55),   // hot pink
            Color(red: 0.72, green: 0.10, blue: 0.90),   // magenta-violet
            fract(seed * 0.19)
        )
        let tipColor = Color(red: 0.25, green: 0.02, blue: 0.55) // deep purple

        let gradient = Gradient(stops: [
            .init(color: baseColor.opacity(alpha * 0.90), location: 0.0),
            .init(color: baseColor.opacity(alpha * 0.55), location: 0.35),
            .init(color: tipColor.opacity(alpha  * 0.20), location: 0.78),
            .init(color: tipColor.opacity(0),             location: 1.0),
        ])

        // Pass 1 — diffuse outer glow
        ctx.drawLayer { g in
            g.addFilter(.blur(radius: lerp(8, 18, fract(seed * 0.41))))
            g.fill(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: cx, y: bottomY),
                    endPoint:   CGPoint(x: cx, y: topY)
                )
            )
        }

        // Pass 2 — bright tight core (thinner path, less blur)
        let corePath = taperedWispPath(
            cx: cx,
            bottomY: bottomY,
            topY: topY + wispH * 0.12,
            baseWidth: baseWidth * 0.38,
            wispH: wispH * 0.88
        )
        ctx.drawLayer { g in
            g.addFilter(.blur(radius: lerp(2, 5, fract(seed * 0.53))))
            g.fill(
                corePath,
                with: .linearGradient(
                    Gradient(stops: [
                        .init(color: Color.white.opacity(alpha * 0.55), location: 0.0),
                        .init(color: baseColor.opacity(alpha * 0.40),   location: 0.40),
                        .init(color: tipColor.opacity(0),               location: 1.0),
                    ]),
                    startPoint: CGPoint(x: cx, y: bottomY),
                    endPoint:   CGPoint(x: cx, y: topY)
                )
            )
        }
    }

    // ─────────────────────────────────────────────
    // MARK: Path builder
    // ─────────────────────────────────────────────

    /// Tapered ribbon: full width at bottom, zero at top.
    /// Two cubic bezier sides give it a slight organic curve.
    private func taperedWispPath(
        cx: Double,
        bottomY: Double,
        topY: Double,
        baseWidth: Double,
        wispH: Double
    ) -> Path {
        var p = Path()
        let halfW  = baseWidth / 2
        // Control point pulls the sides inward 1/3 of the way up
        let ctrl1Y = bottomY - wispH * 0.33
        let ctrl2Y = bottomY - wispH * 0.66

        // left side — bottom-left → top (tapers to point)
        p.move(to: CGPoint(x: cx - halfW, y: bottomY))
        p.addCurve(
            to:      CGPoint(x: cx,        y: topY),
            control1: CGPoint(x: cx - halfW * 0.7, y: ctrl1Y),
            control2: CGPoint(x: cx - halfW * 0.2, y: ctrl2Y)
        )
        // right side — top → bottom-right
        p.addCurve(
            to:      CGPoint(x: cx + halfW, y: bottomY),
            control1: CGPoint(x: cx + halfW * 0.2, y: ctrl2Y),
            control2: CGPoint(x: cx + halfW * 0.7, y: ctrl1Y)
        )
        p.closeSubpath()
        return p
    }

    // ─────────────────────────────────────────────
    // MARK: Math helpers
    // ─────────────────────────────────────────────

    private func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double { a + (b - a) * t }
    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: Double) -> CGFloat {
        CGFloat(lerp(Double(a), Double(b), t))
    }
    private func fract(_ x: Double) -> Double { x - floor(x) }
    private func easeInQuad(_ t: Double) -> Double { t * t }
    private func smoothStep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = max(0, min(1, (x - edge0) / (edge1 - edge0)))
        return t * t * (3 - 2 * t)
    }

    private func lerpColor(_ a: Color, _ b: Color, _ t: Double) -> Color {
        let t = max(0, min(1, t))
        // Resolve to UIColor for component access
        let ua = UIColor(a), ub = UIColor(b)
        var (r1,g1,b1,a1): (CGFloat,CGFloat,CGFloat,CGFloat) = (0,0,0,0)
        var (r2,g2,b2,a2): (CGFloat,CGFloat,CGFloat,CGFloat) = (0,0,0,0)
        ua.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        ub.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red:   Double(r1 + (r2-r1) * t),
            green: Double(g1 + (g2-g1) * t),
            blue:  Double(b1 + (b2-b1) * t),
            opacity: Double(a1 + (a2-a1) * t)
        )
    }
}
