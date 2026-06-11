//
//  MetallicCaseView.swift
//  Vayl
//
//  FoilOpen module — Layer 1 (reusable, content-agnostic).
//
//  The sealed deck's 3D tuck-box: near-void anodized metal with the card back's
//  hex lattice DEBOSSED into the front face. A `Canvas` projects the box (front +
//  visible side + top faces, painter-sorted, per-face brightness = the 3D read);
//  the `hexFoilSurface` shader maps pixels into face-local UV over the projected
//  front quad and lights the groove flanks with one tilt-driven anisotropic band
//  in the deck's colorway (`FoilDeckTheme`). Light lives in the carved structure —
//  flats stay dark. The deck name is embossed low on the face in ClashDisplay,
//  same emboss recipe as the VaylCardBack wordmark.
//
//  Drawing the box in a Canvas (rather than nested rotation3DEffect, which SwiftUI
//  can't composite into a shared 3D scene) means the later crack/disintegrate pass
//  draws in the SAME projected face-space → cracks stay ISOLATED on the deck.
//
//  Everything tunable lives as a stored property below — tinker on device.
//

import SwiftUI
import UIKit
import Darwin

struct MetallicCaseView: View {

    // MARK: - Tunables

    var depthFrac:      CGFloat = 0.26   // box depth as a fraction of face width (chunky tuck-box)
    var tiltAmplitude:  Double  = 6      // float tilt amplitude (deg) — subtle
    var floatSpeed:     Double  = 0.7
    var perspective:    Double  = 820    // larger = flatter perspective
    var specular:       Double  = 0.20   // soft base sheen — the holo shader does the highlights
    var saturation:     Double  = 0.95   // richer base (the holo iridescence adds the electric pop)
    var metalDarkness:  Double  = 0.52   // how dark the metal base sits (solid deep colour, not black)
    var ambient:        Double  = 0.28   // floor brightness on faces away from light (low = box reads in 3D)
    var hueOffset:      Double  = 90     // pick the single metal colour (deg) — ≈ deep purple
    var hueShift:       Double  = 1.4    // how much that one colour shifts as it tilts
    var boxScale:       CGFloat = 0.70   // box size as fraction of the fitting square

    // Foil surface — debossed hex lattice (hexFoilSurface). Light lives in the
    // carved structure: groove flanks ignite in the deck colorway as one
    // tilt-driven band sweeps the face. No noise, no time-driven animation.
    var cornerSoftness: Double  = 0.14   // gentle rounding of the box SILHOUETTE (soft tuck-box corners)
    var latticeColumns: Double = 13      // hex columns across the face width
    var grooveWidth:    Double = 0.10    // groove half-width in cell units
    var bandSharpness:  Double = 10      // band specular exponent
    var bandGain:       Double = 0.9     // band strength
    var glintGain:      Double = 0.5     // per-cell glint strength
    var bandTravel:     Double = 0.35    // band phase per degree of Y tilt
    var theme: FoilDeckTheme   = .vayl

    // Arrival pose (ceremony spec Beat 3): nil = full float pose (default for
    // previews and any consumer that doesn't choreograph an arrival). Set to a
    // Date to drive the flat-on-the-felt → vertical rise from that moment; the
    // lattice + band fade in WITH the rise (latticeFade uniform) so the
    // near-degenerate flat quad never shows aliased grooves.
    var riseStart:    Date?  = nil
    var riseDuration: Double = 1.4

    /// When the hex lattice + band WAKE (ceremony: "start the hex animation
    /// upon zoom-in"). `.distantPast` (default) = awake from the first frame;
    /// `.distantFuture` = asleep (plain anodized metal) until the caller
    /// assigns a real date, after which the material fades in over ~1.2s.
    var latticeWakeStart: Date = .distantPast

    init(theme: FoilDeckTheme = .vayl,
         riseStart: Date? = nil,
         riseDuration: Double = 1.4,
         latticeWakeStart: Date = .distantPast) {
        self.theme = theme
        self.riseStart = riseStart
        self.riseDuration = riseDuration
        self.latticeWakeStart = latticeWakeStart
    }


    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Per-frame geometry

