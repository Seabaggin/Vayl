// Design/Components/Cards/CardFaces/ContextCardFace.swift
//
// Content face for the relationship-context cards (ContextPhase carousel).
// Rendered by VaylCardFace when its content is `.context(...)`.
//
// Signature object: a folded MAP with a dropped location pin — the phase's
// identity ("Where are you starting from?"), mirroring how NamePhase uses the
// typewriter, ModeSelect the controller, Gender the slot machine. The map is a
// pure Canvas line illustration in the spectrum language (two passes: a blurred
// glow + a crisp stroke), occupying the upper region; the number + title sit
// beneath it as the card's header.
//
// Dark-only, spectrum language. All geometry proportional to card width
// (OB card-face rule — no fixed pixels). `subtitle`/`detail`/`isFront` are
// retained as props (unused for rendering) so the 4-param `.context` call site
// in VaylCardFace keeps compiling; subtitle/detail are shown by ContextPhase in
// its bottom panel, not on the card.

import SwiftUI

struct ContextCardFace: View {

    let number:   String
    let title:    String
    let subtitle: String
    let detail:   String
    var isFront:  Bool = true

    var body: some View {
        GeometryReader { geo in
            let w   = geo.size.width
            let h   = geo.size.height
            let pad = w * 0.10

            VStack(alignment: .leading, spacing: 0) {

                // Signature object — fills the upper region, leaves room below.
                MapObject()
                    .frame(maxWidth: .infinity)
                    .frame(height: h * 0.46)

                Spacer(minLength: 0)

                // Header — number overline + title headline
                Text(number)
                    .font(AppFonts.overline)
                    .foregroundStyle(AppColors.spectrumText)
                    .opacity(0.55)

                Text(title)
                    .font(AppFonts.display(24, weight: .semibold, relativeTo: .title2))
                    .foregroundStyle(AppColors.spectrumText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, w * 0.02)
            }
            .padding(pad)
            .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
        }
    }
}

// MARK: - Map object (Canvas line illustration)

/// Folded map + dropped location pin. Pure Canvas illustration — no state.
/// Viewbox 160 × 120; every coordinate × s (= width / 160) maps to a point.
/// Two passes: a blurred glow on the primary outline + pin, then crisp strokes
/// with subordinate elements dimmed.
private struct MapObject: View {

    var body: some View {
        Canvas { context, size in

            // Scale the 160-wide viewbox to fill the available width, then center
            // the 120-tall drawing vertically in the canvas frame.
            let s: CGFloat = size.width / 160
            let drawnH = 120 * s
            let yOffset = (size.height - drawnH) / 2
            context.translateBy(x: 0, y: max(0, yOffset))

            // ── Spectrum gradient shading ─────────────────────────────
            let specGrad = Gradient(stops: [
                .init(color: AppColors.spectrumCyan,    location: 0.00),
                .init(color: AppColors.spectrumPurple,  location: 0.50),
                .init(color: AppColors.spectrumMagenta, location: 1.00),
            ])
            let shading = GraphicsContext.Shading.linearGradient(
                specGrad,
                startPoint: CGPoint(x: 0,          y: 0),
                endPoint:   CGPoint(x: 160 * s,    y: 120 * s)
            )

            // ── Geometry (160 × 120 viewbox) ──────────────────────────
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * s, y: y * s) }

            // 1. Map sheet — a slightly skewed quad (laid-out folded map)
            let tl = p(16, 20), tr = p(146, 12), br = p(152, 90), bl = p(12, 98)
            var mapPath = Path()
            mapPath.move(to: tl)
            mapPath.addLine(to: tr)
            mapPath.addLine(to: br)
            mapPath.addLine(to: bl)
            mapPath.closeSubpath()

