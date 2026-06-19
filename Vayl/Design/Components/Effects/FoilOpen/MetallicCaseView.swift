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

/// A crack in the sealed case, anchored in FACE-LOCAL UV (0…1 across the front
/// face) so it sticks to the case through float and tilt. The FoilOpen module's
/// own currency — consumers map their tear records into this.
struct CaseTear: Identifiable, Equatable {
    let id: UUID
    let faceUV: CGPoint
    let seed: UInt64
    /// When the strike landed — the crack propagates outward from this moment.
    let struck: Date
    /// Dominant orientation of the main fracture (degrees; 0 = horizontal).
    let angleDeg: Double
}

struct MetallicCaseView: View {

    // MARK: - Tunables

    var depthFrac:      CGFloat = 0.26   // box depth as a fraction of face width (chunky tuck-box)
    var tiltAmplitude:  Double  = 6      // float tilt amplitude (deg) — subtle
    var floatSpeed:     Double  = 0.7
    var perspective:    Double  = 820    // larger = flatter perspective
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
    var flatScale:      CGFloat = 1.0    // footprint while FLAT on the felt — fills the frame, matching the deck that melted
    var latticeColumns: Double = 13      // hex columns across the face width
    var grooveWidth:    Double = 0.10    // groove half-width in cell units
    var bandSharpness:  Double = 10      // band specular exponent
    var bandGain:       Double = 0.9     // band strength
    var glintGain:      Double = 0.5     // per-cell glint strength
    var bandTravel:     Double = 0.35    // band phase per degree of Y tilt
    var theme: FoilDeckTheme   = .vayl

    // Arrival pose (ceremony spec Beat 3): nil = full float pose (default for
    // previews and any consumer that doesn't choreograph an arrival). Set to a
    // Date to drive the rise from that moment: FACE-ON flat on the felt (the
    // table's card grammar — matching the deck that melted) tipping back into
    // the floating ¾ box. Material stays asleep until latticeWakeStart.
    var riseStart:    Date?  = nil
    var riseDuration: Double = 1.4

    /// When the hex lattice + band WAKE (ceremony: "start the hex animation
    /// upon zoom-in"). `.distantPast` (default) = awake from the first frame;
    /// `.distantFuture` = asleep (plain anodized metal) until the caller
    /// assigns a real date, after which the material fades in over ~1.2s.
    var latticeWakeStart: Date = .distantPast

    /// Cracks on the sealed case (Beat 5 ceremony) — rendered in face space
    /// with colorway light-bleed that escalates per tear.
    var tears: [CaseTear] = []

    /// When the shatter begins (third crack): `.distantFuture` = sealed.
    /// Assigning a real date runs the bloom-flood — colorway light floods the
    /// face through the lattice, then the case dissolves out.
    var dissolveStart: Date = .distantFuture

    /// Tap-to-crack: when set, taps landing on (or near) the FRONT FACE are
    /// converted to face-local UV at tap time — the inverse-bilinear of the
    /// projected quad — and forwarded. The consumer routes them to its store;
    /// the module never owns crack state.
    var onFaceTap: ((CGPoint) -> Void)? = nil

    /// The KNOCK FROM INSIDE (pre-strike anticipation): each new date plays a
    /// brief seam glimmer — light trying a few hex grooves from within. The
    /// consumer pairs it with a physical twitch + soft haptic.
    var knockStart: Date = .distantFuture
    var knockSeed:  UInt64 = 0

    init(theme: FoilDeckTheme = .vayl,
         riseStart: Date? = nil,
         riseDuration: Double = 1.4,
         latticeWakeStart: Date = .distantPast,
         tears: [CaseTear] = [],
         dissolveStart: Date = .distantFuture,
         onFaceTap: ((CGPoint) -> Void)? = nil,
         knockStart: Date = .distantFuture,
         knockSeed: UInt64 = 0) {
        self.theme = theme
        self.riseStart = riseStart
        self.riseDuration = riseDuration
        self.latticeWakeStart = latticeWakeStart
        self.tears = tears
        self.dissolveStart = dissolveStart
        self.onFaceTap = onFaceTap
        self.knockStart = knockStart
        self.knockSeed = knockSeed
    }


    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Per-frame geometry