    /// Everything the Canvas closure AND the foil shader need each frame.
    /// Computed once per frame in `foilLayer` so the shader's front-quad
    /// uniforms always match the Canvas-drawn box exactly.
    private struct CaseGeometry {
        let rx: Double           // X tilt (radians)
        let ry: Double           // Y tilt (radians)
        let ryDeg: Double        // Y tilt (degrees) — drives metal hue + band phase
        let proj: [CGPoint]      // 8 projected corners
        let frontQuad: [CGPoint] // front face TL, TR, BR, BL (proj[0...3])
    }

    /// 0 = lying flat on the felt · 1 = full float pose. Smoothstep-eased from
    /// `riseStart`; Reduce Motion (motion == false) snaps to the final pose.
    /// A caller that wants the case to MOUNT flat passes `.distantFuture` and
    /// later assigns the real lift moment.
    private func risePose(t: Double, motion: Bool) -> Double {
        guard let riseStart else { return 1 }
        guard motion else { return 1 }
        let elapsed = t - riseStart.timeIntervalSinceReferenceDate
        let p = min(1, max(0, elapsed / riseDuration))
        return p * p * (3 - 2 * p)
    }

    /// 0 = lattice asleep (plain anodized metal) · 1 = fully awake.
    /// Reduce Motion: snaps to the terminal state (awake unless still pending).
    private func latticeWake(t: Double, motion: Bool) -> Double {
        if latticeWakeStart == .distantFuture { return 0 }
        guard motion else { return 1 }
        let e = (t - latticeWakeStart.timeIntervalSinceReferenceDate) / 1.2
        let p = min(1, max(0, e))
        return p * p * (3 - 2 * p)
    }