            // 2. Fold creases — two vertical-ish lines at ~1/3 and ~2/3
            func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
                CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
            }
            var crease1 = Path()
            crease1.move(to: lerp(tl, tr, 0.34))
            crease1.addLine(to: lerp(bl, br, 0.34))
            var crease2 = Path()
            crease2.move(to: lerp(tl, tr, 0.67))
            crease2.addLine(to: lerp(bl, br, 0.67))

            // 3. Contour lines — two nested rounded curves (left-third terrain)
            let contourOuter = Path(ellipseIn: CGRect(x: 22 * s, y: 50 * s, width: 36 * s, height: 26 * s))
            let contourInner = Path(ellipseIn: CGRect(x: 30 * s, y: 56 * s, width: 20 * s, height: 14 * s))

            // 4. Route — a dashed path winding toward the pin
            var route = Path()
            route.move(to: p(28, 86))
            route.addCurve(to: p(70, 66), control1: p(44, 84), control2: p(56, 70))
            route.addCurve(to: p(104, 58), control1: p(84, 62), control2: p(96, 60))

            // 5. Location pin — one smooth teardrop marker (round head → point),
            //    like the 📍 silhouette. Sides are true tangents from the tip to the
            //    head circle, so head and point are a single continuous outline.
            let pinCx: CGFloat = 104, pinCy: CGFloat = 34, pinR: CGFloat = 12
            let pinTipLen: CGFloat = 32                       // head center → tip
            let theta = acos(pinR / pinTipLen)               // tangent half-angle
            let tip  = p(pinCx, pinCy + pinTipLen)
            let tanA = p(pinCx - pinR * sin(theta), pinCy + pinR * cos(theta))  // lower-left
            let angA = atan2(pinR * cos(theta), -pinR * sin(theta))
            let angB = atan2(pinR * cos(theta),  pinR * sin(theta))
            var pinPath = Path()
            pinPath.move(to: tip)
            pinPath.addLine(to: tanA)
            pinPath.addArc(center: p(pinCx, pinCy), radius: pinR * s,
                           startAngle: .radians(Double(angA)),
                           endAngle:   .radians(Double(angB) + 2 * .pi),
                           clockwise:  false)              // over the top, back to lower-right
            pinPath.addLine(to: tip)
            pinPath.closeSubpath()
            // Inner ring — the marker's hole
            let pinHoleR: CGFloat = 4
            let pinHole = Path(ellipseIn: CGRect(
                x: (pinCx - pinHoleR) * s, y: (pinCy - pinHoleR) * s,
                width: pinHoleR * 2 * s, height: pinHoleR * 2 * s))
            // Ground tick under the tip
            let pinBase = Path(ellipseIn: CGRect(
                x: (pinCx - 7) * s, y: (pinCy + pinTipLen - 1) * s,
                width: 14 * s, height: 4 * s))

            // ── Stroke styles ─────────────────────────────────────────
            let mapStroke     = StrokeStyle(lineWidth: 1.3 * s, lineCap: .round, lineJoin: .round)
            let creaseStroke  = StrokeStyle(lineWidth: 0.7 * s, lineCap: .round, dash: [3 * s, 3 * s])
            let contourStroke = StrokeStyle(lineWidth: 0.7 * s, lineCap: .round)
            let routeStroke   = StrokeStyle(lineWidth: 1.0 * s, lineCap: .round, dash: [4 * s, 4 * s])
            let pinStroke     = StrokeStyle(lineWidth: 1.5 * s, lineCap: .round, lineJoin: .round)

            // ── Pass 1: Glow — map outline + pin head/point ───────────
            context.drawLayer { ctx in
                ctx.addFilter(.blur(radius: 3 * s))
                ctx.opacity = 0.26
                ctx.stroke(mapPath, with: shading, style: StrokeStyle(lineWidth: 6 * s, lineJoin: .round))
                ctx.stroke(pinPath, with: shading, style: StrokeStyle(lineWidth: 5 * s, lineJoin: .round))
            }

            // ── Pass 2: Crisp ─────────────────────────────────────────

            // Contours — dim terrain hint
            var contourCtx = context
            contourCtx.opacity = 0.34
            contourCtx.stroke(contourOuter, with: shading, style: contourStroke)
            contourCtx.stroke(contourInner, with: shading, style: contourStroke)

            // Fold creases — dim
            var creaseCtx = context
            creaseCtx.opacity = 0.30
            creaseCtx.stroke(crease1, with: shading, style: creaseStroke)
            creaseCtx.stroke(crease2, with: shading, style: creaseStroke)

            // Route — medium dim
            var routeCtx = context
            routeCtx.opacity = 0.55
            routeCtx.stroke(route, with: shading, style: routeStroke)

            // Map outline — full
            context.stroke(mapPath, with: shading, style: mapStroke)

            // Pin base tick — dim (dropped-on-map feel)
            var baseCtx = context
            baseCtx.opacity = 0.30
            baseCtx.stroke(pinBase, with: shading, style: contourStroke)

            // Pin — bold teardrop marker (the focal point) + inner hole
            context.stroke(pinPath, with: shading, style: pinStroke)
            context.stroke(pinHole, with: shading, style: StrokeStyle(lineWidth: 1.1 * s))
        }
    }
}

// MARK: - Preview

#Preview("Context face — map") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        VaylCardFace(
            content: .context(
                number:   "01",
                title:    "I'm single",
                subtitle: "Dating and still figuring out who I am in NM",
                detail:   "No relationship to navigate — just you and your curiosity."
            )
        )
        .frame(
            width:  AppLayout.obCardWidth(in: 390),
            height: AppLayout.obCardHeight(in: 390)
        )
    }
    .preferredColorScheme(.dark)
}