    /// Everything the Canvas closure AND the foil shader need each frame.
    /// Computed once per frame in `foilLayer` so the shader's front-quad
    /// uniforms always match the Canvas-drawn box exactly.
    private struct CaseGeometry {
        let rx: Double           // X tilt (radians)
        let ry: Double           // Y tilt (radians)
        let ryDeg: Double        // Y tilt (degrees) — drives the band phase
        let hueDeg: Double       // hue driver — anchored at the float's resting yaw
                                 // through flat + rise so the metal NEVER changes
                                 // colour as it stands; only the float drift shifts it
        let boxFit: Double       // face width after the pose-mixed scale — one source for draw + culling
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

    private func caseGeometry(size: CGSize, t: Double, motion: Bool, pose: Double,
                              calm: Double = 0) -> CaseGeometry {
        // float — biased to a clear 3/4 view (static angle shows the 3D), with only a
        // gentle drift on top so it reads as floating without "moving too much".
        // `pose` mixes from the flat-on-the-felt arrival to the floating ¾ view.
        // FLAT follows the table's card grammar: a card lying on the felt is a
        // FACE-ON flat graphic (rx = ry = 0, full footprint) — exactly how the
        // melted deck looked — never a real-3D edge-on sliver. The rise tips it
        // back into the ¾ view: the flat printed thing stands up into a 3D box.
        let osc = (motion ? 1.0 : 0.0) * pose * (1.0 - calm)
        let restYawDeg = 21.0                // the float's resting ¾ yaw
        let ryDeg = restYawDeg * pose
                  + osc * tiltAmplitude        * dsin(t * 0.42 * floatSpeed)
        let rxDeg = -16.0 * pose
                  + osc * tiltAmplitude * 0.4 * dcos(t * 0.31 * floatSpeed)
        let rx = rxDeg * .pi / 180, ry = ryDeg * .pi / 180
        // Hue rides the RESTING yaw, not the rise sweep — the flat case is the
        // same purple it will float at; standing up never reads as a recolour.
        let hueDeg = ryDeg + restYawDeg * (1.0 - pose)

        // box dimensions — flat fills the frame (the deck's footprint), the
        // floating pose settles to boxScale so the tilt has margin to swing in
        let scaleMix = Double(flatScale) + (Double(boxScale) - Double(flatScale)) * pose
        let fit = Double(min(size.width, size.height / 1.5)) * scaleMix
        let w = fit, h = fit * 1.5, d = fit * Double(depthFrac)
        let hx = w / 2, hy = h / 2, hz = d / 2
        let center = CGPoint(x: size.width / 2, y: size.height / 2)

        let corners3D: [SIMD3<Double>] = [
            SIMD3(-hx, -hy,  hz), SIMD3( hx, -hy,  hz), SIMD3( hx,  hy,  hz), SIMD3(-hx,  hy,  hz),
            SIMD3(-hx, -hy, -hz), SIMD3( hx, -hy, -hz), SIMD3( hx,  hy, -hz), SIMD3(-hx,  hy, -hz),
        ]
        let proj = corners3D.map { project(rotate($0, rx: rx, ry: ry), center: center) }
        return CaseGeometry(rx: rx, ry: ry, ryDeg: ryDeg, hueDeg: hueDeg, boxFit: fit,
                            proj: proj, frontQuad: Array(proj[0...3]))
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            Group {
                if reduceMotion {
                    foilLayer(size: size, t: 0, motion: false)
                } else {
                    TimelineView(.animation) { tl in
                        foilLayer(size: size, t: tl.date.timeIntervalSinceReferenceDate, motion: true)
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { value in
                    handleTap(value.location, size: size)
                },
                including: onFaceTap == nil ? .none : .all
            )
        }
    }

    /// The shatter timeline, two acts from `dissolveStart`:
    ///   OVERLOAD (0…0.45s) — every crack flares white-hot, the light inside
    ///   maxes out, nothing moves: the held breath before the shell gives.
    ///   FLOOD (0.45…2.0s) — the bloom erupts and the case dissolves under it.
    /// Reduce Motion snaps both to done (the consumer's cross-dissolve covers it).
    private func dissolvePhases(t: Double, motion: Bool) -> (overload: Double, flood: Double) {
        if dissolveStart == .distantFuture { return (0, 0) }
        guard motion else { return (1, 1) }
        let e = t - dissolveStart.timeIntervalSinceReferenceDate
        let overload = min(1, max(0, e / 0.45))
        let f = min(1, max(0, (e - 0.45) / 1.55))
        return (overload, f * f * (3 - 2 * f))
    }

    /// Convert a tap in view space to face-local UV via the inverse-bilinear of
    /// the CURRENT projected front quad (same geometry path the renderer uses),
    /// then forward it. Taps near the face edge are clamped in — during the
    /// ceremony "the case" is the target, not a precise quad.
    private func handleTap(_ point: CGPoint, size: CGSize) {
        guard let onFaceTap else { return }
        let motion = !reduceMotion
        let t = motion ? Date.now.timeIntervalSinceReferenceDate : 0
        let pose = risePose(t: t, motion: motion)
        let geo = caseGeometry(size: size, t: t, motion: motion, pose: pose)
        guard let uv = invBilinear(point, quad: geo.frontQuad),
              (-0.18...1.18).contains(uv.x), (-0.18...1.18).contains(uv.y) else { return }
        onFaceTap(CGPoint(x: min(max(uv.x, 0.04), 0.96),
                          y: min(max(uv.y, 0.04), 0.96)))
    }

    @ViewBuilder
    private func foilLayer(size: CGSize, t: Double, motion: Bool) -> some View {
        let pose = risePose(t: t, motion: motion)
        let wake = latticeWake(t: t, motion: motion)
        let (overload, flood) = dissolvePhases(t: t, motion: motion)
        // the world holds its breath: the float drift damps to stillness
        // through the overload — nothing sways while the cracks scream
        let geo = caseGeometry(size: size, t: t, motion: motion, pose: pose, calm: overload)
        Canvas { ctx, _ in
            drawCase(&ctx, size: size, geo: geo)
            drawKnock(&ctx, geo: geo, t: t, motion: motion)
            drawTears(&ctx, geo: geo, overload: overload, t: t, motion: motion)
            drawBloom(&ctx, geo: geo, flood: flood)
        }
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
            // Shatter: the bloom-flood peaks mid-dissolve (drawn in-canvas so it
            // ignites THROUGH the lattice), then the case dissolves out under it.
            .opacity(flood <= 0.5 ? 1 : max(0, 1 - (flood - 0.5) / 0.5))
    }

    // MARK: - Draw

    private func drawCase(_ ctx: inout GraphicsContext, size: CGSize, geo: CaseGeometry) {
        let rx = geo.rx, ry = geo.ry

        // ONE metal colour for the whole case (shifts slowly as it tilts — anodized).
        let caseHue = hueOffset + geo.hueDeg * hueShift
        // single light, mostly FRONTAL (high +z) so the front + top read bright and the side
        // panels go genuinely darker — that contrast is what makes the 3D box legible as it moves.
        let light = SIMD3(-0.20, -0.62, 0.72)

        // box dimensions — needed locally for face culling (rotated corner depth);
        // geo.boxFit carries the pose-mixed scale so culling matches the projection
        let fit = geo.boxFit
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

    /// Flat anodized faces — per-face brightness carries the 3D, the hex foil
    /// shader owns ALL the light play (band, glints, grooves). The old white
    /// specular streak predated the lattice and is gone for good.
    private func metalShading(caseHue: Double, brightness b: Double,
                              a: CGPoint, c: CGPoint) -> GraphicsContext.Shading {
        let core  = Self.metalHue(caseHue / 360)               // the single metal hue
        let grey  = (core.x + core.y + core.z) / 3
        let desat = mix(core, SIMD3(grey, grey, grey), 1 - saturation)
        let metal = mix(desat, Self.anchorDark, metalDarkness)
        let lit   = metal * b                                  // face brightness = the 3D read
        let lo    = lit * 0.88                                  // gentle edge falloff (no dark corners)
        return .linearGradient(
            Gradient(stops: [
                .init(color: color(lo),  location: 0.0),
                .init(color: color(lit), location: 0.5),
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

    // MARK: - Crack ceremony (tears + bloom-flood)

    /// The knock from inside: a 0.7s seam glimmer — light tries a few hex
    /// grooves from within, somewhere mid-face. Plays once per `knockStart`
    /// date; deterministic per `knockSeed`. Reduce Motion: none.
    private func drawKnock(_ ctx: inout GraphicsContext, geo: CaseGeometry,
                           t: Double, motion: Bool) {
        guard motion, knockStart != .distantFuture else { return }
        let age = t - knockStart.timeIntervalSinceReferenceDate
        guard age >= 0, age < 0.7 else { return }
        let bell = dsin(min(age / 0.7, 1) * .pi)

        var rng = SplitMix64(seed: knockSeed)
        let u = Double.random(in: 0.30...0.70, using: &rng)
        let v = Double.random(in: 0.25...0.75, using: &rng)
        var current = nearestHexVertex(SIMD2(u * latticeColumns, v * 1.5 * latticeColumns))
        var previous = current
        var path = Path()
        if let start = wrapPoint(current, geo: geo) { path.move(to: start) }
        for _ in 0..<3 {
            let options = hexNeighbors(of: current).filter { dist2($0, previous) > 0.01 }
            guard let next = options.shuffled(using: &rng).first,
                  let pt = wrapPoint(next, geo: geo) else { break }
            path.addLine(to: pt)
            previous = current
            current = next
        }

        let spectrum = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [theme.colorway.c0, theme.colorway.c1, theme.colorway.c2]),
            startPoint: geo.frontQuad[0], endPoint: geo.frontQuad[2])
        var glow = ctx
        glow.opacity = 0.40 * bell
        glow.addFilter(.blur(radius: 5))
        glow.stroke(path, with: spectrum, lineWidth: 3.5)
        var crisp = ctx
        crisp.opacity = 0.5 * bell
        crisp.stroke(path, with: spectrum, lineWidth: 1.0)
    }

    /// Cracks rendered in face space: each tear's branch polylines live in UV,
    /// mapped through the CURRENT projected quad every frame — the crack rides
    /// the case through float and tilt. The strike is an EVENT, not a decal:
    /// branches PROPAGATE outward from the finger (~0.22s), flash white-hot on
    /// impact with an expanding shock ring, and taper from a wide wound at the
    /// strike to hairline tips. Light-bleed escalates per tear and floods
    /// during the shatter.
    private func drawTears(_ ctx: inout GraphicsContext, geo: CaseGeometry,
                           overload: Double, t: Double, motion: Bool) {
        guard !tears.isEmpty else { return }
        let quad = geo.frontQuad
        // THE DECK LIVES UNDER THE SHELL: every crack is a window into it. The
        // leaking light BREATHES (slow pulse, per-tear phase) and its floor
        // RISES with each strike — by the second tear the case visibly can't
        // hold it in. The overload slams everything to maximum and holds.
        let escalation = Double(tears.count - 1)
        let spectrum = GraphicsContext.Shading.linearGradient(
            Gradient(colors: [theme.colorway.c0, theme.colorway.c1, theme.colorway.c2]),
            startPoint: quad[0], endPoint: quad[2])

        // lattice vertices claimed so far this frame — tears generate in strike
        // order, so later cracks route around earlier ones (never cross/merge)
        var occupied = Set<Int64>()

        for tear in tears {
            // Reduce Motion: cracks appear fully formed, steady light, no flash.
            let age   = motion ? max(0, t - tear.struck.timeIntervalSinceReferenceDate) : 10
            let grow  = min(1.0, age / 0.32)
            let growE = 1 - (1 - grow) * (1 - grow)          // easeOut — fast start, soft arrest
            let flash = max(0.0, 1.0 - age / 0.30)           // white-hot impact, gone in 0.3s

            // inner light: breathing pulse unique to each tear, frozen at full
            // during the overload (the held breath — nothing moves)
            let phase = Double(tear.seed % 628) / 100.0
            let pulse = motion ? 0.5 + 0.5 * dsin(t * (2 * .pi / 1.6) + phase) : 1.0
            let bleed = min(1.6, (0.55 + 0.25 * escalation) * (0.7 + 0.5 * pulse)
                                 + 1.0 * overload)
            let widen = 1.0 + 0.18 * escalation + 0.6 * overload

            for branch in crackBranches(tear, geo: geo, occupied: &occupied) {
                let n = branch.count - 1
                guard n > 0 else { continue }
                let reveal = growE * Double(n)

                // revealed portion: full segments + a partial tip mid-propagation
                var revealed = Path()
                revealed.move(to: branch[0])
                var segments: [(Path, Double)] = []      // (segment, tapered width)
                for i in 0..<n {
                    let segP = min(max(reveal - Double(i), 0), 1)
                    guard segP > 0 else { break }
                    let a = branch[i], b = branch[i + 1]
                    let end = segP >= 1 ? b
                        : CGPoint(x: a.x + (b.x - a.x) * segP, y: a.y + (b.y - a.y) * segP)
                    revealed.addLine(to: end)
                    var seg = Path()
                    seg.move(to: a); seg.addLine(to: end)
                    // taper: a wound at the strike, a hairline at the tip
                    let width = 2.6 - 2.0 * Double(i) / Double(max(n - 1, 1))
                    segments.append((seg, width))
                }

                // wide soft halo — light from INSIDE spilling onto the shell
                var halo = ctx
                halo.opacity = min(1.0, 0.30 * bleed)
                halo.addFilter(.blur(radius: 11))
                halo.stroke(revealed, with: spectrum, lineWidth: 12.0 * widen)

                var glow = ctx
                glow.opacity = min(1.0, 0.55 * bleed)
                glow.addFilter(.blur(radius: 4.5))
                glow.stroke(revealed, with: spectrum, lineWidth: 4.5 * widen)

                for (seg, width) in segments {
                    var crisp = ctx
                    crisp.opacity = min(1.0, 0.6 + 0.4 * bleed)
                    crisp.stroke(seg, with: spectrum, lineWidth: width * widen)

                    var core = ctx
                    core.opacity = min(1.0, 0.30 * bleed + 0.65 * flash + overload)
                    core.stroke(seg, with: .color(.white), lineWidth: width * widen * 0.45)
                }
            }

            // shock ring — expands from the strike point and dies as the crack lands
            if flash > 0, motion {
                let origin = bilerp(quad, Double(tear.faceUV.x), Double(tear.faceUV.y))
                let ringP = min(1.0, age / 0.35)
                let radius = 5 + 24 * (1 - (1 - ringP) * (1 - ringP))
                var ring = ctx
                ring.opacity = (1 - ringP) * 0.5
                ring.stroke(Path(ellipseIn: CGRect(x: origin.x - radius, y: origin.y - radius,
                                                   width: radius * 2, height: radius * 2)),
                            with: spectrum, lineWidth: 1.5)
            }
        }
    }

    /// Bloom-flood (after the overload): the light inside finally takes the
    /// shell — it floods the whole silhouette from the last strike outward,
    /// peaking as the case dissolves beneath it. This is the egg giving way.
    private func drawBloom(_ ctx: inout GraphicsContext, geo: CaseGeometry, flood: Double) {
        guard flood > 0.001 else { return }
        let quad = geo.frontQuad
        let centerUV = tears.last?.faceUV ?? CGPoint(x: 0.5, y: 0.5)
        let center = bilerp(quad, Double(centerUV.x), Double(centerUV.y))
        let radius = hypot(quad[2].x - quad[0].x, quad[2].y - quad[0].y) * 1.05
        let hull = roundedFacePath(convexHull(geo.proj), softness: cornerSoftness)
        let peak = dsin(min(flood, 1) * .pi)

        var burst = ctx
        burst.opacity = peak
        burst.fill(hull, with: .radialGradient(
            Gradient(stops: [
                .init(color: .white,                          location: 0.0),
                .init(color: .white,                          location: 0.25),
                .init(color: theme.colorway.c1,               location: 0.6),
                .init(color: theme.colorway.c2.opacity(0.45), location: 1.0),
            ]),
            center: center, startRadius: 0, endRadius: radius))
    }

    /// Cracks propagate ALONG THE HEX GROOVES — the same pointy-top lattice the
    /// foil shader carves (`latticeColumns` across the face, v spanning 1.5× the
    /// width). The break belongs to the material: the seams give way first —
    /// but under high stress a run occasionally CUTS STRAIGHT ACROSS a cell
    /// (a two-vertex chord), so branches mix hex kinks with long fracture runs
    /// instead of reading as uniform zigzag. Deterministic per tear (seeded),
    /// returned as vertex lists so the renderer can propagate + taper them.
    /// One crack = a BIDIRECTIONAL main fracture along the tear's authored
    /// orientation (hero arm + counter arm) plus a short perpendicular stub —
    /// every crack has a strong directional identity, and the director makes
    /// sure no two cracks in a ceremony share one. `occupied` is the set of
    /// lattice vertices already claimed by earlier tears: cracks may run
    /// parallel but can NEVER cross or merge.
    private func crackBranches(_ tear: CaseTear, geo: CaseGeometry,
                               occupied: inout Set<Int64>) -> [[CGPoint]] {
        var rng = SplitMix64(seed: tear.seed)

        // strike point in lattice space (mirrors hexFoilSurface: (u, v·1.5)·lattice)
        let strike = nearestHexVertex(SIMD2(Double(tear.faceUV.x) * latticeColumns,
                                            Double(tear.faceUV.y) * 1.5 * latticeColumns))
        occupied.insert(vertexKey(strike))

        let theta = tear.angleDeg * .pi / 180
        let stubSign: Double = Bool.random(using: &rng) ? 1 : -1
        // (direction, reach): hero arm, counter arm, perpendicular stub.
        // PROPORTION: one hex edge ≈ 4.4% of the face width — long walks or
        // the wound reads as a scratch. Branches WRAP over visible box folds.
        let arms: [(dir: SIMD2<Double>, reach: ClosedRange<Int>)] = [
            (SIMD2(dcos(theta), dsin(theta)),                       12...16),
            (SIMD2(-dcos(theta), -dsin(theta)),                      8...12),
            (SIMD2(dcos(theta + stubSign * .pi / 2),
                   dsin(theta + stubSign * .pi / 2)),                4...7),
        ]

        var branches: [[CGPoint]] = []
        for arm in arms {
            // first step: the free neighbor best aligned with this arm
            let openings = hexNeighbors(of: strike)
                .filter { !occupied.contains(vertexKey($0)) }
            guard let first = openings.max(by: {
                align($0 - strike, arm.dir) < align($1 - strike, arm.dir)
            }) else { continue }
            guard let p0 = wrapPoint(strike, geo: geo),
                  let p1 = wrapPoint(first, geo: geo) else { continue }
            occupied.insert(vertexKey(first))
            var points = [p0, p1]
            var previous = strike
            var current  = first
            let segments = Int.random(in: arm.reach, using: &rng)
            for _ in 0..<segments {
                let options = hexNeighbors(of: current).filter {
                    dist2($0, previous) > 0.01                       // never double back
                    && !occupied.contains(vertexKey($0))             // never cross a crack
                }
                guard !options.isEmpty else { break }
                // hold the authored heading, with noise for the hex kinks
                var next = options.max(by: {
                    align($0 - current, arm.dir) + Double.random(in: 0...0.35, using: &rng)
                  < align($1 - current, arm.dir) + Double.random(in: 0...0.35, using: &rng)
                })!
                // high-stress chord: ~35% of steps cut straight across the cell
                if Double.random(in: 0...1, using: &rng) < 0.35 {
                    let heading = next - current
                    let beyond = hexNeighbors(of: next).filter {
                        dist2($0, current) > 0.01 && !occupied.contains(vertexKey($0))
                    }
                    if let through = beyond.max(by: {
                        align($0 - next, heading) < align($1 - next, heading)
                    }) {
                        next = through      // one straight segment crossing the cell
                    }
                }
                previous = current
                current  = next
                // wrapPoint handles the folds: nil = the branch died at a
                // hidden edge or ran out of box — stop there
                guard let pt = wrapPoint(current, geo: geo) else { break }
                occupied.insert(vertexKey(current))
                points.append(pt)
            }
            branches.append(points)
        }
        return branches
    }

    /// Normalized alignment of a step with a direction (−1…1).
    private func align(_ step: SIMD2<Double>, _ dir: SIMD2<Double>) -> Double {
        let len = (step.x * step.x + step.y * step.y).squareRoot()
        guard len > 1e-9 else { return -1 }
        return (step.x * dir.x + step.y * dir.y) / len
    }

    /// Quantized lattice-vertex key: x lives on multiples of 0.5, y on
    /// multiples of 1/(2√3) — exact integer grid once scaled.
    private func vertexKey(_ v: SIMD2<Double>) -> Int64 {
        let xi = Int64((v.x * 2).rounded())
        let yi = Int64((v.y * 2 * 1.7320508).rounded())
        return (xi << 32) ^ (yi & 0xFFFF_FFFF)
    }

    // MARK: Lattice-space helpers — these mirror hexFoilSurface's grid EXACTLY
    // (pointy-top hexes tiled on r = (1, √3), centers on two offset grids).
    // If the shader's layout changes, these must change with it.

    /// Hex circumradius for apothem 0.5 — also the honeycomb edge length.
    private static let hexR = 1.0 / 1.7320508

    private func uvFromLattice(_ p: SIMD2<Double>) -> CGPoint {
        CGPoint(x: p.x / latticeColumns, y: p.y / (1.5 * latticeColumns))
    }

    /// Face UV → screen, WRAPPING OVER THE BOX FOLDS: u/v beyond [0,1] continue
    /// onto the side/top/bottom faces (the shell fails all around, not just the
    /// front plate). Overhang is mapped across the box depth toward the back
    /// edge; returns nil past the fold of a face the camera can't see, or past
    /// 90% of the depth — the branch dies there.
    private func wrapPoint(_ p: SIMD2<Double>, geo: CaseGeometry) -> CGPoint? {
        let uv = uvFromLattice(p)
        let u = Double(uv.x), v = Double(uv.y)
        let depthU = Double(depthFrac)            // side-face depth in u units
        let depthV = Double(depthFrac) / 1.5      // top/bottom depth in v units
        let proj = geo.proj
        func mixP(_ a: CGPoint, _ b: CGPoint, _ t: Double) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        func facing(_ n: SIMD3<Double>) -> Bool {
            rotate(n, rx: geo.rx, ry: geo.ry).z > 0.04
        }
        switch ((0.0...1.0).contains(u), (0.0...1.0).contains(v)) {
        case (true, true):
            return bilerp(geo.frontQuad, u, v)
        case (false, true):                       // left / right face
            let left = u < 0
            let s = (left ? -u : u - 1) / depthU
            guard s <= 0.9, facing(SIMD3(left ? -1 : 1, 0, 0)) else { return nil }
            return left
                ? mixP(mixP(proj[0], proj[4], s), mixP(proj[3], proj[7], s), v)
                : mixP(mixP(proj[1], proj[5], s), mixP(proj[2], proj[6], s), v)
        case (true, false):                       // top / bottom face
            let top = v < 0
            let s = (top ? -v : v - 1) / depthV
            guard s <= 0.9, facing(SIMD3(0, top ? -1 : 1, 0)) else { return nil }
            return top
                ? mixP(mixP(proj[0], proj[4], s), mixP(proj[1], proj[5], s), u)
                : mixP(mixP(proj[3], proj[7], s), mixP(proj[2], proj[6], s), u)
        default:                                  // past a box corner — stop
            return nil
        }
    }

    private func dist2(_ a: SIMD2<Double>, _ b: SIMD2<Double>) -> Double {
        let d = a - b
        return d.x * d.x + d.y * d.y
    }

    /// Nearest honeycomb VERTEX (cell corner) to a lattice-space point.
    private func nearestHexVertex(_ p: SIMD2<Double>) -> SIMD2<Double> {
        let r = SIMD2(1.0, 1.7320508)
        func wrap(_ x: SIMD2<Double>) -> SIMD2<Double> {
            SIMD2(x.x - r.x * (x.x / r.x).rounded(.down),
                  x.y - r.y * (x.y / r.y).rounded(.down)) - r * 0.5
        }
        let ga = wrap(p)
        let gb = wrap(p - r * 0.5)
        let gv = (ga.x * ga.x + ga.y * ga.y) < (gb.x * gb.x + gb.y * gb.y) ? ga : gb
        let center = p - gv                      // owning cell center
        let R = Self.hexR
        let corners: [SIMD2<Double>] = [
            SIMD2(0,  R), SIMD2(0.5,  R / 2), SIMD2(0.5, -R / 2),
            SIMD2(0, -R), SIMD2(-0.5, -R / 2), SIMD2(-0.5, R / 2),
        ]
        return corners
            .map { center + $0 }
            .min(by: { dist2($0, p) < dist2($1, p) })!
    }

    /// A honeycomb vertex's 3 neighbors: probe all 6 edge directions and keep
    /// the ones that land on a real vertex — no parity bookkeeping to drift.
    private func hexNeighbors(of v: SIMD2<Double>) -> [SIMD2<Double>] {
        let R = Self.hexR
        let dirs: [SIMD2<Double>] = [
            SIMD2(0,  R), SIMD2(0, -R),
            SIMD2( 0.5,  R / 2), SIMD2( 0.5, -R / 2),
            SIMD2(-0.5,  R / 2), SIMD2(-0.5, -R / 2),
        ]
        return dirs.compactMap { d in
            let candidate = v + d
            let snapped = nearestHexVertex(candidate)
            return dist2(snapped, candidate) < (R * 0.05) * (R * 0.05) ? snapped : nil
        }
    }

    /// UV → screen through the projected front quad (TL, TR, BR, BL).
    private func bilerp(_ q: [CGPoint], _ u: Double, _ v: Double) -> CGPoint {
        let top = CGPoint(x: q[0].x + (q[1].x - q[0].x) * u, y: q[0].y + (q[1].y - q[0].y) * u)
        let bot = CGPoint(x: q[3].x + (q[2].x - q[3].x) * u, y: q[3].y + (q[2].y - q[3].y) * u)
        return CGPoint(x: top.x + (bot.x - top.x) * v, y: top.y + (bot.y - top.y) * v)
    }

    /// Screen → UV: analytic inverse-bilinear over the projected front quad
    /// (TL, TR, BR, BL) — the same machinery the foil shader uses, so a tap
    /// lands exactly where the crack will render.
    private func invBilinear(_ p: CGPoint, quad q: [CGPoint]) -> CGPoint? {
        guard q.count == 4 else { return nil }
        let a = SIMD2(Double(q[0].x), Double(q[0].y))
        let b = SIMD2(Double(q[1].x), Double(q[1].y))
        let c = SIMD2(Double(q[2].x), Double(q[2].y))
        let d = SIMD2(Double(q[3].x), Double(q[3].y))
        let pt = SIMD2(Double(p.x), Double(p.y))

        let e = b - a, f = d - a, g = a - b + c - d, h = pt - a
        func cross2(_ x: SIMD2<Double>, _ y: SIMD2<Double>) -> Double { x.x * y.y - x.y * y.x }
        let k2 = cross2(g, f)
        let k1 = cross2(e, f) + cross2(h, g)
        let k0 = cross2(h, e)

        var v: Double
        if abs(k2) < 1e-7 {
            guard abs(k1) > 1e-9 else { return nil }
            v = -k0 / k1
        } else {
            let disc = k1 * k1 - 4 * k2 * k0
            guard disc >= 0 else { return nil }
            let sq = disc.squareRoot()
            let v1 = (-k1 + sq) / (2 * k2)
            let v2 = (-k1 - sq) / (2 * k2)
            // the quad is convex — pick the root nearest the unit interval
            func unitDistance(_ x: Double) -> Double { x < 0 ? -x : (x > 1 ? x - 1 : 0) }
            v = unitDistance(v1) <= unitDistance(v2) ? v1 : v2
        }
        let denX = e.x + g.x * v
        let denY = e.y + g.y * v
        guard max(abs(denX), abs(denY)) > 1e-9 else { return nil }
        let u = abs(denX) > abs(denY) ? (h.x - f.x * v) / denX
                                      : (h.y - f.y * v) / denY
        return CGPoint(x: u, y: v)
    }

    /// Seeded deterministic RNG for crack geometry — same pattern every frame.
    private struct SplitMix64: RandomNumberGenerator {
        var state: UInt64
        init(seed: UInt64) { state = seed }
        mutating func next() -> UInt64 {
            state &+= 0x9E3779B97F4A7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
            z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
            return z ^ (z >> 31)
        }
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