    private func caseGeometry(size: CGSize, t: Double, motion: Bool, pose: Double) -> CaseGeometry {
        // float — biased to a clear 3/4 view (static angle shows the 3D), with only a
        // gentle drift on top so it reads as floating without "moving too much".
        // `pose` mixes from the flat-on-the-felt arrival (rx ≈ −86°, minimal yaw,
        // no oscillation) to the floating ¾ view.
        let osc = (motion ? 1.0 : 0.0) * pose
        let ryDeg = (2.0 + (21.0 - 2.0) * pose)
                  + osc * tiltAmplitude        * dsin(t * 0.42 * floatSpeed)
        let rxDeg = (-86.0 + (-16.0 + 86.0) * pose)
                  + osc * tiltAmplitude * 0.4 * dcos(t * 0.31 * floatSpeed)
        let rx = rxDeg * .pi / 180, ry = ryDeg * .pi / 180

        // box dimensions — fit a 3:2 portrait face into the frame with margin
        let fit = Double(min(size.width, size.height / 1.5)) * Double(boxScale)
        let w = fit, h = fit * 1.5, d = fit * Double(depthFrac)
        let hx = w / 2, hy = h / 2, hz = d / 2
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        let corners3D: [SIMD3<Double>] = [
            SIMD3(-hx, -hy,  hz), SIMD3( hx, -hy,  hz), SIMD3( hx,  hy,  hz), SIMD3(-hx,  hy,  hz),
            SIMD3(-hx, -hy, -hz), SIMD3( hx, -hy, -hz), SIMD3( hx,  hy, -hz), SIMD3(-hx,  hy, -hz),
        ]
        let proj = corners3D.map { project(rotate($0, rx: rx, ry: ry), center: center) }
        return CaseGeometry(rx: rx, ry: ry, ryDeg: ryDeg,
                            proj: proj, frontQuad: Array(proj[0...3]))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            if reduceMotion {
                foilLayer(size: size, t: 0, motion: false)
            } else {
                TimelineView(.animation) { tl in
                    foilLayer(size: size, t: tl.date.timeIntervalSinceReferenceDate, motion: true)
                }
            }
        }
    }

    @ViewBuilder
    private func foilLayer(size: CGSize, t: Double, motion: Bool) -> some View {
        let pose = risePose(t: t, motion: motion)
        let wake = latticeWake(t: t, motion: motion)
        let geo = caseGeometry(size: size, t: t, motion: motion, pose: pose)
        Canvas { ctx, _ in drawCase(&ctx, size: size, geo: geo) }
            // Debossed hex foil — the band phase is driven by the FLOAT TILT, not
            // time, so the light only moves because the box moves (and Reduce
            // Motion freezes both together). No absolute timestamps reach the GPU.
            .colorEffect(ShaderLibrary.hexFoilSurface(
                .float2(geo.frontQuad[0]),
                .float2(geo.frontQuad[1]),
                .float2(geo.frontQuad[2]),
                .float2(geo.frontQuad[3]),
                .color(theme.colorway.c0),
                .color(theme.colorway.c1),
                .color(theme.colorway.c2),
                .float(Float(geo.ryDeg * bandTravel)),
                .float(Float(latticeColumns)),
                .float(Float(grooveWidth)),
                .float(Float(bandSharpness)),
                .float(Float(bandGain)),
                .float(Float(glintGain)),
                .float(Float(wake))
            ))
    }

    // MARK: - Draw

    private func drawCase(_ ctx: inout GraphicsContext, size: CGSize, geo: CaseGeometry) {
        let rx = geo.rx, ry = geo.ry

        // ONE metal colour for the whole case (shifts slowly as it tilts — anodized).
        let caseHue = hueOffset + geo.ryDeg * hueShift
        // single light, mostly FRONTAL (high +z) so the front + top read bright and the side
        // panels go genuinely darker — that contrast is what makes the 3D box legible as it moves.
        let light = SIMD3(-0.20, -0.62, 0.72)

        // box dimensions — needed locally for face culling (rotated corner depth)
        let fit = Double(min(size.width, size.height / 1.5)) * Double(boxScale)
        let w = fit, h = fit * 1.5, d = fit * Double(depthFrac)
        let hx = w / 2, hy = h / 2, hz = d / 2

        // 8 corners (front face = +z)
        let corners3D: [SIMD3<Double>] = [
            SIMD3(-hx, -hy,  hz), SIMD3( hx, -hy,  hz), SIMD3( hx,  hy,  hz), SIMD3(-hx,  hy,  hz),
            SIMD3(-hx, -hy, -hz), SIMD3( hx, -hy, -hz), SIMD3( hx,  hy, -hz), SIMD3(-hx,  hy, -hz),
        ]

        let proj = geo.proj

        // faces: corner indices, outward normal (one colour for all — they differ by lighting)
        struct Face { let idx: [Int]; let n: SIMD3<Double>; let isFront: Bool }
        let faces: [Face] = [
            Face(idx: [0,1,2,3], n: SIMD3(0,0, 1), isFront: true),   // front
            Face(idx: [1,5,6,2], n: SIMD3( 1,0,0), isFront: false),  // right
            Face(idx: [4,0,3,7], n: SIMD3(-1,0,0), isFront: false),  // left
            Face(idx: [4,5,1,0], n: SIMD3(0,-1,0), isFront: false),  // top
            Face(idx: [3,2,6,7], n: SIMD3(0, 1,0), isFront: false),  // bottom
            Face(idx: [5,4,7,6], n: SIMD3(0,0,-1), isFront: false),  // back
        ]

        // visible faces (rotated normal toward camera), painter-sorted back→front
        let visible = faces
            .map { face -> (f: Face, rn: SIMD3<Double>, cz: Double) in
                let rn = rotate(face.n, rx: rx, ry: ry)
                let cz = face.idx.reduce(0.0) { acc, i in acc + rotate(corners3D[i], rx: rx, ry: ry).z } / 4
                return (face, rn, cz)
            }
            .filter { $0.rn.z > 0.001 }
            .sorted { $0.cz < $1.cz }

        // soft tuck-box silhouette: gently round the convex hull of the projected corners and
        // clip to it → soft outer corners with NO gaps; the panel folds inside stay crisp.
        ctx.clip(to: roundedFacePath(convexHull(proj), softness: cornerSoftness))

        for v in visible {
            let pts = v.f.idx.map { proj[$0] }
            var face = Path()
            face.move(to: pts[0])
            for p in pts.dropFirst() { face.addLine(to: p) }
            face.closeSubpath()

            // per-face brightness from a single light → top bright, front mid, side dark = 3D
            let brightness = max(ambient, (v.rn * light).sum())
            let shading = metalShading(caseHue: caseHue, brightness: brightness,
                                       a: pts[0], c: pts[2])
            ctx.fill(face, with: shading)
        }

        // embossed brand layer (deck name + hairline frame) on the front face
        if let front = visible.first(where: { $0.f.isFront }) {
            drawBrand(&ctx, quad: front.f.idx.map { proj[$0] })
        }
    }

    /// Convex hull (monotone chain) of the projected box corners → the outer silhouette.
    private func convexHull(_ input: [CGPoint]) -> [CGPoint] {
        let pts = input.sorted { $0.x != $1.x ? $0.x < $1.x : $0.y < $1.y }
        guard pts.count >= 3 else { return pts }
        func cross(_ o: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
            (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
        }
        var lower: [CGPoint] = []
        for p in pts {
            while lower.count >= 2, cross(lower[lower.count - 2], lower[lower.count - 1], p) <= 0 { lower.removeLast() }
            lower.append(p)
        }
        var upper: [CGPoint] = []
        for p in pts.reversed() {
            while upper.count >= 2, cross(upper[upper.count - 2], upper[upper.count - 1], p) <= 0 { upper.removeLast() }
            upper.append(p)
        }
        lower.removeLast(); upper.removeLast()
        return lower + upper
    }

    // MARK: - Metallic shading

    private func metalShading(caseHue: Double, brightness b: Double,
                              a: CGPoint, c: CGPoint) -> GraphicsContext.Shading {
        let core  = Self.metalHue(caseHue / 360)               // the single metal hue
        let grey  = (core.x + core.y + core.z) / 3
        let desat = mix(core, SIMD3(grey, grey, grey), 1 - saturation)
        let metal = mix(desat, Self.anchorDark, metalDarkness)
        let lit   = metal * b                                  // face brightness = the 3D read
        let lo    = lit * 0.88                                  // gentle edge falloff (no dark corners)
        let hi    = mix(core, SIMD3(1, 1, 1), 0.40 + 0.40 * specular) * min(1.0, b * 1.25)
        let sw    = 0.16 - 0.06 * specular                     // sharper specular at high specular
        return .linearGradient(
            Gradient(stops: [
                .init(color: color(lo),  location: 0.0),
                .init(color: color(lit), location: 0.5 - sw),
                .init(color: color(hi),  location: 0.5),
                .init(color: color(lit), location: 0.5 + sw),
                .init(color: color(lo),  location: 1.0),
            ]),
            startPoint: a, endPoint: c)
    }

    // MARK: - Brand layer (embossed deck name + hairline frame)

    /// Affine map of the unit square onto the projected front quad (TL,TR,BR,BL).
    /// Drops perspective — acceptable at this float's low tilt, same approximation
    /// the old emblem used.
    private func frontFaceTransform(_ q: [CGPoint]) -> CGAffineTransform {
        let o = q[0], bx = q[1], by = q[3]
        return CGAffineTransform(a: bx.x - o.x, b: bx.y - o.y,
                                 c: by.x - o.x, d: by.y - o.y,
                                 tx: o.x, ty: o.y)
    }

    private func drawBrand(_ ctx: inout GraphicsContext, quad: [CGPoint]) {
        guard quad.count == 4 else { return }
        let edgeW = hypot(quad[1].x - quad[0].x, quad[1].y - quad[0].y)
        guard edgeW > 1 else { return }

        // — hairline inset frame, colorway gradient, drawn in unit-face space —
        // (unit square maps to the w × 1.5w face, so y-insets divide by 1.5)
        var fc = ctx
        fc.concatenate(frontFaceTransform(quad))
        let inset = 9.0 / edgeW                   // matches the card back's 9pt inset
        let frame = Path(roundedRect: CGRect(x: inset, y: inset * (2.0 / 3.0),
                                             width: 1 - inset * 2,
                                             height: 1 - inset * (4.0 / 3.0)),
                         cornerRadius: 0.03)
        fc.stroke(
            frame,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: theme.colorway.c0.opacity(0.27), location: 0.0),
                    .init(color: theme.colorway.c1.opacity(0.27), location: 0.5),
                    .init(color: theme.colorway.c2.opacity(0.27), location: 1.0),
                ]),
                startPoint: CGPoint(x: inset, y: 0.5),
                endPoint:   CGPoint(x: 1 - inset, y: 0.5)
            ),
            lineWidth: 0.6 / edgeW
        )

        // — embossed deck name, screen space at the projected anchor (low-center) —
        let cx = (quad[0].x + quad[1].x + quad[2].x + quad[3].x) / 4
        let cy = (quad[0].y + quad[1].y + quad[2].y + quad[3].y) / 4
        let anchor   = CGPoint(x: cx, y: cy + edgeW * 0.52)
        let fontSize = edgeW * 0.085

        func nameText(_ fs: CGFloat) -> Text {
            Text(theme.deckName)
                .font(AppFonts.display(fs, weight: .medium, relativeTo: .title))
                .tracking(fontSize * 0.45)
        }

        // emboss passes — same recipe as the VaylCardBack wordmark
        var shadowPass = ctx
        shadowPass.addFilter(.blur(radius: 0.8))
        shadowPass.draw(nameText(fontSize).foregroundStyle(Color.black.opacity(0.55)),
                        at: CGPoint(x: anchor.x + 0.8, y: anchor.y + 0.9), anchor: .center)

        var highlightPass = ctx
        highlightPass.addFilter(.blur(radius: 0.6))
        highlightPass.draw(nameText(fontSize).foregroundStyle(Color.white.opacity(0.45)),
                           at: CGPoint(x: anchor.x - 0.7, y: anchor.y - 0.8), anchor: .center)

        var corePass = ctx
        corePass.clipToLayer(opacity: 0.90) { clip in
            clip.draw(nameText(fontSize).foregroundStyle(Color.white),
                      at: anchor, anchor: .center)
        }
        let bounds = CGRect(x: anchor.x - fontSize * 4, y: anchor.y - fontSize,
                            width: fontSize * 8, height: fontSize * 2)
        corePass.fill(
            Path(bounds),
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: theme.colorway.c0, location: 0.0),
                    .init(color: theme.colorway.c1, location: 0.4),
                    .init(color: theme.colorway.c2, location: 1.0),
                ]),
                startPoint: CGPoint(x: bounds.minX, y: anchor.y),
                endPoint:   CGPoint(x: bounds.maxX, y: anchor.y)
            )
        )
    }

    // MARK: - 3D math

    private func rotate(_ p: SIMD3<Double>, rx: Double, ry: Double) -> SIMD3<Double> {
        // rotate around X then Y
        let y1 = p.y * dcos(rx) - p.z * dsin(rx)
        let z1 = p.y * dsin(rx) + p.z * dcos(rx)
        let x2 = p.x * dcos(ry) + z1 * dsin(ry)
        let z2 = -p.x * dsin(ry) + z1 * dcos(ry)
        return SIMD3(x2, y1, z2)
    }

    private func project(_ p: SIMD3<Double>, center: CGPoint) -> CGPoint {
        let s = perspective / (perspective - p.z)
        return CGPoint(x: center.x + CGFloat(p.x * s), y: center.y + CGFloat(p.y * s))
    }

    // Disambiguate cos/sin: CoreGraphics' cos(CGFloat) + implicit CGFloat↔Double
    // conversion makes the bare calls ambiguous. Darwin has only the Double overload.
    private func dcos(_ x: Double) -> Double { Darwin.cos(x) }
    private func dsin(_ x: Double) -> Double { Darwin.sin(x) }

    // MARK: - Surface (foil)

    /// A face path with rounded corners — softens the machined-plate read toward foil.
    private func roundedFacePath(_ pts: [CGPoint], softness: Double) -> Path {
        var path = Path()
        guard pts.count >= 3 else { return path }
        if softness <= 0 {
            path.move(to: pts[0]); for p in pts.dropFirst() { path.addLine(to: p) }
            path.closeSubpath(); return path
        }
        let n = pts.count
        for i in 0..<n {
            let cur = pts[i], prev = pts[(i + n - 1) % n], next = pts[(i + 1) % n]
            let r = min(dist(cur, prev), dist(cur, next)) * 0.5 * CGFloat(softness)
            let a = lerpPoint(cur, prev, r)
            let b = lerpPoint(cur, next, r)
            if i == 0 { path.move(to: a) } else { path.addLine(to: a) }
            path.addQuadCurve(to: b, control: cur)
        }
        path.closeSubpath()
        return path
    }

    private func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(b.x - a.x, b.y - a.y) }
    private func lerpPoint(_ from: CGPoint, _ to: CGPoint, _ d: CGFloat) -> CGPoint {
        let len = max(0.0001, dist(from, to))
        let f = min(1, d / len)
        return CGPoint(x: from.x + (to.x - from.x) * f, y: from.y + (to.y - from.y) * f)
    }

    // MARK: - Colour helpers

    private func mix(_ a: SIMD3<Double>, _ b: SIMD3<Double>, _ t: Double) -> SIMD3<Double> {
        a + (b - a) * t
    }
    private func color(_ v: SIMD3<Double>) -> Color {
        Color(red: min(1, max(0, v.x)), green: min(1, max(0, v.y)), blue: min(1, max(0, v.z)))
    }

    /// Cyclic interpolation cyan → purple → magenta → cyan, p in 0...1.
    private static func metalHue(_ p: Double) -> SIMD3<Double> {
        let x = ((p.truncatingRemainder(dividingBy: 1)) + 1).truncatingRemainder(dividingBy: 1)
        let anchors = [anchorCyan, anchorPurple, anchorMagenta, anchorCyan]
        let seg = min(2, Int(x * 3))
        let lt = x * 3 - Double(seg)
        return anchors[seg] + (anchors[seg + 1] - anchors[seg]) * lt
    }

    // spectrum tokens resolved to RGB once, for the metallic math (no raw colour literals)
    private static func components(_ c: Color) -> SIMD3<Double> {
        let ui = UIColor(c)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        _ = ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return SIMD3(Double(r), Double(g), Double(b))
    }
    private static let anchorCyan    = components(AppColors.spectrumCyan)
    private static let anchorPurple  = components(AppColors.spectrumPurple)
    private static let anchorMagenta = components(AppColors.spectrumMagenta)
    private static let anchorDark    = components(AppColors.void)
}

// MARK: - Preview

#Preview("Metallic case") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        MetallicCaseView()
    }
    .preferredColorScheme(.dark)
}

// Reuse-contract proof: a different colorway + deck name with ZERO code changes.
// Ramp deliberately reuses existing tokens in a different order — the real
// category legend (sex, jealousy, …) is defined later.
#Preview("Alt deck theme") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        MetallicCaseView(theme: FoilDeckTheme(
            colorway: FoilColorway(
                c0: AppColors.spectrumMagenta,
                c1: AppColors.spectrumPurple,
                c2: AppColors.spectrumCyan
            ),
            deckName: "JEALOUSY"
        ))
    }
    .preferredColorScheme(.dark)
}

// Temporary verification harness — judge every foil segment against the card
// back it must complement. Same footprint for both so value range, spectrum
// order, and texture family compare directly.
#Preview("Case vs card back") {
    ZStack {
        AppColors.void.ignoresSafeArea()
        HStack(spacing: AppSpacing.md) {
            let cardW = AppLayout.obCardWidth(in: 240)
            let cardH = AppLayout.obCardHeight(in: 240)
            MetallicCaseView()
                .frame(width: cardW, height: cardH)
            VaylCardBack()
                .frame(width: cardW, height: cardH)
        }
    }
    .preferredColorScheme(.dark)
}
